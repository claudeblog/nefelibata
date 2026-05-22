#!/bin/bash
set -e

export PATH="$HOME/.cargo/bin:$PATH"

# Domínio personalizado do GitHub Pages
DOMAIN="ameopoema.com.br"

# ------------------------------------------------------------
# Função 1: Inserir quebra de linha antes de maiúsculas (ignorando cabeçalhos)
# ------------------------------------------------------------
fix_capitalization_breaks() {
    echo "🔠 Inserindo quebras de linha antes de letras maiúsculas (ignorando cabeçalhos)..."
    find . -name "*.md" -not -path "./book/*" -not -path "./.git/*" -not -path "./node_modules/*" | while read -r file; do
        awk '
        function is_header(line) {
            return match(line, /^[[:space:]]*#/)
        }
        function split_on_uppercase(line, out_lines, n) {
            n = 0
            len = length(line)
            if (len == 0) {
                out_lines[++n] = ""
                return n
            }
            result = ""
            prev_char = ""
            for (i = 1; i <= len; i++) {
                char = substr(line, i, 1)
                # Se é maiúscula (A-Z) e o caractere anterior é minúscula (a-z)
                if (char ~ /[A-Z]/ && prev_char ~ /[a-z]/) {
                    # Finaliza a linha atual e começa nova
                    if (result != "") {
                        out_lines[++n] = result
                        result = ""
                    }
                }
                result = result char
                prev_char = char
            }
            if (result != "" || n == 0) {
                out_lines[++n] = result
            }
            return n
        }
        {
            if (is_header($0)) {
                # Cabeçalho: mantém como está (sem quebras)
                print $0
            } else {
                # Linha normal: quebra nas maiúsculas
                n = split_on_uppercase($0, lines)
                for (i = 1; i <= n; i++) {
                    print lines[i]
                }
            }
        }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        echo "   ✔ $file"
    done
    echo "✅ Quebras de linha por maiúsculas inseridas."
}

# ------------------------------------------------------------
# Função 2: Garantir que toda linha NÃO vazia termine com exatamente 2 espaços
# ------------------------------------------------------------
fix_line_breaks() {
    echo "🔧 Garantindo que todas as linhas não vazias terminem com 2 espaços..."
    find . -name "*.md" -not -path "./book/*" -not -path "./.git/*" -not -path "./node_modules/*" | while read -r file; do
        awk '
        {
            # Remove qualquer whitespace do final
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

# 1. Corrigir quebras de linha por maiúsculas (antes de tudo)
fix_capitalization_breaks

# 2. Garantir duas espaços no final de cada linha não vazia
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

# --- CRIAR E GARANTIR O ARQUIVO CNAME ---
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
