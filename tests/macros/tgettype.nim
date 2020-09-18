discard """
output: '''
(ObjectTy (Empty) (Sym "Model") (RecList (Sym "name") (Sym "password")))
(BracketExpr (Sym "typeDesc") (Sym "User"))
'''
"""
import macros

type
  Model = object of RootObj
  User = object of Model
    name : string
    password : string

macro testUser: string =
  result = newLit(User.getType.lispRepr)

macro testGeneric(T: typedesc[Model]): string=
  result = newLit(T.getType.lispRepr)

echo testUser
echo User.testGeneric

macro assertVoid(e: typed): untyped =
  assert(getTypeInst(e).typeKind == ntyVoid)

proc voidProc() = discard

assertVoid voidProc()
