discard """
  timeout: 10
  joinable: false
  output: "fine"
"""

import std/strutils
import std/os

const source = staticRead(splitFile(currentSourcePath).dir / "m20746.nim")

static:
  discard source.multiReplace(
              ("{.inject.}", ""),
              ("{.inject, ", "{."),
              ("<", "["),
              (">", "]"), #Changes Gen. Some types has two levels of inherantce in cpp, that we dont really need to support
              ("::Type", ""), #Enum namespaces EEnumName::Type
              ("::Mode", ""), #Enum namespaces EEnumName::TypeB
              ("::", "."), #Enum namespace
              ("__DelegateSignature", ""))

echo "fine"
