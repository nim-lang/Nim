discard """
  joinable: false
"""

# The compiler runs the C compiler, linker and `--run` commands it builds
# without the system shell when a command needs none (`shellfreeexec`):
# the shell made the host's `/bin/sh`, its C library and its libraries part
# of every compile a build tool records.
#
# `plainCommandArgv` must split exactly the commands whose meaning to the
# shell is the argv their words spell, and refuse every other one, so that
# a refused command still reaches the shell unchanged (`commandArgv`). The
# runners must keep the shell's exit codes. No mocks: the runners start
# this test binary as a real child process.

import std/[os, osproc, strutils, streams]
import compiler/shellfreeexec

when defined(nimPreviewSlimSystem):
  import std/assertions
when defined(posix):
  import std/posix

proc child(args: varargs[string]): string =
  ## A command line that runs this binary in its child mode.
  result = quoteShell(getAppFilename())
  for a in args: result.add " " & quoteShell(a)

if paramCount() >= 1:
  # Child mode: `echo ARGS...` prints each argument on its own line
  # between markers; `exit N` exits with N; `kill` ends itself by SIGTERM.
  case paramStr(1)
  of "echo":
    stdout.write "<"
    for i in 2..paramCount(): stdout.write paramStr(i) & "|"
    stdout.write ">"
    quit 0
  of "exit":
    quit parseInt(paramStr(2))
  of "kill":
    when defined(posix):
      discard posix.kill(getpid(), SIGTERM)
      sleep 10_000
    quit 1
  else:
    quit 2

block plain_commands_split_into_their_words:
  doAssert plainCommandArgv("gcc -c -O2 foo.c") ==
    @["gcc", "-c", "-O2", "foo.c"]
  # What `quoteShell` produces for awkward arguments.
  doAssert plainCommandArgv("cc " & quoteShell("a b") & " " &
    quoteShell("it's") & " " & quoteShell("$HOME") & " " & quoteShell("")) ==
    @["cc", "a b", "it's", "$HOME", ""]
  doAssert plainCommandArgv("cc  -DX=\"y z\"\t-Wl,-rpath,/a:/b x\\ y") ==
    @["cc", "-DX=y z", "-Wl,-rpath,/a:/b", "x y"]
  doAssert plainCommandArgv("/nix/store/abc-gcc/bin/gcc -I'/p q' -o@x %y +z") ==
    @["/nix/store/abc-gcc/bin/gcc", "-I/p q", "-o@x", "%y", "+z"]
  doAssert plainCommandArgv("'gcc' -c") == @["gcc", "-c"]

block commands_the_shell_interprets_are_refused:
  for cmd in ["", "   ", "''", "cc $CFLAGS x.c", "cc `pkg-config x`",
              "cc $(pkg-config x)", "cc x.c > log", "cc x.c 2>&1",
              "cc < in", "a | b", "a && b", "a; b", "a & b", "a\nb",
              "cc *.c", "cc x?.c", "cc [ab].c", "cc ~/x.c", "cc {a,b}.c",
              "cc x.c # note", "CC=gcc make", "cc \"$X\"", "cc \"`x`\"",
              "cc \"a\\b\"", "cc 'unterminated", "cc \"unterminated",
              "cc x\\", "cc (x)", "cc !x", "cd /tmp", "exec gcc",
              "echo hi", "test -f x", "if", "true", ". ./env", "%1",
              "%cc -c", "chdir /tmp", "'echo' hi", "print x", "a\rb",
              "cc \\\n"]:
    doAssert plainCommandArgv(cmd).len == 0, "split: " & cmd

block a_refused_command_still_goes_to_the_shell:
  when not defined(windows):
    doAssert commandArgv("a | b") == @["/bin/sh", "-c", "a | b"]
    doAssert commandArgv("gcc -c x.c") == @["gcc", "-c", "x.c"]

block execCommand_keeps_the_exit_codes_of_the_shell:
  doAssert execCommand(child("exit", "0")) == 0
  doAssert execCommand(child("exit", "3")) == 3
  when defined(posix):
    # A signal is reported as 128 + its number, as the shell reports it.
    doAssert execCommand(child("kill")) == 128 + 15
    # A program that cannot be started: 127, as the shell's "not found".
    doAssert execCommand(quoteShell(getTempDir() / "no-such-program-x7") &
      " arg") == 127
    # A file that is there but cannot be executed: 126, as the shell's
    # "Permission denied".
    let noExec = getTempDir() / "tshellfreeexec-noexec-" & $getpid()
    writeFile(noExec, "#!/bin/sh\nexit 0\n")
    setFilePermissions(noExec, {fpUserRead, fpUserWrite})
    try:
      doAssert execCommand(quoteShell(noExec)) == 126
    finally:
      removeFile(noExec)
    # A command that needs the shell still runs through it.
    doAssert execCommand("exit 4") == 4

