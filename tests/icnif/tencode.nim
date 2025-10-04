import std/assertions
import "../../compiler/icnif" / [nifencoder, nifdecoder]
import "../../compiler" / [idents, options, modulegraphs]

var graph = newModuleGraph(newIdentCache(), newConfigRef())

block:
  const TestNif = """
    (.nif24)
    (.vendor "nim2")
    (.dialect "nim2-ic-nif")
    (stmts
     (import
      (sym :testmod2.1 . "/home/nimdev/testnim/testmod2.nim"))
     (var
      (identdefs
       (sym :x.2.tesvp2f3v ueg +0) . +123))
     (var
      (identdefs
       (sym :y.3.tesvp2f3v g +0) . x.2.tesvp2f3v)))"""

  assert loadNifFromBuffer(TestNif, graph).saveNifToBuffer(graph.config) == TestNif
