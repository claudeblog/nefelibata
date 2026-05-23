#!/bin/bash

# Pasta onde estão os arquivos .md
TARGET_DIR="./src"

find "$TARGET_DIR" -maxdepth 1 -type f -name "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md" | while read -r file; do
    filename=$(basename "$file")
    
    # Extrai YYYY-MM-DD (primeiros 10 caracteres) e converte para DD/MM/YYYY
    date_part="${filename:0:10}"
    year="${date_part:0:4}"
    month="${date_part:5:2}"
    day="${date_part:8:2}"
    formatted_date="$day/$month/$year"

    tmp_file=$(mktemp)

    awk -v newdate="$formatted_date" '
    {
        lines[NR] = $0
    }
    END {
        # Primeira linha é o título (presume-se)
        print lines[1]
        
        # Procura pela primeira linha que seja um blockquote de data (formato > DD/MM/AAAA)
        date_idx = 0
        for (i = 2; i <= NR; i++) {
            if (lines[i] ~ /^> [0-9]{2}\/[0-9]{2}\/[0-9]{4}/) {
                date_idx = i
                break
            }
        }
        
        if (date_idx > 0) {
            # Imprime linhas entre o título e a data (mantém formatação)
            for (i = 2; i < date_idx; i++) {
                print lines[i]
            }
            # Imprime a data atualizada
            print "> " newdate
            # Imprime o restante, ignorando outros possíveis blockquotes de data
            for (i = date_idx + 1; i <= NR; i++) {
                if (lines[i] ~ /^> [0-9]{2}\/[0-9]{2}\/[0-9]{4}/) {
                    continue   # pula duplicatas
                }
                print lines[i]
            }
        } else {
            # Nenhuma data encontrada: insere após o título com linhas em branco
            print ""
            print "> " newdate
            print ""
            for (i = 2; i <= NR; i++) {
                print lines[i]
            }
        }
    }' "$file" > "$tmp_file"

    mv "$tmp_file" "$file"
    echo "Corrigido: $file -> $formatted_date"
done