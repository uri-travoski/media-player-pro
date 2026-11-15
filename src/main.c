/*
 * Media Player Pro (v1.2)
 * High-performance media player with complete frosted glass skin and video enhancements.
 * Based on mpv (https://github.com/mpv-player/mpv)
 */

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <sys/stat.h>

#define VERSION "1.2"
#define APP_NAME "Media Player Pro"

static int file_exists(const char *path) {
    struct stat st;
    return (stat(path, &st) == 0);
}

static char *find_resource_dir(void) {
    char exe_path[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
    if (len != -1) {
        exe_path[len] = '\0';
        char *dir = strdup(exe_path);
        char *last_slash = strrchr(dir, '/');
        if (last_slash) {
            *last_slash = '\0'; // directory containing binary
            
            // Check AppImage / bundle path
            char candidate[PATH_MAX];
            snprintf(candidate, sizeof(candidate), "%s/../share/media-player-pro/scripts/media_player_pro_glass.lua", dir);
            if (file_exists(candidate)) {
                snprintf(candidate, sizeof(candidate), "%s/../share/media-player-pro", dir);
                free(dir);
                return strdup(candidate);
            }
            
            // Check local build / repo path
            snprintf(candidate, sizeof(candidate), "%s/../scripts/media_player_pro_glass.lua", dir);
            if (file_exists(candidate)) {
                snprintf(candidate, sizeof(candidate), "%s/..", dir);
                free(dir);
                return strdup(candidate);
            }

            snprintf(candidate, sizeof(candidate), "%s/scripts/media_player_pro_glass.lua", dir);
            if (file_exists(candidate)) {
                char *res = strdup(dir);
                free(dir);
                return res;
            }
        }
        free(dir);
    }

    // Check system install paths
    if (file_exists("/usr/share/media-player-pro/scripts/media_player_pro_glass.lua")) {
        return strdup("/usr/share/media-player-pro");
    }
    if (file_exists("/usr/local/share/media-player-pro/scripts/media_player_pro_glass.lua")) {
        return strdup("/usr/local/share/media-player-pro");
    }
    if (file_exists("/app/share/media-player-pro/scripts/media_player_pro_glass.lua")) { // Flatpak
        return strdup("/app/share/media-player-pro");
    }

    // Fallback to current working directory
    return strdup(".");
}

static void print_version(void) {
    printf("%s v%s\n", APP_NAME, VERSION);
    printf("Modern Glass Skin Media Player based on mpv (https://github.com/mpv-player/mpv)\n");
}

static void print_help(void) {
    print_version();
    printf("\nUsage:\n");
    printf("  media-player-pro [options] [file|URL...]\n\n");
    printf("Features:\n");
    printf("  • Transparent seekbar & non-obstructive floating controls\n");
    printf("  • Remembers last 20 unfinished videos with resume prompt\n");
    printf("  • 7-second skip backward (◄◄) / forward (►►) controls\n");
    printf("  • Speed play dropup (0.25x - 3.0x)\n");
    printf("  • Smooth volume slider & mouse wheel control\n");
    printf("  • Ctrl + Mouse Wheel zoom centered at cursor position\n");
    printf("  • Ctrl + Left Drag to pan video viewport\n");
    printf("  • 3 Genuine Video Enhancement levels (Deband + CAS + Lanczos)\n");
    printf("  • Automatic 3-second non-touch HUD & cursor hiding during playback\n\n");
    printf("Options:\n");
    printf("  --version          Display version information\n");
    printf("  --help             Display this help message\n");
    printf("  (All standard mpv command-line options are supported)\n\n");
}

int main(int argc, char *argv[]) {
    if (argc > 1) {
        if (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0) {
            print_version();
            return 0;
        }
        if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
            print_help();
            return 0;
        }
    }

    char *res_dir = find_resource_dir();

    char script_glass[PATH_MAX];
    char script_zoom[PATH_MAX];
    char script_enh[PATH_MAX];
    char config_file[PATH_MAX];
    char input_file[PATH_MAX];

    snprintf(script_glass, sizeof(script_glass), "--script=%s/scripts/media_player_pro_glass.lua", res_dir);
    snprintf(script_zoom, sizeof(script_zoom), "--script=%s/scripts/glass_zoom_pan.lua", res_dir);
    snprintf(script_enh, sizeof(script_enh), "--script=%s/scripts/glass_enhancements.lua", res_dir);
    snprintf(config_file, sizeof(config_file), "%s/config/mpv.conf", res_dir);
    snprintf(input_file, sizeof(input_file), "%s/config/input.conf", res_dir);

    // Build arguments list for mpv execution
    int max_args = argc + 28;
    char **mpv_argv = malloc(sizeof(char*) * max_args);
    int arg_idx = 0;

    mpv_argv[arg_idx++] = "mpv";
    mpv_argv[arg_idx++] = "--idle=yes";
    mpv_argv[arg_idx++] = "--force-window=yes";
    mpv_argv[arg_idx++] = "--osc=no";
    mpv_argv[arg_idx++] = "--cursor-autohide=3000";
    mpv_argv[arg_idx++] = "--title=Media Player Pro - ${media-title:${filename:Ready}}";
    mpv_argv[arg_idx++] = "--x11-name=media-player-pro";
    mpv_argv[arg_idx++] = "--wayland-app-id=media-player-pro";
    mpv_argv[arg_idx++] = "--gpu-context=wayland,x11egl,waylandvk,x11vk";
    mpv_argv[arg_idx++] = "--vo=gpu-next,gpu";

    if (file_exists(config_file)) {
        char *include_conf;
        asprintf(&include_conf, "--include=%s", config_file);
        mpv_argv[arg_idx++] = include_conf;
    }
    if (file_exists(input_file)) {
        char *include_input;
        asprintf(&include_input, "--input-conf=%s", input_file);
        mpv_argv[arg_idx++] = include_input;
    }

    mpv_argv[arg_idx++] = script_enh;
    mpv_argv[arg_idx++] = script_zoom;
    mpv_argv[arg_idx++] = script_glass;

    // Append user arguments
    for (int i = 1; i < argc; i++) {
        mpv_argv[arg_idx++] = argv[i];
    }
    mpv_argv[arg_idx] = NULL;

    execvp("mpv", mpv_argv);

    // If execvp fails
    perror("Failed to launch mpv engine");
    fprintf(stderr, "Please ensure 'mpv' is installed and in your PATH.\n");
    free(res_dir);
    free(mpv_argv);
    return 1;
}
