## This module provides the standard Nim command line parser.
## It supports one convenience iterator over all command line options and some
## lower-level features.
##
##
##
## # Supported Syntax
##
## The following syntax is supported when arguments for the ``shortNoVal`` and
## ``longNoVal`` parameters, which are
## `described later<#shortnoval-and-longnoval>`_, are not provided:
##
## 1. Short options: ``-abcd``, ``-e:5``, ``-e=5``
## 2. Long options: ``--foo:bar``, ``--foo=bar``, ``--foo``
## 3. Arguments: everything that does not start with a ``-``
##
## These three kinds of tokens are enumerated in the
## `CmdLineKind enum<#CmdLineKind>`_.
##
## When option values begin with ':' or '=', they need to be doubled up (as in
## ``--delim::``) or alternated (as in ``--delim=:``).
##
## The ``--`` option, commonly used to denote that every token that follows is
## an argument, is interpreted as a long option, and its name is the empty
## string.
##
##
## # Basic usage
##
## ## Parsing
##
## Use an `OptParser<#OptParser>`_ to parse command line options. It can be
## created with `initOptParser<#initOptParser,string,set[char],seq[string]>`_,
## and `next<#next,OptParser>`_ advances the parser by one token.
##
## For each token, the parser's ``kind``, ``key``, and ``val`` fields give
## information about that token. If the token is a long or short option, ``key``
## is the option's name, and  ``val`` is either the option's value, if provided,
## or the empty string. For arguments, the ``key`` field contains the argument
## itself, and ``val`` is unused. To check if the end of the command line has
## been reached, check if ``kind`` is equal to ``cmdEnd``.
##
## Here is an example:
##
## .. code-block::
##   import parseopt
##
##   var p = initOptParser("-ab -e:5 --foo --bar=20 file.txt")
##   while true:
##     p.next()
##     case p.kind
##     of cmdEnd: break
##     of cmdShortOption, cmdLongOption:
##       if p.val == "":
##         echo "Option: ", p.key
##       else:
##         echo "Option and value: ", p.key, ", ", p.val
##     of cmdArgument:
##       echo "Argument: ", p.key
##
##   # Output:
##   # Option: a
##   # Option: b
##   # Option and value: e, 5
##   # Option: foo
##   # Option and value: bar, 20
##   # Argument: file.txt
##
## The `getopt iterator<#getopt.i,OptParser>`_, which is provided for
## convenience, can be used to iterate through all command line options as well.
##
##
##
## ## ``shortNoVal`` and ``longNoVal``
##
## The optional ``shortNoVal`` and ``longNoVal`` parameters present in
## `initOptParser<#initOptParser,string,set[char],seq[string]>`_ are for
## specifying which short and long options do not accept values.
##
## When ``shortNoVal`` is non-empty, users are not required to separate short
## options and their values with a ':' or '=' since the parser knows which
## options accept values and which ones do not. This behavior also applies for
## long options if ``longNoVal`` is non-empty. For short options, ``-j4``
## becomes supported syntax, and for long options, ``--foo bar`` becomes
## supported. This is in addition to the `previously mentioned
## syntax<#supported-syntax>`_. Users can still separate options and their
## values with ':' or '=', but that becomes optional.
##
## As more options which do not accept values are added to your program,
## remember to amend ``shortNoVal`` and ``longNoVal`` accordingly.
##
## The following example illustrates the difference between having an empty
## ``shortNoVal`` and ``longNoVal``, which is the default, and providing
## arguments for those two parameters:
##
## .. code-block::
##   import parseopt
##
##   proc printToken(kind: CmdLineKind, key: string, val: string) =
##     case kind
##     of cmdEnd: doAssert(false)  # Doesn't happen with getopt()
##     of cmdShortOption, cmdLongOption:
##       if val == "":
##         echo "Option: ", key
##       else:
##         echo "Option and value: ", key, ", ", val
##     of cmdArgument:
##       echo "Argument: ", key
##
##   let cmdLine = "-j4 --first bar"
##
##   var emptyNoVal = initOptParser(cmdLine)
##   for kind, key, val in emptyNoVal.getopt():
##     printToken(kind, key, val)
##
##   # Output:
##   # Option: j
##   # Option: 4
##   # Option: first
##   # Argument: bar
##
##   var withNoVal = initOptParser(cmdLine, shortNoVal = {'c'},
##                                 longNoVal = @["second"])
##   for kind, key, val in withNoVal.getopt():
##     printToken(kind, key, val)
##
##   # Output:
##   # Option and value: j, 4
##   # Option and value: first, bar
##
##
##
## # See also
##
## * `os module<os.html>`_ for lower-level command line parsing procs
## * `parseutils module<parseutils.html>`_ for helpers that parse tokens,
##   numbers, identifiers, etc.
## * `strutils module<strutils.html>`_ for common string handling operations
## * `json module<json.html>`_ for a JSON parser
## * `parsecfg module<parsecfg.html>`_ for a configuration file parser
## * `parsecsv module<parsecsv.html>`_ for a simple CSV (comma separated value)
##   parser
## * `parsexml module<parsexml.html>`_ for a XML / HTML parser
## * `other parsers<lib.html#pure-libraries-parsers>`_ for more parsers
