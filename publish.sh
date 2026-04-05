#!/bin/bash
set -e  # Sai se algum comando falhar

echo "📚 Atualizando SUMMARY.md com todos os posts (ordenado por data de adição no Git)..."

# Função para gerar o SUMMARY.md automaticamente
generate_summary() {
    local summary_file="src/SUMMARY.md"
    local temp_summary=$(mktemp)

    # Cabeçalho (sem link vazio em [Posts])
    cat > "$temp_summary" << 'EOF'
# Sumário

- [Início](README.md)
- [Posts]

EOF

    declare -a files_with_dates

    for file in src/*.md; do
        [ -f "$file" ] || continue
        basename=$(basename "$file")
        # Excluir README, SUMMARY e sobre.md (case insensitive)
        if [[ "$basename" == "README.md" || "$basename" == "SUMMARY.md" ]]; then
            continue
        fi
        # Ignorar 'sobre.md' ou 'Sobre.md' (será adicionado manualmente)
        if [[ "${basename,,}" == "sobre.md" ]]; then
            continue
        fi
        # Ignorar arquivos com espaços no nome (problemas com markdown)
        if [[ "$basename" =~ \  ]]; then
            echo "⚠️ Aviso: ignorando arquivo com espaço: $basename"
            continue
        fi

        # Data do primeiro commit (adição) do arquivo
        first_commit_date=$(git log --follow --format=%ai --diff-filter=A -- "$file" 2>/dev/null | tail -1)
        if [ -z "$first_commit_date" ]; then
            # Fallback: data de modificação do sistema
            first_commit_date=$(stat -c %y "$file" 2>/dev/null || date -r "$file" +"%Y-%m-%d %H:%M:%S %z")
        fi
        timestamp=$(date -d "$first_commit_date" +%s 2>/dev/null || echo "0")
        files_with_dates+=("$timestamp|$file")
    done

    # Ordenar decrescente (mais novo primeiro)
    if [ ${#files_with_dates[@]} -gt 0 ]; then
        IFS=$'\n' sorted=($(sort -t'|' -k1 -nr <<<"${files_with_dates[*]}"))
        unset IFS
    else
        sorted=()
    fi

    for entry in "${sorted[@]}"; do
        file="${entry#*|}"
        basename=$(basename "$file" .md)
        # Substitui '-' por espaço no título
        title=$(echo "$basename" | tr '-' ' ')
        # Remove espaços duplicados
        title=$(echo "$title" | sed 's/  */ /g')
        rel_path=$(echo "$file" | sed 's|src/||')
        echo "  - [$title]($rel_path)" >> "$temp_summary"
    done

    # Seção Sobre (fixa)
    echo "- [Sobre](sobre.md)" >> "$temp_summary"

    mv "$temp_summary" "$summary_file"
    echo "✅ SUMMARY.md atualizado (ordem: posts mais recentes primeiro)."
}

# Gerar novo sumário
generate_summary

echo "📚 Gerando o site com mdBook..."
mdbook build

echo "🚀 Preparando deploy para gh-pages via /tmp..."

# Criar diretório temporário
TMP_DIR=$(mktemp -d -t gh-pages-deploy-XXXXXX)

# Copiar conteúdo compilado
cp -r book/* "$TMP_DIR/"

# Inicializar repositório isolado e enviar para gh-pages
cd "$TMP_DIR"
git init
git checkout -b gh-pages
git add .
git commit -m "Deploy do site - $(date '+%Y-%m-%d %H:%M:%S')"
git remote add origin https://github.com/claudeblog/nefelibata.git
git push origin gh-pages --force

# Voltar ao diretório original
cd -

# Limpar
rm -rf "$TMP_DIR"

echo "✅ Pronto! Site publicado em: https://claudeblog.github.io/nefelibata"