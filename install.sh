#!/bin/bash
set -e

echo "🔧 Instalando pré-requisitos para o projeto mdBook..."

# Detecta distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "⚠️ Não foi possível detectar a distribuição Linux."
    exit 1
fi

# Função para instalar pacotes
install_packages() {
    case "$DISTRO" in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y git curl build-essential
            ;;
        fedora)
            sudo dnf install -y git curl @development-tools
            ;;
        *)
            echo "⚠️ Distribuição não suportada: $DISTRO"
            exit 1
            ;;
    esac
}

install_packages

# Instala Rust se necessário
if ! command -v rustc &> /dev/null; then
    echo "🦀 Instalando Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Carrega Rust/Cargo no shell atual
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Garante que ~/.cargo/bin está no PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Instala mdBook
if ! command -v mdbook &> /dev/null; then
    echo "📚 Instalando mdBook..."
    cargo install mdbook
else
    echo "✅ mdBook já instalado."
fi

# Adiciona ~/.cargo/bin ao PATH permanentemente
if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    echo "➕ PATH atualizado no ~/.bashrc"
fi

# Cria update-summary.sh no formato mdBook com data no final e espaços limpos
cat > update-summary.sh << 'EOF'
#!/bin/bash
# Gera src/SUMMARY.md compatível com mdBook
# Título sem data no início, mas com data no final entre parênteses
# Remove espaços duplos consecutivos

SUMMARY_FILE="src/SUMMARY.md"
TMP_SUMMARY=$(mktemp)

cat > "$TMP_SUMMARY" << 'HEAD'
# Summary

HEAD

# Coleta arquivos válidos
files=()
for file in src/*.md; do
    [ -f "$file" ] || continue
    basename=$(basename "$file")
    [[ "$basename" == "README.md" || "$basename" == "SUMMARY.md" ]] && continue
    [[ "${basename,,}" == "sobre.md" ]] && continue
    if [[ "$basename" =~ \  ]]; then
        echo "⚠️ Ignorando arquivo com espaço: $basename"
        continue
    fi
    files+=("$file")
done

# Extrai data do nome do arquivo (YYYY-MM-DD)
extract_date() {
    local filename=$(basename "$1")
    if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "0000-00-00"  # fallback
    fi
}

# Ordena arquivos do mais novo para o mais antigo
IFS=$'\n' sorted_files=($(for f in "${files[@]}"; do
    echo "$(extract_date "$f") $f"
done | sort -r | awk '{print $2}'))

# Gera SUMMARY.md
for file in "${sorted_files[@]}"; do
    basename=$(basename "$file" .md)

    if [[ "$basename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]]; then
        date="${BASH_REMATCH[1]}"
        title_part="${BASH_REMATCH[2]}"
    else
        date="0000-00-00"
        title_part="$basename"
    fi

    # Substitui _ e - por espaços
    title=$(echo "$title_part" | sed 's/_/ /g; s/-/ /g')
    # Remove espaços duplos consecutivos
    title=$(echo "$title" | sed 's/  */ /g')

    # Formata data para (YYYY/MM/DD)
    date_formatted=$(echo "$date" | sed 's/-/\//g')

    rel_path=$(echo "$file" | sed 's|src/||')
    echo "- [$title ($date_formatted)]($rel_path)" >> "$TMP_SUMMARY"
done

# Adiciona sobre.md por último, se existir
if [ -f "src/sobre.md" ]; then
    echo "- [Sobre](sobre.md)" >> "$TMP_SUMMARY"
fi

mv "$TMP_SUMMARY" "$SUMMARY_FILE"
echo "✅ SUMMARY.md atualizado (títulos limpos, data no final)."
EOF
chmod +x update-summary.sh
echo "✅ Script update-summary.sh criado."

# Cria publish.sh usando SSH
cat > publish.sh << 'EOF'
#!/bin/bash
set -e

# Garante que mdBook seja encontrado
export PATH="$HOME/.cargo/bin:$PATH"

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

# Usa SSH para push
git remote add origin git@github.com:claudeblog/nefelibata.git
git push origin gh-pages --force
cd -
rm -rf "$TMP_DIR"

echo "✅ Site publicado em: https://claudeblog.github.io/nefelibata"
EOF
chmod +x publish.sh
echo "✅ Script publish.sh criado (SSH ready)."

# Configura hooks do Git
if [ -d ".git" ]; then
    mkdir -p .git/hooks

    # pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
./update-summary.sh
git add src/SUMMARY.md
EOF
    chmod +x .git/hooks/pre-commit
    echo "✅ Hook pre-commit instalado."

    # post-commit hook (opcional)
    read -p "Deseja instalar o hook post-commit para publicar automaticamente após cada commit? (s/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
./publish.sh
EOF
        chmod +x .git/hooks/post-commit
        echo "✅ Hook post-commit instalado."
    else
        echo "ℹ️ Você pode executar ./publish.sh manualmente quando quiser publicar."
    fi
else
    echo "⚠️ Diretório .git não encontrado. Hooks não instalados."
fi

echo "🎉 Instalação concluída!"
echo "Comandos disponíveis:"
echo "  ./update-summary.sh   - atualiza o SUMÁRIO do blog"
echo "  ./publish.sh          - gera o site e publica no GitHub Pages (SSH)"