# Whatcha

A minimal KDE Plasma 6 panel widget that shows the **one thing you are doing right now** — so you stay on task.

- Empty state: a nearly transparent bar asking *"What are you doing now?"*
- Double-click the bar → a popup where you type your current task
- The bar tints green (color configurable) with your task centered
- An elapsed timer sits at the right edge, so you know how long you've been at it
- Everything survives reboots and plasmashell restarts

## Features

- **One task, always visible** — lives in your panel, no window to lose
- **Elapsed timer** — `MM:SS` (or `H:MM:SS` past an hour), monospace so it doesn't jiggle; resets when the task changes
- **Translucent tint** — your wallpaper shows through; tint strength configurable
- **Configurable** — bar color, tint strength, font face, font color, timer font, timer on/off

## Requirements

- KDE Plasma 6

## Installation

```sh
git clone https://github.com/rodbv/whatcha.git
cd whatcha
./install.sh
systemctl --user restart plasma-plasmashell
```

Then right-click your panel → *Enter Edit Mode* → *Add Widgets…* → search for **Whatcha** and drag it onto the panel. Resize it in edit mode to taste.

### Manual install

```sh
kpackagetool6 --type Plasma/Applet --install .   # or --upgrade on updates
mkdir -p ~/.local/share/icons/hicolor/scalable/apps
cp icon.svg ~/.local/share/icons/hicolor/scalable/apps/com.rodbv.whatcha.svg
```

### Uninstall

```sh
kpackagetool6 --type Plasma/Applet --remove com.rodbv.whatcha
rm -f ~/.local/share/icons/hicolor/scalable/apps/com.rodbv.whatcha.svg
```

## Usage

| Action | Result |
|---|---|
| Double-click the bar | Open the task popup |
| Type + <kbd>Enter</kbd> (or *Set*) | Set the task, start the timer |
| Clear button (✕) | Clear the task |
| <kbd>Esc</kbd> | Close the popup without changes |
| Right-click → *Configure Whatcha…* | Colors, fonts, timer settings |

Setting the same text again keeps the timer running; changing the text resets it.

## Development

```sh
./install.sh && systemctl --user restart plasma-plasmashell
```

Widget code is plain QML — no build step:

```
contents/
├── ui/main.qml            # bar (compact) + popup editor (full representation)
├── ui/configGeneral.qml   # settings page
└── config/main.xml        # config schema
```

## License

[MIT](LICENSE)
