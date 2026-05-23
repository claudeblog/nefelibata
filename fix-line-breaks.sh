#!/bin/bash

# Script: fix-line-breaks.sh
# Descrição: Garante que todas as linhas NÃO vazias de arquivos .md
#            terminem com exatamente 2 espaços (para quebra de linha no Markdown).

echo "🔧 Garantindo que todas as linhas não vazias terminem com 2 espaços..."

find . -name "*.md" -not -path "./book/*" -not -path "./.git/*" -not -path "./node_modules/*" | while read -r file; do
    awk '
    {
        # Remove qualquer whitespace (espaços, tabs) do final da linha
        gsub(/[[:space:]]+$/, "", $0)
        # Se a linha não estiver vazia após a remoção
        if (length($0) > 0) {
            # Adiciona exatamente dois espaços
            print $0 "  "
        } else {
            # Linha vazia (ou que continha só espaços) -> imprime linha vazia
            print ""
        }
    }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    echo "   ✔ $file"
done

echo "✅ Correção concluída: todas as linhas com conteúdo agora têm exatamente 2 espaços no final."