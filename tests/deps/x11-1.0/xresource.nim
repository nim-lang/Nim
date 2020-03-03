
import 
  x, xlib

#const 
#  libX11* = "libX11.so"

#
#  Automatically converted by H2Pas 0.99.15 from xresource.h
#  The following command line parameters were used:
#    -p
#    -T
#    -S
#    -d
#    -c
#    xresource.h
#

proc Xpermalloc*(para1: int32): cstring{.cdecl, dynlib: libX11, importc.}
type 
  PXrmQuark* = ptr TXrmQuark
  TXrmQuark* = int32
  TXrmQuarkList* = PXrmQuark
  PXrmQuarkList* = ptr TXrmQuarkList

proc NULLQUARK*(): TXrmQuark
type 
  PXrmString* = ptr TXrmString
  TXrmString* = ptr char

proc NULLSTRING*(): TXrmString
proc XrmStringToQuark*(para1: cstring): TXrmQuark{.cdecl, dynlib: libX11, 
    importc.}
proc XrmPermStringToQuark*(para1: cstring): TXrmQuark{.cdecl, dynlib: libX11, 
    importc.}
proc XrmQuarkToString*(para1: TXrmQuark): TXrmString{.cdecl, dynlib: libX11, 
    importc.}
proc XrmUniqueQuark*(): TXrmQuark{.cdecl, dynlib: libX11, importc.}
#when defined(MACROS): 
proc XrmStringsEqual*(a1, a2: cstring): bool
type 
  PXrmBinding* = ptr TXrmBinding
  TXrmBinding* = enum 
    XrmBindTightly, XrmBindLoosely
  TXrmBindingList* = PXrmBinding
  PXrmBindingList* = ptr TXrmBindingList

proc XrmStringToQuarkList*(para1: cstring, para2: TXrmQuarkList){.cdecl, 
    dynlib: libX11, importc.}
proc XrmStringToBindingQuarkList*(para1: cstring, para2: TXrmBindingList, 
                                  para3: TXrmQuarkList){.cdecl, dynlib: libX11, 
    importc.}
type 
  PXrmName* = ptr TXrmName
  TXrmName* = TXrmQuark
  PXrmNameList* = ptr TXrmNameList
  TXrmNameList* = TXrmQuarkList

#when defined(MACROS): 
proc XrmNameToString*(name: int32): TXrmString
proc XrmStringToName*(str: cstring): int32
proc XrmStringToNameList*(str: cstring, name: PXrmQuark)
type 
  PXrmClass* = ptr TXrmClass
  TXrmClass* = TXrmQuark
  PXrmClassList* = ptr TXrmClassList
  TXrmClassList* = TXrmQuarkList

#when defined(MACROS): 
proc XrmClassToString*(c_class: int32): TXrmString
proc XrmStringToClass*(c_class: cstring): int32
proc XrmStringToClassList*(str: cstring, c_class: PXrmQuark)
type 
  PXrmRepresentation* = ptr TXrmRepresentation
  TXrmRepresentation* = TXrmQuark

#when defined(MACROS): 
proc XrmStringToRepresentation*(str: cstring): int32
proc XrmRepresentationToString*(thetype: int32): TXrmString
type 
  PXrmValue* = ptr TXrmValue
  TXrmValue*{.final.} = object 
    size*: int32
    address*: TXPointer

  TXrmValuePtr* = PXrmValue
  PXrmValuePtr* = ptr TXrmValuePtr
  PXrmHashBucketRec* = ptr TXrmHashBucketRec
  TXrmHashBucketRec*{.final.} = object 
  TXrmHashBucket* = PXrmHashBucketRec
  PXrmHashBucket* = ptr TXrmHashBucket
  PXrmHashTable* = ptr TXrmHashTable
  TXrmHashTable* = ptr TXrmHashBucket
  TXrmDatabase* = PXrmHashBucketRec
  PXrmDatabase* = ptr TXrmDatabase

proc XrmDestroyDatabase*(para1: TXrmDatabase){.cdecl, dynlib: libX11, importc.}
proc XrmQPutResource*(para1: PXrmDatabase, para2: TXrmBindingList, 
                      para3: TXrmQuarkList, para4: TXrmRepresentation, 
                      para5: PXrmValue){.cdecl, dynlib: libX11, importc.}
proc XrmPutResource*(para1: PXrmDatabase, para2: cstring, para3: cstring, 
                     para4: PXrmValue){.cdecl, dynlib: libX11, importc.}
proc XrmQPutStringResource*(para1: PXrmDatabase, para2: TXrmBindingList, 
                            para3: TXrmQuarkList, para4: cstring){.cdecl, 
    dynlib: libX11, importc.}
proc XrmPutStringResource*(para1: PXrmDatabase, para2: cstring, para3: cstring){.
    cdecl, dynlib: libX11, importc.}
proc XrmPutLineResource*(para1: PXrmDatabase, para2: cstring){.cdecl, 
    dynlib: libX11, importc.}
