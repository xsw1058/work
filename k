# follow python venv activate file
# you can move this file to '/usr/local/bin/', then use "source k" or ". k"
# you cannot run it directly
KUBECONFIGPATH=${KUBECONFIGPATH:-"$HOME/.kube/"}

render_options() {
    for i in "${!options[@]}"; do
        if [ $i -eq $options_index ]; then
            echo -e "\033[47;30m${i} ${options[$i]}    \033[0m"
        else
            echo "${i} ${options[$i]}"
        fi
    done
}

quit () {
    if [ -n "${_OLD_VIRTUAL_PS1:-}" ] ; then
        PS1="${_OLD_VIRTUAL_PS1:-}"
        export PS1
        unset _OLD_VIRTUAL_PS1
    fi

    if [ -n "${KUBECONFIG:-}" ] ; then
        _OLD_VIRTUAL_KUBECONFIG="${KUBECONFIG:-}"
    fi

    unset KUBECONFIG
    
    if [ ! "$1" = "nondestructive" ] ; then
    # Self destruct!
        unset -f quit
        unset -f render_options
        unset -f main
    fi
}

main () {
    local options=()
    # string -> array  see: https://www.shellcheck.net/wiki/SC2207
    # bash3 & bash4 test ok
    IFS=" " read -r -a options <<< "$(find "${KUBECONFIGPATH}" -maxdepth 1  -regex '.*\.ya*ml' | sort | tr "\n" " ")"

    local options_index=0 
    local options_len=${#options[@]}
    if [ "${options_len}" = 0 ]; then
        echo "not found yml|yaml in ($KUBECONFIGPATH)"
    else
        quit nondestructive

        # frist render
        render_options

        while true; do
            read -r -s -n 1 key  

            case $key in
                "A")  # up
                    if [ $options_index -gt 0 ]; then
                        options_index=$((options_index - 1))
                    elif [ $options_index -eq 0 ]; then
                        options_index=$((options_len - 1))
                    fi
                    ;;
                "B")  # down
                    if [ $options_index -lt $(( options_len - 1 )) ]; then
                        options_index=$((options_index + 1))
                    elif [ $options_index -eq $(( options_len - 1 )) ]; then
                        options_index=0
                    fi
                    ;;
                "")  # enter
                    break
                    ;;
            esac
            tput cuu "${options_len}"
            tput ed 
            render_options

        done

        export KUBECONFIG="${options[$options_index]}"

        _OLD_VIRTUAL_PS1="${PS1:-}"
        # DO NOT USE COLOR!
        PS1="($(basename "$(basename "${KUBECONFIG}" .yml)" .yaml))$PS1"
        export PS1
    fi
}

main "$@"
