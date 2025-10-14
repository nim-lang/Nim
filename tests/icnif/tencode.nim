import std/assertions
import "../../compiler/icnif" / [nifencoder, nifdecoder]
import "../../compiler" / [idents, options, pathutils, modulegraphs]

var graph = newModuleGraph(newIdentCache(), newConfigRef())
graph.config.searchPaths.add AbsoluteDir "/tmp/testnim"

block:
  const TestNif = """
(.nif24)
(.vendor "nim2")
(.dialect "nim2-ic-nif")
(stmts
 (import
  (sym :testmod2.0.tesfd9rxn1 +1 . . "/tmp/testnim/testmod2.nim"))
 (var
  (identdefs
   (sym :x.0.tesvp2f3v +2 testmod.0.tesvp2f3v ueg +0)
   (i -1
    (tf c3)) +123))
 (var
  (identdefs
   (sym :y.0.tesvp2f3v +3 testmod.0.tesvp2f3v g +0)
   (i -1
    (tf c3)) x.0.tesvp2f3v)))"""

  assert loadNifFromBuffer(TestNif, AbsoluteFile"/tmp/testnim/testmod.nim", graph).saveNifToBuffer(graph.config) == TestNif
