#!/bin/bash
set -e

echo "📚 Gerando o site com mdBook..."
mdbook build

echo "🚀 Preparando o envio para gh-pages..."
CURRENT_BRANCH=$(git branch --show-current)

# Cria uma branch temporária sem histórico
git checkout --orphan temp-gh-pages

# Remove tudo que estiver na branch temporária (se houver)
git rm -rf . > /dev/null 2>&1 || true

# Copia os arquivos gerados (garantindo caminho absoluto)
cp -r "$(pwd)/book/"* .

# Adiciona todos os arquivos ao commit
git add .

# Verifica se há mudanças para commit
if git diff --cached --quiet; then
    echo "⚠️ Nenhuma mudança detectada. O site já está atualizado."
else
    git commit -m "Deploy do site - $(date '+%Y-%m-%d %H:%M:%S')"
fi

# Envia para o branch gh-pages (sobrescreve)
git push origin temp-gh-pages:gh-pages --force

# Volta para a branch original (main)
git checkout "$CURRENT_BRANCH"

# Remove a branch temporária local
git branch -D temp-gh-pages

echo "✅ Pronto! Site publicado em: https://claudeblog.github.io/nefelibata"