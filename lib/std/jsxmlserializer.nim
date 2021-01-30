## - `XMLSerializer` for the JavaScript target: https://developer.mozilla.org/en-US/docs/Web/API/XMLSerializer
when not defined(js):
  {.fatal: "Module jsxmlserializer is designed to be used with the JavaScript backend.".}

from std/dom import Node

type XMLSerializer* = ref object of JsRoot  ## XMLSerializer API.

func newXMLSerializer*(): XMLSerializer {.importjs: "new XMLSerializer()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLSerializer

func serializeToString*(this: XMLSerializer; node: Node): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLSerializer/serializeToString


runnableExamples:
  from std/dom import document
  if defined(nimJsXMLSerializerTests):
    let cerealizer: XMLSerializer = newXMLSerializer()
    echo cerealizer.serializeToString(node = document)
