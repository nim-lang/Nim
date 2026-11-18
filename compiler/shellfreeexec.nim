## Running the external commands the compiler builds without a shell.
##
## The compiler builds every C compiler, assembler, linker and `--run`
## command as ONE string, each argument quoted with `quoteShell`, and on
## POSIX it ran that string through the system shell: `osproc.execCmd` is
## libc's `system`, and `osproc.execProcesses` and `execCmdEx` add
## `poEvalCommand`, so both start `/bin/sh -c <command>`.
##
## A command made only of plain and quoted words means the same thing to
## the shell as the argv those words spell, so for such a command the shell
## adds nothing but one more program on the path of every compile: the
## machine's `/bin/sh`, its C library and whatever libraries it links. A
## build tool that records what a compile reads (a sandbox, a filesystem
## monitor, a hermetic build system) then records the host's shell as an
## input of every compile, and a compile recorded on one machine is not
## the same compile on a machine whose `/bin/sh` is another program (a
## NixOS `/bin/sh` is an interactive bash with readline; a Debian one is
## dash).
##
## `plainCommandArgv` splits a command into the argv the shell would have
## executed when, and only when, the command uses nothing the shell would
## interpret: no parameter or command substitution, no redirection, pipe,
## list, glob, tilde, comment, assignment prefix, reserved word, builtin or
## job specification.
## Any such command keeps going to the shell (`commandArgv` returns
## `@["/bin/sh", "-c", cmd]`, exactly what `poEvalCommand` starts), so no
## command changes meaning. The rules are those of the POSIX Shell Command
## Language, "Token Recognition" and "Quote Removal":
## https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html
##
## `staticExec` and `gorgeEx` (`gorgeimpl`) run user commands at compile
## time, in the directory of the module that calls them, so a command that
## needs another working directory is spelled `cd DIR && COMMAND`.
## `directCommand` also takes that one form, for an absolute `DIR` and a
## plain `COMMAND`, and runs `COMMAND` in `DIR` (`cd` "Description",
## "Operands": https://pubs.opengroup.org/onlinepubs/9799919799/utilities/cd.html).
##
## Windows is unchanged: there `execCmd` and `poEvalCommand` start the
## command line with `CreateProcess`, with no shell in between.

import std/[os, osproc, streams, strutils]

when defined(posix):
  from std/posix import ENOENT, ENOTDIR

when defined(nimPreviewSlimSystem):
  import std/syncio

const
  PlainWordChars = {'a'..'z', 'A'..'Z', '0'..'9', '-', '_', '.', '/', ':',
                    ',', '+', '%', '@', '=', '^'}
    ## Characters that stand for themselves, unquoted, in every POSIX shell
    ## (bash included: no brace, tilde or history expansion starts with
    ## one). `=` is plain in an argument; in the first word it would make an
    ## assignment, which `plainCommandArgv` refuses separately.
  ShellOnlyNames = ["!", "{", "}", "[[", "]]", "case", "do", "done", "elif",
    "else", "esac", "fi", "for", "function", "if", "in", "select", "then",
    "time", "until", "while",
    # Special and regular built-ins: a shell runs these itself, and some
    # have no program of that name at all.
    ".", ":", "[", "alias", "bg", "bind", "break", "builtin", "caller", "cd",
    "command", "compgen", "complete", "compopt", "continue", "coproc",
    "declare", "dirs", "disown", "echo", "enable", "eval", "exec", "exit",
    "export", "false", "fc", "fg", "getopts", "hash", "help", "history",
    "jobs", "kill", "let", "local", "logout", "mapfile", "newgrp", "popd",
    "printf", "pushd", "pwd", "read", "readarray", "readonly", "return",
    "set", "shift", "shopt", "source", "suspend", "test", "times", "trap",
    "true", "type", "typeset", "ulimit", "umask", "unalias", "unset", "wait",
    # Built-ins of other shells a system may install as `/bin/sh`: dash and
    # BusyBox ash (`chdir`), and ksh and zsh in sh emulation.
    "autoload", "bye", "chdir", "disable", "emulate", "end", "float",
    "foreach", "functions", "integer", "limit", "nameref", "nocorrect",
    "noglob", "print", "r", "rehash", "repeat", "sched", "setopt",
    "unfunction", "unhash", "unlimit", "unsetopt", "vared", "whence", "where",
    "which", "zmodload"]
  useShPath {.strdefine.} =
    when defined(android): "/system/bin/sh" else: "/bin/sh"
    ## What `poEvalCommand` starts: the same define, and the same default,
    ## as osproc's, so a compiler built with `-d:useShPath=...` hands a
    ## refused command to the shell it names.
  ShellPath = useShPath

