#!/usr/bin/env bash
set -euo pipefail

# Edit this path to choose where the generated theme files are written.
OUTPUT_DIR="${SDDM_THEME_DIR:-/usr/share/sddm/themes/r1999_tinted}"

# --- Notification Helpers ---
notify_err() {
    command -v notify-send >/dev/null && notify-send -u critical -a "SDDM Updater" "Theme Update Failed" "$1"
    printf '%s\n' "$1" >&2
}

notify_ok() {
    command -v notify-send >/dev/null && notify-send -u normal -a "SDDM Updater" "SDDM Theme Updated" "$1"
    printf '%s\n' "$1"
}
# ----------------------------

usage() {
    cat <<'EOF'
Usage: update-theme.sh [OPTIONS] [IMAGE_OR_VIDEO]

Generate and install an SDDM theme background and colors.js using matugen.
Supports both images and videos (mp4, webm, mkv, etc.).

Arguments:
  IMAGE_OR_VIDEO        Media used to generate the theme colors and background.
                        If omitted, an existing bg.* file beside this script is used.
                        An existing colors.js beside the script is reused when
                        no explicit media or color is provided.

Options:
  -c, --color HEX       Manually specify a hex color (e.g., "#ff55aa") to generate
                        the palette, bypassing automatic image/video extraction.
  -o, --output-dir DIR  Write generated theme files to DIR. This overrides
                        OUTPUT_DIR and SDDM_THEME_DIR for this run.
  -l, --generate-local  Debugging option: also keep generated bg.* and
                        colors.js beside this script. The output directory
                        is always updated.
  -h, --help            Show this help and exit.

Configuration:
  Edit OUTPUT_DIR near the top of this script, or set SDDM_THEME_DIR.
  With no media or --color, an existing colors.js beside the script is reused.

Dependencies:
  Required:
    bash 4+, core utilities (mkdir, find, sort, cp, mktemp), and matugen.
  Required for video input:
    ffmpeg.
  Optional:
    notify-send, used for desktop success/error notifications.

Examples:
  update-theme.sh ~/Pictures/wallpaper.png
  update-theme.sh ~/Videos/live_wallpaper.mp4
  update-theme.sh ~/Videos/live_wallpaper.mp4 -c "#00aaff"
  update-theme.sh --output-dir /tmp/sddm-theme ~/Pictures/wallpaper.png
  update-theme.sh -c "#ff0000"
EOF
}

generate_local=false
image_path=""
custom_color=""
existing_colors=""
output_dir="$OUTPUT_DIR"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

while (( $# > 0 )); do
    case "$1" in
        -l|--generate-local)
            generate_local=true
            ;;
        -c|--color)
            if [[ -z "${2:-}" ]]; then
                notify_err "Option --color requires a hex color argument."
                exit 2
            fi
            custom_color="$2"
            # Ensure hex starts with #
            if [[ "$custom_color" != \#* ]]; then
                custom_color="#$custom_color"
            fi
            shift
            ;;
        -o|--output-dir)
            if [[ -z "${2:-}" ]]; then
                notify_err "Option --output-dir requires a directory argument."
                exit 2
            fi
            output_dir="$2"
            shift
            ;;
        --output-dir=*)
            output_dir="${1#*=}"
            if [[ -z "$output_dir" ]]; then
                notify_err "Option --output-dir requires a directory argument."
                exit 2
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            notify_err "Unknown option: $1"
            usage >&2
            exit 2
            ;;
        *)
            if [[ -n "$image_path" ]]; then
                notify_err "Only one media path may be provided."
                usage >&2
                exit 2
            fi
            image_path="$1"
            ;;
    esac
    shift
done

template_content='.pragma library

var foreground = "{{colors.on_surface.default.hex}}"
var accent = "{{colors.primary.default.hex}}"
var accentMuted = "{{colors.secondary.default.hex}}"
var highlight = "{{colors.tertiary.default.hex}}"
'

mkdir -p "$output_dir"

# Generate temporary files
matugen_config="$(mktemp --suffix=.toml)"
template="$(mktemp)"
generated_colors="$(mktemp)"
temp_frame=""
background=""
background_name=""

