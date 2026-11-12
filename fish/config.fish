if status is-interactive
    set -g fish_greeting ""

    # Synchronized Cyberpunk Fish Colors
    set -g fish_color_command 00f0ff --bold
    set -g fish_color_param e0e6ed
    set -g fish_color_keyword ff0055
    set -g fish_color_quote ffe600
    set -g fish_color_error ff0055 --bold

    set -g fish_color_user 00f0ff
    set -g fish_color_at ff0055
    set -g fish_color_host ffe600

    alias ls='ls --color=auto'
    alias lsa='ls -a --color=auto'
    alias grep='grep --color=auto'
    alias pacman='sudo pacman'
    alias dotnetnewconsole='dotnet new console --use-program-main'
    alias ..='cd ..'
    alias sudo='sudo -E'
    alias server='ssh zaln@techtrove.cc -p 22000'
    alias szamrend='ssh s1uiuj@szamrend.inf.elte.hu'
    alias fetch="fastfetch"
    alias top="btop"

end
