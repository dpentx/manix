{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      # Format - daha modern ve temiz
      format = ''
        [╭─](bold cyan)$username$hostname$directory$git_branch$git_status$nix_shell$rust$python$nodejs$package
        [╰─](bold cyan)$character
      '';
      
      # Karakter (prompt simgesi)
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
        vimcmd_symbol = "[](bold green)";
      };
      
      # Kullanıcı adı
      username = {
        style_user = "bold blue";
        style_root = "bold red";
        format = "[$user]($style) ";
        disabled = false;
        show_always = true;
      };
      
      # Hostname
      hostname = {
        ssh_only = false;
        format = "[@$hostname](bold green) ";
        disabled = false;
      };
      
      # Dizin
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        read_only = " 🔒";
        read_only_style = "red";
        home_symbol = "~";
        truncation_symbol = "…/";
      };
      
      # Git branch
      git_branch = {
        symbol = " ";
        style = "bold purple";
        format = "[$symbol$branch(:$remote_branch)]($style) ";
        truncation_length = 20;
        truncation_symbol = "…";
      };
      
      # Git status - daha detaylı
      git_status = {
        style = "bold yellow";
        format = "([$all_status$ahead_behind]($style) )";
        conflicted = "🏳 ";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        up_to_date = "✓";
        untracked = "?\${count}";
        stashed = "$\${count}";
        modified = "!\${count}";
        staged = "+\${count}";
        renamed = "»\${count}";
        deleted = "✘\${count}";
      };
      
      # Git commit
      git_commit = {
        commit_hash_length = 7;
        tag_symbol = "🏷 ";
        style = "bold green";
        format = "[($hash$tag)]($style) ";
        disabled = false;
      };
      
      # Komut süresi
      cmd_duration = {
        min_time = 1000;
        format = "[ $duration](bold yellow)";
        show_milliseconds = false;
      };
      
      # Nix shell
      nix_shell = {
        symbol = " ";
        format = "[$symbol$state( \\($name\\))]($style) ";
        style = "bold blue";
        impure_msg = "[impure](bold red)";
        pure_msg = "[pure](bold green)";
      };
      
      # Rust
      rust = {
        symbol = " ";
        style = "bold red";
        format = "[$symbol($version )]($style)";
      };
      
      # Python
      python = {
        symbol = " ";
        style = "bold yellow";
        format = "[($symbol$version )($virtualenv )]($style)";
        pyenv_version_name = true;
      };
      
      # Node.js
      nodejs = {
        symbol = " ";
        style = "bold green";
        format = "[$symbol($version )]($style)";
      };
      
      # Package
      package = {
        symbol = "📦 ";
        style = "bold cyan";
        format = "[$symbol$version]($style) ";
        display_private = false;
      };
      
      # Docker context
      docker_context = {
        symbol = " ";
        style = "bold blue";
        format = "[$symbol$context]($style) ";
        only_with_files = true;
      };
      
      # Golang
      golang = {
        symbol = " ";
        style = "bold cyan";
        format = "[$symbol($version )]($style)";
      };
      
      # Java
      java = {
        symbol = " ";
        style = "bold red";
        format = "[$symbol($version )]($style)";
      };
      
      # Memory usage
      memory_usage = {
        disabled = true;
        threshold = 75;
        symbol = " ";
        style = "bold dimmed white";
        format = "$symbol[$ram( | $swap)]($style) ";
      };
      
      # Time
      time = {
        disabled = false;
        time_format = "%T";
        style = "bold white";
        format = "🕙 [$time]($style) ";
      };
      
      # Battery
      battery = {
        full_symbol = "🔋";
        charging_symbol = "⚡️";
        discharging_symbol = "💀";
        display = [
          {
            threshold = 10;
            style = "bold red";
          }
          {
            threshold = 30;
            style = "bold yellow";
          }
        ];
      };
      
      # Status
      status = {
        style = "bold red";
        symbol = "✖";
        format = "[$symbol $status]($style) ";
        disabled = false;
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      share = true;
    };
    
    shellAliases = {
      # Genel kısayollar
      ll = "ls -l";
      la = "ls -la";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      
      # Git kısayolları
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit";
      gcm = "git commit -m";
      gp = "git push";
      gl = "git pull";
      gs = "git status";
      gd = "git diff";
      gb = "git branch";
      gco = "git checkout";
      gcb = "git checkout -b";
      glog = "git log --oneline --graph --decorate";
      
      # NixOS kısayolları
      rebuild = "sudo nixos-rebuild switch --flake .";
      rebuild-test = "sudo nixos-rebuild test --flake .";
      hm-switch = "home-manager switch --flake .";
      hm-build = "home-manager build --flake .";
      update = "nix flake update";
      
      # Sistem kısayolları
      grep = "grep --color=auto";
      cat = "bat";
      ls = "exa --icons";
      tree = "exa --tree";
      
      # Sistem bilgileri
      ports = "ss -tulanp";
      meminfo = "free -m -l -t";
      psmem = "ps auxf | sort -nr -k 4 | head -20";
      pscpu = "ps auxf | sort -nr -k 3 | head -20";
      
      # Paket yönetimi
      search = "nix search nixpkgs";
      shell = "nix-shell -p";
    };
    
    initExtra = ''
      # Zsh completion system
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' completer _expand _complete _ignored _approximate
      zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
      
      # Case insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      
      # Partial completion
      zstyle ':completion:*' list-suffixes
      zstyle ':completion:*' expand prefix suffix
      
      # Key bindings
      bindkey "^[[A" history-search-backward
      bindkey "^[[B" history-search-forward
      bindkey "^[[3~" delete-char
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line
      
      # Custom functions
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }
      
      extract() {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }
      
      # Hızlı dizin geçişi
      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_SILENT
      
      # Environment variables
      export EDITOR="nvim"
      export VISUAL="nvim"
      export BROWSER="firefox"
      export TERMINAL="kitty"
      
      # Wayland/Niri specific
      if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        export MOZ_ENABLE_WAYLAND=1
        export QT_QPA_PLATFORM=wayland
        export SDL_VIDEODRIVER=wayland
        export _JAVA_AWT_WM_NONREPARENTING=1
        export NIXOS_OZONE_WL=1
      fi
      
      # Color support for less
      export LESS_TERMCAP_mb=$'\e[1;32m'
      export LESS_TERMCAP_md=$'\e[1;32m'
      export LESS_TERMCAP_me=$'\e[0m'
      export LESS_TERMCAP_se=$'\e[0m'
      export LESS_TERMCAP_so=$'\e[01;33m'
      export LESS_TERMCAP_ue=$'\e[0m'
      export LESS_TERMCAP_us=$'\e[1;4;31m'
      
      # Load plugins
      eval "$(direnv hook zsh)"
    '';
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      rebuild = "sudo nixos-rebuild switch --flake /home/asus/manix/#asus";
      hm-switch = "home-manager switch --flake .";
    };
  };
}
