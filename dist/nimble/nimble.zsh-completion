#compdef nimble

_nimble() {
  local line

  _arguments -C \
    '1: :(install init publish uninstall build c cc js doc doc2 refresh search list tasks path dump develop)' \
    '*::options:->options' \
    '(--version)--version[show version]' \
    '(--help)--help[show help]' \
    '(-)--help[display help information]' \
    '(-)--version[display version information]' \
    '(-y --accept)'{-y,--accept}'[accept all interactive prompts]' \
                    {-n,--reject}'[reject all interactive prompts]' \
    '--ver[Query remote server for package version information when searching or listing packages]' \
    '--nimbleDir dirname[Set the Nimble directory]' \
    '(-d --depsOnly)'{-d,--depsOnly}'[Install only dependencies]'

  if [ $#line -eq 0 ]; then
    # if the command line is empty and "nimble tasks" is successfull, add custom tasks
    tasks=$(nimble tasks)
    if [ $? -eq 0 ]; then
      compadd - $(echo $tasks | cut -f1 -d" " | tr '\n' ' ')
    fi
  fi

  case $line[1] in
    install)
      _nimble_installable_packages
    ;;
    uninstall|path|dump)
      _nimble_installed_packages
    ;;
    init|publish|build|refresh|search|tasks)
      (( ret )) && _message 'no more arguments'
    ;;
    *)
      (( ret )) && _message 'no more arguments'
    ;;
  esac
}

function _nimble_installable_packages {
  compadd - $(nimble list 2> /dev/null | grep -v '^ ' | tr -d ':')
}

function _nimble_installed_packages {
  compadd - $(nimble list -i 2> /dev/null | grep ']$' | cut -d' ' -f1)
}

_nimble "$@"
