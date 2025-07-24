discard """
  cmd: "nim cpp --incremental:on $file"
"""

{.emit:"""/*TYPESECTION*/
#include <iostream>
  struct Foo { };
""".}

type Foo {.importcpp.} = object
echo $Foo() #Notice the generic is instantiate in the this module if not, it wouldnt find Foo