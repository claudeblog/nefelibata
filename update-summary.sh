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
