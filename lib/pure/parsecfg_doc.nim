## The ``parsecfg`` module implements a high performance configuration file
## parser. The configuration file's syntax is similar to the Windows ``.ini``
## format, but much more powerful, as it is not a line based parser. String
## literals, raw string literals and triple quoted string literals are supported
## as in the Nim programming language.

## This is an example of how a configuration file may look like:
##
## .. include:: ../../doc/mytest.cfg
##     :literal:
##

##[ Here is an example of how to use the configuration file parser:

.. code-block:: nim

    import
      os, parsecfg, strutils, streams

    var f = newFileStream(paramStr(1), fmRead)
    if f != nil:
      var p: CfgParser
      open(p, f, paramStr(1))
      while true:
        var e = next(p)
        case e.kind
        of cfgEof: break
        of cfgSectionStart:   ## a ``[section]`` has been parsed
          echo("new section: " & e.section)
        of cfgKeyValuePair:
          echo("key-value-pair: " & e.key & ": " & e.value)
        of cfgOption:
          echo("command: " & e.key & ": " & e.value)
        of cfgError:
          echo(e.msg)
      close(p)
    else:
      echo("cannot open: " & paramStr(1))

]##

## Basic usage
## -----------
##
## This is an example of a configuration file.
##
## ::
##
##     charset = "utf-8"
##     [Package]
##     name = "hello"
##     --threads:on
##     [Author]
##     name = "lihf8515"
##     qq = "10214028"
##     email = "lihaifeng@wxm.com"
##
## Creating a configuration file
## =============================
## .. code-block:: nim
##
##     import parsecfg
##     var dict=newConfig()
##     dict.setSectionKey("","charset","utf-8")
##     dict.setSectionKey("Package","name","hello")
##     dict.setSectionKey("Package","--threads","on")
##     dict.setSectionKey("Author","name","lihf8515")
##     dict.setSectionKey("Author","qq","10214028")
##     dict.setSectionKey("Author","email","lihaifeng@wxm.com")
##     dict.writeConfig("config.ini")
##
## Reading a configuration file
## ============================
## .. code-block:: nim
##
##     import parsecfg
##     var dict = loadConfig("config.ini")
##     var charset = dict.getSectionValue("","charset")
##     var threads = dict.getSectionValue("Package","--threads")
##     var pname = dict.getSectionValue("Package","name")
##     var name = dict.getSectionValue("Author","name")
##     var qq = dict.getSectionValue("Author","qq")
##     var email = dict.getSectionValue("Author","email")
##     echo pname & "\n" & name & "\n" & qq & "\n" & email
##
## Modifying a configuration file
## ==============================
## .. code-block:: nim
##
##     import parsecfg
##     var dict = loadConfig("config.ini")
##     dict.setSectionKey("Author","name","lhf")
##     dict.writeConfig("config.ini")
##
## Deleting a section key in a configuration file
## ==============================================
## .. code-block:: nim
##
##     import parsecfg
##     var dict = loadConfig("config.ini")
##     dict.delSectionKey("Author","email")
##     dict.writeConfig("config.ini")
