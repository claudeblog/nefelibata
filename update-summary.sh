#!/bin/bash
SUMMARY_FILE="src/SUMMARY.md"
TMP_SUMMARY=$(mktemp)

cat > "$TMP_SUMMARY" << 'HEAD'
# Summary

HEAD

# 1️⃣ Adiciona Sobre.md como primeira página
if [ -f "src/Sobre.md" ]; then
    echo "- [Sobre](Sobre.md)" >> "$TMP_SUMMARY"
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
