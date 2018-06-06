#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


import strutils
## This module implements XML DOM Level 2 Core
## specification (http://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html)


#http://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html

#Exceptions
type
  EDOMException* = object of ValueError ## Base exception object for all DOM Exceptions
  EDOMStringSizeErr* = object of EDOMException ## If the specified range of text does not fit into a DOMString
                                               ## Currently not used(Since DOMString is just string)
  EHierarchyRequestErr* = object of EDOMException ## If any node is inserted somewhere it doesn't belong
  EIndexSizeErr* = object of EDOMException ## If index or size is negative, or greater than the allowed value
  EInuseAttributeErr* = object of EDOMException ## If an attempt is made to add an attribute that is already in use elsewhere
  EInvalidAccessErr* = object of EDOMException ## If a parameter or an operation is not supported by the underlying object.
  EInvalidCharacterErr* = object of EDOMException ## This exception is raised when a string parameter contains an illegal character
  EInvalidModificationErr* = object of EDOMException ## If an attempt is made to modify the type of the underlying object.
  EInvalidStateErr* = object of EDOMException ## If an attempt is made to use an object that is not, or is no longer, usable.
  ENamespaceErr* = object of EDOMException ## If an attempt is made to create or change an object in a way which is incorrect with regard to namespaces.
  ENotFoundErr* = object of EDOMException ## If an attempt is made to reference a node in a context where it does not exist
  ENotSupportedErr* = object of EDOMException ## If the implementation does not support the requested type of object or operation.
  ENoDataAllowedErr* = object of EDOMException ## If data is specified for a node which does not support data
  ENoModificationAllowedErr* = object of EDOMException ## If an attempt is made to modify an object where modifications are not allowed
  ESyntaxErr* = object of EDOMException ## If an invalid or illegal string is specified.
  EWrongDocumentErr* = object of EDOMException ## If a node is used in a different document than the one that created it (that doesn't support it)

const
  ElementNode* = 1
  AttributeNode* = 2
  TextNode* = 3
  CDataSectionNode* = 4
  ProcessingInstructionNode* = 7
  CommentNode* = 8
  DocumentNode* = 9
  DocumentFragmentNode* = 11

  # Nodes which are childless - Not sure about AttributeNode
  childlessObjects = {DocumentNode, AttributeNode, TextNode,
    CDataSectionNode, ProcessingInstructionNode, CommentNode}
  # Illegal characters
  illegalChars = {'>', '<', '&', '"'}

  # standard xml: attribute names
  # see https://www.w3.org/XML/1998/namespace
  stdattrnames = ["lang", "space", "base", "id"]

type
  Feature = tuple[name: string, version: string]
  PDOMImplementation* = ref DOMImplementation
  DOMImplementation = object
    features: seq[Feature] # Read-Only

  PNode* = ref Node
  Node = object of RootObj
    attributes*: seq[PAttr]
    childNodes*: seq[PNode]
    fLocalName: string # Read-only
    fNamespaceURI: string # Read-only
    fNodeName: string # Read-only
    nodeValue*: string
    fNodeType: int # Read-only
    fOwnerDocument: PDocument # Read-Only
    fParentNode: PNode # Read-Only
    prefix*: string # Setting this should change some values... TODO!

  PElement* = ref Element
  Element = object of Node
    fTagName: string # Read-only

  PCharacterData* = ref CharacterData
  CharacterData = object of Node
    data*: string

  PDocument* = ref Document
  Document = object of Node
    fImplementation: PDOMImplementation # Read-only
    fDocumentElement: PElement # Read-only

  PAttr* = ref Attr
  Attr = object of Node
    fName: string # Read-only
    fSpecified: bool # Read-only
    value*: string
    fOwnerElement: PElement # Read-only

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
    fTarget: string # Read-only

# DOMImplementation
proc getDOM*(): PDOMImplementation =
  ## Returns a DOMImplementation
  new(result)
  result.features = @[(name: "core", version: "2.0"),
                      (name: "core", version: "1.0"),
                      (name: "XML", version: "2.0")]

proc createDocument*(dom: PDOMImplementation, namespaceURI: string, qualifiedName: string): PDocument =
  ## Creates an XML Document object of the specified type with its document element.
  var doc: PDocument
  new(doc)
  doc.fNamespaceURI = namespaceURI
  doc.fImplementation = dom

  var elTag: PElement
  new(elTag)
  elTag.fTagName = qualifiedName
  elTag.fNodeName = qualifiedName
  doc.fDocumentElement = elTag
  doc.fNodeType = DocumentNode

  return doc

proc createDocument*(dom: PDOMImplementation, n: PElement): PDocument =
  ## Creates an XML Document object of the specified type with its document element.

  # This procedure is not in the specification, it's provided for the parser.
  var doc: PDocument
  new(doc)
  doc.fDocumentElement = n
  doc.fImplementation = dom
  doc.fNodeType = DocumentNode

  return doc

proc hasFeature*(dom: PDOMImplementation, feature: string, version: string = ""): bool =
  ## Returns ``true`` if this ``version`` of the DomImplementation implements ``feature``, otherwise ``false``
  for iName, iVersion in items(dom.features):
    if iName == feature:
      if version == "":
        return true
      else:
        if iVersion == version:
          return true
  return false


