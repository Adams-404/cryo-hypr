#define _GNU_SOURCE
#include <dlfcn.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <time.h>

static ssize_t (*real_write)(int fd, const void *buf, size_t count) = NULL;
static ssize_t (*real_send)(int sockfd, const void *buf, size_t len, int flags) = NULL;

static unsigned long long get_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (unsigned long long)ts.tv_sec * 1000 + (unsigned long long)ts.tv_nsec / 1000000;
}

static unsigned long long last_scroll_time = 0;

static int translate_dispatch(const void *buf, size_t count, char *out, size_t out_len) {
    if (count < 9 || strncmp((const char *)buf, "dispatch ", 9) != 0) {
        return 0;
    }

    char cmd[512] = {0};
    size_t copy_len = count < sizeof(cmd) - 1 ? count : sizeof(cmd) - 1;
    memcpy(cmd, buf, copy_len);
    cmd[copy_len] = '\0';

    // Strip trailing newlines/spaces
    while (copy_len > 0 && (cmd[copy_len - 1] == '\n' || cmd[copy_len - 1] == '\r' || cmd[copy_len - 1] == ' ')) {
        cmd[--copy_len] = '\0';
    }

    const char *rest = cmd + 9;
    while (*rest == ' ') rest++;

    if (strncmp(rest, "workspace ", 10) == 0) {
        const char *arg = rest + 10;
        const char *target_arg = arg;
        if (strcmp(arg, "e+1") == 0 || strcmp(arg, "r+1") == 0) {
            target_arg = "r+1";
        } else if (strcmp(arg, "e-1") == 0 || strcmp(arg, "r-1") == 0) {
            target_arg = "r-1";
        }

        // Debounce relative scroll switches to ensure exactly 1 smooth slide per gesture
        if (target_arg != arg || strcmp(arg, "m+1") == 0 || strcmp(arg, "m-1") == 0) {
            unsigned long long now = get_time_ms();
            if (now - last_scroll_time < 220) {
                // Return harmless no-op that yields "ok" from Hyprland without double-sliding
                snprintf(out, out_len, "/eval true\n");
                return 1;
            }
            last_scroll_time = now;
        }

        snprintf(out, out_len, "/dispatch hl.dsp.focus({ workspace = \"%s\" })\n", target_arg);
        return 1;
    }
    if (strncmp(rest, "focusworkspaceoncurrentmonitor ", 31) == 0) {
        const char *arg = rest + 31;
        snprintf(out, out_len, "/dispatch hl.dsp.focus({ workspace = \"%s\", on_current_monitor = true })\n", arg);
        return 1;
    }
    if (strncmp(rest, "togglespecialworkspace ", 23) == 0) {
        const char *arg = rest + 23;
        snprintf(out, out_len, "/dispatch hl.dsp.workspace.toggle_special(\"%s\")\n", arg);
        return 1;
    }
    if (strcmp(rest, "togglespecialworkspace") == 0) {
        snprintf(out, out_len, "/dispatch hl.dsp.workspace.toggle_special()\n");
        return 1;
    }

    // Generic fallback: dispatch <name> <arg>
    char dsp_name[128] = {0};
    char dsp_arg[256] = {0};
    if (sscanf(rest, "%127s %255[^\n]", dsp_name, dsp_arg) == 2) {
        snprintf(out, out_len, "/dispatch hl.dsp.%s(\"%s\")\n", dsp_name, dsp_arg);
        return 1;
    }
    if (sscanf(rest, "%127s", dsp_name) == 1) {
        snprintf(out, out_len, "/dispatch hl.dsp.%s()\n", dsp_name);
        return 1;
    }

    return 0;
}

ssize_t write(int fd, const void *buf, size_t count) {
    if (!real_write) {
        real_write = dlsym(RTLD_NEXT, "write");
    }

    char trans[1024];
    if (translate_dispatch(buf, count, trans, sizeof(trans))) {
        ssize_t res = real_write(fd, trans, strlen(trans));
        // Return original count so caller thinks its exact buffer was written
        return (res > 0) ? (ssize_t)count : res;
    }

    return real_write(fd, buf, count);
}

ssize_t send(int sockfd, const void *buf, size_t len, int flags) {
    if (!real_send) {
        real_send = dlsym(RTLD_NEXT, "send");
    }

    char trans[1024];
    if (translate_dispatch(buf, len, trans, sizeof(trans))) {
        ssize_t res = real_send(sockfd, trans, strlen(trans), flags);
        return (res > 0) ? (ssize_t)len : res;
    }

    return real_send(sockfd, buf, len, flags);
}
