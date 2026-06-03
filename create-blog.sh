#!/bin/bash
set -e

echo "📄 Criando blog.html a partir do print.html..."

if [ ! -f "book/print.html" ]; then
    echo "❌ book/print.html não encontrado. Execute 'mdbook build' primeiro."
    exit 1
fi

cp book/print.html book/blog.html

# Remove script de impressão automática
sed -i '/<script>/,/<\/script>/ {
    /window\.print/d
    /window\.addEventListener/d
    /window\.setTimeout/d
}' book/blog.html

perl -i -0pe 's/\s*window\.addEventListener('"'"'load'"'"',\s*function\s*\(\s*\)\s*\{\s*window\.setTimeout\(window\.print,\s*100\s*\);\s*\}\s*\);\s*<\/script>//gis' book/blog.html

sed -i 's|window\.print();|window.print = function() { return false; };|g' book/blog.html

# ============================================================
# REMOVER A SEÇÃO DO SUMÁRIO
# ============================================================

echo "📖 Removendo a página de sumário do blog.html..."

sed -i '/id="summary"/,/<\/div>/d' book/blog.html
sed -i '/Sum[áa]rio<\/h1>/,/<\/div>/d' book/blog.html

echo "✅ Seção do sumário removida."

# ============================================================
# FAZER O BLOG SER A PÁGINA PRINCIPAL
# ============================================================

echo "🏠 Tornando o blog a página padrão do site..."

cp book/blog.html book/index.html

echo "✅ index.html atualizado."

# ============================================================
# ADICIONAR BOTÃO "BLOG"
# ============================================================

echo "🔘 Inserindo botão 'Blog' à esquerda do ícone de impressão..."

BLOG_BUTTON='<a href="index.html" class="icon-button" title="Blog" aria-label="Blog">Blog</a>'

find book -maxdepth 1 -name "*.html" \
    ! -name "print.html" \
    ! -name "blog.html" \
    -type f | while read -r page; do

    # Remove botão existente
    perl -i -0pe 's|<a href="index\.html"[^>]*>.*?Blog</a>||gs' "$page"

    # Insere antes do botão de impressão
    perl -i -0pe 's|(<div class="right-buttons">)(.*?)(<a href="print\.html")|\1'"$BLOG_BUTTON"'\2\3|s' "$page"

    echo "   ✅ Botão inserido em: $(basename "$page")"

done

echo "✅ Blog configurado como página inicial."