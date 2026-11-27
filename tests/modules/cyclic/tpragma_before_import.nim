discard """
  joinable: false
  matrix: "--warningAsError:UnusedImport:on --warningAsError:Deprecated:on"
  output: "1"
"""

# A `{.warning[X]: off.}` before the imports of a module of the group concerns
# its imports, and it lasts through the phases of the other modules.
{.warning[Deprecated]: off.}
{.warning[UnusedImport]: off.}
import pragmas/mpragma_before_import {.cyclic.}
import std/strutils

proc fa*(): int = 1
echo fa()
