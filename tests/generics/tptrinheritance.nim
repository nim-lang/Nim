type NSPasteboardItem* = ptr object
type NSPasteboard* = ptr object
type NSArrayAbstract = ptr object {.inheritable.}
type NSMutableArrayAbstract = ptr object of NSArrayAbstract
type NSArray*[T] = ptr object of NSArrayAbstract
type NSMutableArray*[T] = ptr object of NSArray[T]

proc newMutableArrayAbstract*(): NSMutableArrayAbstract = discard

template newMutableArray*(T: typedesc): NSMutableArray[T] =
  cast[NSMutableArray[T]](newMutableArrayAbstract())

proc writeObjects*(p: NSPasteboard, o: NSArray[NSPasteboardItem]) = discard

let a = newMutableArray NSPasteboardItem
var x: NSMutableArray[NSPasteboardItem]
var y: NSArray[NSPasteboardItem] = x

writeObjects(nil, a)

