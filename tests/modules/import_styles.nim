discard """
  output: "ok"
"""
import strutils as strutils1
import strutils as strutils2
import std/strutils as strutils3
import std/strutils

import std/sha1
import std/sha1 as sha1_2
# TODO: Error: cannot open file: stdlib/std/sha1; inconsistent with the fact we
# generate `stdlib.std.sha1`
# import stdlib/std/sha1 as sha1_3

import ./mnotuniquename
import ./tnotuniquename/mnotuniquename as mnotuniquename1

import pure/ospaths as ospaths1
import std/ospaths as ospaths2
import ospaths as ospaths3

# Error: cannot open file: std/pure/ospaths
# import std/pure/ospaths as ospaths4

echo "ok"
