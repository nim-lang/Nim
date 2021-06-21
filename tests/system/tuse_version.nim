discard """
  cmd: "nim c --useVersion:1.0 -r $file"
  output: "1.0.100"
"""

{.warning[UnusedImport]: off.}

import std/[
  # Core:
  bitops, typetraits, lenientops, macros, volatile,

  # Algorithms:
  algorithm, sequtils,

  # Collections:
  critbits, deques, heapqueue, intsets, lists, options, sets,
  sharedlist, tables,

  # Strings:
  editdistance, wordwrap, parseutils, ropes,
  pegs, punycode, strformat, strmisc, strscans, strtabs,
  strutils, unicode, unidecode,

  # Generic operator system services:
  os, streams,

  # Math libraries:
  complex, math, mersenne, random, rationals, stats, sums,

  # Internet protocols:
  httpcore, mimetypes, uri,

  # Parsers:
  htmlparser, json, lexbase, parsecfg, parsecsv, parsesql, parsexml,

  # XML processing:
  xmltree, xmlparser,

  # Generators:
  htmlgen,

  # Hashing:
  base64, hashes,

  # Miscellaneous:
  colors, sugar, varints,
]


echo NimVersion
