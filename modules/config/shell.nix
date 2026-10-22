{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      format = ''
        [╭─](bold cyan)$username$hostname$directory$git_branch$git_status$git_commit
        [╰─](bold cyan)$character
      '';
      
      username = {
        style_user = "bold blue";
        format = "[$user]($style) ";
        disabled = false;
        show_always = true;
      };
      
      hostname = {
        ssh_only = false;
        format = "[@$hostname](bold green) ";
        disabled = false;
      };
      
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
        format = "[ $path]($style)[$read_only]($read_only_style) ";
        read_only = " 🔒";
        home_symbol = "~";
        truncation_symbol = "…/";
      };
      
      git_branch = {
        symbol = " ";
        style = "bold purple";
        format = "[$symbol$branch]($style) ";
      };
      
      git_status = {
        style = "bold yellow";
        format = "([$all_status$ahead_behind]($style) )";
        ahead = "⇡$count";
        behind = "⇣$count";
        untracked = "?$count";
        stashed = "\$$count";
        modified = "!$count";
        staged = "+$count";
        deleted = "✘$count";
      };
      
      git_commit = {
        commit_hash_length = 8;
        style = "bold green";
        format = "[$hash]($style) ";
        disabled = false;
      };
      
      character = {
        success_symbol = "[❯](bold green)[❯](green)[❯](bright-black)";
        error_symbol = "[❯](bold red)[❯](red)[❯](bright-black)";
      };
      
      cmd_duration = {
        min_time = 1000;
        format = "[⏱ $duration](bold yellow) ";
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
      share = true;
    };
    
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      rebuild = "cd /home/asus/manix && git add -A && git commit -m 'update' && sudo nixos-rebuild switch --flake '.#asus'";
    };
    
    initContent = ''
      # Completion
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      
      # Key bindings
      bindkey "^[[A" history-search-backward
      bindkey "^[[B" history-search-forward
      
      # Environment
      export EDITOR="nvim"
      export TERMINAL="kitty"
      
      # Wayland
      if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        export MOZ_ENABLE_WAYLAND=1
        export NIXOS_OZONE_WL=1
      fi
    '';
  };

  programs.bash.enable = true;
}
