discard """
  output: '''

[Suite] nimgrep filesystem

[Suite] nimgrep contents filtering
'''
"""
## Authors: quantimnot, a-mr

import std/[osproc, os, streams, unittest, strutils]

import std/syncio

#=======
# setup
#=======

var process: Process
var ngStdOut, ngStdErr: string
var ngExitCode: int
let previousDir = getCurrentDir()
let tempDir = getTempDir()
let testFilesRoot = tempDir / "nimgrep_test_files"

template nimgrep(optsAndArgs): untyped =
  process = startProcess(previousDir / "bin/nimgrep " & optsAndArgs,
                         options = {poEvalCommand})
  ngExitCode = process.waitForExit
  ngStdOut = process.outputStream.readAll
  ngStdErr = process.errorStream.readAll

func fixSlash(s: string): string =
  if DirSep == '/':
    result = s
  else:  # on Windows
    result = s.replace('/', DirSep)

func initString(len = 1000, val = ' '): string =
  result = newString(len)
  for i in 0..<len:
    result[i] = val

# Create test file hierarchy.
createDir testFilesRoot
setCurrentDir testFilesRoot
createDir "a" / "b"
createDir "c" / "b"
createDir ".hidden"
writeFile("do_not_create_another_file_with_this_pattern_KJKJHSFSFKASHFBKAF", "PATTERN")
writeFile("a" / "b" / "only_the_pattern", "PATTERN")
writeFile("c" / "b" / "only_the_pattern", "PATTERN")
writeFile(".hidden" / "only_the_pattern", "PATTERN")
writeFile("null_in_first_1k", "\0PATTERN")
writeFile("null_after_first_1k", initString(1000) & "\0")
writeFile("empty", "")
writeFile("context_match_filtering", """
-
CONTEXTPAT
-
PATTERN
-
-
-

-
-
-
PATTERN
-
-
-
""")
writeFile("only_the_pattern.txt", "PATTERN")
writeFile("only_the_pattern.ascii", "PATTERN")


#=======
# tests
#=======

suite "nimgrep filesystem":

  test "`--filename` with matching file":
    nimgrep "-r --filename:KJKJHSFSFKASHFBKAF PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == fixSlash dedent"""
        ./do_not_create_another_file_with_this_pattern_KJKJHSFSFKASHFBKAF:1: PATTERN
        1 matches
        """


  test "`--dirname` with matching dir":
    nimgrep "-r --dirname:.hid PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == fixSlash dedent"""
        .hidden/only_the_pattern:1: PATTERN
        1 matches
        """

  let only_the_pattern = fixSlash dedent"""
        a/b/only_the_pattern:1: PATTERN
        c/b/only_the_pattern:1: PATTERN
        2 matches
        """

  let only_a = fixSlash dedent"""
        a/b/only_the_pattern:1: PATTERN
        1 matches
        """

  test "`--dirname` with matching grandparent path segment":
    nimgrep "-r --dirname:a PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == only_a

  test "`--dirpath` with matching grandparent path segment":
    nimgrep "-r --dirp:a PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == only_a

  test "`--dirpath` with matching grandparent path segment":
    nimgrep "-r --dirpath:a/b PATTERN".fixSlash
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == only_a


  test "`--dirname` with matching parent path segment":
    nimgrep "-r --dirname:b PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == only_the_pattern

  test "`--dirpath` with matching parent path segment":
    nimgrep "-r --dirpath:b PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == only_the_pattern


  let patterns_without_directory_a_b = fixSlash dedent"""
        ./context_match_filtering:4: PATTERN
        ./context_match_filtering:12: PATTERN
        ./do_not_create_another_file_with_this_pattern_KJKJHSFSFKASHFBKAF:1: PATTERN
        ./null_in_first_1k:1: """ & "\0PATTERN\n" & dedent"""
        ./only_the_pattern.ascii:1: PATTERN
        ./only_the_pattern.txt:1: PATTERN
        .hidden/only_the_pattern:1: PATTERN
        c/b/only_the_pattern:1: PATTERN
        8 matches
        """

  let patterns_without_directory_b = fixSlash dedent"""
        ./context_match_filtering:4: PATTERN
        ./context_match_filtering:12: PATTERN
        ./do_not_create_another_file_with_this_pattern_KJKJHSFSFKASHFBKAF:1: PATTERN
        ./null_in_first_1k:1: """ & "\0PATTERN\n" & dedent"""
        ./only_the_pattern.ascii:1: PATTERN
        ./only_the_pattern.txt:1: PATTERN
        .hidden/only_the_pattern:1: PATTERN
        7 matches
        """

  test "`--ndirname` not matching grandparent path segment":
    nimgrep "-r --ndirname:a PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == patterns_without_directory_a_b

  test "`--ndirname` not matching parent path segment":
    nimgrep "-r --ndirname:b PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == patterns_without_directory_b

  test "`--notdirpath` not matching grandparent path segment":
    nimgrep "-r --notdirpath:a PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == patterns_without_directory_a_b

  test "`--notdirpath` not matching parent path segment":
    nimgrep "-r --ndirp:b PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == patterns_without_directory_b

  test "`--notdirpath` with matching grandparent/parent path segment":
    nimgrep "-r --ndirp:a/b PATTERN".fixSlash
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == patterns_without_directory_a_b


  test "`--text`, `-t`, `--bin:off` with file containing a null in first 1k chars":
    nimgrep "-r --text PATTERN null_in_first_1k"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == "0 matches\n"
    checkpoint "`--text`"
    nimgrep "-r -t PATTERN null_in_first_1k"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == "0 matches\n"
    checkpoint "`-t`"
    nimgrep "-r --bin:off PATTERN null_in_first_1k"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == "0 matches\n"
    checkpoint "`--binary:off`"


  test "`--bin:only` with file containing a null in first 1k chars":
    nimgrep "--bin:only -@ PATTERN null_in_first_1k null_after_first_1k only_the_pattern.txt"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == dedent"""
        null_in_first_1k:1: ^@PATTERN
        1 matches
        """


  test "`--bin:only` with file containing a null after first 1k chars":
    nimgrep "--bin:only PATTERN null_after_first_1k only_the_pattern.txt"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == "0 matches\n"


  # TODO: we need to throw a warning if e.g. both extension was provided and
  # inappropriate filename was directly provided via command line
  #
  #  test "`--ext:doesnotexist` without a matching file":
  #    # skip() # FIXME: this test fails
  #    nimgrep "--ext:doesnotexist PATTERN context_match_filtering only_the_pattern.txt"
  #    check ngExitCode == 0
  #    check ngStdErr.len == 0
  #    check ngStdOut == """
  #0 matches
  #"""
  #
  #
  #  test "`--ext:txt` with a matching file":
  #    nimgrep "--ext:txt PATTERN context_match_filtering only_the_pattern.txt"
  #    check ngExitCode == 0
  #    check ngStdErr.len == 0
  #    check ngStdOut == """
  #only_the_pattern.txt:1: PATTERN
  #1 matches
  #"""
  #
  #
  #  test "`--ext:txt|doesnotexist` with some matching files":
  #    nimgrep "--ext:txt|doesnotexist PATTERN context_match_filtering only_the_pattern.txt only_the_pattern.ascii"
  #    check ngExitCode == 0
  #    check ngStdErr.len == 0
  #    check ngStdOut == """
  #only_the_pattern.txt:1: PATTERN
  #1 matches
  #"""
  #
  #
  #  test "`--ext` with some matching files":
  #    nimgrep "--ext PATTERN context_match_filtering only_the_pattern.txt only_the_pattern.ascii"
  #    check ngExitCode == 0
  #    check ngStdErr.len == 0
  #    check ngStdOut == """
  #context_match_filtering:4: PATTERN
  #context_match_filtering:12: PATTERN
  #2 matches
  #"""
  #
  #
  #  test "`--ext:txt --ext` with some matching files":
  #    nimgrep "--ext:txt --ext PATTERN context_match_filtering only_the_pattern.txt only_the_pattern.ascii"
  #    check ngExitCode == 0
  #    check ngStdErr.len == 0
  #    check ngStdOut == """
  #context_match_filtering:4: PATTERN
  #context_match_filtering:12: PATTERN
  #only_the_pattern.txt:1: PATTERN
  #3 matches
  #"""


