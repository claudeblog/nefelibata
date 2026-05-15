#!/bin/bash
# Gera src/SUMMARY.md compatível com mdBook (ordenado do mais novo para o mais antigo)

SUMMARY_FILE="src/SUMMARY.md"
TMP_SUMMARY=$(mktemp)

cat > "$TMP_SUMMARY" << 'HEAD'
# Summary

HEAD

# Coleta os arquivos válidos
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

# Função para extrair a data do início do nome do arquivo (YYYY-MM-DD)
extract_date() {
    local filename=$(basename "$1")
    if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "0000-00-00"  # fallback para arquivos sem data
    fi
}

# Ordena arquivos do mais novo para o mais antigo
IFS=$'\n' sorted_files=($(for f in "${files[@]}"; do
    echo "$(extract_date "$f") $f"
done | sort -r | awk '{print $2}'))

# Gera SUMMARY.md
for file in "${sorted_files[@]}"; do
    basename=$(basename "$file" .md)
    # substitui "_" e "-" por espaços, mantendo legibilidade
    title=$(echo "$basename" | sed 's/_/ /g; s/-/ /g')
    rel_path=$(echo "$file" | sed 's|src/||')
    echo "- [$title]($rel_path)" >> "$TMP_SUMMARY"
done

# Adiciona sobre.md por último, se existir
if [ -f "src/sobre.md" ]; then
    echo "- [Sobre](sobre.md)" >> "$TMP_SUMMARY"
fi

mv "$TMP_SUMMARY" "$SUMMARY_FILE"
echo "✅ SUMMARY.md atualizado (do mais novo para o mais antigo)."
