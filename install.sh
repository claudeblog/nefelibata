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

# Cria update-summary.sh
cat > update-summary.sh << 'EOF'
#!/bin/bash
SUMMARY_FILE="src/SUMMARY.md"
TMP_SUMMARY=$(mktemp)

cat > "$TMP_SUMMARY" << 'HEAD'
# Summary

HEAD

# 1️⃣ Adiciona Sobre.md como primeira página
if [ -f "src/sobre.md" ]; then
    echo "- [Sobre](sobre.md)" >> "$TMP_SUMMARY"
fi

# 2️⃣ Adiciona SUMÁRIO.md como segunda página
echo "- [Sumário](SUMMARY.md)" >> "$TMP_SUMMARY"

# 3️⃣ Lista todos os outros arquivos .md na pasta src
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

# Função para extrair data do nome do arquivo
extract_date() {
    local filename=$(basename "$1")
    if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "0000-00-00"
    fi
}

# Ordena os arquivos por data decrescente
IFS=$'\n' sorted_files=($(for f in "${files[@]}"; do
    echo "$(extract_date "$f") $f"
done | sort -r | awk '{print $2}'))

# Adiciona os arquivos ao SUMMARY.md sem mostrar a data
for file in "${sorted_files[@]}"; do
    basename=$(basename "$file" .md)
    if [[ "$basename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]]; then
        title_part="${BASH_REMATCH[2]}"
    else
        title_part="$basename"
    fi
    title=$(echo "$title_part" | sed 's/_/ /g; s/-/ /g; s/  */ /g')
    rel_path=$(echo "$file" | sed 's|src/||')
    echo "- [$title]($rel_path)" >> "$TMP_SUMMARY"
done

mv "$TMP_SUMMARY" "$SUMMARY_FILE"
echo "✅ SUMMARY.md atualizado."
EOF
chmod +x update-summary.sh
echo "✅ Script update-summary.sh criado."

# Cria publish.sh
cat > publish.sh << 'EOF'
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
EOF
chmod +x publish.sh
echo "✅ Script publish.sh criado."

echo "🎉 Instalação concluída!"
echo "Use ./publish.sh para atualizar SUMMARY.md, commitar alterações, enviar para o repositório e publicar o site."