# Document
# Attributes

proc implementation*(doc: PDocument): PDOMImplementation =
  return doc.fImplementation

proc documentElement*(doc: PDocument): PElement =
  return doc.fDocumentElement

# Internal procedures
proc findNodes(nl: PNode, name: string): seq[PNode] =
  # Made for getElementsByTagName
  var r: seq[PNode] = @[]
  if isNil(nl.childNodes): return @[]
  if nl.childNodes.len() == 0: return @[]

  for i in items(nl.childNodes):
    if i.fNodeType == ElementNode:
      if i.fNodeName == name or name == "*":
        r.add(i)

      if not isNil(i.childNodes):
        if i.childNodes.len() != 0:
          r.add(findNodes(i, name))

  return r

proc findNodesNS(nl: PNode, namespaceURI: string, localName: string): seq[PNode] =
  # Made for getElementsByTagNameNS
  var r: seq[PNode] = @[]
  if isNil(nl.childNodes): return @[]
  if nl.childNodes.len() == 0: return @[]

  for i in items(nl.childNodes):
    if i.fNodeType == ElementNode:
      if (i.fNamespaceURI == namespaceURI or namespaceURI == "*") and (i.fLocalName == localName or localName == "*"):
        r.add(i)

      if not isNil(i.childNodes):
        if i.childNodes.len() != 0:
          r.add(findNodesNS(i, namespaceURI, localName))

  return r


#Procedures
proc createAttribute*(doc: PDocument, name: string): PAttr =
  ## Creates an Attr of the given name. Note that the Attr instance can then be set on an Element using the setAttributeNode method.
  ## To create an attribute with a qualified name and namespace URI, use the createAttributeNS method.

  # Check if name contains illegal characters
  if illegalChars in name:
    raise newException(EInvalidCharacterErr, "Invalid character")

  var attrNode: PAttr
  new(attrNode)
  attrNode.fName = name
  attrNode.fNodeName = name
  attrNode.fLocalName = nil
  attrNode.prefix = nil
  attrNode.fNamespaceURI = nil
  attrNode.value = ""
  attrNode.fSpecified = false
  return attrNode

proc createAttributeNS*(doc: PDocument, namespaceURI: string, qualifiedName: string): PAttr =
  ## Creates an attribute of the given qualified name and namespace URI

  # Check if name contains illegal characters
  if illegalChars in namespaceURI or illegalChars in qualifiedName:
    raise newException(EInvalidCharacterErr, "Invalid character")
  # Exceptions
  if qualifiedName.contains(':'):
    let qfnamespaces = qualifiedName.toLowerAscii().split(':')
    if isNil(namespaceURI):
      raise newException(ENamespaceErr, "When qualifiedName contains a prefix namespaceURI cannot be nil")
    elif qfnamespaces[0] == "xml" and
        namespaceURI != "http://www.w3.org/XML/1998/namespace" and
        qfnamespaces[1] notin stdattrnames:
      raise newException(ENamespaceErr,
        "When the namespace prefix is \"xml\" namespaceURI has to be \"http://www.w3.org/XML/1998/namespace\"")
    elif qfnamespaces[1] == "xmlns" and namespaceURI != "http://www.w3.org/2000/xmlns/":
      raise newException(ENamespaceErr,
        "When the namespace prefix is \"xmlns\" namespaceURI has to be \"http://www.w3.org/2000/xmlns/\"")

  var attrNode: PAttr
  new(attrNode)
  attrNode.fName = qualifiedName
  attrNode.fNodeName = qualifiedName
  attrNode.fSpecified = false
  attrNode.fNamespaceURI = namespaceURI
  if qualifiedName.contains(':'):
    attrNode.prefix = qualifiedName.split(':')[0]
    attrNode.fLocalName = qualifiedName.split(':')[1]
  else:
    attrNode.prefix = nil
    attrNode.fLocalName = qualifiedName
  attrNode.value = ""

  attrNode.fNodeType = AttributeNode
  return attrNode

proc createCDATASection*(doc: PDocument, data: string): PCDataSection =
  ## Creates a CDATASection node whose value is the specified string.
  var cData: PCDataSection
  new(cData)
  cData.data = data
  cData.nodeValue = data
  cData.fNodeName = "#text" # Not sure about this, but this is technically a TextNode
  cData.fNodeType = CDataSectionNode
  return cData

proc createComment*(doc: PDocument, data: string): PComment =
  ## Creates a Comment node given the specified string.
  var comm: PComment
  new(comm)
  comm.data = data
  comm.nodeValue = data

  comm.fNodeType = CommentNode
  return comm

proc createDocumentFragment*(doc: PDocument): PDocumentFragment =
  ## Creates an empty DocumentFragment object.
  var df: PDocumentFragment
  new(df)
  return df

proc createElement*(doc: PDocument, tagName: string): PElement =
  ## Creates an element of the type specified.

  # Check if name contains illegal characters
  if illegalChars in tagName:
    raise newException(EInvalidCharacterErr, "Invalid character")

  var elNode: PElement
  new(elNode)
  elNode.fTagName = tagName
  elNode.fNodeName = tagName
  elNode.fLocalName = nil
  elNode.prefix = nil
  elNode.fNamespaceURI = nil
  elNode.childNodes = @[]
  elNode.attributes = @[]

  elNode.fNodeType = ElementNode

  return elNode

