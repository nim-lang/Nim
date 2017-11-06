
# bug #6691
type
  ConceptA = concept c

  ConceptB = concept c
      c.myProc(ConceptA)

  Obj = object

proc myProc(obj: Obj, x: ConceptA) = discard

echo Obj is ConceptB
