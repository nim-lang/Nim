# This nimscript is used to test if the following modules can be imported
# http://nim-lang.org/docs/nims.html

{.warning[UnusedImport]: off.}

import std/[
  # Core:
  bitops, typetraits, lenientops, macros, volatile,
  # fails: typeinfo, endians
  # works but shouldn't: cpuinfo, rlocks, locks

  # Algorithms:
  algorithm, sequtils,

  # Collections:
  critbits, deques, heapqueue, intsets, lists, options, sets,
  sharedlist, tables,
  # fails: sharedtables

  # Strings:
  editdistance, wordwrap, parseutils, ropes,
  pegs, punycode, strformat, strmisc, strscans, strtabs,
  strutils, unicode, unidecode,
  # works but shouldn't: cstrutils, encodings

  # Time handling:
  # fails: monotimes, times
  # but times.getTime() implemented for VM

  # Generic operator system services:
  os, streams,
  # fails: distros, dynlib, marshal, memfiles, osproc, terminal

  # Math libraries:
  complex, math, mersenne, random, rationals, stats, sums,
  # works but shouldn't: fenv

  # Internet protocols:
  httpcore, mimetypes, uri,
  # fails: asyncdispatch, asyncfile, asyncftpclient, asynchttpserver,
  # asyncnet, cgi, cookies, httpclient, nativesockets, net, selectors, smtp
  # works but shouldn't test: asyncstreams, asyncfutures

  # Threading:
  # fails: threadpool

  # Parsers:
  htmlparser, json, lexbase, parsecfg, parsecsv, parsesql, parsexml,
  # fails: parseopt

  # XML processing:
  xmltree, xmlparser,

  # Generators:
  htmlgen,

  # Hashing:
  base64, hashes,
  # fails: md5, oids, sha1

  # Miscellaneous:
  colors, sugar, varints,
  # fails: browsers, coro, logging (times), segfaults, unittest (uses methods)

  # Modules for JS backend:
  # fails: asyncjs, dom, jsconsole, jscore, jsffi,

  # Unlisted in lib.html:
  decls, compilesettings, with, wrapnils
]

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
