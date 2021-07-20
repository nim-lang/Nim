discard """
  matrix: "--moduleoverride:pkgC/module2:std/foo2b:$nim_prs_D/lib/"
  # matrix: "--moduleoverride:std/foo2:std/foo2b:$nim_prs_D/lib/"
"""
import std/strutils
import pkgA/module2 as A
import pkgB/module2 as B
import pkgC/module2 as C
