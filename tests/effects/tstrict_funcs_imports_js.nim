discard """
  cmd: "nim $target $options --hints:on --experimental:strictFuncs --experimental:views $file"
  targets: "js"
"""
{.warning[UnusedImport]: off.}

import
  asyncjs,
  dom,
  jsconsole,
  jsffi,
  jsre

import std/[
  jsbigints,
]

import std/private/[
  jsutils,
]
