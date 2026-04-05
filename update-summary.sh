#!/bin/bash
# Gera src/SUMMARY.md no formato plano (sem aninhamento)

SUMMARY_FILE="src/SUMMARY.md"
TMP_SUMMARY=$(mktemp)

cat > "$TMP_SUMMARY" << 'HEAD'
# Summary

HEAD

for file in src/*.md; do
    [ -f "$file" ] || continue
    basename=$(basename "$file")
    [[ "$basename" == "README.md" || "$basename" == "SUMMARY.md" ]] && continue
    [[ "${basename,,}" == "sobre.md" ]] && continue
    if [[ "$basename" =~ \  ]]; then
        echo "⚠️ Ignorando arquivo com espaço: $basename"
        continue
    fi
    title=$(basename "$file" .md | tr '-' ' ')
    title=$(echo "$title" | sed 's/  */ /g')
    rel_path=$(echo "$file" | sed 's|src/||')
    echo "- [$title]($rel_path)" >> "$TMP_SUMMARY"
done

if [ -f "src/sobre.md" ]; then
    echo "- [Sobre](sobre.md)" >> "$TMP_SUMMARY"
fi

mv "$TMP_SUMMARY" "$SUMMARY_FILE"
echo "✅ SUMMARY.md atualizado (formato plano)."
