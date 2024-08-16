discard """
  action: compile
"""

{.warning[UnusedImport]: off.}

when defined(nimPreviewSlimSystem):
  import std/[
    syncio, assertions, formatfloat, objectdollar, widestrs
  ]

import std/[
  # Core:
  bitops, typetraits, lenientops, macros, volatile, typeinfo,
  # fails due to FFI: rlocks
  # fails due to cstring cast/copyMem: endians
  # works but uses FFI: cpuinfo, locks

  # Algorithms:
  algorithm, enumutils, sequtils, setutils,
  
  # Collections:
  critbits, deques, heapqueue, intsets, lists, options, sets,
  tables, packedsets,

  # Strings:
  cstrutils, editdistance, wordwrap, parseutils, ropes,
  pegs, strformat, strmisc, strscans, strtabs,
  strutils, unicode, unidecode,
  # fails due to FFI: encodings

  # Time handling:
  monotimes, times,

  # Generic operator system services:
  os, streams,
  # fails intentionally: dynlib, marshal, memfiles
  # fails due to FFI: osproc, terminal
  # fails due to osproc import: distros

  # Math libraries:
  complex, math, random, rationals, stats, sums, sysrand,
  # works but uses FFI: fenv

  # Internet protocols:
  cookies, httpcore, mimetypes, uri,
  # fails due to FFI: asyncdispatch, asyncfile, asyncftpclient, asynchttpserver,
  # asyncnet, cgi, httpclient, nativesockets, net, selectors
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
  # fails due to cstring cast/endians import: oids
  # fails due to copyMem/endians import: sha1

  # Miscellaneous:
  colors, logging, sugar, unittest, varints, enumerate, with,
  # fails due to FFI: browsers, coro
  # works but uses FFI: segfaults

  # Modules for JS backend:
  asyncjs, dom, jsconsole, jscore, jsffi, jsbigints,

  # Unlisted in lib.html:
  decls, compilesettings, wrapnils, exitprocs, effecttraits,
  genasts, importutils, isolation, jsfetch, jsformdata, jsheaders
]
