#!/bin/bash
set -e

echo "📚 Atualizando SUMMARY.md com todos os posts (ordenado por data de adição no Git)..."

# Função para gerar o SUMMARY.md automaticamente
generate_summary() {
    local summary_file="src/SUMMARY.md"
    local temp_summary=$(mktemp)

    # Cabeçalho do SUMMARY.md
    cat > "$temp_summary" << 'EOF'
# Sumário

- [Início](README.md)
- [Posts]()

EOF

    # Array para armazenar arquivos com suas datas
    declare -a files_with_dates

    # Lista todos os arquivos .md em src, excluindo README.md e SUMMARY.md
    for file in src/*.md; do
        # Pula se não for arquivo ou se for os excluídos
        [ -f "$file" ] || continue
        basename=$(basename "$file")
        [[ "$basename" == "README.md" || "$basename" == "SUMMARY.md" ]] && continue

        # Tenta obter a data do primeiro commit (adição) do arquivo
        # Formato: YYYY-MM-DD HH:MM:SS +0000
        first_commit_date=$(git log --follow --format=%ai --diff-filter=A -- "$file" 2>/dev/null | tail -1)
        if [ -z "$first_commit_date" ]; then
            # Se nunca foi commitado (ex.: arquivo novo ainda não adicionado), usa data de modificação
            first_commit_date=$(stat -c %y "$file" 2>/dev/null || date -r "$file" +"%Y-%m-%d %H:%M:%S %z")
        fi
        # Converte para timestamp Unix para ordenação numérica
        timestamp=$(date -d "$first_commit_date" +%s 2>/dev/null || echo "0")
        files_with_dates+=("$timestamp|$file")
    done

    # Ordena por timestamp decrescente (mais novo primeiro)
    IFS=$'\n' sorted=($(sort -t'|' -k1 -nr <<<"${files_with_dates[*]}"))
    unset IFS

    # Escreve os links no SUMMARY.md
    for entry in "${sorted[@]}"; do
        file="${entry#*|}"
        basename=$(basename "$file" .md)
        title=$(echo "$basename" | tr '-' ' ')
        rel_path=$(echo "$file" | sed 's|src/||')
        echo "  - [$title]($rel_path)" >> "$temp_summary"
    done

    # Adiciona seção Sobre (opcional)
    echo "- [Sobre](sobre.md)" >> "$temp_summary"

    # Substitui o SUMMARY.md antigo
    mv "$temp_summary" "$summary_file"
    echo "✅ SUMMARY.md atualizado com sucesso (ordem: posts mais recentes primeiro)!"
}

# Chama a função
generate_summary

echo "📚 Gerando o site com mdBook..."
mdbook build

echo "🚀 Preparando deploy para gh-pages via /tmp..."
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

echo "✅ Pronto! Site publicado em: https://claudeblog.github.io/nefelibata"