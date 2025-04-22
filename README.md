# DESKscript: Developer Environment Setup Kit

> An interactive script for rapid setup of optimized Linux development environments for programmers.

## 🚀 Overview

DESKscript (Developer Environment Setup Kit) is a command-line tool that automatically configures a complete development environment on Linux. With a friendly, interactive interface, it installs and configures everything a developer needs to start working quickly: fonts, terminal, shell, programming languages, development tools, and productivity utilities.

## ✨ Features

- **Interactive interface** with visual indicators and selection menus
- **Complete customization** of the development environment
- **Nerd Fonts installation** for terminals and editors with icon support
- **Modern shell configuration** (zsh + oh-my-zsh or fish)
- **Terminal installation** (kitty or alacritty) with optimized settings
- **Support for multiple programming languages** (Go, Python, Rust, Java, Node.js)
- **Essential tools** for development (git, curl, tmux, etc.)
- **Docker and Docker Compose** for containerization
- **Productivity utilities** (fzf, bat, exa, ripgrep, etc.)
- **Dotfiles management** with GitHub integration
- **SSH key generation** for Git services
- **Detailed logs** for diagnostics and tracking

## 📋 Requirements

- Arch Linux-based distribution
- Root access via sudo
- Internet connection

## 🔧 Installation

1. Download the script:

```bash
curl -O https://raw.githubusercontent.com/alucod3/deskscript/main/deskscript.sh
```

2. Make it executable:

```bash
chmod +x deskscript.sh
```

3. Run the script:

```bash
./deskscript.sh
```

## 📝 Usage

DESKscript will guide you through an interactive process to select which components you want to install:

1. **Component Selection**:
   - Choose which Nerd Fonts to install
   - Select your preferred shell (zsh or fish)
   - Choose your terminal (kitty or alacritty)
   - Select programming languages and tools

2. **Installation**:
   - The script will automatically install the selected components
   - Visual feedback shows progress during installation

3. **Configuration**:
   - Basic configurations are created for each tool
   - Option to import custom dotfiles
   - SSH key generation for GitHub/GitLab

4. **Summary**:
   - At the end, a complete installation summary is displayed
   - Detailed logs are saved for future reference

## ⚙️ Customization

Settings and selections are saved in `~/.config/devsetup/user_preferences.conf`, allowing you to re-run the script later with the same selections.

You can manually edit this file before running the script again to modify default selections.

## 🔍 Code Structure

```
deskscript.sh
├── UI and logging functions
│   ├── show_header()
│   ├── show_step()
│   ├── log_info(), log_success(), log_warning(), log_error()
│   ├── show_progress()
│   └── show_spinner()
├── Selection functions
│   ├── select_fonts()
│   ├── select_shell()
│   ├── select_terminal()
│   └── select_tools()
├── Installation functions
│   ├── install_fonts()
│   ├── install_shell()
│   ├── install_terminal()
│   └── install_tools()
└── Helper functions
    ├── setup_ssh_keys()
    ├── install_dotfiles()
    └── generate_summary()
```

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

### How to contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💖 Acknowledgements

- [Nerd Fonts](https://www.nerdfonts.com/) for the amazing font collection
- [Oh My Zsh](https://ohmyz.sh/) for the zsh framework
- [Starship](https://starship.rs/) for the cross-shell prompt
- [Fish Shell](https://fishshell.com/) for the friendly shell
- All the open-source tools that make developers' lives easier

---

Developed with ❤️ for the developer community.
