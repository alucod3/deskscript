#!/bin/bash

# =============================================================================
#  🚀 Script de Configuração de Ambiente de Desenvolvimento
#  Versão: 2.0
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Cores e estilos para saídas
COLOR_RESET="\033[0m"
COLOR_INFO="\033[1;34m"
COLOR_SUCCESS="\033[1;32m"
COLOR_WARNING="\033[1;33m"
COLOR_ERROR="\033[1;31m"
COLOR_TITLE="\033[1;36m"
COLOR_INPUT="\033[1;35m"

# Diretórios importantes
FONT_DIR="/usr/share/fonts/NerdFonts"
CONFIG_DIR="$HOME/.config/devsetup"
LOG_FILE="$CONFIG_DIR/setup_log.txt"

# Lista de fontes disponíveis
FONTS=(
    "FiraMono"
    "FiraCode"
    "DepartureMono"
    "ComicShannsMono"
    "CascadiaCode"
    "CascadiaMono"
    "JetBrainsMono"
    "Meslo"
    "Hack"
)

# Configuração do usuário (será salva)
USER_CONFIG="$CONFIG_DIR/user_preferences.conf"

# -----------------------------------------------------------------------------
# Funções de saída e logging
# -----------------------------------------------------------------------------

show_header() {
    clear
    echo -e "${COLOR_TITLE}"
    echo -e "╔═══════════════════════════════════════════════════════════════════╗"
    echo -e "║                                                                   ║"
    echo -e "║  🚀 ${1}  ║"
    echo -e "║                                                                   ║"
    echo -e "╚═══════════════════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo
}

show_step() {
    echo -e "\n${COLOR_TITLE}📌 $1${COLOR_RESET}\n"
}

log_info() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${COLOR_SUCCESS}[✓]${COLOR_RESET} $1"
    echo "[SUCCESS] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${COLOR_WARNING}[ATENÇÃO]${COLOR_RESET} $1"
    echo "[WARNING] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${COLOR_ERROR}[ERRO]${COLOR_RESET} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

show_progress() {
    local total=$1
    local current=$2
    local name=$3
    local width=50
    local progress=$((current * width / total))
    local percent=$((current * 100 / total))
    
    printf "\r[%-${width}s] %d%% %s" "$(printf '#%.0s' $(seq 1 $progress))" "$percent" "$name"
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

prompt_yes_no() {
    local prompt=$1
    local default=${2:-s}
    local options="(S/n)"
    
    if [ "$default" = "n" ]; then
        options="(s/N)"
    fi
    
    echo -en "${COLOR_INPUT}$prompt $options: ${COLOR_RESET}"
    read -r answer
    
    if [ -z "$answer" ]; then
        answer=$default
    fi
    
    [[ "$answer" =~ ^[sS]$ ]]
}

show_spinner() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r${COLOR_INFO}[%c]${COLOR_RESET} %s" "${spin:$i:1}" "$message"
        sleep 0.1
    done
    
    printf "\r${COLOR_SUCCESS}[✓]${COLOR_RESET} %s\n" "$message"
}

create_directories() {
    mkdir -p "$CONFIG_DIR"
    touch "$LOG_FILE"
    
    log_info "Iniciando configuração em $(date)"
    log_info "Usuário: $USER"
    log_info "Sistema: $(uname -a)"
}

# -----------------------------------------------------------------------------
# Funções de instalação
# -----------------------------------------------------------------------------

check_dependencies() {
    show_step "Verificando dependências básicas"
    
    local dependencies=("wget" "curl" "git" "sudo")
    local missing=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_warning "Dependências ausentes: ${missing[*]}"
        if prompt_yes_no "Deseja instalar as dependências ausentes?"; then
            sudo pacman -S --noconfirm "${missing[@]}"
            log_success "Dependências instaladas"
        else
            log_error "Dependências necessárias não instaladas. O script pode falhar."
        fi
    else
        log_success "Todas as dependências básicas estão instaladas"
    fi
}

