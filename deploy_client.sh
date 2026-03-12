#!/bin/bash
# Build Flutter web + copie dans public/client/ pour que l'app soit servie à /client/
# Usage: ./deploy_client.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/resto-app"
PUBLIC_CLIENT="$SCRIPT_DIR/public/client"

echo "Build Flutter web (base-href /client/)..."
cd "$APP_DIR"
flutter build web --base-href /client/ --release

echo "Copie vers public/client/..."
rm -rf "$PUBLIC_CLIENT"
mkdir -p "$PUBLIC_CLIENT"
cp -R build/web/* "$PUBLIC_CLIENT"/

echo "OK. L'app client est dans public/client/."
echo "Déploie le projet (git push, etc.) : l'app sera à https://ton-domaine.com/client/"
