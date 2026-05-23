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