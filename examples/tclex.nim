# Example to embed TCL in Nimrod

import tcl, os

const
  myScript = """puts "Hello, World - In quotes" """
  myScript2 = """
package require Tk
pack [entry .e -textvar e -width 50]
bind .e <Return> {
  set e  [regsub { *=.*} $e ""] ;# remove evaluation (Chris)
  catch {expr [string map {/ *1./} $e]} res
  append e " = $res"
}  
"""

Tcl_FindExecutable(getApplicationFilename())
var interp = Tcl_CreateInterp()
if interp == nil: quit("cannot create TCL interpreter")
if Tcl_Init(interp) != TCL_OK: 
  quit("cannot init interpreter")
if Tcl_Eval(interp, myScript) != TCL_OK: 
  quit("cannot execute script.tcl")


