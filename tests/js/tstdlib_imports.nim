discard """
  action: compile
"""

{.warning[UnusedImport]: off.}

import std/[
  # Core:
  bitops, typetraits, lenientops, macros, volatile, typeinfo,
  # fails: endians, rlocks
  # works but shouldn't: cpuinfo, locks

  # Algorithms:
  algorithm, sequtils,
  
  # Collections:
  critbits, deques, heapqueue, intsets, lists, options, sets,
  sharedlist, tables,
  # fails: sharedtables

  # Strings:
  cstrutils, editdistance, wordwrap, parseutils, ropes,
  pegs, punycode, strformat, strmisc, strscans, strtabs,
  strutils, unicode, unidecode,
  # fails: encodings

  # Time handling:
  monotimes, times,

  # Generic operator system services:
  os, streams,
  # fails: distros, dynlib, marshal, memfiles, osproc, terminal

  # Math libraries:
  complex, math, mersenne, random, rationals, stats, sums,
  # works but shouldn't: fenv

  # Internet protocols:
  cookies, httpcore, mimetypes, uri,
  # fails: asyncdispatch, asyncfile, asyncftpclient, asynchttpserver,
  # asyncnet, cgi, httpclient, nativesockets, net, selectors, smtp
  # works but shouldn't test: asyncstreams, asyncfutures
  
  # Threading:
  # fails: threadpool

  # Parsers:
  htmlparser, json, lexbase, parsecfg, parsecsv, parsesql, parsexml,
  parseopt,

  # XML processing:
  xmltree, xmlparser,

  # Generators:
  htmlgen,

  # Hashing:
  base64, hashes,
  # fails: md5, oids, sha1

  # Miscellaneous:
  colors, logging, sugar, unittest, varints,
  # fails: browsers, coro
  # works but shouldn't: segfaults

  # Modules for JS backend:
  asyncjs, dom, jsconsole, jscore, jsffi,

  # Unlisted in lib.html:
  decls, compilesettings, with, wrapnils
]
