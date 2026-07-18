#!/usr/bin/env bash
# Install or upgrade the AckBar plasmoid for the current user.
set -euo pipefail
cd "$(dirname "$0")"

if kpackagetool6 --type Plasma/Applet --show com.rodbv.ackbar &>/dev/null; then
    kpackagetool6 --type Plasma/Applet --upgrade .
else
    kpackagetool6 --type Plasma/Applet --install .
fi

echo "Installed. Restart plasmashell to reload:"
echo "  systemctl --user restart plasma-plasmashell"