proc createElementNS*(doc: PDocument, namespaceURI: string, qualifiedName: string): PElement =
  ## Creates an element of the given qualified name and namespace URI.
  if qualifiedName.contains(':'):
    let qfnamespaces = qualifiedName.toLowerAscii().split(':')
    if isNil(namespaceURI):
      raise newException(ENamespaceErr, "When qualifiedName contains a prefix namespaceURI cannot be nil")
    elif qfnamespaces[0] == "xml" and
        namespaceURI != "http://www.w3.org/XML/1998/namespace" and
        qfnamespaces[1] notin stdattrnames:
      raise newException(ENamespaceErr,
        "When the namespace prefix is \"xml\" namespaceURI has to be \"http://www.w3.org/XML/1998/namespace\"")

  # Check if name contains illegal characters
  if illegalChars in namespaceURI or illegalChars in qualifiedName:
    raise newException(EInvalidCharacterErr, "Invalid character")

  var elNode: PElement
  new(elNode)
  elNode.fTagName = qualifiedName
  elNode.fNodeName = qualifiedName
  if qualifiedName.contains(':'):
    elNode.prefix = qualifiedName.split(':')[0]
    elNode.fLocalName = qualifiedName.split(':')[1]
  else:
    elNode.prefix = nil
    elNode.fLocalName = qualifiedName
  elNode.fNamespaceURI = namespaceURI
  elNode.childNodes = @[]
  elNode.attributes = @[]

  elNode.fNodeType = ElementNode

  return elNode

proc createProcessingInstruction*(doc: PDocument, target: string, data: string): PProcessingInstruction =
  ## Creates a ProcessingInstruction node given the specified name and data strings.

  #Check if name contains illegal characters
  if illegalChars in target:
    raise newException(EInvalidCharacterErr, "Invalid character")

  var pi: PProcessingInstruction
  new(pi)
  pi.fTarget = target
  pi.data = data
  pi.fNodeType = ProcessingInstructionNode
  return pi

proc createTextNode*(doc: PDocument, data: string): PText = #Propably TextNode
  ## Creates a Text node given the specified string.
  var txtNode: PText
  new(txtNode)
  txtNode.data = data
  txtNode.nodeValue = data
  txtNode.fNodeName = "#text"

  txtNode.fNodeType = TextNode
  return txtNode

discard """proc getElementById*(doc: PDocument, elementId: string): PElement =
  ##Returns the ``Element`` whose ID is given by ``elementId``. If no such element exists, returns ``nil``
  #TODO"""

proc getElementsByTagName*(doc: PDocument, tagName: string): seq[PNode] =
  ## Returns a NodeList of all the Elements with a given tag name in
  ## the order in which they are encountered in a preorder traversal of the Document tree.
  result = @[]
  if doc.fDocumentElement.fNodeName == tagName or tagName == "*":
    result.add(doc.fDocumentElement)

  result.add(doc.fDocumentElement.findNodes(tagName))

proc getElementsByTagNameNS*(doc: PDocument, namespaceURI: string, localName: string): seq[PNode] =
  ## Returns a NodeList of all the Elements with a given localName and namespaceURI
  ## in the order in which they are encountered in a preorder traversal of the Document tree.
  result = @[]
  if doc.fDocumentElement.fLocalName == localName or localName == "*":
    if doc.fDocumentElement.fNamespaceURI == namespaceURI or namespaceURI == "*":
      result.add(doc.fDocumentElement)

  result.add(doc.fDocumentElement.findNodesNS(namespaceURI, localName))

proc importNode*(doc: PDocument, importedNode: PNode, deep: bool): PNode =
  ## Imports a node from another document to this document
  case importedNode.fNodeType
  of AttributeNode:
    var nAttr: PAttr = PAttr(importedNode)
    nAttr.fOwnerDocument = doc
    nAttr.fParentNode = nil
    nAttr.fOwnerElement = nil
    nAttr.fSpecified = true
    return nAttr
  of DocumentFragmentNode:
    var n: PNode
    new(n)
    n = importedNode
    n.fOwnerDocument = doc
    n.fParentNode = nil

    n.fOwnerDocument = doc
    n.fParentNode = nil
    var tmp: seq[PNode] = n.childNodes
    n.childNodes = @[]
    if deep:
      for i in low(tmp.len())..high(tmp.len()):
        n.childNodes.add(importNode(doc, tmp[i], deep))

    return n
  of ElementNode:
    var n: PNode
    new(n)
    n = importedNode
    n.fOwnerDocument = doc
    n.fParentNode = nil

    var tmpA: seq[PAttr] = n.attributes
    n.attributes = @[]
    # Import the Element node's attributes
    for i in low(tmpA.len())..high(tmpA.len()):
      n.attributes.add(PAttr(importNode(doc, tmpA[i], deep)))
    # Import the childNodes
    var tmp: seq[PNode] = n.childNodes
    n.childNodes = @[]
    if deep:
      for i in low(tmp.len())..high(tmp.len()):
        n.childNodes.add(importNode(doc, tmp[i], deep))

    return n
  of ProcessingInstructionNode, TextNode, CDataSectionNode, CommentNode:
    var n: PNode
    new(n)
    n = importedNode
    n.fOwnerDocument = doc
    n.fParentNode = nil
    return n
  else:
    raise newException(ENotSupportedErr, "The type of node being imported is not supported")


