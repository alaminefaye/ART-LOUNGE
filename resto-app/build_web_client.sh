#!/bin/bash
# Build Flutter web pour déploiement sous /client sur ton serveur
# Usage: ./build_web_client.sh
# Puis copie le contenu de build/web/ vers ton serveur (ex: public/client/)

set -e
echo "Build Flutter web avec base-href /client/..."
flutter build web --base-href /client/ --release
echo ""
echo "Build terminé. Fichiers dans: build/web/"
echo "Copie le contenu de build/web/ vers ton projet web (ex: public/client/) sur le serveur."
echo "L'app sera accessible à: https://ton-domaine.com/client/"
echo "L'API sera appelée automatiquement à: https://ton-domaine.com/api"
