discard """
  description: '''IC vs `nim c`: module-level globals must be destroyed at exit'''
"""

#? metamorphic

# `graph.globalDestructors` is filled while a module's top level goes through
# `injectDestructorCalls`, and whole-program cgen empties the list into the main
# module's init proc — which IS the program body, so the calls land at program
# exit. Under `nim ic` every module's `cg` is a separate process, so the main
# module's `cg` only ever saw its OWN entries and a module-level `var` with a
# `=destroy` in any imported module was simply never destroyed.
#
# The teardown ORDER is the other half: it must be the reverse of the init order
# (importers before their dependencies), which is what the oracle pins down here
# — three modules in a chain plus main, each with a global of its own.

#!FILE gdlog.nim
type G* = object
  tag*: string

proc `=destroy`*(g: G) = echo "destroy ", g.tag
proc mk*(t: string): G = G(tag: t)

#!FILE gda.nim
import gdlog
var ga* = mk("a")

#!FILE gdb.nim
import gdlog, gda
var gb* = mk("b:" & ga.tag)

#!FILE gdc.nim
import gdlog, gdb
var gcv* = mk("c:" & gb.tag)

#!FILE main.nim
import gdlog, gda, gdb, gdc

var gmain = mk("main")

echo "body ", ga.tag, " ", gb.tag, " ", gcv.tag, " ", gmain.tag
#!STEP

# touching a leaf module must not lose anyone's teardown
#!FILE gda.nim
import gdlog
var ga* = mk("a2")
#!STEP