proc splitPlainWords(cmd: string; words: var seq[string]): bool =
  ## Split `cmd` into the words the shell would make of it, after quote
  ## removal, when it is made only of plain and quoted words (it may hold
  ## none); `false` when it uses anything else the shell interprets.
  ##
  ## Words are separated by spaces and tabs (a newline separates commands,
  ## so it needs the shell). A single-quoted string is literal; a
  ## double-quoted one is literal when it holds no `$`, backquote or
  ## backslash; a backslash outside quotes makes the next character literal.
  ## Adjacent unquoted and quoted parts make one word, and `''` is an empty
  ## word, as in the shell. An unquoted `=` in the first word would make it
  ## an assignment, so it is refused here.
  words.setLen 0
  var word = ""
  var inWord = false
  var i = 0
  while i < cmd.len:
    let c = cmd[i]
    case c
    of ' ', '\t':
      if inWord:
        words.add word
        word = ""
        inWord = false
      inc i
    of '\'':
      let close = cmd.find('\'', i + 1)
      if close < 0: return false
      word.add cmd.substr(i + 1, close - 1)
      inWord = true
      i = close + 1
    of '"':
      var j = i + 1
      while j < cmd.len and cmd[j] != '"':
        if cmd[j] in {'$', '`', '\\'}: return false
        word.add cmd[j]
        inc j
      if j >= cmd.len: return false
      inWord = true
      i = j + 1
    of '\\':
      if i + 1 >= cmd.len or cmd[i + 1] == '\n': return false
      word.add cmd[i + 1]
      inWord = true
      i += 2
    else:
      if c notin PlainWordChars: return false
      # An unquoted `=` in the first word makes it an assignment.
      if c == '=' and words.len == 0: return false
      word.add c
      inWord = true
      inc i
  if inWord:
    words.add word
  true

proc plainArgv(words: seq[string]): seq[string] =
  ## `words` when the shell would execute them as a program and its
  ## arguments, otherwise `@[]`: the first word must not be empty, a
  ## reserved word, a builtin, or a bash job specification (`%1`).
  if words.len == 0 or words[0].len == 0 or words[0] in ShellOnlyNames:
    return @[]
  # bash runs a first word starting with `%` as a job specification (`fg`).
  if words[0][0] == '%':
    return @[]
  words

proc plainCommandArgv*(cmd: string): seq[string] =
  ## The argv the shell would execute for `cmd`, or `@[]` when `cmd` needs
  ## the shell: it uses a character, quoting form or word the shell would
  ## interpret (see the module documentation), or it is empty.
  var words: seq[string] = @[]
  if not splitPlainWords(cmd, words):
    return @[]
  plainArgv(words)

type
  DirectCommand* = object
    ## A command line the shell would run as one program, without the shell.
    dir*: string
      ## The directory the program starts in, when the command changes to
      ## one first (`cd DIR && ...`); "" when it does not.
    argv*: seq[string]
      ## The program and its arguments; `@[]` when the command needs the
      ## shell.

proc directCommand*(cmd: string): DirectCommand =
  ## What `cmd` runs, when it can run without the shell: a plain command
  ## (`plainCommandArgv`), or one prefixed by a change of directory,
  ## `cd DIR && COMMAND` or `cd DIR && exec COMMAND`, where `DIR` is one
  ## absolute word and `COMMAND` a plain command. A program that wants a
  ## working directory of its own at compile time has no other way to ask
  ## for one (`staticExec` runs every command in the directory of the module
  ## that calls it), and this is how such commands are spelled.
  ##
  ## For that prefix the shell changes to `DIR` and then runs `COMMAND`
  ## (`exec` only saves the shell's own process), so the program runs with
  ## `DIR` as its working directory: the same as starting it there. `DIR`
  ## must be absolute because `cd` looks a relative one up in `CDPATH`. A
  ## `cd` with an option, an `exec` with one (`exec -a`), anything else
  ## before or after the `&&`, or more than one `&&` keeps the command on
  ## the shell (`argv` is `@[]`).
  result = DirectCommand(dir: "", argv: plainCommandArgv(cmd))
  if result.argv.len > 0:
    return
  const sep = " && "
  var at = cmd.find(sep)
  while at >= 0:
    # The prefix must split into exactly `cd DIR`. A ` && ` inside quotes
    # leaves the prefix with an unterminated quote, which does not split,
    # so the first separator that splits is the one the shell sees.
    var prefix: seq[string] = @[]
    if splitPlainWords(cmd.substr(0, at - 1), prefix):
      if prefix.len == 2 and prefix[0] == "cd" and prefix[1].len > 0 and
          prefix[1][0] == '/':
        var rest: seq[string] = @[]
        if not splitPlainWords(cmd.substr(at + sep.len), rest):
          return
        if rest.len > 0 and rest[0] == "exec":
          rest.delete(0)
          # `exec -a NAME`, `exec -c`, `exec -l` (bash) change what runs.
          if rest.len > 0 and rest[0].len > 0 and rest[0][0] == '-':
            return
        let argv = plainArgv(rest)
        if argv.len > 0:
          result = DirectCommand(dir: prefix[1], argv: argv)
      return
    at = cmd.find(sep, at + 1)