suite "nimgrep contents filtering":

  test "`--inFile` with matching file":
    nimgrep "-r --inf:CONTEXTPAT PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == fixSlash dedent"""
        ./context_match_filtering:4: PATTERN
        ./context_match_filtering:12: PATTERN
        2 matches
        """


  test "`--notinFile` with matching files":
    nimgrep "-r --ninf:CONTEXTPAT PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == fixSlash dedent"""
        ./do_not_create_another_file_with_this_pattern_KJKJHSFSFKASHFBKAF:1: PATTERN
        ./null_in_first_1k:1: """ & "\0PATTERN\n" & dedent"""
        ./only_the_pattern.ascii:1: PATTERN
        ./only_the_pattern.txt:1: PATTERN
        .hidden/only_the_pattern:1: PATTERN
        a/b/only_the_pattern:1: PATTERN
        c/b/only_the_pattern:1: PATTERN
        7 matches
        """


  test "`--inContext` with missing context option":
    # Using `--inContext` implies default -c:1 is used
    nimgrep "-r --inContext:CONTEXTPAT PATTERN"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == "0 matches\n"


  test "`--inContext` with PAT matching PATTERN":
    # This tests the scenario where PAT always matches PATTERN and thus
    # has the same effect as excluding the `inContext` option.
    # I'm not sure of the desired behaviour here.
    nimgrep "--context:2 --inc:PAT PATTERN context_match_filtering"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == dedent"""
        context_match_filtering:2  CONTEXTPAT
        context_match_filtering:3  -
        context_match_filtering:4: PATTERN
        context_match_filtering:5  -
        context_match_filtering:6  -

        context_match_filtering:10  -
        context_match_filtering:11  -
        context_match_filtering:12: PATTERN
        context_match_filtering:13  -
        context_match_filtering:14  -

        2 matches
        """


  test "`--inContext` with PAT in context":
    nimgrep "--context:2 --inContext:CONTEXTPAT PATTERN context_match_filtering"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == dedent"""
        context_match_filtering:2  CONTEXTPAT
        context_match_filtering:3  -
        context_match_filtering:4: PATTERN
        context_match_filtering:5  -
        context_match_filtering:6  -

        1 matches
        """


  test "`--notinContext` with PAT matching some contexts":
    nimgrep "--context:2 --ninContext:CONTEXTPAT PATTERN context_match_filtering"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == dedent"""
        context_match_filtering:10  -
        context_match_filtering:11  -
        context_match_filtering:12: PATTERN
        context_match_filtering:13  -
        context_match_filtering:14  -

        1 matches
        """


  test "`--notinContext` with PAT not matching any of the contexts":
    nimgrep "--context:1 --ninc:CONTEXTPAT PATTERN context_match_filtering"
    check ngExitCode == 0
    check ngStdErr.len == 0
    check ngStdOut == dedent"""
        context_match_filtering:3  -
        context_match_filtering:4: PATTERN
        context_match_filtering:5  -

        context_match_filtering:11  -
        context_match_filtering:12: PATTERN
        context_match_filtering:13  -

        2 matches
        """


#=========
# cleanup
#=========

setCurrentDir previousDir
removeDir testFilesRoot
