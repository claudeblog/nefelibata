#!/bin/bash
set -e

echo "📚 Gerando o site com mdBook..."
mdbook build

echo "🚀 Preparando deploy para gh-pages via /tmp..."

# Cria uma pasta temporária única
TMP_DIR=$(mktemp -d -t gh-pages-deploy-XXXXXX)

# Copia o conteúdo compilado (a pasta book) para a pasta temporária
cp -r book/* "$TMP_DIR/"

# Inicializa um repositório git na pasta temporária
cd "$TMP_DIR"
git init
git checkout -b gh-pages   # cria branch gh-pages
git add .
git commit -m "Deploy do site - $(date '+%Y-%m-%d %H:%M:%S')"

# Adiciona o repositório remoto (seu GitHub)
git remote add origin https://github.com/claudeblog/nefelibata.git

# Envia (força) a branch gh-pages para o GitHub
git push origin gh-pages --force

# Volta para o diretório original
cd -

# Remove a pasta temporária
rm -rf "$TMP_DIR"

echo "✅ Pronto! Site publicado em: https://claudeblog.github.io/nefelibata"