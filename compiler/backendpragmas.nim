import pragmas, options, ast, trees

proc pushBackendOption(optionsStack: var seq[TOptions], options: var TOptions) =
  optionsStack.add options

proc popBackendOption(optionsStack: var seq[TOptions], options: var TOptions) =
  options = optionsStack[^1]
  optionsStack.setLen(optionsStack.len-1)

proc processPushBackendOption*(optionsStack: var seq[TOptions], options: var TOptions,
                           n: PNode, start: int) =
  pushBackendOption(optionsStack, options)
  for i in start..<n.len:
    let it = n[i]
    if it.kind in nkPragmaCallKinds and it.len == 2 and it[1].kind == nkIntLit:
      let sw = whichPragma(it[0])
      let opts = pragmaToOptions(sw)
      if opts != {}:
        if it[1].intVal != 0:
          options.incl opts
        else:
          options.excl opts

template processPopBackendOption*(optionsStack: var seq[TOptions], options: var TOptions) =
  popBackendOption(optionsStack, options)
