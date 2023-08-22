

type
  Feature = tuple[name: string, version: string]
  PDOMImplementation* = ref DOMImplementation
  DOMImplementation = object
    Features: seq[Feature] # Read-Only

  PNode* = ref Node
  Node {.inheritable.} = object
    attributes*: seq[PAttr]
    childNodes*: seq[PNode]
    FLocalName: string # Read-only
    FNamespaceURI: string # Read-only
    FNodeName: string # Read-only
    nodeValue*: string
    FNodeType: int # Read-only
    FOwnerDocument: PDocument # Read-Only
    FParentNode: PNode # Read-Only
    prefix*: string # Setting this should change some values... TODO!

  PElement* = ref Element
  Element = object of Node
    FTagName: string # Read-only

  PCharacterData = ref CharacterData
  CharacterData = object of Node
    data*: string

  PDocument* = ref Document
  Document = object of Node
    FImplementation: PDOMImplementation # Read-only
    FDocumentElement: PElement # Read-only

  PAttr* = ref Attr
  Attr = object of Node
    FName: string # Read-only
    FSpecified: bool # Read-only
    value*: string
    FOwnerElement: PElement # Read-only

  PDocumentFragment* = ref DocumentFragment
  DocumentFragment = object of Node

  PText* = ref Text
  Text = object of CharacterData

  PComment* = ref Comment
  Comment = object of CharacterData

  PCDataSection* = ref CDataSection
  CDataSection = object of Text

  PProcessingInstruction* = ref ProcessingInstruction
  ProcessingInstruction = object of Node
    data*: string
    FTarget: string # Read-only

proc `namespaceURI=`*(n: var PNode, value: string) =
  n.FNamespaceURI = value

proc main =
  var n: PNode
  new(n)
  n.namespaceURI = "test"

main()
