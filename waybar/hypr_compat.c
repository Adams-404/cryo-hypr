#define _GNU_SOURCE
#include <dlfcn.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>

static ssize_t (*real_write)(int fd, const void *buf, size_t count) = NULL;
static ssize_t (*real_send)(int sockfd, const void *buf, size_t len, int flags) = NULL;

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
        snprintf(out, out_len, "/dispatch hl.dsp.focus({ workspace = \"%s\" })\n", arg);
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
        FILE *f = fopen("/tmp/waybar_shim.log", "a");
        if (f) {
            fprintf(f, "WRITE: %.*s -> %s", (int)count, (const char*)buf, trans);
            fclose(f);
        }
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
