# This nimscript is used to test if the following modules can be imported
# http://nim-lang.org/docs/nims.html

{.warning[UnusedImport]: off.}

from stdtest/specialpaths import buildDir

when defined(nimPreviewSlimSystem):
  import std/[
    syncio, assertions, formatfloat, objectdollar, widestrs
  ]

import std/[
  # Core:
  bitops, typetraits, lenientops, macros, volatile,
  # fails due to FFI: typeinfo
  # fails due to cstring cast/copyMem: endians
  # works but uses FFI: cpuinfo, rlocks, locks

  # Algorithms:
  algorithm, enumutils, sequtils, setutils,

  # Collections:
  critbits, deques, heapqueue, intsets, lists, options, sets,
  tables, packedsets,

  # Strings:
  editdistance, wordwrap, parseutils, ropes,
  pegs, strformat, strmisc, strscans, strtabs,
  strutils, unicode, unidecode, cstrutils,
  # works but uses FFI: encodings

  # Time handling:
  # fails due to FFI: monotimes, times
  # but times.getTime() implemented for VM

  # Generic operator system services:
  os, streams, distros,
  # fails due to FFI: memfiles, osproc, terminal
  # works but uses FFI: dynlib
  # intentionally fails: marshal

  # Math libraries:
  complex, math, random, rationals, stats, sums,
  # works but uses FFI: fenv, sysrand

  # Internet protocols:
  httpcore, mimetypes, uri,
  # fails due to FFI: asyncdispatch, asyncfile, asyncftpclient, asynchttpserver,
  # asyncnet, cgi, cookies, httpclient, nativesockets, net, selectors, smtp
  # works but no need to test: asyncstreams, asyncfutures

  # Threading:
  # fails due to FFI: threadpool

  # Parsers:
  htmlparser, json, lexbase, parsecfg, parsecsv, parsesql, parsexml,
  parseopt, jsonutils,

  # XML processing:
  xmltree, xmlparser,

  # Generators:
  htmlgen,

  # Hashing:
  base64, hashes,
  # fails due to cstring cast/times import/endians import: oids
  # fails due to copyMem/endians import: sha1

  # Miscellaneous:
  colors, sugar, varints, enumerate, with,
  # fails due to FFI: browsers, coro, segfaults
  # fails due to times import/methods: logging
  # fails due to methods: unittest

  # Modules for JS backend:
  # fails intentionally: asyncjs, dom, jsconsole, jscore, jsffi, jsbigints,
  # jsfetch, jsformdata, jsheaders

  # Unlisted in lib.html:
  decls, compilesettings, wrapnils, effecttraits, genasts,
  importutils, isolation
]

# non-std imports
import stdtest/testutils
# tests (increase coverage via code reuse)
import stdlib/trandom
import stdlib/tosenv

echo "Nimscript imports are successful."

block:
  doAssert "./foo//./bar/".normalizedPath == "foo/bar".unixToNativePath
block:
  doAssert $3'u == "3"
  doAssert $3'u64 == "3"

block: # #14142
  discard dirExists("/usr")
  discard fileExists("/usr/foo")
  discard findExe("nim")

block:
  doAssertRaises(AssertionDefect): doAssert false
  try: doAssert false
  except Exception as e:
    discard

block:  # cpDir, cpFile, dirExists, fileExists, mkDir, mvDir, mvFile, rmDir, rmFile
  const dname = buildDir/"D20210121T175016"
  const subDir = dname/"sub"
  const subDir2 = dname/"sub2"
  const fpath = subDir/"f"
  const fpath2 = subDir/"f2"
  const fpath3 = subDir2/"f"
  mkDir(subDir)
  writeFile(fpath, "some text")
  cpFile(fpath, fpath2)
  doAssert fileExists(fpath2)
  rmFile(fpath2)
  cpDir(subDir, subDir2)
  doAssert fileExists(fpath3)
  rmDir(subDir2)
  mvFile(fpath, fpath2)
  doAssert not fileExists(fpath)
  doAssert fileExists(fpath2)
  mvFile(fpath2, fpath)
  mvDir(subDir, subDir2)
  doAssert not dirExists(subDir)
  doAssert dirExists(subDir2)
  mvDir(subDir2, subDir)
  rmDir(dname)

block:
  # check parseopt can get command line:
  discard initOptParser()
