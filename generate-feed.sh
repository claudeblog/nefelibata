#!/bin/bash

# ================= CONFIGURAÇÕES =================
SITE_URL="https://ameopoema.com"
FEED_TITLE="Ame o Poema"
FEED_DESCRIPTION="Poemas do livro Nefelibata"

# Diretório onde este script está localizado (raiz do projeto)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
OUTPUT_FILE="$SCRIPT_DIR/feed.xml"
# =================================================

# Cabeçalho do RSS
cat > "$OUTPUT_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
<channel>
  <title>${FEED_TITLE}</title>
  <link>${SITE_URL}</link>
  <description>${FEED_DESCRIPTION}</description>
  <language>pt-br</language>
  <lastBuildDate>$(LC_TIME=en_US.UTF-8 date "+%a, %d %b %Y %H:%M:%S %z" 2>/dev/null || date -R)</lastBuildDate>
  <itunes:author>Ame o Poema</itunes:author>
  <itunes:image href="${SITE_URL}/capa-podcast.png"/>
  <itunes:category text="Arts"/>
</channel>
</rss>
EOF

# Coleta arquivos .md em ordem decrescente (mais recentes primeiro)
files=()
while IFS= read -r -d '' file; do
    files+=("$(basename "$file")")
done < <(find "$SRC_DIR" -maxdepth 1 -name '*.md' ! -name 'SUMMARY.md' -print0 | sort -rz)

# Processa cada arquivo
for filename in "${files[@]}"; do
    filepath="$SRC_DIR/$filename"

    # Data do nome do arquivo (YYYY-MM-DD)
    filedate="${filename:0:10}"
    day="${filedate:8:2}"
    month="${filedate:5:2}"
    year="${filedate:0:4}"

    case $month in
        01) mon="Jan";; 02) mon="Feb";; 03) mon="Mar";;
        04) mon="Apr";; 05) mon="May";; 06) mon="Jun";;
        07) mon="Jul";; 08) mon="Aug";; 09) mon="Sep";;
        10) mon="Oct";; 11) mon="Nov";; 12) mon="Dec";;
        *)  mon="Jan" ;;
    esac
    pubdate="${day} ${mon} ${year} 00:00:00 +0000"

    # Título
    title=$(sed -n 's/^# //p;q' "$filepath" 2>/dev/null)
    if [ -z "$title" ]; then
        title="${filename:11}"
        title="${title%.md}"
        title="${title//_/ }"
    fi

    # Link para a página
    link="${SITE_URL}/${filename%.md}.html"

    # Conteúdo escapado para <description>
    escaped_content=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$filepath")

    # Escreve o item
    cat >> "$OUTPUT_FILE" <<ITEMEOF
  <item>
    <title>$(echo "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</title>
    <link>${link}</link>
    <guid isPermaLink="true">${link}</guid>
    <pubDate>${pubdate}</pubDate>
    <description>&lt;pre&gt;${escaped_content}&lt;/pre&gt;</description>
ITEMEOF

    # ---- Verifica se há áudio para podcast ----
    # Procura a primeira tag <source src="..."> dentro de <audio>
    audio_src=$(grep -oP '<source\s+src="\K[^"]+' "$filepath" | head -1)
    if [ -n "$audio_src" ]; then
        audio_path="$SRC_DIR/$audio_src"
        if [ -f "$audio_path" ]; then
            # Obtém o tamanho do arquivo (em bytes) – compatível com Linux e macOS
            if stat --version >/dev/null 2>&1; then
                # Linux (GNU stat)
                length=$(stat -c%s "$audio_path")
            else
                # macOS / BSD
                length=$(stat -f%z "$audio_path")
            fi
            # URL pública do áudio
            audio_url="${SITE_URL}/${audio_src}"
            # Adiciona enclosure
            echo "    <enclosure url=\"${audio_url}\" length=\"${length}\" type=\"audio/mpeg\"/>" >> "$OUTPUT_FILE"
        else
            echo "    <!-- Áudio '${audio_src}' não encontrado em ${SRC_DIR} -->" >> "$OUTPUT_FILE"
        fi
    fi
    # Fecha o item
    echo "  </item>" >> "$OUTPUT_FILE"
done

# Fecha o RSS
cat >> "$OUTPUT_FILE" <<EOF
</channel>
</rss>
EOF

echo "Feed gerado em: ${OUTPUT_FILE}"