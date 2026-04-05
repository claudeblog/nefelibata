#!/bin/bash
set -e

# Guarda a branch atual e garante que vamos voltar para ela mesmo em caso de erro
CURRENT_BRANCH=$(git branch --show-current)
cleanup() {
    git checkout "$CURRENT_BRANCH" 2>/dev/null || true
    git branch -D temp-gh-pages 2>/dev/null || true
}
trap cleanup EXIT

echo "📚 Gerando o site com mdBook..."
mdbook build

echo "🚀 Preparando o envio para gh-pages..."

# Cria branch temporária sem histórico
git checkout --orphan temp-gh-pages
git rm -rf . > /dev/null 2>&1 || true

# Copia os arquivos gerados
cp -r "$(pwd)/book/"* .

# Adiciona todos os arquivos
git add .

# Verifica se há mudanças para commit
if git diff --cached --quiet; then
    echo "⚠️ Nenhuma mudança detectada. O site já está atualizado."
    echo "✅ Nada a fazer. Saindo..."
    exit 0
else
    git commit -m "Deploy do site - $(date '+%Y-%m-%d %H:%M:%S')"
    # Envia para o branch gh-pages (sobrescreve)
    git push origin temp-gh-pages:gh-pages --force
    echo "✅ Pronto! Site publicado em: https://claudeblog.github.io/nefelibata"
fi