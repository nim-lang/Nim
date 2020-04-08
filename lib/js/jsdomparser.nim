## DOM Parser for JavaScript target
## ================================
##
## * https://developer.mozilla.org/en-US/docs/Web/API/DOMParser
##
## .. code-block:: nim
##   let prsr = newDOMParser()
##   discard prsr.parseFromString("<html><marquee>Hello World</marquee></html>".cstring)

include "system/inclrtl"

since (1, 3):
  from dom import Document
  export Document

  type DOMParser* = ref object  ## \
    ## DOM Parser object (defined on browser only, may not be on NodeJS).

  func newDOMParser*(): DOMParser {.importcpp: "(new DOMParser()​​)".}
    ## DOM Parser constructor.

  func parseFromString*(this: DOMParser; str: cstring; mimeType = "text/html".cstring): Document {.importcpp.}
    ## Parse from string to Document.
