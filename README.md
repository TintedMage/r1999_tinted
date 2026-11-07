# r1999_tinted

An animated and customizable SDDM login theme with support for image or video
backgrounds, user and session selection, and externally generated color
palettes.

This project started from the **Reverse 1999 Qylock Theme** by
[Darkkal44](https://github.com/Darkkal44), from the
[`themes/R1999_1` theme](https://github.com/Darkkal44/qylock/tree/main/themes/R1999_1).
It is now maintained as `r1999_tinted` with a changed font, configurable
backgrounds, and other visual and functional modifications.

## Features

- Qt 6 SDDM theme
- Image and looping video backgrounds
- Palette generation through the external `update-theme.sh` script

## Requirements

- SDDM with Qt 6 support
- `matugen`
- `ffmpeg` (only required when generating colors from a video)
- `notify-send` (optional; used for update notifications)

## Installation

Clone or download this repository, then copy the project directory to the
SDDM themes directory:

```bash
sudo mkdir -p /usr/share/sddm/themes/r1999_tinted
sudo cp -r . /usr/share/sddm/themes/r1999_tinted
```

Set the theme in SDDM's configuration, for example in
`/etc/sddm.conf.d/theme.conf`:

```ini
[Theme]
Current=r1999_tinted
```

Restart SDDM or reboot to apply the theme.
```bash
sudo systemctl restart sddm
```

## Updating the background and colors

The external `update-theme.sh` script uses `matugen` to generate `colors.js`
and install the selected background into the SDDM theme directory. The script
can be run from any working directory; it does not need to remain inside the
theme directory.

You can copy the script into any local directory you use for scripts. For
example:

```bash
mkdir -p ~/scripts
cp update-theme.sh ~/scripts/update-theme.sh
chmod +x ~/scripts/update-theme.sh
```

If the script is copied without the theme's `bg.*` file, provide an image or
video path when running it. Running the script without a media argument looks
for exactly one `bg.*` file beside the script, so you can place a test
background next to the script and run it from anywhere. The generated
`colors.js` is installed into the output directory and is the file imported
by `Main.qml` for the theme palette.

When no media path or `--color` is supplied, an existing non-empty
`colors.js` beside the script is reused instead of generating a new palette.
This lets you keep a manually edited or previously generated palette. The
single `bg.*` file is still used and installed as the background. Supplying
an image, video, or `--color` explicitly regenerates `colors.js` with
`matugen`.

The `--generate-local` option is intended for debugging. It also copies the
selected background and generated `colors.js` beside the script, allowing you
to inspect or test the generated files locally. The output directory is still
updated, and the script location must be writable. Do not use this option as
a requirement for normal SDDM installation.

### Output directory permissions

The default output directory is
`/usr/share/sddm/themes/r1999_tinted`. The account running the script must be
able to create, remove, and replace files there. Otherwise the script will
fail when it tries to install the background or `colors.js`.

To allow the current user to update the default theme directly:

```bash
sudo chown -R "$USER":"$USER" /usr/share/sddm/themes/r1999_tinted
sudo chmod -R u+rwX /usr/share/sddm/themes/r1999_tinted
```

Alternatively, use an output directory that the current user owns and copy
the finished theme to SDDM separately.

### Script options

```text
update-theme.sh [OPTIONS] [IMAGE_OR_VIDEO]
```

- `IMAGE_OR_VIDEO` — use an image or video as the background and source for
  palette generation. Supported video formats include `mp4`, `webm`, `mkv`,
  `avi`, `mov`, and `m4v`. For videos, `ffmpeg` extracts a frame for
  `matugen`; the video itself remains the SDDM background.
- No media argument — use the single `bg.*` file beside the script. If a
  non-empty `colors.js` is also beside the script, reuse it; otherwise
  generate the palette from the background.
- `-c, --color HEX` — use a manually selected color instead of extracting
  colors from media. The `#` prefix is optional.
- `-o, --output-dir DIR` — install the generated background and `colors.js`
  into `DIR` for this run. This overrides both `OUTPUT_DIR` and
  `SDDM_THEME_DIR`.
- `--output-dir=DIR` — equivalent `--output-dir` syntax.
- `-l, --generate-local` — debugging mode; also keep the generated background
  and `colors.js` beside the script. The output directory is still updated.
- `-h, --help` — show the complete command usage.

Examples:

```bash
./update-theme.sh ~/Pictures/wallpaper.png
./update-theme.sh ~/Videos/live_wallpaper.mp4
./update-theme.sh ~/Videos/live_wallpaper.mp4 --color '#00aaff'
./update-theme.sh --output-dir /tmp/r1999_tinted ~/Pictures/wallpaper.png
./update-theme.sh --color '#ff0000'
```

### Choosing the output directory

`SDDM_THEME_DIR` is an environment variable that changes the default output
directory without editing the script:

```bash
SDDM_THEME_DIR=/path/to/r1999_tinted ./update-theme.sh
```

You can also permanently change the fallback directory by editing the
`OUTPUT_DIR` line near the top of `update-theme.sh`:

```bash
OUTPUT_DIR="${SDDM_THEME_DIR:-/usr/share/sddm/themes/r1999_tinted}"
```

The command-line `--output-dir` option has the highest priority, followed by
`SDDM_THEME_DIR`, followed by the `OUTPUT_DIR` fallback.

### Advanced script customization

Users who want to change how `colors.js` is generated can edit the
`template_content` block in the script. It maps `matugen` palette values to
the QML variables `foreground`, `accent`, `accentMuted`, and `highlight`.
The notification helper functions can also be edited if desktop
notifications are not wanted. `notify-send` is optional; errors and success
messages are always printed in the terminal.

Each update removes old `bg.*` files from the selected output directory before
installing the new background. `colors.js` is regenerated on every run and
copied to the output directory, so manual edits to an existing `colors.js`
will be overwritten. When `--generate-local` is used, the local `colors.js`
is overwritten as well.

Run `./update-theme.sh --help` for the built-in usage text and dependency
details.

## Credits and licensing

- **Original project:** [Darkkal44/qylock](https://github.com/Darkkal44/qylock)
- **Original theme author:** [Darkkal44](https://github.com/Darkkal44)
- **Current derivative/customization:** TintedMage
- **License:** GPL-3.0, inherited from the upstream project

Please retain the upstream attribution and license terms when redistributing
this derivative project.