proc notStartedExitCode*(err: int32): int =
  ## The exit code the shell reports for a program it could not start with
  ## `err`: 127 when there is no such program, 126 when there is one that
  ## cannot be executed (POSIX Shell Command Language, "Exit Status for
  ## Commands":
  ## https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html#tag_19_08_02).
  when defined(posix):
    if err == ENOENT or err == ENOTDIR: 127 else: 126
  else:
    127

proc shellStartPwd*(dir: string): string =
  ## The `PWD` a POSIX shell started in `dir` exports to the commands it
  ## runs: the inherited `PWD` when it is an absolute path to that same
  ## directory, otherwise the directory's physical path, as `getcwd` gives
  ## it (`sh` "Shell Variables", `PWD`:
  ## https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html#tag_19_05_03).
  ## bash and dash both initialise it so. An empty `dir` is the current
  ## directory.
  let target = if dir.len > 0: dir else: getCurrentDir()
  let inherited = getEnv("PWD")
  if inherited.len > 0 and inherited.isAbsolute:
    try:
      if sameFile(inherited, target):
        return inherited
    except OSError:
      discard
  try:
    result = expandFilename(target)
  except OSError:
    result = target

proc commandArgv*(cmd: string): seq[string] =
  ## What runs `cmd`: its own argv when it needs no shell, otherwise the
  ## shell with `cmd` as its script, as `poEvalCommand` would start it.
  result = plainCommandArgv(cmd)
  if result.len == 0:
    result = @[ShellPath, "-c", cmd]

proc execCommand*(cmd: string): int =
  ## `osproc.execCmd`, without the shell when `cmd` does not need one. The
  ## child inherits the standard streams; the result is its exit code, or
  ## 128 plus the signal that ended it, as the shell reports one. A program
  ## that cannot be started is reported on stderr with the exit code the
  ## shell would give (`notStartedExitCode`).
  when defined(windows):
    result = execCmd(cmd)
  else:
    let argv = plainCommandArgv(cmd)
    if argv.len == 0:
      return execCmd(cmd)
    var p: Process = nil
    try:
      p = startProcess(argv[0], args = argv.toOpenArray(1, argv.high),
        options = {poUsePath, poParentStreams})
    except OSError as e:
      stderr.writeLine(argv[0] & ": " & e.msg)
      return notStartedExitCode(e.errorCode)
    try:
      result = waitForExit(p)
    finally:
      close(p)

proc execCommandEx*(cmd: string): tuple[output: string, exitCode: int] =
  ## `osproc.execCmdEx` with its default options (stderr merged into the
  ## captured output, the program searched for on `PATH`), without the shell
  ## when `cmd` does not need one.
  when defined(windows):
    result = execCmdEx(cmd)
  else:
    result = ("", 0)
    let argv = commandArgv(cmd)
    let p = startProcess(argv[0], args = argv.toOpenArray(1, argv.high),
      options = {poStdErrToStdOut, poUsePath})
    try:
      p.inputStream.close()
      result.output = p.outputStream.readAll()
      result.exitCode = waitForExit(p)
    finally:
      close(p)

proc execCommandsInParallel*(cmds: openArray[string];
    options: set[ProcessOption]; n: int;
    beforeRunEvent: proc(idx: int) = nil;
    afterRunEvent: proc(idx: int, p: Process) = nil): int =
  ## `osproc.execProcesses`, with each command that does not need the shell
  ## started without one (`execArgvProcesses`).
  when defined(windows) or not declared(execArgvProcesses):
    # Also when the compiler is built against a standard library older than
    # `execArgvProcesses` (bootstrapping with an installed Nim): every
    # command then goes to the shell, as before.
    result = execProcesses(cmds, options, n, beforeRunEvent, afterRunEvent)
  else:
    var argvs = newSeq[seq[string]](cmds.len)
    for i, cmd in cmds:
      argvs[i] = commandArgv(cmd)
    result = execArgvProcesses(argvs, options, n, beforeRunEvent,
      afterRunEvent)
