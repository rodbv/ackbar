#!/usr/bin/env bash
# Install or upgrade the Whatcha plasmoid for the current user.
set -euo pipefail
cd "$(dirname "$0")"

if kpackagetool6 --type Plasma/Applet --show com.rodbv.whatcha &>/dev/null; then
    kpackagetool6 --type Plasma/Applet --upgrade .
else
    kpackagetool6 --type Plasma/Applet --install .
fi

echo "Installed. Restart plasmashell to reload:"
echo "  systemctl --user restart plasma-plasmashell"
