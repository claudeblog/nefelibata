#!/bin/bash

# ============================================================
# rename_md_by_title.sh
# 
# Renomeia arquivos .md dentro da pasta ./src
# baseado na data do nome do arquivo e no primeiro cabeçalho #.
#
# Uso: ./rename_md_by_title.sh
# ============================================================

set -euo pipefail

# Diretório relativo (pasta src no mesmo nível do script)
SRC_DIR="./src"

if [ ! -d "$SRC_DIR" ]; then
    echo "❌ Erro: Diretório $SRC_DIR não encontrado."
    echo "Certifique-se de que a pasta 'src' existe no diretório atual."
    exit 1
fi

cd "$SRC_DIR"

for file in *.md; do
    [ -f "$file" ] || continue

    # Extrai a data do nome (formato YYYY-MM-DD-)
    if [[ ! "$file" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})- ]]; then
        echo "⚠️  Aviso: $file não começa com data YYYY-MM-DD, pulando."
        continue
    fi
    date="${BASH_REMATCH[1]}"

    # Extrai o título (primeira linha que começa com '# ')
    title=$(grep -m 1 '^# ' "$file" | sed 's/^# //' | sed 's/^[[:space:]]*//')
    if [ -z "$title" ]; then
        echo "⚠️  Aviso: $file não contém cabeçalho # Título, pulando."
        continue
    fi

    # Sanitiza o título para usar no nome do arquivo
    slug=$(echo "$title" | sed 's/[：:，,；;()（）]//g' | tr ' ' '_')
    slug=$(echo "$slug" | sed 's/_\+/_/g' | sed 's/^_//;s/_$//')

    newname="${date}-${slug}.md"

    if [ "$file" = "$newname" ]; then
        echo "✅ $file já está correto."
        continue
    fi

    if [ -e "$newname" ]; then
        echo "❌ Erro: $newname já existe, não foi possível renomear $file"
        continue
    fi

    echo "🔄 Renomeando: $file -> $newname"
    mv -- "$file" "$newname"
done

echo "🎉 Concluído!"