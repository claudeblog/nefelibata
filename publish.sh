#!/bin/bash
set -e

export PATH="$HOME/.cargo/bin:$PATH"

DOMAIN="ameopoema.com.br"

# ------------------------------------------------------------
# Função 1: Inserir quebra de linha antes de CADA letra maiúscula
#           (ignorando cabeçalhos e primeira posição da linha)
# ------------------------------------------------------------
fix_capitalization_breaks() {
    echo "🔠 Inserindo quebras de linha antes de letras maiúsculas (ignorando cabeçalhos)..."

    # Verifica se perl está disponível (recomendado)
    if command -v perl &>/dev/null; then
        echo "   Usando perl (suporte a Unicode e espaços especiais)"
        find . -name "*.md" -not -path "./book/*" -not -path "./.git/*" -not -path "./node_modules/*" | while read -r file; do
            perl -i -pe '
                # Pula linhas que são cabeçalhos (começam com #)
                next if /^\s*#/;
                # Insere newline antes de cada letra maiúscula que não esteja no início da linha
                s/(?<=.)(?=[A-Z])/\n/g;
            ' "$file"
            echo "   ✔ $file"
        done
    else
        # Fallback usando awk (menos robusto, mas tenta)
        echo "   ⚠️ perl não encontrado, usando awk (pode falhar com espaços especiais)"
        find . -name "*.md" -not -path "./book/*" -not -path "./.git/*" -not -path "./node_modules/*" | while read -r file; do
            awk '
            function is_header(line) {
                return match(line, /^[[:space:]]*#/)
            }
            {
                if (is_header($0)) {
                    print $0
                } else {
                    # Insere newline antes de cada maiúscula (exceto no início)
                    line = $0
                    result = ""
                    for (i = 1; i <= length(line); i++) {
                        char = substr(line, i, 1)
                        if (i > 1 && char ~ /[A-Z]/ && substr(line, i-1, 1) !~ /\n/) {
                            result = result "\n" char
                        } else {
                            result = result char
                        }
                    }
                    print result
                }
            }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            echo "   ✔ $file"
        done
    fi
    echo "✅ Quebras de linha antes de maiúsculas inseridas."
}

# ------------------------------------------------------------
# Função 2: Garantir que toda linha NÃO vazia termine com 2 espaços
# ------------------------------------------------------------
fix_line_breaks() {
    echo "🔧 Garantindo que todas as linhas não vazias terminem com 2 espaços..."
    find . -name "*.md" -not -path "./book/*" -not -path "./.git/*" -not -path "./node_modules/*" | while read -r file; do
        awk '
        {
            gsub(/[[:space:]]+$/, "", $0)
            if (length($0) > 0) {
                print $0 "  "
            } else {
                print ""
            }
        }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        echo "   ✔ $file"
    done
    echo "✅ Linhas não vazias agora terminam com exatamente 2 espaços."
}

# ------------------------------------------------------------
# Execução principal
# ------------------------------------------------------------
echo "🔄 Atualizando SUMMARY.md..."
./update-summary.sh

# Corrige quebras antes de maiúsculas (ignora cabeçalhos)
fix_capitalization_breaks

# Corrige dois espaços no final
fix_line_breaks

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

# --- CNAME ---
echo "🌐 Configurando domínio personalizado: $DOMAIN"
echo "$DOMAIN" > book/CNAME
if [ ! -f "CNAME" ]; then
    echo "$DOMAIN" > CNAME
    echo "   (Arquivo CNAME criado na raiz do repositório)"
fi

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

echo "✅ Publicação concluída! O domínio $DOMAIN foi persistido."