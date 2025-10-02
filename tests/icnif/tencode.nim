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
 (var
  (identdefs
   (sym x +1) . +123))
 (var
  (identdefs
   (sym y +2) . +321)))"""

  assert loadNifFromBuffer(TestNif, graph).saveNifToBuffer() == TestNif
