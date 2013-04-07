discard """
  output: '''some text
Destructor called!'''
"""

type
  TMyObj = object
    x, y: int
    p: pointer
    
proc destruct(o: var TMyObj) {.destructor.} =
  if o.p != nil: dealloc o.p
  echo "Destructor called!"
  
proc open: TMyObj =
  # allow for superfluous ()
  result = (TMyObj(x: 1, y: 2, p: alloc(3)))


proc `$`(x: TMyObj): string = $x.y

proc main() =
  var x = open()
  echo "some text"

main()
