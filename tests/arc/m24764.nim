type QObject* {.inheritable.} = object
proc `=destroy`(self: var QObject) = discard
proc `=sink`(dest: var QObject, source: QObject) = discard
proc `=copy`(dest: var QObject, source: QObject) {.error.}