# Node
# Attributes

proc firstChild*(n: PNode): PNode =
  ## Returns this node's first child

  if not isNil(n.childNodes) and n.childNodes.len() > 0:
    return n.childNodes[0]
  else:
    return nil

proc lastChild*(n: PNode): PNode =
  ## Returns this node's last child

  if not isNil(n.childNodes) and n.childNodes.len() > 0:
    return n.childNodes[n.childNodes.len() - 1]
  else:
    return nil

proc localName*(n: PNode): string =
  ## Returns this nodes local name

  return n.fLocalName

proc namespaceURI*(n: PNode): string =
  ## Returns this nodes namespace URI

  return n.fNamespaceURI

proc `namespaceURI=`*(n: PNode, value: string) =
  n.fNamespaceURI = value

proc nextSibling*(n: PNode): PNode =
  ## Returns the next sibling of this node

  if isNil(n.fParentNode) or isNil(n.fParentNode.childNodes):
    return nil
  var nLow: int = low(n.fParentNode.childNodes)
  var nHigh: int = high(n.fParentNode.childNodes)
  for i in nLow..nHigh:
    if n.fParentNode.childNodes[i] == n:
      return n.fParentNode.childNodes[i + 1]
  return nil

proc nodeName*(n: PNode): string =
  ## Returns the name of this node

  return n.fNodeName

proc nodeType*(n: PNode): int =
  ## Returns the type of this node

  return n.fNodeType

proc ownerDocument*(n: PNode): PDocument =
  ## Returns the owner document of this node

  return n.fOwnerDocument

proc parentNode*(n: PNode): PNode =
  ## Returns the parent node of this node

  return n.fParentNode

proc previousSibling*(n: PNode): PNode =
  ## Returns the previous sibling of this node

  if isNil(n.fParentNode) or isNil(n.fParentNode.childNodes):
    return nil
  var nLow: int = low(n.fParentNode.childNodes)
  var nHigh: int = high(n.fParentNode.childNodes)
  for i in nLow..nHigh:
    if n.fParentNode.childNodes[i] == n:
      return n.fParentNode.childNodes[i - 1]
  return nil

proc `prefix=`*(n: PNode, value: string) =
  ## Modifies the prefix of this node

  # Setter
  # Check if name contains illegal characters
  if illegalChars in value:
    raise newException(EInvalidCharacterErr, "Invalid character")

  if isNil(n.fNamespaceURI):
    raise newException(ENamespaceErr, "namespaceURI cannot be nil")
  elif value.toLowerAscii() == "xml" and n.fNamespaceURI != "http://www.w3.org/XML/1998/namespace":
    raise newException(ENamespaceErr,
      "When the namespace prefix is \"xml\" namespaceURI has to be \"http://www.w3.org/XML/1998/namespace\"")
  elif value.toLowerAscii() == "xmlns" and n.fNamespaceURI != "http://www.w3.org/2000/xmlns/":
    raise newException(ENamespaceErr,
      "When the namespace prefix is \"xmlns\" namespaceURI has to be \"http://www.w3.org/2000/xmlns/\"")
  elif value.toLowerAscii() == "xmlns" and n.fNodeType == AttributeNode:
    raise newException(ENamespaceErr, "An AttributeNode cannot have a prefix of \"xmlns\"")

  n.fNodeName = value & ":" & n.fLocalName
  if n.nodeType == ElementNode:
    var el: PElement = PElement(n)
    el.fTagName = value & ":" & n.fLocalName

  elif n.nodeType == AttributeNode:
    var attr: PAttr = PAttr(n)
    attr.fName = value & ":" & n.fLocalName

# Procedures
proc appendChild*(n: PNode, newChild: PNode) =
  ## Adds the node newChild to the end of the list of children of this node.
  ## If the newChild is already in the tree, it is first removed.

  # Check if n contains newChild
  if not isNil(n.childNodes):
    for i in low(n.childNodes)..high(n.childNodes):
      if n.childNodes[i] == newChild:
        raise newException(EHierarchyRequestErr, "The node to append is already in this nodes children.")

  # Check if newChild is from this nodes document
  if n.fOwnerDocument != newChild.fOwnerDocument:
    raise newException(EWrongDocumentErr, "This node belongs to a different document, use importNode.")

  if n == newChild:
    raise newException(EHierarchyRequestErr, "You can't add a node into itself")

  if n.nodeType in childlessObjects:
    raise newException(ENoModificationAllowedErr, "Cannot append children to a childless node")

  if isNil(n.childNodes): n.childNodes = @[]

  newChild.fParentNode = n
  for i in low(n.childNodes)..high(n.childNodes):
    if n.childNodes[i] == newChild:
      n.childNodes[i] = newChild

  n.childNodes.add(newChild)