proc XrmQGetResource*(para1: TXrmDatabase, para2: TXrmNameList, 
                      para3: TXrmClassList, para4: PXrmRepresentation, 
                      para5: PXrmValue): TBool{.cdecl, dynlib: libX11, importc.}
proc XrmGetResource*(para1: TXrmDatabase, para2: cstring, para3: cstring, 
                     para4: PPchar, para5: PXrmValue): TBool{.cdecl, 
    dynlib: libX11, importc.}
  # There is no definition of TXrmSearchList 
  #function XrmQGetSearchList(para1:TXrmDatabase; para2:TXrmNameList; para3:TXrmClassList; para4:TXrmSearchList; para5:longint):TBool;cdecl;external libX11;
  #function XrmQGetSearchResource(para1:TXrmSearchList; para2:TXrmName; para3:TXrmClass; para4:PXrmRepresentation; para5:PXrmValue):TBool;cdecl;external libX11;
proc XrmSetDatabase*(para1: PDisplay, para2: TXrmDatabase){.cdecl, 
    dynlib: libX11, importc.}
proc XrmGetDatabase*(para1: PDisplay): TXrmDatabase{.cdecl, dynlib: libX11, 
    importc.}
proc XrmGetFileDatabase*(para1: cstring): TXrmDatabase{.cdecl, dynlib: libX11, 
    importc.}
proc XrmCombineFileDatabase*(para1: cstring, para2: PXrmDatabase, para3: TBool): TStatus{.
    cdecl, dynlib: libX11, importc.}
proc XrmGetStringDatabase*(para1: cstring): TXrmDatabase{.cdecl, dynlib: libX11, 
    importc.}
proc XrmPutFileDatabase*(para1: TXrmDatabase, para2: cstring){.cdecl, 
    dynlib: libX11, importc.}
proc XrmMergeDatabases*(para1: TXrmDatabase, para2: PXrmDatabase){.cdecl, 
    dynlib: libX11, importc.}
proc XrmCombineDatabase*(para1: TXrmDatabase, para2: PXrmDatabase, para3: TBool){.
    cdecl, dynlib: libX11, importc.}
const 
  XrmEnumAllLevels* = 0
  XrmEnumOneLevel* = 1

type 
  funcbool* = proc (): TBool {.cdecl.}

proc XrmEnumerateDatabase*(para1: TXrmDatabase, para2: TXrmNameList, 
                           para3: TXrmClassList, para4: int32, para5: funcbool, 
                           para6: TXPointer): TBool{.cdecl, dynlib: libX11, 
    importc.}
proc XrmLocaleOfDatabase*(para1: TXrmDatabase): cstring{.cdecl, dynlib: libX11, 
    importc.}
type 
  PXrmOptionKind* = ptr TXrmOptionKind
  TXrmOptionKind* = enum 
    XrmoptionNoArg, XrmoptionIsArg, XrmoptionStickyArg, XrmoptionSepArg, 
    XrmoptionResArg, XrmoptionSkipArg, XrmoptionSkipLine, XrmoptionSkipNArgs
  PXrmOptionDescRec* = ptr TXrmOptionDescRec
  TXrmOptionDescRec*{.final.} = object 
    option*: cstring
    specifier*: cstring
    argKind*: TXrmOptionKind
    value*: TXPointer

  TXrmOptionDescList* = PXrmOptionDescRec
  PXrmOptionDescList* = ptr TXrmOptionDescList

proc XrmParseCommand*(para1: PXrmDatabase, para2: TXrmOptionDescList, 
                      para3: int32, para4: cstring, para5: ptr int32, 
                      para6: PPchar){.cdecl, dynlib: libX11, importc.}
# implementation

proc NULLQUARK(): TXrmQuark = 
  result = TXrmQuark(0)

proc NULLSTRING(): TXrmString = 
  result = nil

#when defined(MACROS): 
proc XrmStringsEqual(a1, a2: cstring): bool = 
  #result = (strcomp(a1, a2)) == 0
  $a1 == $a2

proc XrmNameToString(name: int32): TXrmString = 
  result = XrmQuarkToString(name)

proc XrmStringToName(str: cstring): int32 = 
  result = XrmStringToQuark(str)

proc XrmStringToNameList(str: cstring, name: PXrmQuark) = 
  XrmStringToQuarkList(str, name)

proc XrmClassToString(c_class: int32): TXrmString = 
  result = XrmQuarkToString(c_class)

proc XrmStringToClass(c_class: cstring): int32 = 
  result = XrmStringToQuark(c_class)

proc XrmStringToClassList(str: cstring, c_class: PXrmQuark) = 
  XrmStringToQuarkList(str, c_class)

proc XrmStringToRepresentation(str: cstring): int32 = 
  result = XrmStringToQuark(str)

proc XrmRepresentationToString(thetype: int32): TXrmString = 
  result = XrmQuarkToString(thetype)
