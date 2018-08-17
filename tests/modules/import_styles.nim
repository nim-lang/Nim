discard """
  output: "ok"
"""
import strutils as strutils1
import strutils as strutils2
import std/strutils as strutils3
import std/strutils

import std/sha1
import std/sha1 as sha1_2

import ./mnotuniquename
import ./tnotuniquename/mnotuniquename as mnotuniquename1

import pure/ospaths as ospaths1
import std/ospaths as ospaths2
import ospaths as ospaths3

# TODO: this is inconsistent: Error: cannot open file: std/pure/ospaths
# import std/pure/ospaths as ospaths4

echo "ok"
