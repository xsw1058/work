# follow python venv activate file
# you can move this file to '/usr/local/bin/', then use "source k" or ". k"
# you cannot run it directly
KUBECONFIGPATH=${KUBECONFIGPATH:-"$HOME/.kube"}

render_options() {
    for i in "${!options[@]}"; do
        # if [ $i -eq $options_index ] && [[ "${options[$i]}" =~ "prod" ]]; then
        #     echo -e "\e[31m> ${options[$i]}    \e[0m"
        # el
        if [ $i -eq $options_index ]; then
            echo -e "\e[32m> ${options[$i]}\e[0m"
        else
            echo "  ${options[$i]}"
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
    # IFS=" " read -r -a options <<< "$(find "${KUBECONFIGPATH}" -maxdepth 1  -regex '.*\.ya*ml' | sort | tr "\n" " ")"
    IFS=" " read -r -a options <<< "$(find "${KUBECONFIGPATH}" -maxdepth 1  -regex '.*\.ya*ml' -exec basename {} \; | sort | tr "\n" " ")"

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

            # echo "$key"
            
            case $key in
                "A")  # up
                    if [ $options_index -gt 0 ]; then
                        options_index=$((options_index - 1))
                    elif [ $options_index -eq 0 ]; then
                        options_index=$((options_len - 1))
                    fi
                    ;;
                "k")  # up
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
                "j")  # down
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

        export KUBECONFIG="${KUBECONFIGPATH}/${options[$options_index]}"

        _OLD_VIRTUAL_PS1="${PS1:-}"
        # Don't use color on a single line !
        if [[ "${KUBECONFIG}" =~ "prod" ]];then
            PS1="(\e[31m$(basename "$(basename "${KUBECONFIG}" .yml)" .yaml)\e[0m)$PS1\n>"
        else
            PS1="($(basename "$(basename "${KUBECONFIG}" .yml)" .yaml))$PS1"
        fi
        
        export PS1
    fi
}

main "$@"
