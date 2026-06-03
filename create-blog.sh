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
# REMOVER A SEÇÃO DO SUMÁRIO DO blog.html (VERSÃO ROBUSTA)
# ============================================================
echo "📖 Removendo a página de sumário do blog.html..."

# Utiliza Perl com padrões flexíveis para remover qualquer variante do sumário
perl -i -0pe '
    # 1. Remove sumário com <h1 id="sumário"> ou <h1>Sumário</h1> seguido do conteúdo até a quebra de página
    s/<h1[^>]*>Sum[áa]rio<\/h1>.*?<div style="break-before: page; page-break-before: always;"><\/div>//gis;
    
    # 2. Remove sumário dentro de <nav id="toc"> (tema padrão mdBook)
    s/<nav id="toc"[^>]*>.*?<\/nav>//gis;
    
    # 3. Remove sumário dentro de <div class="sidetoc"> (alguns temas)
    s/<div class="sidetoc">.*?<\/div>//gis;
    
    # 4. Remove qualquer div vazia de quebra de página que tenha ficado
    s/<div style="break-before: page; page-break-before: always;"><\/div>//gis;
' book/blog.html

# Verifica se ainda há vestígios do sumário (opcional, apenas para debug)
if grep -qi "sum[áa]rio" book/blog.html; then
    echo "⚠️  Aviso: Possível resquício do sumário encontrado. Verifique manualmente."
fi

echo "✅ Seção do sumário removida."

# ============================================================
# ADICIONAR BOTÃO "BLOG" EM TODAS AS PÁGINAS
# ============================================================
echo "🔘 Inserindo botão 'Blog' à esquerda do ícone de impressão..."

BLOG_BUTTON='<a href="blog.html" title="Ver todos os poemas em sequência" aria-label="Blog" style="margin-left: 8px; display: inline-flex; align-items: center; gap: 4px; color: gray; font-weight: bolder;">Blog</a>'

find book -maxdepth 1 -name "*.html" ! -name "print.html" ! -name "blog.html" -type f | while read -r page; do
    perl -i -0pe 's|<a href="blog\.html"[^>]*>.*?Blog<\/a>||gs' "$page"
    perl -i -0pe 's|(<div class="right-buttons">)(.*?)(<a href="print\.html")|\1'"$BLOG_BUTTON"'\2\3|s' "$page"
    echo "   ✅ Botão inserido em: $(basename "$page")"
done

echo "✅ Botão 'Blog' adicionado em todas as páginas."

# ============================================================
# TORNAR blog.html A PÁGINA PADRÃO
# ============================================================
echo "🔀 Tornando blog.html a página principal..."

if [ -f "book/blog.html" ]; then
    cp book/blog.html book/index.html
    echo "✅ index.html substituído pelo conteúdo do blog."
else
    echo "❌ blog.html não encontrado para substituir index.html."
fi

echo "🎉 Tudo pronto! O blog agora é a página inicial do livro (index.html)."