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

import ast, msgs, ropes, options, pathutils

type
  NdiFile* = object
    enabled: bool
    f: File
    buf: string
    filename: AbsoluteFile
    syms: seq[PSym]

proc doWrite(f: var NdiFile; s: PSym; conf: ConfigRef) =
  f.buf.setLen 0
  f.buf.addInt s.info.line.int
  f.buf.add "\t"
  f.buf.addInt s.info.col.int
  f.f.write(s.name.s, "\t")
  f.f.writeRope(s.loc.r)
  f.f.writeLine("\t", toFullPath(conf, s.info), "\t", f.buf)

template writeMangledName*(f: NdiFile; s: PSym; conf: ConfigRef) =
  if f.enabled: f.syms.add s

proc open*(f: var NdiFile; filename: AbsoluteFile; conf: ConfigRef) =
  f.enabled = not filename.isEmpty
  if f.enabled:
    f.filename = filename
    f.buf = newStringOfCap(20)

proc close*(f: var NdiFile, conf: ConfigRef) =
  if f.enabled:
    f.f = open(f.filename.string, fmWrite, 8000)
    doAssert f.f != nil, f.filename.string
    for s in f.syms:
      doWrite(f, s, conf)
    close(f.f)
    f.syms.reset
    f.filename.reset
