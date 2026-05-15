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

extract_date() {
    local filename=$(basename "$1")
    if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "0000-00-00"
    fi
}

IFS=$'\n' sorted_files=($(for f in "${files[@]}"; do
    echo "$(extract_date "$f") $f"
done | sort -r | awk '{print $2}'))

for file in "${sorted_files[@]}"; do
    basename=$(basename "$file" .md)
    if [[ "$basename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]]; then
        date="${BASH_REMATCH[1]}"
        title_part="${BASH_REMATCH[2]}"
    else
        date="0000-00-00"
        title_part="$basename"
    fi
    title=$(echo "$title_part" | sed 's/_/ /g; s/-/ /g; s/  */ /g')
    date_formatted=$(echo "$date" | sed 's/-/\//g')
    rel_path=$(echo "$file" | sed 's|src/||')
    echo "- [$title ($date_formatted)]($rel_path)" >> "$TMP_SUMMARY"
done

mv "$TMP_SUMMARY" "$SUMMARY_FILE"
echo "✅ SUMMARY.md atualizado."
