## - `XMLSerializer` for the JavaScript target: https://developer.mozilla.org/en-US/docs/Web/API/XMLSerializer
when not defined(js) and not defined(nimdoc):
  {.fatal: "Module jsxmlserializer is designed to be used with the JavaScript backend.".}

from dom import Node
export Node

type XMLSerializer* = ref object  ## XMLSerializer API.

func newXMLSerializer*(): XMLSerializer {.importjs: "new XMLSerializer()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLSerializer

func serializeToString*(this: XMLSerializer; node: Node): cstring {.importjs: "#.serializeToString(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLSerializer/serializeToString


runnableExamples:
  when defined(nimJsXMLSerializerTests):
    from dom import document
    let cerealizer: XMLSerializer = newXMLSerializer()
    echo cerealizer.serializeToString(node = document)
