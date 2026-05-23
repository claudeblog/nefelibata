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
    /window.addEventListener/d
    /window.setTimeout/d
}' book/blog.html

perl -i -0pe 's/<script>\s*window\.addEventListener\('"'"'load'"'"',\s*function\(\s*\)\s*\{\s*window\.setTimeout\(window\.print,\s*100\s*\);\s*\}\s*\);\s*<\/script>//gis' book/blog.html

sed -i 's|</body>|<script>window.print = function() { return false; };</script></body>|' book/blog.html

# ============================================================
# REMOVER A SEÇÃO DO SUMÁRIO DO blog.html
# ============================================================
echo "📖 Removendo a página de sumário do blog.html..."

# Remove desde <h1 id="sumário"> até a quebra de página seguinte
perl -i -0pe 's|<h1\s+id="sum[áa]rio"[^>]*>.*?<div\s+style="break-before:\s*page;.*?</div>||si' book/blog.html

# Fallback: remove título sem id e a lista
perl -i -0pe 's|<h1[^>]*>Sum[áa]rio</h1>.*?<ul>.*?</ul>.*?<div\s+style="break-before:\s*page;.*?</div>||si' book/blog.html

echo "✅ Seção do sumário removida."

# ============================================================
# ADICIONAR BOTÃO "BLOG" EM TODAS AS PÁGINAS (à esquerda do ícone de impressão)
# ============================================================
echo "🔘 Inserindo botão 'Blog' à esquerda do ícone de impressão..."

BLOG_BUTTON='<a href="blog.html" title="Ver todos os poemas em sequência" aria-label="Blog" style="margin-left: 8px; display: inline-flex; align-items: center; gap: 4px; color: gray; font-weight: bolder;">Blog</a>'

# Processa todas as páginas HTML na raiz da pasta book (exceto print.html e blog.html)
find book -maxdepth 1 -name "*.html" ! -name "print.html" ! -name "blog.html" -type f | while read -r page; do
    # Remove qualquer botão Blog existente (para evitar duplicação)
    perl -i -0pe 's|<a href="blog\.html"[^>]*>.*?Blog<\/a>||gs' "$page"
    
    # Insere o botão DENTRO da div .right-buttons, ANTES do link de impressão
    perl -i -0pe 's|(<div class="right-buttons">)(.*?)(<a href="print\.html")|\1'"$BLOG_BUTTON"'\2\3|s' "$page"
    
    echo "   ✅ Botão inserido em: $(basename "$page")"
done

echo "✅ Botão 'Blog' adicionado em todas as páginas (à esquerda do ícone de impressão)."