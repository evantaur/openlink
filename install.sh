#!/bin/bash
# Simple script to make openLink your default url handler
#

set -euo pipefail

_get() {
  if [[ -n "`command -v wget`" ]]; then
    wget -nv "$1" -O "$2"
  else
    curl -s "$1" -o "$2"
  fi
}

safemv() {
  if [[ -e "$2" ]]; then
    echo "Overwrite \"$2\" [y/N]"
    read yesno
    if [[ "$yesno" == "y" ]] || [[ "$yesno" == "Y" ]]; then 
      mv "$1" "$2"
    else
      rm "$1"
    fi
  else
    mv "$1" "$2"
  fi
}

# Downloading the two files needed for openlink

_get "https://raw.githubusercontent.com/evantaur/openlink/refs/heads/main/share/applications/openlink.desktop" "/tmp/openlink.desktop" && \
_get "https://raw.githubusercontent.com/evantaur/openlink/refs/heads/main/bin/openlink" "/tmp/openlink" && \
_DIR="$HOME/.local/"; [[ ! -d "$_DIR/bin" ]] && mkdir -p "$_DIR/bin"
_DIR="$HOME/.local/share/applications"; [[ ! -d "$_DIR" ]] && mkdir -p "$_DIR"

# Prefetch the browser from openlink script
C_BROWSER=""
if [[ -f ~/.local/bin/openlink ]]; then
  C_BROWSER=`sed -n 's/^BROWSER=\(.*\)/\1/p' $HOME/.local/bin/openlink | tr -d '"'`
fi


safemv "/tmp/openlink.desktop" "$HOME/.local/share/applications/openlink.desktop"
safemv "/tmp/openlink" "$HOME/.local/bin/openlink"
chmod +x "$HOME/.local/bin/openlink"
# Updating proper username in openlink.desktop
sed -i "s|USER_NAME|$USER|g" $HOME/.local/share/applications/openlink.desktop

# Changing the default browser for openlink script
D_BROWSER="$(xdg-mime query default x-scheme-handler/https)"
D_BROWSER="${D_BROWSER%.desktop}"
[[ "$D_BROWSER" == "openlink" ]] && [[ -n $C_BROWSER ]] && \
  D_BROWSER=$C_BROWSER
echo "Enter browser in which links will be opened. Defaults to: [$D_BROWSER]"
read USER_BROWSER 
USER_BROWSER=${USER_BROWSER:-$D_BROWSER}

sed -i "s|BROWSER=.*|BROWSER=\"$USER_BROWSER\"|" $HOME/.local/bin/openlink

echo "Set default url handler to openlink? [y/N]"
read yesno
if [[ "$yesno" == "y" ]] || [[ "$yesno" == "Y" ]]; then 
  echo "set default http handler to openlink" 
  xdg-mime default openlink.desktop x-scheme-handler/http
  echo "set default https handler to openlink"
  xdg-mime default openlink.desktop x-scheme-handler/https
  echo "set default-web-browser to openlink" 
  xdg-settings set default-web-browser openlink.desktop
fi

echo "done!"
