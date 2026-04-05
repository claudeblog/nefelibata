#!/bin/bash
set -e

echo "🔧 Instalando pré-requisitos para o projeto mdBook..."

# 1. Atualiza sistema e instala pacotes base
sudo apt update
sudo apt install -y git curl build-essential

# 2. Instala Rust (se ausente)
if ! command -v rustc &> /dev/null; then
    echo "🦀 Instalando Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "✅ Rust já instalado."
fi

export PATH="$HOME/.cargo/bin:$PATH"

# 3. Instala mdBook via Cargo
if ! command -v mdbook &> /dev/null; then
    echo "📚 Instalando mdBook..."
    cargo install mdbook
else
    echo "✅ mdBook já instalado."
fi

# 4. Adiciona ~/.cargo/bin ao PATH permanentemente
if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    echo "➕ PATH atualizado no ~/.bashrc"
fi

# 5. Cria script update-summary.sh (gerador de SUMMARY.md plano)
cat > update-summary.sh << 'EOF'
#!/bin/bash
# Gera src/SUMMARY.md no formato plano (sem aninhamento)

SUMMARY_FILE="src/SUMMARY.md"
TMP_SUMMARY=$(mktemp)

cat > "$TMP_SUMMARY" << 'HEAD'
# Summary

HEAD

for file in src/*.md; do
    [ -f "$file" ] || continue
    basename=$(basename "$file")
    [[ "$basename" == "README.md" || "$basename" == "SUMMARY.md" ]] && continue
    [[ "${basename,,}" == "sobre.md" ]] && continue
    if [[ "$basename" =~ \  ]]; then
        echo "⚠️ Ignorando arquivo com espaço: $basename"
        continue
    fi
    title=$(basename "$file" .md | tr '-' ' ')
    title=$(echo "$title" | sed 's/  */ /g')
    rel_path=$(echo "$file" | sed 's|src/||')
    echo "- [$title]($rel_path)" >> "$TMP_SUMMARY"
done

if [ -f "src/sobre.md" ]; then
    echo "- [Sobre](sobre.md)" >> "$TMP_SUMMARY"
fi

mv "$TMP_SUMMARY" "$SUMMARY_FILE"
echo "✅ SUMMARY.md atualizado (formato plano)."
EOF
chmod +x update-summary.sh
echo "✅ Script update-summary.sh criado."

# 6. Cria script publish.sh
cat > publish.sh << 'EOF'
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
EOF
chmod +x publish.sh
echo "✅ Script publish.sh criado."

# 7. Configura hooks do Git (se dentro de um repositório)
if [ -d ".git" ]; then
    mkdir -p .git/hooks

    # pre-commit: atualiza SUMMARY.md e adiciona ao commit
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
./update-summary.sh
git add src/SUMMARY.md
EOF
    chmod +x .git/hooks/pre-commit
    echo "✅ Hook pre-commit instalado (atualiza SUMMARY.md antes de cada commit)."

    # post-commit: (opcional) publica automaticamente
    read -p "Deseja instalar o hook post-commit para publicar automaticamente após cada commit? (s/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
./publish.sh
EOF
        chmod +x .git/hooks/post-commit
        echo "✅ Hook post-commit instalado (publica automaticamente)."
    else
        echo "ℹ️ Você pode executar ./publish.sh manualmente quando quiser publicar."
    fi
else
    echo "⚠️ Diretório .git não encontrado. Hooks não instalados."
    echo "   Execute 'git init' e depois rode este script novamente para configurar os hooks."
fi

echo "🎉 Instalação concluída!"
echo "Comandos disponíveis:"
echo "  ./update-summary.sh   - atualiza o SUMÁRIO do blog (apenas links planos)"
echo "  ./publish.sh          - gera o site e publica no GitHub Pages"
echo ""
echo "Se instalou o hook pre-commit, o sumário será atualizado automaticamente a cada commit."
echo "Se instalou o post-commit, o site será publicado automaticamente após cada commit."