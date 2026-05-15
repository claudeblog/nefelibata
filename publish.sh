#!/bin/bash
set -e

export PATH="$HOME/.cargo/bin:$PATH"

echo "🔄 Atualizando SUMMARY.md..."
./update-summary.sh

# Comita todas alterações no branch principal e faz push
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 Adicionando todas as alterações..."
    git add .
    commit_date=$(date '+%Y-%m-%d %H:%M:%S')
    changed_files=$(git diff --cached --name-only)
    git commit -m "Atualização automática em $commit_date
Arquivos alterados:
$changed_files"

    echo "📤 Enviando commit para o repositório remoto..."
    git push origin HEAD
else
    echo "ℹ️ Nenhuma alteração para commitar."
fi

echo "📚 Construindo o site com mdBook..."
mdbook build

echo "🚀 Publicando para gh-pages..."
TMP_DIR=$(mktemp -d -t gh-pages-deploy-XXXXXX)
cp -r book/* "$TMP_DIR/"
cd "$TMP_DIR"
git init
git checkout -b gh-pages
git add .
git commit -m "Deploy do site - $(date '+%Y-%m-%d %H:%M:%S')"
git remote add origin git@github.com:claudeblog/nefelibata.git
git push origin gh-pages --force
cd -
rm -rf "$TMP_DIR"

echo "✅ Publicação concluída!"
