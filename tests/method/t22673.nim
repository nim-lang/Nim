discard """
  matrix: "--warningAsError:UseBase"
"""

# bug #22673
type RefEntry = ref object of RootObj

type RefFile = ref object of RefEntry
    filename*: string
    data*: string

type RefDir = ref object of RefEntry
    dirname*: string
    files*: seq[RefFile]

method name*(e: RefEntry): lent string {.base.} =
  raiseAssert "Don't call the base method"

method name*(e: RefFile): lent string = e.filename

method name*(e: RefDir): lent string = e.dirname