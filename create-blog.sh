#!/bin/bash
set -e

echo "📄 Criando blog.html a partir do print.html..."

# Verifica se o print.html foi gerado
if [ ! -f "book/print.html" ]; then
    echo "❌ book/print.html não encontrado. Execute 'mdbook build' primeiro."
    exit 1
fi

# Copia o print.html para blog.html
cp book/print.html book/blog.html

# Remove o script que chama window.print() – exatamente o bloco que você mostrou
sed -i '/<script>/,/<\/script>/ {
    /window\.print/d
    /window.addEventListener/d
    /window.setTimeout/d
}' book/blog.html

# Caso o bloco inteiro precise ser removido de forma mais agressiva (linhas consecutivas)
perl -i -0pe 's/<script>\s*window\.addEventListener\('"'"'load'"'"',\s*function\(\s*\)\s*\{\s*window\.setTimeout\(window\.print,\s*100\s*\);\s*\}\s*\);\s*<\/script>//gis' book/blog.html

# Adiciona um script de bloqueio como fallback (garantia total)
sed -i 's|</body>|<script>window.print = function() { return false; };</script></body>|' book/blog.html

echo "✅ blog.html criado com sucesso (prompt de impressão desativado)."

# ============================================================
# INJEÇÃO DO LINK DO BLOG NA PÁGINA DE SUMÁRIO (sem aparecer na sidebar)
# ============================================================
echo "🔗 Injetando link do Blog na página de sumário..."

BLOG_LINK='<div style="text-align: center; margin: 2rem 0; padding: 1rem; background-color: #f5f5f5; border-radius: 8px;"><a href="blog.html" style="font-size: 1.2rem; font-weight: bold; text-decoration: none;">📖 Ver todos os poemas em uma única página (Blog)</a></div>'

# Procura pelo arquivo da página de sumário (case-insensitive, dentro da pasta book)
SUMMARY_HTML=$(find book -maxdepth 1 -iname "sum*.html" -type f | head -1)

if [ -z "$SUMMARY_HTML" ]; then
    echo "⚠️ Página de sumário não encontrada. O link NÃO foi injetado."
else
    # Tenta injetar dentro da tag <main>
    if grep -q '</main>' "$SUMMARY_HTML"; then
        sed -i "s|</main>|${BLOG_LINK}\n</main>|" "$SUMMARY_HTML"
        echo "✅ Link do Blog adicionado dentro de <main> na página $SUMMARY_HTML"
    # Fallback: insere antes do fechamento da div de conteúdo
    elif grep -q '<div class="content">' "$SUMMARY_HTML"; then
        sed -i "s|</div>|${BLOG_LINK}\n</div>|" "$SUMMARY_HTML"
        echo "✅ Link do Blog adicionado (fallback) na página $SUMMARY_HTML"
    else
        echo "⚠️ Não foi possível encontrar o local de injeção. Link não adicionado."
    fi
fi

echo "✅ Processo concluído. O link do Blog aparece APENAS na página de sumário, não na sidebar."