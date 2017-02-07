#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the generation of ``.ndi`` files for better debugging
## support of Nim code. "ndi" stands for "Nim debug info".

import ast, msgs, ropes

type
  NdiFile* = object
    enabled: bool
    f: File
    buf: string

proc doWrite(f: var NdiFile; s: PSym) =
  f.buf.setLen 0
  f.buf.add s.info.line.int
  f.buf.add "\t"
  f.buf.add s.info.col.int
  f.f.write(s.name.s, "\t")
  f.f.writeRope(s.loc.r)
  f.f.writeLine("\t", s.info.toFullPath, "\t", f.buf)

template writeMangledName*(f: NdiFile; s: PSym) =
  if f.enabled: doWrite(f, s)

proc open*(f: var NdiFile; filename: string) =
  f.enabled = filename.len > 0
  if f.enabled:
    f.f = open(filename, fmWrite, 8000)
    f.buf = newStringOfCap(20)

proc close*(f: var NdiFile) =
  if f.enabled: close(f.f)
