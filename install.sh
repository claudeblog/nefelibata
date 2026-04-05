#!/bin/bash
set -e  # Para o script se algum comando falhar

echo "🔧 Instalando pré-requisitos para o projeto mdBook..."

# Atualiza lista de pacotes
sudo apt update

# 1. Instalar git, curl e build-essential (linker C)
echo "📦 Instalando git, curl e build-essential..."
sudo apt install -y git curl build-essential

# 2. Verificar/instalar Rust
if ! command -v rustc &> /dev/null; then
    echo "🦀 Rust não encontrado. Instalando via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # Carrega o ambiente Rust para a sessão atual
    source "$HOME/.cargo/env"
else
    echo "✅ Rust já está instalado."
fi

# Garantir que o Cargo está no PATH (para o script)
export PATH="$HOME/.cargo/bin:$PATH"

# 3. Instalar mdBook via Cargo (se não existir)
if ! command -v mdbook &> /dev/null; then
    echo "📚 Instalando mdBook via cargo..."
    cargo install mdbook
else
    echo "✅ mdBook já está instalado."
fi

# 4. Adicionar ~/.cargo/bin ao PATH permanentemente (se ainda não tiver)
if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    echo "➕ Adicionado ~/.cargo/bin ao PATH no ~/.bashrc"
fi

# 5. Configurar hook do Git (post-commit) para executar publish.sh automaticamente
if [ -d ".git" ]; then
    echo "🔗 Configurando hook post-commit do Git..."
    HOOK_FILE=".git/hooks/post-commit"
    cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash
# post-commit hook: executa publish.sh após cada commit no branch main

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$BRANCH" = "main" ]; then
    echo "🔁 Commit detectado no branch main. Executando publish.sh..."
    ./publish.sh
fi
EOF
    chmod +x "$HOOK_FILE"
    echo "✅ Hook post-commit instalado com sucesso."
else
    echo "⚠️ Diretório .git não encontrado. Certifique-se de que este é um repositório Git."
    echo "   O hook automático não foi instalado. Execute 'git init' e depois rode este script novamente."
fi

echo "🎉 Tudo pronto! Você pode agora usar os comandos:"
echo "   mdbook build   - para gerar o site"
echo "   mdbook serve   - para ver localmente"
echo "   ./publish.sh   - para publicar no GitHub Pages"
echo ""
echo "📌 O hook post-commit já está configurado: a cada 'git commit' no branch main, o site será publicado automaticamente."
echo "   Para começar, execute:"
echo "   cd ~/Projects/nefelibata"
echo "   mdbook serve --open"