proc cloneNode*(n: PNode, deep: bool): PNode =
  ## Returns a duplicate of this node, if ``deep`` is `true`, Element node's children are copied
  case n.fNodeType
  of AttributeNode:
    var newNode: PAttr
    new(newNode)
    newNode = PAttr(n)
    newNode.fSpecified = true
    newNode.fOwnerElement = nil
    return newNode
  of ElementNode:
    var newNode: PElement
    new(newNode)
    newNode = PElement(n)
    # Import the childNodes
    var tmp: seq[PNode] = n.childNodes
    n.childNodes = @[]
    if deep and not isNil(tmp):
      for i in low(tmp.len())..high(tmp.len()):
        n.childNodes.add(cloneNode(tmp[i], deep))
    return newNode
  else:
    var newNode: PNode
    new(newNode)
    newNode = n
    return newNode

proc hasAttributes*(n: PNode): bool =
  ## Returns whether this node (if it is an element) has any attributes.
  return not isNil(n.attributes) and n.attributes.len() > 0

proc hasChildNodes*(n: PNode): bool =
  ## Returns whether this node has any children.
  return not isNil(n.childNodes) and n.childNodes.len() > 0

proc insertBefore*(n: PNode, newChild: PNode, refChild: PNode): PNode =
  ## Inserts the node ``newChild`` before the existing child node ``refChild``.
  ## If ``refChild`` is nil, insert ``newChild`` at the end of the list of children.

  # Check if newChild is from this nodes document
  if n.fOwnerDocument != newChild.fOwnerDocument:
    raise newException(EWrongDocumentErr, "This node belongs to a different document, use importNode.")

  if isNil(n.childNodes):
    n.childNodes = @[]

  for i in low(n.childNodes)..high(n.childNodes):
    if n.childNodes[i] == refChild:
      n.childNodes.insert(newChild, i - 1)
      return

  n.childNodes.add(newChild)

proc isSupported*(n: PNode, feature: string, version: string): bool =
  ## Tests whether the DOM implementation implements a specific
  ## feature and that feature is supported by this node.
  return n.fOwnerDocument.fImplementation.hasFeature(feature, version)

proc isEmpty(s: string): bool =

  if isNil(s) or s == "":
    return true
  for i in items(s):
    if i != ' ':
      return false
  return true

proc normalize*(n: PNode) =
  ## Merges all separated TextNodes together, and removes any empty TextNodes
  var curTextNode: PNode = nil
  var i: int = 0

  var newChildNodes: seq[PNode] = @[]
  while true:
    if isNil(n.childNodes) or i >= n.childNodes.len:
      break
    if n.childNodes[i].nodeType == TextNode:

      #If the TextNode is empty, remove it
      if PText(n.childNodes[i]).data.isEmpty():
        inc(i)

      if isNil(curTextNode):
        curTextNode = n.childNodes[i]
      else:
        PText(curTextNode).data.add(PText(n.childNodes[i]).data)
        curTextNode.nodeValue.add(PText(n.childNodes[i]).data)
        inc(i)
    else:
      newChildNodes.add(curTextNode)
      newChildNodes.add(n.childNodes[i])
      curTextNode = nil

    inc(i)
  n.childNodes = newChildNodes

proc removeChild*(n: PNode, oldChild: PNode): PNode =
  ## Removes the child node indicated by ``oldChild`` from the list of children, and returns it.
  if not isNil(n.childNodes):
    for i in low(n.childNodes)..high(n.childNodes):
      if n.childNodes[i] == oldChild:
        result = n.childNodes[i]
        n.childNodes.delete(i)
        return

  raise newException(ENotFoundErr, "Node not found")

proc replaceChild*(n: PNode, newChild: PNode, oldChild: PNode): PNode =
  ## Replaces the child node ``oldChild`` with ``newChild`` in the list of children, and returns the ``oldChild`` node.

  # Check if newChild is from this nodes document
  if n.fOwnerDocument != newChild.fOwnerDocument:
    raise newException(EWrongDocumentErr, "This node belongs to a different document, use importNode.")

  if not isNil(n.childNodes):
    for i in low(n.childNodes)..high(n.childNodes):
      if n.childNodes[i] == oldChild:
        result = n.childNodes[i]
        n.childNodes[i] = newChild
        return

  raise newException(ENotFoundErr, "Node not found")

# NamedNodeMap

proc getNamedItem*(nList: seq[PNode], name: string): PNode =
  ## Retrieves a node specified by ``name``. If this node cannot be found returns ``nil``
  for i in items(nList):
    if i.nodeName() == name:
      return i
  return nil

proc getNamedItem*(nList: seq[PAttr], name: string): PAttr =
  ## Retrieves a node specified by ``name``. If this node cannot be found returns ``nil``
  for i in items(nList):
    if i.nodeName() == name:
      return i
  return nil

proc getNamedItemNS*(nList: seq[PNode], namespaceURI: string, localName: string): PNode =
  ## Retrieves a node specified by ``localName`` and ``namespaceURI``. If this node cannot be found returns ``nil``
  for i in items(nList):
    if i.namespaceURI() == namespaceURI and i.localName() == localName:
      return i
  return nil

