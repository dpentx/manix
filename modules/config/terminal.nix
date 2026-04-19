{ config, pkgs, ... }:

{
  # Kitty terminal yapılandırması
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      # Pencere ayarları
      background_opacity = "0.85";
      window_padding_width = 12;
      scrollback_lines = 10000;
      enable_audio_bell = false;
      confirm_os_window_close = 0;
      
      # Cursor ayarları
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = 0;
      
      # Modern Catppuccin Mocha teması
      foreground = "#CDD6F4";
      background = "#1E1E2E";
      selection_foreground = "#1E1E2E";
      selection_background = "#F5E0DC";
      
      cursor = "#F5E0DC";
      cursor_text_color = "#1E1E2E";
      
      url_color = "#89B4FA";
      url_style = "curly";
      
      # Border renkleri
      active_border_color = "#B4BEFE";
      inactive_border_color = "#6C7086";
      bell_border_color = "#F9E2AF";
      
      # Tab bar
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      active_tab_foreground = "#11111B";
      active_tab_background = "#CBA6F7";
      inactive_tab_foreground = "#CDD6F4";
      inactive_tab_background = "#181825";
      tab_bar_background = "#11111B";
      tab_bar_margin_color = "#11111B";
      
      # Black
      color0 = "#45475A";
      color8 = "#585B70";
      
      # Red
      color1 = "#F38BA8";
      color9 = "#F38BA8";
      
      # Green
      color2 = "#A6E3A1";
      color10 = "#A6E3A1";
      
      # Yellow
      color3 = "#F9E2AF";
      color11 = "#F9E2AF";
      
      # Blue
      color4 = "#89B4FA";
      color12 = "#89B4FA";
      
      # Magenta
      color5 = "#F5C2E7";
      color13 = "#F5C2E7";
      
      # Cyan
      color6 = "#94E2D5";
      color14 = "#94E2D5";
      
      # White
      color7 = "#BAC2DE";
      color15 = "#A6ADC8";
    };
    
    keybindings = {
      # Clipboard
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      
      # Pencere yönetimi
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";
      "ctrl+shift+w" = "close_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";
      
      # Tab yönetimi
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+q" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+shift+," = "move_tab_backward";
      
      # Font boyutu
      "ctrl+shift+equal" = "change_font_size all +2.0";
      "ctrl+shift+minus" = "change_font_size all -2.0";
      "ctrl+shift+backspace" = "change_font_size all 0";
      
      # Layout
      "ctrl+shift+l" = "next_layout";
      
      # Scroll
      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
    };
    
    extraConfig = ''
      # Performance optimizations
      repaint_delay 10
      input_delay 3
      sync_to_monitor yes
      
      # Mouse
      mouse_hide_wait 3.0
      
      # Shell integration
      shell_integration enabled
      
      # Clipboard
      strip_trailing_spaces smart
      
      # Advanced
      allow_remote_control yes
      listen_on unix:@mykitty
      update_check_interval 0
    '';
  };
}