select_fonts() {
    show_step "Seleção de Nerd Fonts"
    
    if ! prompt_yes_no "Deseja instalar Nerd Fonts?"; then
        echo "font_install=no" >> "$USER_CONFIG"
        return
    fi
    
    echo "font_install=yes" >> "$USER_CONFIG"
    
    echo -e "Selecione as fontes que deseja instalar (separadas por espaço):"
    echo
    
    for i in "${!FONTS[@]}"; do
        echo -e "  $((i+1))) ${FONTS[i]}"
    done
    
    echo -e "  a) Todas"
    echo -e "  n) Nenhuma"
    echo
    
    echo -en "${COLOR_INPUT}Sua escolha: ${COLOR_RESET}"
    read -r font_choice
    
    selected_fonts=()
    
    if [[ "$font_choice" == "a" ]]; then
        selected_fonts=("${FONTS[@]}")
    elif [[ "$font_choice" != "n" ]]; then
        for num in $font_choice; do
            if [[ $num =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#FONTS[@]} ]; then
                selected_fonts+=("${FONTS[$((num-1))]}")
            fi
        done
    fi
    
    echo "selected_fonts=${selected_fonts[*]}" >> "$USER_CONFIG"
}

install_fonts() {
    show_step "Instalando Nerd Fonts"
    
    if ! grep -q "font_install=yes" "$USER_CONFIG"; then
        log_info "Instalação de fontes ignorada conforme escolha do usuário"
        return
    fi
    
    # Carrega fontes selecionadas do arquivo de configuração
    source "$USER_CONFIG"
    
    if [ ${#selected_fonts[@]} -eq 0 ]; then
        log_info "Nenhuma fonte selecionada para instalação"
        return
    fi
    
    log_info "Instalando Nerd Fonts em $FONT_DIR..."
    sudo mkdir -p "$FONT_DIR"
    
    pushd /tmp > /dev/null
    
    for i in "${!selected_fonts[@]}"; do
        font="${selected_fonts[$i]}"
        log_info "Baixando $font..."
        
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/${font}.zip"
        show_progress ${#selected_fonts[@]} $((i+1)) "Instalando $font"
        
        unzip -o -q "${font}.zip" -d "$font"
        sudo cp -r "$font"/* "$FONT_DIR/"
        rm -rf "$font" "${font}.zip"
    done
    
    popd > /dev/null
    
    # Atualiza cache de fontes em segundo plano
    sudo fc-cache -f > /dev/null 2>&1 &
    show_spinner $! "Atualizando cache de fontes"
    
    log_success "Nerd Fonts instaladas com sucesso"
}

select_shell() {
    show_step "Escolha do Shell"
    
    local options=("zsh + oh-my-zsh" "fish" "Nenhum")
    echo -e "Escolha seu shell moderno favorito:"
    echo
    
    for i in "${!options[@]}"; do
        echo -e "  $((i+1))) ${options[i]}"
    done
    echo
    
    echo -en "${COLOR_INPUT}Sua escolha (1-3): ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1) echo "shell_choice=zsh" >> "$USER_CONFIG" ;;
        2) echo "shell_choice=fish" >> "$USER_CONFIG" ;;
        *) echo "shell_choice=none" >> "$USER_CONFIG" ;;
    esac
}

install_shell() {
    show_step "Instalando Shell"
    
    source "$USER_CONFIG"
    
    case $shell_choice in
        "zsh")
            log_info "Instalando zsh + oh-my-zsh..."
            sudo pacman -S --noconfirm zsh git curl
            
            # Cria arquivo de configuração zsh pré-existente para evitar substituição
            touch ~/.zshrc
            
            # Instala oh-my-zsh sem mudar de shell imediatamente
            log_info "Instalando Oh My Zsh..."
            RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &> /dev/null
            
            # Adiciona configuração do starship se não existir
            if ! grep -q "starship init zsh" ~/.zshrc; then
                echo -e '\n# Inicializa Starship prompt\nif command -v starship &> /dev/null; then\n  eval "$(starship init zsh)"\nfi' >> ~/.zshrc
            fi
            
            # Pergunta se deseja alterar o shell padrão
            if prompt_yes_no "Deseja definir zsh como seu shell padrão?"; then
                chsh -s "$(command -v zsh)"
                log_success "Shell padrão alterado para zsh. A alteração terá efeito no próximo login."
            fi
            ;;
            
        "fish")
            log_info "Instalando fish..."
            sudo pacman -S --noconfirm fish
            
            mkdir -p ~/.config/fish
            
            # Adiciona configuração do starship se não existir
            if ! grep -q "starship init fish" ~/.config/fish/config.fish; then
                echo -e '\n# Inicializa Starship prompt\nif command -v starship &> /dev/null\n  eval "$(starship init fish)"\nend' >> ~/.config/fish/config.fish
            fi
            
            # Pergunta se deseja alterar o shell padrão
            if prompt_yes_no "Deseja definir fish como seu shell padrão?"; then
                chsh -s "$(command -v fish)"
                log_success "Shell padrão alterado para fish. A alteração terá efeito no próximo login."
            fi
            ;;
            
        *)
            log_info "Instalação de shell ignorada conforme escolha do usuário"
            ;;
    esac
}

select_terminal() {
    show_step "Escolha do Terminal"
    
    local options=("kitty" "alacritty" "Nenhum")
    echo -e "Escolha seu terminal preferido:"
    echo
    
    for i in "${!options[@]}"; do
        echo -e "  $((i+1))) ${options[i]}"
    done
    echo
    
    echo -en "${COLOR_INPUT}Sua escolha (1-3): ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1) echo "terminal_choice=kitty" >> "$USER_CONFIG" ;;
        2) echo "terminal_choice=alacritty" >> "$USER_CONFIG" ;;
        *) echo "terminal_choice=none" >> "$USER_CONFIG" ;;
    esac
}

install_terminal() {
    show_step "Instalando Terminal"
    
    source "$USER_CONFIG"
    
    case $terminal_choice in
        "kitty")
            log_info "Instalando kitty..."
            sudo pacman -S --noconfirm kitty
            
            # Configuração básica do kitty
            mkdir -p ~/.config/kitty
            if [ ! -f ~/.config/kitty/kitty.conf ]; then
                cat > ~/.config/kitty/kitty.conf << 'EOL'
# Kitty Terminal Configuration
font_family      JetBrainsMono Nerd Font
font_size        12.0
background_opacity 0.95
enable_audio_bell no
window_padding_width 4
EOL
                log_success "Configuração básica do kitty criada"
            fi
            ;;
            
        "alacritty")
            log_info "Instalando alacritty..."
            sudo pacman -S --noconfirm alacritty
            
            # Configuração básica do alacritty
            mkdir -p ~/.config/alacritty
            if [ ! -f ~/.config/alacritty/alacritty.yml ]; then
                cat > ~/.config/alacritty/alacritty.yml << 'EOL'
# Alacritty Terminal Configuration
font:
  normal:
    family: JetBrainsMono Nerd Font
  size: 12.0

window:
  padding:
    x: 4
    y: 4
  opacity: 0.95

bell:
  duration: 0
EOL
                log_success "Configuração básica do alacritty criada"
            fi
            ;;
            
        *)
            log_info "Instalação de terminal ignorada conforme escolha do usuário"
            ;;
    esac
}

select_tools() {
    show_step "Seleção de Ferramentas"
    
    # Ferramentas essenciais
    if prompt_yes_no "Instalar ferramentas essenciais (curl, wget, jq, tmux, git, btop)?"; then
        echo "install_core_tools=yes" >> "$USER_CONFIG"
    else
        echo "install_core_tools=no" >> "$USER_CONFIG"
    fi
    
    # Linguagens de programação
    echo -e "\nSelecione as linguagens de programação que deseja instalar:"
    local options=("Go" "Python" "Rust" "Java" "Node.js")
    local selected_langs=""
    
    for i in "${!options[@]}"; do
        if prompt_yes_no "  - Instalar ${options[i]}?" "n"; then
            selected_langs+="${options[i]} "
        fi
    done
    
    echo "selected_langs=$selected_langs" >> "$USER_CONFIG"
    
    # Ferramentas de desenvolvimento
    if prompt_yes_no "Instalar Docker e Docker Compose?"; then
        echo "install_docker=yes" >> "$USER_CONFIG"
    else
        echo "install_docker=no" >> "$USER_CONFIG"
    fi
    
    # Ferramentas de produtividade
    if prompt_yes_no "Instalar ferramentas de produtividade (fzf, bat, exa, ripgrep, thefuck, tldr, zoxide, neofetch)?"; then
        echo "install_productivity=yes" >> "$USER_CONFIG"
    else
        echo "install_productivity=no" >> "$USER_CONFIG"
    fi
    
    # Starship prompt
    if prompt_yes_no "Instalar Starship prompt?"; then
        echo "install_starship=yes" >> "$USER_CONFIG"
    else
        echo "install_starship=no" >> "$USER_CONFIG"
    fi
}

install_tools() {
    show_step "Instalando Ferramentas"
    
    source "$USER_CONFIG"
    
    # Ferramentas essenciais
    if [ "$install_core_tools" = "yes" ]; then
        log_info "Instalando ferramentas essenciais..."
        sudo pacman -S --noconfirm curl wget jq tmux git btop
        log_success "Ferramentas essenciais instaladas"
    fi
    
    # Linguagens de programação
    if [ -n "$selected_langs" ]; then
        log_info "Instalando linguagens de programação selecionadas..."
        
        for lang in $selected_langs; do
            case $lang in
                "Go")
                    log_info "Instalando Go..."
                    sudo pacman -S --noconfirm go
                    mkdir -p ~/go/{bin,pkg,src}
                    ;;
                "Python")
                    log_info "Instalando Python..."
                    sudo pacman -S --noconfirm python python-pip
                    pip install --user pipenv
                    ;;
                "Rust")
                    log_info "Instalando Rust..."
                    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                    source "$HOME/.cargo/env"
                    ;;
                "Java")
                    log_info "Instalando Java..."
                    sudo pacman -S --noconfirm jdk-openjdk
                    ;;
                "Node.js")
                    log_info "Instalando Node.js..."
                    sudo pacman -S --noconfirm nodejs npm
                    ;;
            esac
        done
        
        log_success "Linguagens de programação instaladas"
    fi
    
    # Docker
    if [ "$install_docker" = "yes" ]; then
        log_info "Instalando Docker e Docker Compose..."
        sudo pacman -S --noconfirm docker docker-compose
        sudo systemctl enable docker.service
        
        if prompt_yes_no "Iniciar o serviço Docker agora?"; then
            sudo systemctl start docker.service
        fi
        
        if prompt_yes_no "Adicionar usuário ao grupo docker? (não precisará usar sudo para comandos docker)"; then
            sudo usermod -aG docker "$USER"
            log_warning "Você precisará fazer logout e login novamente para usar o Docker sem sudo"
        fi
        
        log_success "Docker instalado"
    fi
    
    # Ferramentas de produtividade
    if [ "$install_productivity" = "yes" ]; then
        log_info "Instalando ferramentas de produtividade..."
        sudo pacman -S --noconfirm fzf bat exa ripgrep thefuck tldr zoxide neofetch
        log_success "Ferramentas de produtividade instaladas"
    fi
    
    # Starship
    if [ "$install_starship" = "yes" ]; then
        log_info "Instalando Starship prompt..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        log_success "Starship instalado"
    fi
}

setup_ssh_keys() {
    show_step "Configuração de Chave SSH"
    
    if ! prompt_yes_no "Deseja gerar uma nova chave SSH (se ainda não existir)?"; then
        return
    fi
    
    local key_type="ed25519"
    local key_path="$HOME/.ssh/id_$key_type"
    
    # Verifica se já existe uma chave
    if [[ -f "$key_path" ]]; then
        log_warning "Chave SSH já existe em $key_path"
        if ! prompt_yes_no "Deseja substituir a chave existente?"; then
            return
        fi
    fi
    
    # Cria diretório .ssh se não existir
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Solicita email para o comentário da chave
    echo -en "${COLOR_INPUT}Digite seu email para o comentário da chave (ou deixe em branco): ${COLOR_RESET}"
    read -r email
    
    local comment="$USER@$(hostname)"
    if [[ -n "$email" ]]; then
        comment="$email"
    fi
    
    # Gera a chave SSH
    log_info "Gerando chave SSH do tipo $key_type..."
    ssh-keygen -t "$key_type" -C "$comment" -f "$key_path" -N ""
    
    log_success "Chave SSH gerada em $key_path"
    
    # Exibe a chave pública
    echo -e "\n${COLOR_INFO}Chave pública (copie para GitHub/GitLab):${COLOR_RESET}"
    echo -e "${COLOR_SUCCESS}$(cat "$key_path.pub")${COLOR_RESET}\n"
    
    # Pergunta se deseja iniciar o agente SSH
    if prompt_yes_no "Deseja iniciar o agente SSH e adicionar a chave?"; then
        eval "$(ssh-agent -s)"
        ssh-add "$key_path"
        log_success "Chave adicionada ao agente SSH"
    fi
    
    # Pergunta se deseja copiar a chave
    if command -v xclip &> /dev/null; then
        if prompt_yes_no "Copiar a chave pública para a área de transferência?"; then
            cat "$key_path.pub" | xclip -selection clipboard
            log_success "Chave pública copiada para a área de transferência"
        fi
    elif command -v wl-copy &> /dev/null; then
        if prompt_yes_no "Copiar a chave pública para a área de transferência?"; then
            cat "$key_path.pub" | wl-copy
            log_success "Chave pública copiada para a área de transferência"
        fi
    fi
}

install_dotfiles() {
    show_step "Configuração de Dotfiles"
    
    if ! prompt_yes_no "Você tem dotfiles personalizados no GitHub?"; then
        echo -e "\n${COLOR_INFO}Dicas para gerenciar seus dotfiles:${COLOR_RESET}"
        echo -e "1. Crie um repositório no GitHub para seus arquivos de configuração"
        echo -e "2. Use ferramentas como GNU Stow ou Chezmoi para gerenciar seus dotfiles"
        echo -e "3. Considere usar bare git repos para simplicidade"
        return
    fi
    
    echo -en "${COLOR_INPUT}Informe a URL do repositório (https ou ssh): ${COLOR_RESET}"
    read -r repo_url
    
    if [ -d ~/dotfiles ]; then
        log_warning "Diretório ~/dotfiles já existe"
        if ! prompt_yes_no "Deseja substituir o diretório existente?"; then
            return
        fi
        rm -rf ~/dotfiles
    fi
    
    log_info "Clonando repositório de dotfiles..."
    git clone "$repo_url" ~/dotfiles
    
    if [ $? -ne 0 ]; then
        log_error "Falha ao clonar o repositório"
        return
    fi
    
    if [ -f ~/dotfiles/install.sh ]; then
        if prompt_yes_no "Encontrado script de instalação. Deseja executá-lo?"; then
            (cd ~/dotfiles && ./install.sh)
            if [ $? -eq 0 ]; then
                log_success "Script de instalação de dotfiles executado com sucesso"
            else
                log_error "Falha na execução do script de instalação de dotfiles"
            fi
        fi
    else
        log_warning "Nenhum script de instalação (install.sh) encontrado no repositório"
        log_info "Você pode precisar configurar seus dotfiles manualmente"
    fi
}

generate_summary() {
    show_step "Resumo da Configuração"
    
    source "$USER_CONFIG"
    
    echo -e "${COLOR_TITLE}Componentes Instalados:${COLOR_RESET}"
    echo
    
    # Nerd Fonts
    if [ "$font_install" = "yes" ]; then
        echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Nerd Fonts: ${selected_fonts[*]}"
    else
        echo -e "${COLOR_WARNING}✗${COLOR_RESET} Nerd Fonts: Não instaladas"
    fi
    
    # Shell
    case $shell_choice in
        "zsh") echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Shell: ZSH + Oh My Zsh" ;;
        "fish") echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Shell: Fish" ;;
        *) echo -e "${COLOR_WARNING}✗${COLOR_RESET} Shell: Nenhum instalado" ;;
    esac
    
    # Terminal
    case $terminal_choice in
        "kitty") echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Terminal: Kitty" ;;
        "alacritty") echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Terminal: Alacritty" ;;
        *) echo -e "${COLOR_WARNING}✗${COLOR_RESET} Terminal: Nenhum instalado" ;;
    esac
    
    # Ferramentas essenciais
    if [ "$install_core_tools" = "yes" ]; then
        echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Ferramentas essenciais: curl, wget, jq, tmux, git, btop"
    else
        echo -e "${COLOR_WARNING}✗${COLOR_RESET} Ferramentas essenciais: Não instaladas"
    fi
    
    # Linguagens
    if [ -n "$selected_langs" ]; then
        echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Linguagens: $selected_langs"
    else
        echo -e "${COLOR_WARNING}✗${COLOR_RESET} Linguagens: Nenhuma instalada"
    fi
    
    # Docker
    if [ "$install_docker" = "yes" ]; then
        echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Docker: Instalado"
    else
        echo -e "${COLOR_WARNING}✗${COLOR_RESET} Docker: Não instalado"
    fi
    
    # Ferramentas de produtividade
    if [ "$install_productivity" = "yes" ]; then
        echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Ferramentas de produtividade: fzf, bat, exa, ripgrep, thefuck, tldr, zoxide, neofetch"
    else
        echo -e "${COLOR_WARNING}✗${COLOR_RESET} Ferramentas de produtividade: Não instaladas"
    fi
    
    # Starship
    if [ "$install_starship" = "yes" ]; then
        echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} Starship prompt: Instalado"
    else
        echo -e "${COLOR_WARNING}✗${COLOR_RESET} Starship prompt: Não instalado"
    fi
    
    echo
    log_info "Configuração salva em $USER_CONFIG"
    log_info "Log detalhado disponível em $LOG_FILE"
    
    echo -e "\n${COLOR_SUCCESS}🎉 Configuração concluída com sucesso!${COLOR_RESET}"
    echo -e "\n${COLOR_INFO}Recomendação:${COLOR_RESET} Reinicie o terminal ou faça logout/login para aplicar todas as alterações."
}

# -----------------------------------------------------------------------------
# Fluxo principal
# -----------------------------------------------------------------------------

main() {
    show_header "Configuração de Ambiente de Desenvolvimento"
    
    create_directories
    check_dependencies
    
    select_fonts
    select_shell
    select_terminal
    select_tools
    
    echo -e "\n${COLOR_INFO}Iniciando instalação dos componentes selecionados...${COLOR_RESET}\n"
    sleep 1
    
    install_fonts
    install_shell
    install_terminal
    install_tools
    setup_ssh_keys
    install_dotfiles
    
    generate_summary
}

main