cleanup() {
    rm -f "$matugen_config" "$template" "$generated_colors"
    if [[ -n "$temp_frame" ]]; then
        rm -f "$temp_frame"
    fi
}
trap cleanup EXIT

# 1. Resolve Background Media
if [[ -n "$image_path" ]]; then
    if [[ ! -f "$image_path" ]]; then
        notify_err "File not found: $image_path"
        exit 1
    fi
    image_path="$(cd -- "$(dirname -- "$image_path")" && pwd)/$(basename -- "$image_path")"
    background_name="bg.${image_path##*.}"
    background="$image_path"
else
    mapfile -t backgrounds < <(find "$script_dir" -maxdepth 1 -type f -name 'bg.*' -printf '%f\n' | sort)
    if (( ${#backgrounds[@]} != 1 )); then
        notify_err "Expected exactly one bg.* file beside the script in $script_dir, found ${#backgrounds[@]}."
        exit 1
    fi
    background_name="${backgrounds[0]}"
    background="$script_dir/$background_name"
fi

if [[ -z "$custom_color" && -z "$image_path" && -s "$script_dir/colors.js" ]]; then
    existing_colors="$script_dir/colors.js"
elif ! command -v matugen >/dev/null 2>&1; then
    notify_err "matugen is required to generate colors.js."
    exit 1
fi

printf '%s\n' "$template_content" > "$template"

cat > "$matugen_config" <<EOF
[config]

[templates]

[templates.sddm]
input_path = "${template}"
output_path = "${generated_colors}"
EOF

# 2. Color Generation Logic
if [[ -n "$custom_color" ]]; then
    # Use manual hex color
    if ! matugen color hex "$custom_color" -c "$matugen_config"; then
        notify_err "matugen failed to process the custom color: $custom_color"
        exit 1
    fi
elif [[ -n "$existing_colors" ]]; then
    cp "$existing_colors" "$generated_colors"
else
    # Process Media (Image or Video)
    target_media="$background"
    
    # If the file is a video, extract a frame using ffmpeg
    if [[ "$background_name" =~ \.(mp4|webm|mkv|avi|mov|m4v|MP4|WEBM|MKV|AVI|MOV|M4V)$ ]]; then
        if ! command -v ffmpeg >/dev/null 2>&1; then
            notify_err "ffmpeg is required to extract colors from video. Please install it or provide a custom color using -c."
            exit 1
        fi
        
        temp_frame="$(mktemp --suffix=.jpg)"
        
        # Try to extract a frame at 1-second mark (to bypass fade-in from black)
        if ! ffmpeg -y -ss 00:00:01 -i "$background" -frames:v 1 -q:v 2 "$temp_frame" >/dev/null 2>&1; then
            # Fallback to the very first frame if the video is shorter than 1 second
            if ! ffmpeg -y -i "$background" -frames:v 1 -q:v 2 "$temp_frame" >/dev/null 2>&1; then
                 notify_err "Failed to extract a video frame with ffmpeg."
                 exit 1
            fi
        fi
        target_media="$temp_frame"
    fi
    
    # Run matugen on the image or the extracted video frame
    if ! matugen image "$target_media" -c "$matugen_config" --source-color-index 0; then
        notify_err "matugen failed to process the background media."
        exit 1
    fi
fi

if [[ ! -s "$generated_colors" ]]; then
    notify_err "matugen did not generate $generated_colors."
    exit 1
fi

# 3. Copy files to destination
if [[ -n "$image_path" ]]; then
    find "$output_dir" -maxdepth 1 -type f -name 'bg.*' -delete
    cp "$image_path" "$output_dir/$background_name"
elif [[ "$background" != "$output_dir/$background_name" ]]; then
    find "$output_dir" -maxdepth 1 -type f -name 'bg.*' -delete
    cp "$background" "$output_dir/$background_name"
fi

cp "$generated_colors" "$output_dir/colors.js"

# 4. Handle Local Generation
if [[ "$generate_local" == true && "$background" != "$script_dir/$background_name" ]]; then
    cp "$background" "$script_dir/$background_name"
    cp "$generated_colors" "$script_dir/colors.js"
elif [[ "$generate_local" == true ]]; then
    cp "$generated_colors" "$script_dir/colors.js"
fi

notify_ok "Installed ${background_name} and colors.js into $output_dir"