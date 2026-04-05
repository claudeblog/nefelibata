#!/bin/bash
set -e

echo "📚 Gerando o site com mdBook..."
mdbook build

echo "🚀 Publicando para gh-pages..."
TMP_DIR=$(mktemp -d -t gh-pages-deploy-XXXXXX)
cp -r book/* "$TMP_DIR/"
cd "$TMP_DIR"
git init
git checkout -b gh-pages
git add .
git commit -m "Deploy do site - $(date '+%Y-%m-%d %H:%M:%S')"
git remote add origin https://github.com/claudeblog/nefelibata.git
git push origin gh-pages --force
cd -
rm -rf "$TMP_DIR"

echo "✅ Site publicado em: https://claudeblog.github.io/nefelibata"
