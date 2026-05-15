#!/bin/bash
set -e

SUMMARY_FILE="src/SUMMARY.md"
TMP_SUMMARY=$(mktemp)

cat > "$TMP_SUMMARY" << 'HEAD'
# Sumário

HEAD

# Adiciona páginas especiais
[ -f "src/Capa.md" ] && echo "- [Capa](Capa.md)" >> "$TMP_SUMMARY"
[ -f "src/Sobre.md" ] && echo "- [Sobre](Sobre.md)" >> "$TMP_SUMMARY"
[ -f "src/SUMMARY.md" ] && echo "- [Sumário](SUMMARY.md)" >> "$TMP_SUMMARY"

# Lista todos os outros arquivos .md
files=()
for file in src/*.md; do
    [ -f "$file" ] || continue
    basename=$(basename "$file")
    [[ "$basename" =~ ^(README|SUMMARY|Sobre|Capa)\.md$ ]] && continue
    [[ "$basename" =~ \  ]] && { echo "⚠️ Ignorando arquivo com espaço: $basename"; continue; }
    files+=("$file")
done

# Extrai data do nome
extract_date() {
    local filename=$(basename "$1")
    [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]] && echo "${BASH_REMATCH[1]}" || echo "0000-00-00"
}

# Ordena arquivos por data decrescente
IFS=$'\n' sorted_files=($(for f in "${files[@]}"; do
    echo "$(extract_date "$f") $f"
done | sort -r | awk '{print $2}'))

# Adiciona arquivos ao SUMMARY.md
for file in "${sorted_files[@]}"; do
    basename=$(basename "$file" .md)
    [[ "$basename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.*)$ ]] && title_part="${BASH_REMATCH[2]}" || title_part="$basename"
    title=$(echo "$title_part" | sed 's/_/ /g; s/-/ /g; s/  */ /g')
    rel_path=$(echo "$file" | sed 's|src/||')
    echo "- [$title]($rel_path)" >> "$TMP_SUMMARY"
done

mv "$TMP_SUMMARY" "$SUMMARY_FILE"
echo "✅ SUMMARY.md atualizado."
