#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <time.h>
#include <glob.h>

static unsigned long long get_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (unsigned long long)ts.tv_sec * 1000 + (unsigned long long)ts.tv_nsec / 1000000;
}

int main(int argc, char *argv[]) {
    if (argc < 2) return 1;

    // High-performance debounce in /dev/shm (RAM) to ensure exactly 1 slide per gesture
    const char *lock_path = "/dev/shm/cryo_ws_scroll.stamp";
    unsigned long long now_ms = get_time_ms();

    FILE *f = fopen(lock_path, "r+");
    if (f) {
        unsigned long long last_ms = 0;
        if (fscanf(f, "%llu", &last_ms) == 1) {
            if (now_ms - last_ms < 280) { // 280ms debounce matching slide animation
                fclose(f);
                return 0; // Debounced
            }
        }
        rewind(f);
        fprintf(f, "%llu\n", now_ms);
        fclose(f);
    } else {
        f = fopen(lock_path, "w");
        if (f) {
            fprintf(f, "%llu\n", now_ms);
            fclose(f);
        }
    }

    const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
    if (!runtime_dir) return 1;

    char pattern[512];
    snprintf(pattern, sizeof(pattern), "%s/hypr/*/.socket.sock", runtime_dir);
    glob_t g;
    if (glob(pattern, 0, NULL, &g) != 0 || g.gl_pathc == 0) {
        globfree(&g);
        return 1;
    }

    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) {
        globfree(&g);
        return 1;
    }

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, g.gl_pathv[0], sizeof(addr.sun_path) - 1);
    globfree(&g);

    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(sock);
        return 1;
    }

    char cmd[256];
    snprintf(cmd, sizeof(cmd), "/dispatch hl.dsp.focus({ workspace = \"%s\" })\n", argv[1]);
    ssize_t written = write(sock, cmd, strlen(cmd));
    (void)written;

    // Read Hyprland's ok response
    char resp[128];
    ssize_t read_bytes = read(sock, resp, sizeof(resp) - 1);
    (void)read_bytes;

    close(sock);
    return 0;
}