proc getNamedItemNS*(nList: seq[PAttr], namespaceURI: string, localName: string): PAttr =
  ## Retrieves a node specified by ``localName`` and ``namespaceURI``. If this node cannot be found returns ``nil``
  for i in items(nList):
    if i.namespaceURI() == namespaceURI and i.localName() == localName:
      return i
  return nil

proc item*(nList: seq[PNode], index: int): PNode =
  ## Returns the ``index`` th item in the map.
  ## If ``index`` is greater than or equal to the number of nodes in this map, this returns ``nil``.
  if index >= nList.len(): return nil
  else: return nList[index]

proc removeNamedItem*(nList: var seq[PNode], name: string): PNode =
  ## Removes a node specified by ``name``
  ## Raises the ``ENotFoundErr`` exception, if the node was not found
  for i in low(nList)..high(nList):
    if nList[i].fNodeName == name:
      result = nList[i]
      nList.delete(i)
      return

  raise newException(ENotFoundErr, "Node not found")

proc removeNamedItemNS*(nList: var seq[PNode], namespaceURI: string, localName: string): PNode =
  ## Removes a node specified by local name and namespace URI
  for i in low(nList)..high(nList):
    if nList[i].fLocalName == localName and nList[i].fNamespaceURI == namespaceURI:
      result = nList[i]
      nList.delete(i)
      return

  raise newException(ENotFoundErr, "Node not found")

proc setNamedItem*(nList: var seq[PNode], arg: PNode): PNode =
  ## Adds ``arg`` as a ``Node`` to the ``NList``
  ## If a node with the same name is already present in this map, it is replaced by the new one.
  if not isNil(nList):
    if nList.len() > 0:
      #Check if newChild is from this nodes document
      if nList[0].fOwnerDocument != arg.fOwnerDocument:
        raise newException(EWrongDocumentErr, "This node belongs to a different document, use importNode.")
  #Exceptions End

  var item: PNode = nList.getNamedItem(arg.nodeName())
  if isNil(item):
    nList.add(arg)
    return nil
  else:
    # Node with the same name exists
    var index: int = 0
    for i in low(nList)..high(nList):
      if nList[i] == item:
        index = i
        break
    nList[index] = arg
    return item # Return the replaced node

proc setNamedItem*(nList: var seq[PAttr], arg: PAttr): PAttr =
  ## Adds ``arg`` as a ``Node`` to the ``NList``
  ## If a node with the same name is already present in this map, it is replaced by the new one.
  if not isNil(nList):
    if nList.len() > 0:
      # Check if newChild is from this nodes document
      if nList[0].fOwnerDocument != arg.fOwnerDocument:
        raise newException(EWrongDocumentErr, "This node belongs to a different document, use importNode.")

  if not isNil(arg.fOwnerElement):
    raise newException(EInuseAttributeErr, "This attribute is in use by another element, use cloneNode")

  # Exceptions end
  var item: PAttr = nList.getNamedItem(arg.nodeName())
  if isNil(item):
    nList.add(arg)
    return nil
  else:
    # Node with the same name exists
    var index: int = 0
    for i in low(nList)..high(nList):
      if nList[i] == item:
        index = i
        break
    nList[index] = arg
    return item # Return the replaced node

proc setNamedItemNS*(nList: var seq[PNode], arg: PNode): PNode =
  ## Adds a node using its ``namespaceURI`` and ``localName``
  if not isNil(nList):
    if nList.len() > 0:
      # Check if newChild is from this nodes document
      if nList[0].fOwnerDocument != arg.fOwnerDocument:
        raise newException(EWrongDocumentErr, "This node belongs to a different document, use importNode.")
  #Exceptions end

  var item: PNode = nList.getNamedItemNS(arg.namespaceURI(), arg.localName())
  if isNil(item):
    nList.add(arg)
    return nil
  else:
    # Node with the same name exists
    var index: int = 0
    for i in low(nList)..high(nList):
      if nList[i] == item:
        index = i
        break
    nList[index] = arg
    return item # Return the replaced node

proc setNamedItemNS*(nList: var seq[PAttr], arg: PAttr): PAttr =
  ## Adds a node using its ``namespaceURI`` and ``localName``
  if not isNil(nList):
    if nList.len() > 0:
      # Check if newChild is from this nodes document
      if nList[0].fOwnerDocument != arg.fOwnerDocument:
        raise newException(EWrongDocumentErr, "This node belongs to a different document, use importNode.")

  if not isNil(arg.fOwnerElement):
    raise newException(EInuseAttributeErr, "This attribute is in use by another element, use cloneNode")

  # Exceptions end
  var item: PAttr = nList.getNamedItemNS(arg.namespaceURI(), arg.localName())
  if isNil(item):
    nList.add(arg)
    return nil
  else:
    # Node with the same name exists
    var index: int = 0
    for i in low(nList)..high(nList):
      if nList[i] == item:
        index = i
        break
    nList[index] = arg
    return item # Return the replaced node

# CharacterData - Decided to implement this,
# Didn't add the procedures, because you can just edit .data

# Attr
# Attributes
proc name*(a: PAttr): string =
  ## Returns the name of the Attribute

  return a.fName

