#!/bin/bash
set -e  # Sai se algum comando falhar

echo "📚 Gerando o site com mdBook..."
mdbook build

echo "🚀 Preparando o envio para gh-pages..."
# Guarda a branch atual
CURRENT_BRANCH=$(git branch --show-current)

# Cria uma branch temporária com o conteúdo da pasta book
git checkout --orphan temp-gh-pages
git rm -rf . > /dev/null 2>&1 || true
cp -r book/* .
git add .
git commit -m "Deploy do site - $(date '+%Y-%m-%d %H:%M:%S')"

# Envia para a branch gh-pages (sobrescreve)
git push origin temp-gh-pages:gh-pages --force

# Volta para a branch original e limpa
git checkout "$CURRENT_BRANCH"
git branch -D temp-gh-pages

echo "✅ Pronto! Seu site está em: https://claudeblog.github.io/nefelibata"