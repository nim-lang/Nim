discard """
disabled: "windows"
"""

# `staticExec` / `gorgeEx` run a command that needs no shell without one
# (`compiler/shellfreeexec`, `compiler/gorgeimpl`), so the host's `/bin/sh`
# is not part of a compile that calls them. Run directly, a command must
# mean what it meant through the shell: the same argv after quote removal,
# the same working directory (the calling module's, or the one a leading
# `cd DIR &&` names), `PWD` set to it, the program's exit code, 127 for no
# such program and 126 for one that cannot be executed, and a file without
# a `#!` line still run as a shell script. A command that needs the shell still gets it.
#
# No mocks: every command below is a real child of the compiler.

import std/[os, strutils]

template scriptDir(): string =
  parentDir(instantiationInfo(-1, true).filename)

const
  here = scriptDir()
  show = quoteShell(here / "tgorgedirect_show.sh")

block arguments_reach_the_program_unchanged:
  const res = gorgeEx(show & " " & quoteShell("a b") & " " &
    quoteShell("it's") & " " & quoteShell("$HOME") & " ''")
  doAssert res.exitCode == 0, res.output
  doAssert res.output.splitLines()[0] == "<a b|it's|$HOME||>", res.output

block it_runs_in_the_calling_module_s_directory:
  const res = gorgeEx(show)
  doAssert res.exitCode == 0, res.output
  let lines = res.output.splitLines()
  doAssert lines[1] == "cwd=" & here, res.output
  # `printenv` reads the environment it was given; a shell script would
  # reset `PWD` itself and show nothing.
  const pwd = gorgeEx("printenv PWD")
  doAssert pwd == (here, 0), $pwd

block a_leading_cd_names_the_directory:
  const target = here.parentDir
  const res = gorgeEx("cd " & quoteShell(target) & " && exec " & show & " x")
  doAssert res.exitCode == 0, res.output
  let lines = res.output.splitLines()
  doAssert lines[0] == "<x|>", res.output
  doAssert lines[1] == "cwd=" & target, res.output
  const pwd = gorgeEx("cd " & quoteShell(target) & " && exec printenv PWD")
  doAssert pwd == (target, 0), $pwd

block exit_codes_are_the_program_s:
  const exited = gorgeEx(show & " --exit 3")
  doAssert exited.exitCode == 3, $exited
  # A program that cannot be started, as the shell reports one.
  const missing = gorgeEx(quoteShell(here / "no-such-program-x7") & " a")
  doAssert missing.exitCode == 127, $missing
  # One that is there but cannot be executed, as the shell's "Permission
  # denied".
  const noExec = gorgeEx(quoteShell(here / "tgorgedirect_noexec.sh"))
  doAssert noExec.exitCode == 126, $noExec
  # A directory that cannot be entered fails.
  const noDir = gorgeEx("cd " & quoteShell(here / "no-such-dir-x7") &
    " && exec " & show)
  doAssert noDir.exitCode != 0, $noDir

block a_script_without_an_interpreter_line_still_runs:
  const res = gorgeEx(quoteShell(here / "tgorgedirect_noshebang.sh"))
  doAssert res.exitCode == 0, $res
  doAssert res.output == "no interpreter line", $res

block a_command_that_needs_the_shell_still_gets_one:
  const res = gorgeEx("printf '%s' x | tr x y; exit 4")
  doAssert res.output == "y" and res.exitCode == 4, $res
