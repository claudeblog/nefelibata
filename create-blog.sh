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

echo "✅ blog.html criado."

# ============================================================
# ADICIONAR BOTÃO "BLOG" APENAS NA DIV .right-buttons (barra superior)
# ============================================================
echo "🔘 Inserindo botão 'Blog' ao lado do ícone de impressão (uma única vez por página)..."

BLOG_BUTTON='<a href="blog.html" title="Ver todos os poemas em sequência" aria-label="Blog" style="margin-left: 8px; display: inline-flex; align-items: center; gap: 4px;"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512" width="18" height="18" fill="currentColor"><path d="M249.6 471.5c10.8 3.8 22.4-4.1 22.4-15.5V78.6c0-4.2-1.6-8.4-5-11C247.4 52 202.4 32 144 32C87.5 32 35.1 48.6 9 59.9c-5.6 2.4-9 8-9 14V454.1c0 11.9 12.8 20.2 24.1 16.5C55.6 460.1 105.5 448 144 448c33.9 0 79 14 105.6 23.5zm76.8 0C353 462 398.1 448 432 448c38.5 0 88.4 12.1 119.9 22.6c11.3 3.7 24.1-4.6 24.1-16.5V73.9c0-6-3.4-11.6-9-14C511.9 48.6 459.5 32 403 32c-58.4 0-103.4 20-125 32.6c-3.4 2.6-5 6.8-5 11V456c0 11.4 11.6 19.3 22.4 15.5z"/></svg> Blog</a>'

# Processa todas as páginas HTML (exceto print.html e blog.html)
find book -maxdepth 1 -name "*.html" ! -name "print.html" ! -name "blog.html" -type f | while read -r page; do
    # 1. Remove TODAS as ocorrências do botão Blog em qualquer lugar da página
    perl -i -0pe 's|<a href="blog\.html"[^>]*>.*?Blog<\/a>||gs' "$page"
    
    # 2. Agora insere APENAS dentro da div class="right-buttons" que contém o botão de impressão
    # Usa perl para fazer a substituição apenas na primeira ocorrência da div .right-buttons
    perl -i -0pe 's|(<div class="right-buttons">.*?)(</div>)|\1'"$BLOG_BUTTON"'\2|s' "$page"
    
    echo "   ✅ Botão (re)inserido em: $(basename "$page")"
done

echo "✅ Botão 'Blog' adicionado corretamente em todas as páginas (apenas na barra superior)."