block execCommandEx_passes_arguments_unchanged:
  let (output, code) = execCommandEx(child("echo", "a b", "it's", "$HOME", ""))
  doAssert code == 0, output
  doAssert output == "<a b|it's|$HOME||>", output
  when defined(posix):
    let (shOut, shCode) = execCommandEx("printf '%s' x | tr x y")
    doAssert shCode == 0 and shOut == "y", shOut

block execCommandsInParallel_runs_every_command:
  var outputs = newSeq[string](4)
  let cmds = @[child("echo", "0 0"), child("echo", "1"),
    child("echo", "two words"), child("exit", "5")]
  let worst = execCommandsInParallel(cmds, {poStdErrToStdOut, poUsePath}, 2,
    afterRunEvent = proc (idx: int, p: Process) =
      outputs[idx] = p.outputStream.readAll())
  doAssert worst == 5
  doAssert outputs[0] == "<0 0|>", outputs[0]
  doAssert outputs[1] == "<1|>", outputs[1]
  doAssert outputs[2] == "<two words|>", outputs[2]

block a_change_of_directory_before_a_plain_command_runs_directly:
  # What `staticExec` callers spell to run a program in another directory.
  doAssert directCommand("cd /tmp && exec gcc -c x.c") ==
    DirectCommand(dir: "/tmp", argv: @["gcc", "-c", "x.c"])
  doAssert directCommand("cd /tmp && gcc -c x.c") ==
    DirectCommand(dir: "/tmp", argv: @["gcc", "-c", "x.c"])
  doAssert directCommand("cd " & quoteShell("/a b/it's") & " && exec " &
    quoteShell("/n/bin/nim") & " c " & quoteShell("x && y.nim")) ==
    DirectCommand(dir: "/a b/it's", argv: @["/n/bin/nim", "c", "x && y.nim"])
  # A ` && ` inside the quoted directory is not the operator.
  doAssert directCommand("cd '/a && b' && exec x") ==
    DirectCommand(dir: "/a && b", argv: @["x"])
  # A plain command has no directory of its own.
  doAssert directCommand("gcc -c x.c") ==
    DirectCommand(dir: "", argv: @["gcc", "-c", "x.c"])

block every_other_use_of_cd_or_and_if_keeps_the_shell:
  for cmd in ["cd /tmp", "cd /tmp &&", "cd /tmp && ", "cd /tmp && exec",
              "cd tmp && x", "cd ./tmp && x", "cd ~ && x", "cd - && x",
              "cd -P /tmp && x", "cd /tmp /u && x", "cd && x",
              "cd /tmp && exec -a name x", "cd /tmp && exec -- x",
              "cd /tmp && echo hi", "cd /tmp && cd /u && x",
              "cd /tmp && x && y", "cd /tmp && x | y", "cd $D && x",
              "cd /tmp && X=1 y", "cd /tmp && x > log", "pushd /tmp && x",
              "a && b", "cd /tmp&&x", "cd /tmp && exec exec x",
              "cd /tmp && %1", "cd '/tmp && x"]:
    doAssert directCommand(cmd).argv.len == 0, "direct: " & cmd

block a_shell_exports_the_pwd_it_was_started_with_or_the_physical_one:
  when defined(posix):
    let root = getTempDir() / "tshellfreeexec-pwd-" & $getpid()
    let real = root / "real"
    let link = root / "link"
    createDir(real)
    createSymlink(real, link)
    let saved = getEnv("PWD")
    try:
      let physical = expandFilename(real)
      # An inherited `PWD` naming another directory is replaced by the
      # physical path of the one the shell starts in.
      putEnv("PWD", "/")
      doAssert shellStartPwd(link) == physical, shellStartPwd(link)
      # A relative one is never kept.
      putEnv("PWD", "link")
      doAssert shellStartPwd(link) == physical, shellStartPwd(link)
      # An absolute one that names the same directory is kept as it is,
      # symbolic link and all.
      putEnv("PWD", link)
      doAssert shellStartPwd(link) == link, shellStartPwd(link)
      doAssert shellStartPwd(real) == link, shellStartPwd(real)
    finally:
      putEnv("PWD", saved)
      removeFile(link)
      removeDir(root)
