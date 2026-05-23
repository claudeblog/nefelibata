#!/bin/bash

# Diretório base (primeiro argumento ou diretório atual)
SEARCH_DIR="${1:-.}"

# Encontra todos os arquivos (type f) com "__" no nome
find "$SEARCH_DIR" -type f -name "*__*" -print0 | while IFS= read -r -d '' file; do
    # Obtém o diretório e o nome do arquivo separadamente
    dir=$(dirname "$file")
    oldname=$(basename "$file")

    # Substitui todas as ocorrências de "__" por "_"
    newname="${oldname//__/_}"

    # Se o nome não mudou, pula (evita loop desnecessário)
    if [[ "$oldname" == "$newname" ]]; then
        continue
    fi

    newpath="$dir/$newname"

    # Verifica se o novo nome já existe (para evitar sobrescrita acidental)
    if [[ -e "$newpath" ]]; then
        echo "AVISO: Não foi possível renomear '$file' porque '$newpath' já existe." >&2
        continue
    fi

    # Realiza a renomeação
    mv "$file" "$newpath"
    echo "Renomeado: $file -> $newpath"
done