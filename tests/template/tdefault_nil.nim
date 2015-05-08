
# bug #2629
import sequtils, os

template glob_rst(basedir: string = nil): expr =
  if baseDir.isNil:
    to_seq(walk_files("*.rst"))
  else:
    to_seq(walk_files(basedir/"*.rst"))

let
  rst_files = concat(glob_rst(), glob_rst("docs"))

when isMainModule: echo rst_files
