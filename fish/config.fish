if status is-interactive
    set -g fish_greeting ""

    # Synchronized Cyberpunk Fish Colors
    set -g fish_color_command 00f0ff --bold
    set -g fish_color_param e0e6ed
    set -g fish_color_keyword ff0055
    set -g fish_color_quote ffe600
    set -g fish_color_error ff0055 --bold

    alias fetch="fastfetch"
    alias top="btop"

end