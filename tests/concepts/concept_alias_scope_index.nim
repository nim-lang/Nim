# Helper for tconcept_alias_scope.nim
import concept_alias_scope_concept

type
  MyIndex*[K: Sized] = object
  MyAlias* = MyIndex[int]