proc specified*(a: PAttr): bool =
  ## Specifies whether this attribute was specified in the original document

  return a.fSpecified

proc ownerElement*(a: PAttr): PElement =
  ## Returns this Attributes owner element

  return a.fOwnerElement

# Element
# Attributes

proc tagName*(el: PElement): string =
  ## Returns the Element Tag Name

  return el.fTagName

# Procedures
proc getAttribute*(el: PNode, name: string): string =
  ## Retrieves an attribute value by ``name``
  if isNil(el.attributes):
    return nil
  var attribute = el.attributes.getNamedItem(name)
  if not isNil(attribute):
    return attribute.value
  else:
    return nil

proc getAttributeNS*(el: PNode, namespaceURI: string, localName: string): string =
  ## Retrieves an attribute value by ``localName`` and ``namespaceURI``
  if isNil(el.attributes):
    return nil
  var attribute = el.attributes.getNamedItemNS(namespaceURI, localName)
  if not isNil(attribute):
    return attribute.value
  else:
    return nil

proc getAttributeNode*(el: PElement, name: string): PAttr =
  ## Retrieves an attribute node by ``name``
  ## To retrieve an attribute node by qualified name and namespace URI, use the `getAttributeNodeNS` method
  if isNil(el.attributes):
    return nil
  return el.attributes.getNamedItem(name)

proc getAttributeNodeNS*(el: PElement, namespaceURI: string, localName: string): PAttr =
  ## Retrieves an `Attr` node by ``localName`` and ``namespaceURI``
  if isNil(el.attributes):
    return nil
  return el.attributes.getNamedItemNS(namespaceURI, localName)

proc getElementsByTagName*(el: PElement, name: string): seq[PNode] =
  ## Returns a `NodeList` of all descendant `Elements` of ``el`` with a given tag ``name``,
  ## in the order in which they are encountered in a preorder traversal of this `Element` tree
  ## If ``name`` is `*`, returns all descendant of ``el``
  result = el.findNodes(name)

proc getElementsByTagNameNS*(el: PElement, namespaceURI: string, localName: string): seq[PNode] =
  ## Returns a `NodeList` of all the descendant Elements with a given
  ## ``localName`` and ``namespaceURI`` in the order in which they are
  ## encountered in a preorder traversal of this Element tree
  result = el.findNodesNS(namespaceURI, localName)

proc hasAttribute*(el: PElement, name: string): bool =
  ## Returns ``true`` when an attribute with a given ``name`` is specified
  ## on this element , ``false`` otherwise.
  if isNil(el.attributes):
    return false
  return not isNil(el.attributes.getNamedItem(name))

proc hasAttributeNS*(el: PElement, namespaceURI: string, localName: string): bool =
  ## Returns ``true`` when an attribute with a given ``localName`` and
  ## ``namespaceURI`` is specified on this element , ``false`` otherwise
  if isNil(el.attributes):
    return false
  return not isNil(el.attributes.getNamedItemNS(namespaceURI, localName))

proc removeAttribute*(el: PElement, name: string) =
  ## Removes an attribute by ``name``
  if not isNil(el.attributes):
    for i in low(el.attributes)..high(el.attributes):
      if el.attributes[i].fName == name:
        el.attributes.delete(i)

proc removeAttributeNS*(el: PElement, namespaceURI: string, localName: string) =
  ## Removes an attribute by ``localName`` and ``namespaceURI``
  if not isNil(el.attributes):
    for i in low(el.attributes)..high(el.attributes):
      if el.attributes[i].fNamespaceURI == namespaceURI and
          el.attributes[i].fLocalName == localName:
        el.attributes.delete(i)

proc removeAttributeNode*(el: PElement, oldAttr: PAttr): PAttr =
  ## Removes the specified attribute node
  ## If the attribute node cannot be found raises ``ENotFoundErr``
  if not isNil(el.attributes):
    for i in low(el.attributes)..high(el.attributes):
      if el.attributes[i] == oldAttr:
        result = el.attributes[i]
        el.attributes.delete(i)
        return

  raise newException(ENotFoundErr, "oldAttr is not a member of el's Attributes")

proc setAttributeNode*(el: PElement, newAttr: PAttr): PAttr =
  ## Adds a new attribute node, if an attribute with the same `nodeName` is
  ## present, it is replaced by the new one and the replaced attribute is
  ## returned, otherwise ``nil`` is returned.

  # Check if newAttr is from this nodes document
  if el.fOwnerDocument != newAttr.fOwnerDocument:
    raise newException(EWrongDocumentErr,
      "This node belongs to a different document, use importNode.")

  if not isNil(newAttr.fOwnerElement):
    raise newException(EInuseAttributeErr,
      "This attribute is in use by another element, use cloneNode")
  # Exceptions end

  if isNil(el.attributes): el.attributes = @[]
  return el.attributes.setNamedItem(newAttr)

