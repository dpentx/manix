{ config, pkgs, ... }:

{
  # Starship - Süper renkli ve detaylı
  programs.starship = {
    enable = true;
    settings = {
      format = ''
        [╭─](bold bright-cyan)$os$username$hostname$directory$git_branch$git_status$git_commit$docker_context$nix_shell
        [│](bold bright-cyan)$rust$python$nodejs$golang$java$c$package$cmd_duration
        [╰─](bold bright-cyan)$character
      '';
      
      # İşletim sistemi ikonu
      os = {
        disabled = false;
        style = "bold white";
        symbols = {
          NixOS = " ";
          Linux = " ";
        };
      };
      
      # Kullanıcı
      username = {
        style_user = "bold bright-blue";
        style_root = "bold bright-red";
        format = "[$user]($style)";
        disabled = false;
        show_always = true;
      };
      
      # Hostname
      hostname = {
        ssh_only = false;
        format = "[@$hostname](bold bright-green) ";
        disabled = false;
      };
      
      # Dizin - daha renkli ve belirgin
      directory = {
        truncation_length = 4;
        truncate_to_repo = true;
        style = "bold bright-cyan";
        format = "[ $path]($style)[$read_only]($read_only_style) ";
        read_only = " 🔒";
        read_only_style = "bright-red";
        home_symbol = "~";
        truncation_symbol = "…/";
        
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
          "Videos" = " ";
          "Projects" = "󰲋 ";
          ".config" = " ";
          "manix" = " ";
        };
      };
      
      # Git branch - daha parlak
      git_branch = {
        symbol = " ";
        style = "bold bright-purple";
        format = "[$symbol$branch(:$remote_branch)]($style) ";
        truncation_length = 25;
        truncation_symbol = "…";
      };
      
      # Git status - daha detaylı ve renkli
      git_status = {
        style = "bold bright-yellow";
        format = "([$all_status$ahead_behind]($style) )";
        conflicted = "[🏳 $count](bold bright-red) ";
        ahead = "[⇡$count](bold bright-green) ";
        behind = "[⇣$count](bold bright-red) ";
        diverged = "[⇕⇡$ahead_count⇣$behind_count](bold bright-magenta) ";
        up_to_date = "[✓](bold bright-green) ";
        untracked = "[?$count](bold bright-blue) ";
        stashed = "[\$count](bold bright-cyan) ";
        modified = "[!$count](bold bright-yellow) ";
        staged = "[+$count](bold bright-green) ";
        renamed = "[»$count](bold bright-magenta) ";
        deleted = "[✘$count](bold bright-red) ";
      };
      
      # Git commit
      git_commit = {
        commit_hash_length = 8;
        tag_symbol = "🏷 ";
        style = "bold bright-green";
        format = "[($hash$tag)]($style) ";
        disabled = false;
        only_detached = false;
      };
      
      # Karakter
      character = {
        success_symbol = "[❯](bold bright-green)[❯](bold green)[❯](bold bright-black)";
        error_symbol = "[❯](bold bright-red)[❯](bold red)[❯](bold bright-black)";
        vimcmd_symbol = "[❮](bold bright-green)[❮](bold green)[❮](bold bright-black)";
      };
      
      # Komut süresi - daha belirgin
      cmd_duration = {
        min_time = 500;
        format = "[⏱ $duration](bold bright-yellow) ";
        show_milliseconds = true;
      };
      
      # Nix shell - parlak mavi
      nix_shell = {
        symbol = " ";
        format = "[$symbol$state( $name)]($style) ";
        style = "bold bright-blue";
        impure_msg = "[impure](bold bright-red)";
        pure_msg = "[pure](bold bright-green)";
      };
      
      # Docker
      docker_context = {
        symbol = " ";
        style = "bold bright-blue";
        format = "[$symbol$context]($style) ";
        only_with_files = true;
      };
      
      # Rust
      rust = {
        symbol = " ";
        style = "bold bright-red";
        format = "[$symbol$version]($style) ";
      };
      
      # Python
      python = {
        symbol = " ";
        style = "bold bright-yellow";
        format = "[$symbol$version( $virtualenv)]($style) ";
        pyenv_version_name = true;
      };
      
      # Node.js
      nodejs = {
        symbol = " ";
        style = "bold bright-green";
        format = "[$symbol$version]($style) ";
      };
      
      # Golang
      golang = {
        symbol = " ";
        style = "bold bright-cyan";
        format = "[$symbol$version]($style) ";
      };
      
      # Java
      java = {
        symbol = " ";
        style = "bold bright-red";
        format = "[$symbol$version]($style) ";
      };
      
      # C/C++
      c = {
        symbol = " ";
        style = "bold bright-blue";
        format = "[$symbol$version]($style) ";
      };
      
      # Package
      package = {
        symbol = "📦 ";
        style = "bold bright-magenta";
        format = "[$symbol$version]($style) ";
        display_private = false;
      };
      
      # Battery - daha detaylı
      battery = {
        full_symbol = "🔋";
        charging_symbol = "⚡";
        discharging_symbol = "💀";
        unknown_symbol = "❓";
        empty_symbol = "🪫";
        
        display = [
          {
            threshold = 10;
            style = "bold bright-red";
            charging_symbol = "⚡";
            discharging_symbol = "💀";
          }
          {
            threshold = 30;
            style = "bold bright-yellow";
          }
          {
            threshold = 60;
            style = "bold bright-blue";
          }
          {
            threshold = 100;
            style = "bold bright-green";
          }
        ];
      };
      
      # Status
      status = {
        style = "bold bright-red";
        symbol = "✖ ";
        format = "[$symbol$status]($style) ";
        disabled = false;
      };
      
      # Memory
      memory_usage = {
        disabled = false;
        threshold = 70;
        symbol = " ";
        style = "bold bright-yellow";
        format = "$symbol[$ram_pct]($style) ";
      };
    };
  };

  # Zsh - Süper güçlü pluginler
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      share = true;
      extended = true;
    };
    
    shellAliases = {
      # Sistem - renkli
      ls = "exa --icons --color=always --group-directories-first";
      ll = "exa -la --icons --color=always --group-directories-first";
      la = "exa -a --icons --color=always --group-directories-first";
      lt = "exa --tree --icons --color=always --level=2";
      tree = "exa --tree --icons --color=always";
      
      cat = "bat --style=auto";
      grep = "grep --color=auto";
      diff = "diff --color=auto";
      ip = "ip --color=auto";
      
      # Navigasyon
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      
      # Git - süper kısayollar
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit";
      gcmsg = "git commit -m";
      gca = "git commit --amend";
      gp = "git push";
      gpu = "git push -u origin HEAD";
      gl = "git pull";
      gf = "git fetch";
      gs = "git status -sb";
      gss = "git status";
      gd = "git diff";
      gdc = "git diff --cached";
      gb = "git branch";
      gba = "git branch -a";
      gco = "git checkout";
      gcb = "git checkout -b";
      gcheckout = "git checkout main || git checkout master";
      gm = "git merge";
      gr = "git rebase";
      gri = "git rebase -i";
      glog = "git log --oneline --graph --decorate --all";
      glg = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      gundo = "git reset --soft HEAD^";
      gclean = "git clean -fd";
      
      # NixOS - flake desteği
      rebuild = "git add -A && git commit -m 'update' && sudo nixos-rebuild switch --flake .#asus";
      rebuild-test = "git add -A && sudo nixos-rebuild test --flake .#asus";
      rebuild-boot = "git add -A && git commit -m 'update' && sudo nixos-rebuild boot --flake .#asus";
      hm-switch = "git add -A && home-manager switch --flake .#asus";
      update = "nix flake update && git add flake.lock && git commit -m 'update flake'";
      upgrade = "update && rebuild";
      
      # Paket yönetimi
      search = "nix search nixpkgs";
      shell = "nix-shell -p";
      run = "nix run nixpkgs#";
      
      # Sistem bilgisi - renkli
      ports = "ss -tulanp";
      listening = "ss -tlnp";
      meminfo = "free -h";
      diskinfo = "df -h";
      psmem = "ps auxf | sort -nr -k 4 | head -20";
      pscpu = "ps auxf | sort -nr -k 3 | head -20";
      
      # Hızlı işlemler
      c = "clear";
      h = "history";
      j = "jobs";
      v = "nvim";
      vim = "nvim";
      
      # Güvenlik
      rm = "rm -i";
      cp = "cp -i";
      mv = "mv -i";
      
      # Ağ
      myip = "curl -s ifconfig.me";
      speedtest = "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -";
      
      # Sistem kontrol
      update-grub = "sudo grub-mkconfig -o /boot/grub/grub.cfg";
      please = "sudo";
      fucking = "sudo";
    };
    
    initExtra = ''
      # Renkli terminal
      export TERM="xterm-256color"
      
      # Zsh seçenekleri - daha akıllı
      setopt AUTO_CD              # Sadece dizin adı yazınca cd yap
      setopt AUTO_PUSHD           # cd geçmişi tut
      setopt PUSHD_IGNORE_DUPS    # Tekrar eden dizinleri ignore et
      setopt PUSHD_SILENT         # pushd sessiz olsun
      setopt CORRECT              # Komut düzeltme
      setopt CORRECT_ALL          # Argüman düzeltme
      setopt INTERACTIVE_COMMENTS # Komut satırında # ile yorum
      setopt EXTENDED_GLOB        # Gelişmiş glob
      setopt NUMERIC_GLOB_SORT    # Sayısal sıralama
      
      # History seçenekleri
      setopt HIST_IGNORE_ALL_DUPS # Tüm dupları sil
      setopt HIST_FIND_NO_DUPS    # Aramada dup gösterme
      setopt HIST_SAVE_NO_DUPS    # Kaydetme dupları ignore
      setopt HIST_REDUCE_BLANKS   # Boşlukları temizle
      
      # Completion sistemi - süper gelişmiş
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' completer _expand _complete _ignored _approximate
      zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
      zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
      
      # Case insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      
      # Process completion
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
      zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
      
      # Key bindings - daha kullanışlı
      bindkey "^[[A" history-substring-search-up
      bindkey "^[[B" history-substring-search-down
      bindkey "^[[3~" delete-char
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line
      bindkey "^[[Z" reverse-menu-complete
      bindkey "^R" history-incremental-search-backward
      
      # Autosuggestion ayarları
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      
      # Custom functions - süper kullanışlı
      
      # Dizin oluştur ve içine gir
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }
      
      # Dosya çıkart
      extract() {
        if [ -f "$1" ] ; then
          case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.xz)        unxz "$1"        ;;
            *.tar.xz)    tar xf "$1"      ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }
      
      # Git repo clone ve içine gir
      gcl() {
        git clone "$1" && cd "$(basename "$1" .git)"
      }
      
      # Hızlı backup
      backup() {
        cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
      }
      
      # Port dinleme
      port() {
        ss -tulanp | grep ":$1"
      }
      
      # Hızlı not alma
      note() {
        echo "$(date): $*" >> "$HOME/notes.txt"
      }
      
      # NixOS özel - paket arama ve yükleme
      nix-install() {
        nix-env -iA nixpkgs.$1
      }
      
      # Dosya boyutunu human-readable göster
      sizeof() {
        du -sh "$1"
      }
      
      # Environment variables
      export EDITOR="nvim"
      export VISUAL="nvim"
      export BROWSER="microsoft-edge"
      export TERMINAL="kitty"
      export PAGER="less"
      
      # Wayland/Niri specific
      if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        export MOZ_ENABLE_WAYLAND=1
        export QT_QPA_PLATFORM=wayland
        export SDL_VIDEODRIVER=wayland
        export _JAVA_AWT_WM_NONREPARENTING=1
        export NIXOS_OZONE_WL=1
        export GDK_BACKEND=wayland,x11
      fi
      
      # Color support for less
      export LESS_TERMCAP_mb=$'\e[1;32m'
      export LESS_TERMCAP_md=$'\e[1;32m'
      export LESS_TERMCAP_me=$'\e[0m'
      export LESS_TERMCAP_se=$'\e[0m'
      export LESS_TERMCAP_so=$'\e[01;33m'
      export LESS_TERMCAP_ue=$'\e[0m'
      export LESS_TERMCAP_us=$'\e[1;4;31m'
      
      # LS_COLORS - renkli ls
      eval "$(dircolors -b)"
      
      # Başlangıç mesajı - renkli
      echo ""
      echo -e "\e[1;36m╔═══════════════════════════════════════╗\e[0m"
      echo -e "\e[1;36m║\e[0m  \e[1;35mWelcome to NixOS + Niri 🚀\e[0m           \e[1;36m║\e[0m"
      echo -e "\e[1;36m╚═══════════════════════════════════════╝\e[0m"
      echo ""
      
      # Sistem bilgisi göster
      echo -e "\e[1;33m📅 Date:\e[0m $(date '+%A, %B %d, %Y - %H:%M')"
      echo -e "\e[1;32m💻 Uptime:\e[0m $(uptime | awk '{print $3, $4}' | sed 's/,//')"
      echo ""
      
      # Load direnv if available
      if command -v direnv &> /dev/null; then
        eval "$(direnv hook zsh)"
      fi
    '';
  };

  # Bash için fallback
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [ "ignoredups" "ignorespace" "erasedups" ];
    
    shellAliases = {
      ls = "exa --icons --color=always";
      ll = "exa -la --icons --color=always";
      cat = "bat";
      rebuild = "git add -A && git commit -m 'update' && sudo nixos-rebuild switch --flake .#asus";
    };
    
    initExtra = ''
      # Bash için basit prompt
      PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
    '';
  };
}
