# This file must be used with "source k" or ". k" *from bash*
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
        unset KUBECONFIG
    fi

    unset KUBECONFIG
    
    if [ ! "$1" = "nondestructive" ] ; then
    # Self destruct!
        unset -f quit
        unset -f render_options
        unset -f main
    fi
}

# 使用函数+local可减少变量作用到整个shell
main () {
    # str -> array  see: https://www.shellcheck.net/wiki/SC2207
    # 经测试 以下用发在GNU bash, version 3.00.15(1)-release (x86_64-redhat-linux-gnu)可正常使用
    local options=( $(find "${KUBECONFIGPATH}" -maxdepth 1  -regex '.*\.ya*ml' | sort ) )
    # or
    # options=()
    # while IFS='' read -r line; do options+=("$line"); done < <(find "${CONFIGPATH}" -maxdepth 1  -regex '.*\.ya*ml' | sort )

    # for i in $(find "${CONFIGPATH}" -maxdepth 1  -regex '.*\.ya*ml' | sort )
    # files=$(find "${CONFIGPATH}" -maxdepth 1  -regex '.*\.ya*ml' )
    # declare -a options=( "$files" )

    local options_index=0  # default index
    local options_len=${#options[@]}

    quit nondestructive

    # # 初始渲染
    render_options

    while true; do
        read -r -s -n 1 key  # 读取单个按键输入，不显示在终端上

        case $key in
            "A")  # 上箭头键
                if [ $options_index -gt 0 ]; then
                    options_index=$((options_index - 1))
                # 在第一行按上键，到最后一行
                elif [ $options_index -eq 0 ]; then
                    options_index=$((options_len - 1))
                fi
                ;;
            "B")  # 下箭头键
                # if [ $options_index -lt $(( "${options_len}" - 1 )) ]; then
                if [ $options_index -lt $(( options_len - 1 )) ]; then
                    options_index=$((options_index + 1))
                # 在最后一行按下键，到第一行
                elif [ $options_index -eq $(( options_len - 1 )) ]; then
                    options_index=0
                fi
                ;;
            "")  # 回车键
                break
                ;;
        esac

        tput cuu "${options_len}"  # 光标移动回到选项列表的开头
        tput ed  # 清除当前行
        render_options  # 重新渲染选项列表
    done

    export KUBECONFIG="${options[$options_index]}"

    _OLD_VIRTUAL_PS1="${PS1:-}"

    # local tag
    # tag=$(basename "$(basename "${KUBECONFIG}" .yml)" .yaml)

    # 添加颜色会产生字符位移
    # if [[ $tag =~ 'prod' ]]; then 
    #     PS1="(\[\e[1;35m${tag}\e[m\]) ${PS1:-}"
    # else
    #     PS1="(\[\e[1;32m${tag}\e[m\]) ${PS1:-}"
    # fi
    PS1="($(basename "$(basename "${KUBECONFIG}" .yml)" .yaml))$PS1"
    export PS1
}

main "$@"