proc setAttributeNodeNS*(el: PElement, newAttr: PAttr): PAttr =
  ## Adds a new attribute node, if an attribute with the localName and
  ## namespaceURI of ``newAttr`` is present, it is replaced by the new one
  ## and the replaced attribute is returned, otherwise ``nil`` is returned.

  # Check if newAttr is from this nodes document
  if el.fOwnerDocument != newAttr.fOwnerDocument:
    raise newException(EWrongDocumentErr,
      "This node belongs to a different document, use importNode.")

  if not isNil(newAttr.fOwnerElement):
    raise newException(EInuseAttributeErr,
      "This attribute is in use by another element, use cloneNode")
  # Exceptions end

  if isNil(el.attributes): el.attributes = @[]
  return el.attributes.setNamedItemNS(newAttr)

proc setAttribute*(el: PElement, name: string, value: string) =
  ## Adds a new attribute, as specified by ``name`` and ``value``
  ## If an attribute with that name is already present in the element, its
  ## value is changed to be that of the value parameter
  ## Raises the EInvalidCharacterErr if the specified ``name`` contains
  ## illegal characters
  var attrNode = el.fOwnerDocument.createAttribute(name)
  # Check if name contains illegal characters
  if illegalChars in name:
    raise newException(EInvalidCharacterErr, "Invalid character")

  discard el.setAttributeNode(attrNode)
  # Set the info later, the setAttributeNode checks
  # if FOwnerElement is nil, and if it isn't it raises an exception
  attrNode.fOwnerElement = el
  attrNode.fSpecified = true
  attrNode.value = value

proc setAttributeNS*(el: PElement, namespaceURI, localName, value: string) =
  ## Adds a new attribute, as specified by ``namespaceURI``, ``localName``
  ## and ``value``.

  # Check if name contains illegal characters
  if illegalChars in namespaceURI or illegalChars in localName:
    raise newException(EInvalidCharacterErr, "Invalid character")

  var attrNode = el.fOwnerDocument.createAttributeNS(namespaceURI, localName)

  discard el.setAttributeNodeNS(attrNode)
  # Set the info later, the setAttributeNode checks
  # if FOwnerElement is nil, and if it isn't it raises an exception
  attrNode.fOwnerElement = el
  attrNode.fSpecified = true
  attrNode.value = value

# Text
proc splitData*(textNode: PText, offset: int): PText =
  ## Breaks this node into two nodes at the specified offset,
  ## keeping both in the tree as siblings.

  if offset > textNode.data.len():
    raise newException(EIndexSizeErr, "Index out of bounds")

  var left: string = textNode.data.substr(0, offset)
  textNode.data = left
  var right: string = textNode.data.substr(offset, textNode.data.len())

  if not isNil(textNode.fParentNode) and not isNil(textNode.fParentNode.childNodes):
    for i in low(textNode.fParentNode.childNodes)..high(textNode.fParentNode.childNodes):
      if textNode.fParentNode.childNodes[i] == textNode:
        var newNode: PText = textNode.fOwnerDocument.createTextNode(right)
        textNode.fParentNode.childNodes.insert(newNode, i)
        return newNode
  else:
    var newNode: PText = textNode.fOwnerDocument.createTextNode(right)
    return newNode

# ProcessingInstruction
proc target*(pi: PProcessingInstruction): string =
  ## Returns the Processing Instructions target

  return pi.fTarget

proc escapeXml*(s: string; result: var string) =
  ## Prepares a string for insertion into a XML document
  ## by escaping the XML special characters.
  result = ""
  for c in items(s):
    case c
    of '<': result.add("&lt;")
    of '>': result.add("&gt;")
    of '&': result.add("&amp;")
    of '"': result.add("&quot;")
    else: result.add(c)

proc escapeXml*(s: string): string =
  ## Prepares a string for insertion into a XML document
  ## by escaping the XML special characters.
  result = newStringOfCap(s.len + s.len shr 4)
  escapeXml(s, result)

# --Other stuff--
# Writer

proc nodeToXml(n: PNode, indent: int = 0): string =
  result = spaces(indent) & "<" & n.nodeName
  if not isNil(n.attributes):
    for i in items(n.attributes):
      result.add(" " & i.name & "=\"" & escapeXml(i.value) & "\"")

  if isNil(n.childNodes) or n.childNodes.len() == 0:
    result.add("/>") # No idea why this doesn't need a \n :O
  else:
    # End the beginning of this tag
    result.add(">\n")
    for i in items(n.childNodes):
      case i.nodeType
      of ElementNode:
        result.add(nodeToXml(i, indent + 2))
      of TextNode:
        result.add(spaces(indent * 2))
        result.add(escapeXml(i.nodeValue))
      of CDataSectionNode:
        result.add(spaces(indent * 2))
        result.add("<![CDATA[" & i.nodeValue & "]]>")
      of ProcessingInstructionNode:
        result.add(spaces(indent * 2))
        result.add("<?" & PProcessingInstruction(i).target & " " &
                          PProcessingInstruction(i).data & " ?>")
      of CommentNode:
        result.add(spaces(indent * 2))
        result.add("<!-- " & i.nodeValue & " -->")
      else:
        continue
      result.add("\n")
    # Add the ending tag - </tag>
    result.add(spaces(indent) & "</" & n.nodeName & ">")

proc `$`*(doc: PDocument): string =
  ## Converts a PDocument object into a string representation of it's XML
  result = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
  result.add(nodeToXml(doc.documentElement))
