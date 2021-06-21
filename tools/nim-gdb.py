import gdb
import re
import sys
import traceback

# some feedback that the nim runtime support is loading, isn't a bad
# thing at all.
gdb.write("Loading Nim Runtime support.\n", gdb.STDERR)

# When error occure they occur regularly. This 'caches' known errors
# and prevents them from being reprinted over and over again.
errorSet = set()
def printErrorOnce(id, message):
  global errorSet
  if id not in errorSet:
    errorSet.add(id)
    gdb.write("printErrorOnce: " + message, gdb.STDERR)


################################################################################
#####  Type pretty printers
################################################################################

type_hash_regex = re.compile("^([A-Za-z0-9]*)_([A-Za-z0-9]*)_+([A-Za-z0-9]*)$")

def getNimRti(type_name):
  """ Return a ``gdb.Value`` object for the Nim Runtime Information of ``type_name``. """

  # Get static const TNimType variable. This should be available for
  # every non trivial Nim type.
  m = type_hash_regex.match(type_name)
  lookups = [
    "NTI" + m.group(2).lower() + "__" + m.group(3) + "_",
    "NTI" + "__" + m.group(3) + "_",
    "NTI" + m.group(2).replace("colon", "58").lower() + "__" + m.group(3) + "_"
    ]
  if m:
      for l in lookups:
        try:
          return gdb.parse_and_eval(l)
        except:
          pass
  None

def getNameFromNimRti(rti):
  """ Return name (or None) given a Nim RTI ``gdb.Value`` """
  try:
    # sometimes there isn't a name field -- example enums
    return rti['name'].string(encoding="utf-8", errors="ignore")
  except:
    return None

class NimTypeRecognizer:
  # this type map maps from types that are generated in the C files to
  # how they are called in nim. To not mix up the name ``int`` from
  # system.nim with the name ``int`` that could still appear in
  # generated code, ``NI`` is mapped to ``system.int`` and not just
  # ``int``.

  type_map_static = {
    'NI': 'system.int',  'NI8': 'int8', 'NI16': 'int16',  'NI32': 'int32',
    'NI64': 'int64',
    
    'NU': 'uint', 'NU8': 'uint8','NU16': 'uint16', 'NU32': 'uint32',
    'NU64': 'uint64',
    
    'NF': 'float', 'NF32': 'float32', 'NF64': 'float64',
    
    'NIM_BOOL': 'bool',

    'NIM_CHAR': 'char', 'NCSTRING': 'cstring', 'NimStringDesc': 'string'
  }

  # object_type_pattern = re.compile("^(\w*):ObjectType$")

  def recognize(self, type_obj):
    # skip things we can't handle like functions
    if type_obj.code in [gdb.TYPE_CODE_FUNC, gdb.TYPE_CODE_VOID]:
      return None

    tname = None
    if type_obj.tag is not None:
      tname = type_obj.tag
    elif type_obj.name is not None:
      tname = type_obj.name

    # handle pointer types
    if not tname:
      target_type = type_obj
      if type_obj.code in [gdb.TYPE_CODE_PTR]:
        target_type = type_obj.target()

      if target_type.name:
        # visualize 'string' as non pointer type (unpack pointer type).
        if target_type.name == "NimStringDesc":
          tname = target_type.name # could also just return 'string'
        else:
          rti = getNimRti(target_type.name)
          if rti:
            return getNameFromNimRti(rti)

    if tname:
      result = self.type_map_static.get(tname, None)
      if result:
        return result

      rti = getNimRti(tname)
      if rti:
        return getNameFromNimRti(rti)

    return None

class NimTypePrinter:
  """Nim type printer. One printer for all Nim types."""

  # enabling and disabling of type printers can be done with the
  # following gdb commands:
  #
  #   enable  type-printer NimTypePrinter
  #   disable type-printer NimTypePrinter
  # relevant docs: https://sourceware.org/gdb/onlinedocs/gdb/Type-Printing-API.html

  name = "NimTypePrinter"

  def __init__(self):
    self.enabled = True

  def instantiate(self):
    return NimTypeRecognizer()

################################################################################
#####  GDB Function, equivalent of Nim's $ operator
################################################################################

class DollarPrintFunction (gdb.Function):
  "Nim's equivalent of $ operator as a gdb function, available in expressions `print $dollar(myvalue)"

  dollar_functions = re.findall(
    'NimStringDesc \*(dollar__[A-z0-9_]+?)\(([^,)]*)\);',
    gdb.execute("info functions dollar__", True, True)
  )

  def __init__ (self):
    super (DollarPrintFunction, self).__init__("dollar")


  @staticmethod
  def invoke_static(arg):

    if arg.type.code == gdb.TYPE_CODE_PTR and arg.type.target().name == "NimStringDesc":
      return arg

    argTypeName = str(arg.type)

    for func, arg_typ in DollarPrintFunction.dollar_functions:
      # this way of overload resolution cannot deal with type aliases,
      # therefore it won't find all overloads.
      if arg_typ == argTypeName:
        func_value = gdb.lookup_global_symbol(func, gdb.SYMBOL_FUNCTIONS_DOMAIN).value()
        return func_value(arg)

      elif arg_typ == argTypeName + " *":
        func_value = gdb.lookup_global_symbol(func, gdb.SYMBOL_FUNCTIONS_DOMAIN).value()
        return func_value(arg.address)

    printErrorOnce(argTypeName, "No suitable Nim $ operator found for type: " + argTypeName + "\n")
    return None

  def invoke(self, arg):
    return self.invoke_static(arg)

DollarPrintFunction()


################################################################################
#####  GDB Function, Nim string comparison
################################################################################

class NimStringEqFunction (gdb.Function):
  """Compare Nim strings for example in conditionals for breakpoints."""

  def __init__ (self):
    super (NimStringEqFunction, self).__init__("nimstreq")

  @staticmethod
  def invoke_static(arg1,arg2):
    if arg1.type.code == gdb.TYPE_CODE_PTR and arg1.type.target().name == "NimStringDesc":
      str1 = NimStringPrinter(arg1).to_string()
    else:
      str1 = arg1.string()
    if arg2.type.code == gdb.TYPE_CODE_PTR and arg2.type.target().name == "NimStringDesc":
      str2 = NimStringPrinter(arg1).to_string()
    else:
      str2 = arg2.string()

    return str1 == str2

  def invoke(self, arg1, arg2):
    return self.invoke_static(arg1, arg2)

NimStringEqFunction()


################################################################################
#####  GDB Command, equivalent of Nim's $ operator
################################################################################

class DollarPrintCmd (gdb.Command):
  """Dollar print command for Nim, `$ expr` will invoke Nim's $ operator and print the result."""

  def __init__ (self):
    super (DollarPrintCmd, self).__init__ ("$", gdb.COMMAND_DATA, gdb.COMPLETE_EXPRESSION)

  def invoke(self, arg, from_tty):
    param = gdb.parse_and_eval(arg)
    strValue = DollarPrintFunction.invoke_static(param)
    if strValue:
      gdb.write(
        NimStringPrinter(strValue).to_string() + "\n",
        gdb.STDOUT
      )

    # could not find a suitable dollar overload. This here is the
    # fallback to get sensible output of basic types anyway.

    elif param.type.code == gdb.TYPE_CODE_ARRAY and param.type.target().name == "char":
      gdb.write(param.string("utf-8", "ignore") + "\n", gdb.STDOUT)
    elif param.type.code == gdb.TYPE_CODE_INT:
      gdb.write(str(int(param)) + "\n", gdb.STDOUT)
    elif param.type.name == "NIM_BOOL":
      if int(param) != 0:
        gdb.write("true\n", gdb.STDOUT)
      else:
        gdb.write("false\n", gdb.STDOUT)

DollarPrintCmd()


################################################################################
#####  GDB Commands to invoke common nim tools.
################################################################################


import subprocess, os


class KochCmd (gdb.Command):
  """Command that invokes ``koch'', the build tool for the compiler."""

  def __init__ (self):
    super (KochCmd, self).__init__ ("koch",
                                    gdb.COMMAND_USER, gdb.COMPLETE_FILENAME)
    self.binary = os.path.join(
      os.path.dirname(os.path.dirname(__file__)), "koch")

  def invoke(self, argument, from_tty):
    import os
    subprocess.run([self.binary] + gdb.string_to_argv(argument))

KochCmd()


class NimCmd (gdb.Command):
  """Command that invokes ``nim'', the nim compiler."""

  def __init__ (self):
    super (NimCmd, self).__init__ ("nim",
                                   gdb.COMMAND_USER, gdb.COMPLETE_FILENAME)
    self.binary = os.path.join(
      os.path.dirname(os.path.dirname(__file__)), "bin/nim")

  def invoke(self, argument, from_tty):
    subprocess.run([self.binary] + gdb.string_to_argv(argument))

NimCmd()


class NimbleCmd (gdb.Command):
  """Command that invokes ``nimble'', the nim package manager and build tool."""

  def __init__ (self):
    super (NimbleCmd, self).__init__ ("nimble",
                                      gdb.COMMAND_USER, gdb.COMPLETE_FILENAME)
    self.binary = os.path.join(
      os.path.dirname(os.path.dirname(__file__)), "bin/nimble")

  def invoke(self, argument, from_tty):
    subprocess.run([self.binary] + gdb.string_to_argv(argument))

NimbleCmd()

################################################################################
#####  Value pretty printers
################################################################################

class NimBoolPrinter:

  pattern = re.compile(r'^NIM_BOOL$')

  def __init__(self, val):
    self.val = val

  def to_string(self):
    if self.val == 0:
      return "false"
    else:
      return "true"

################################################################################

class NimStringPrinter:
  pattern = re.compile(r'^NimStringDesc \*$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'string'

  def to_string(self):
    if self.val:
      l = int(self.val['Sup']['len'])
      return self.val['data'].lazy_string(encoding="utf-8", length=l)
    else:
      return ""

class NimRopePrinter:
  pattern = re.compile(r'^tyObject_RopeObj__([A-Za-z0-9]*) \*$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'string'

  def to_string(self):
    if self.val:
      left  = NimRopePrinter(self.val["left"]).to_string()
      data  = NimStringPrinter(self.val["data"]).to_string()
      right = NimRopePrinter(self.val["right"]).to_string()
      return left + data + right
    else:
      return ""


################################################################################

# proc reprEnum(e: int, typ: PNimType): string {.compilerRtl.} =
#   ## Return string representation for enumeration values
#   var n = typ.node
#   if ntfEnumHole notin typ.flags:
#     let o = e - n.sons[0].offset
#     if o >= 0 and o <% typ.node.len:
#       return $n.sons[o].name
#   else:
#     # ugh we need a slow linear search:
#     var s = n.sons
#     for i in 0 .. n.len-1:
#       if s[i].offset == e:
#         return $s[i].name
#   result = $e & " (invalid data!)"

def reprEnum(e, typ):
  """ this is a port of the nim runtime function `reprEnum` to python """
  e = int(e)
  n = typ["node"]
  flags = int(typ["flags"])
  # 1 << 6 is {ntfEnumHole}
  if ((1 << 6) & flags) == 0:
    o = e - int(n["sons"][0]["offset"])
    if o >= 0 and 0 < int(n["len"]):
      return n["sons"][o]["name"].string("utf-8", "ignore")
  else:
    # ugh we need a slow linear search:
    s = n["sons"]
    for i in range(0, int(n["len"])):
      if int(s[i]["offset"]) == e:
        return s[i]["name"].string("utf-8", "ignore")

  return str(e) + " (invalid data!)"

def enumNti(typeNimName, idString):
  typeInfoName = "NTI" + typeNimName.lower() + "__" + idString + "_"
  nti = gdb.lookup_global_symbol(typeInfoName)
  if nti is None:
    typeInfoName = "NTI" + "__" + idString + "_"
    nti = gdb.lookup_global_symbol(typeInfoName)
  return (typeInfoName, nti)

class NimEnumPrinter:
  pattern = re.compile(r'^tyEnum_([A-Za-z0-9]+)__([A-Za-z0-9]*)$')

  def __init__(self, val):
    self.val = val
    typeName = self.val.type.name
    match = self.pattern.match(typeName)
    self.typeNimName  = match.group(1)
    typeInfoName, self.nti = enumNti(self.typeNimName, match.group(2))

    if self.nti is None:
      printErrorOnce(typeInfoName, f"NimEnumPrinter: lookup global symbol: '{typeInfoName}' failed for {typeName}.\n")

  def to_string(self):
    if self.nti:
      arg0     = self.val
      arg1     = self.nti.value(gdb.newest_frame())
      return reprEnum(arg0, arg1)
    else:
      return self.typeNimName + "(" + str(int(self.val)) + ")"

################################################################################

class NimSetPrinter:
  ## the set printer is limited to sets that fit in an integer.  Other
  ## sets are compiled to `NU8 *` (ptr uint8) and are invisible to
  ## gdb (currently).
  pattern = re.compile(r'^tySet_tyEnum_([A-Za-z0-9]+)__([A-Za-z0-9]*)$')

  def __init__(self, val):
    self.val = val
    typeName = self.val.type.name
    match = self.pattern.match(typeName)
    self.typeNimName = match.group(1)
    typeInfoName, self.nti = enumNti(self.typeNimName, match.group(2))

    if self.nti is None:
      printErrorOnce(typeInfoName, f"NimSetPrinter: lookup global symbol: '{typeInfoName}' failed for {typeName}.\n")

  def to_string(self):
    if self.nti:
      nti = self.nti.value(gdb.newest_frame())
      enumStrings = []
      val = int(self.val)
      i   = 0
      while val > 0:
        if (val & 1) == 1:
          enumStrings.append(reprEnum(i, nti))
        val = val >> 1
        i += 1

      return '{' + ', '.join(enumStrings) + '}'
    else:
      return str(int(self.val))

################################################################################

class NimHashSetPrinter:
  pattern = re.compile(r'^tyObject_(HashSet)__([A-Za-z0-9]*)$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'array'

  def to_string(self):
    counter  = 0
    capacity = 0
    if self.val:
      counter  = int(self.val['counter'])
      if self.val['data']:
        capacity = int(self.val['data']['Sup']['len'])

    return 'HashSet({0}, {1})'.format(counter, capacity)

  def children(self):
    if self.val:
      data = NimSeqPrinter(self.val['data'])
      for idxStr, entry in data.children():
        if int(entry['Field0']) > 0:
          yield ("data." + idxStr + ".Field1", str(entry['Field1']))

################################################################################

class NimSeqPrinter:
  # the pointer is explicity part of the type. So it is part of
  # ``pattern``.
  pattern = re.compile(r'^tySequence_\w* \*$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'array'

  def to_string(self):
    len = 0
    cap = 0
    if self.val:
      len = int(self.val['Sup']['len'])
      cap = int(self.val['Sup']['reserved'])

    return 'seq({0}, {1})'.format(len, cap)

  def children(self):
    if self.val:
      val = self.val
      valType = val.type
      length = int(val['Sup']['len'])

      if length <= 0:
        return

      dataType = valType['data'].type
      data = val['data']

      if self.val.type.name is None:
        dataType = valType['data'].type.target().pointer()
        data = val['data'].cast(dataType)

      inaccessible = False
      for i in range(length):
        if inaccessible:
          return
        try:
          str(data[i])
          yield "data[{0}]".format(i), data[i]
        except RuntimeError:
          inaccessible = True
          yield "data[{0}]".format(i), "inaccessible"
      
################################################################################

class NimArrayPrinter:
  pattern = re.compile(r'^tyArray_\w*$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'array'

  def to_string(self):
    return 'array'

  def children(self):
    length = self.val.type.sizeof // self.val[0].type.sizeof
    align = len(str(length-1))
    for i in range(length):
      yield ("[{0:>{1}}]".format(i, align), self.val[i])

################################################################################

class NimStringTablePrinter:
  pattern = re.compile(r'^tyObject_(StringTableObj)__([A-Za-z0-9]*)(:? \*)?$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'map'

  def to_string(self):
    counter  = 0
    capacity = 0
    if self.val:
      counter  = int(self.val['counter'])
      if self.val['data']:
        capacity = int(self.val['data']['Sup']['len'])

    return 'StringTableObj({0}, {1})'.format(counter, capacity)

  def children(self):
    if self.val:
      data = NimSeqPrinter(self.val['data'].referenced_value())
      for idxStr, entry in data.children():
        if int(entry['Field0']) != 0:
          yield (idxStr + ".Field0", entry['Field0'])
          yield (idxStr + ".Field1", entry['Field1'])

################################################################

class NimTablePrinter:
  pattern = re.compile(r'^tyObject_(Table)__([A-Za-z0-9]*)(:? \*)?$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'map'

  def to_string(self):
    counter  = 0
    capacity = 0
    if self.val:
      counter  = int(self.val['counter'])
      if self.val['data']:
        capacity = int(self.val['data']['Sup']['len'])

    return 'Table({0}, {1})'.format(counter, capacity)

  def children(self):
    if self.val:
      data = NimSeqPrinter(self.val['data'])
      for idxStr, entry in data.children():
        if int(entry['Field0']) != 0:
          yield (idxStr + '.Field1', entry['Field1'])
          yield (idxStr + '.Field2', entry['Field2'])

################################################################

# this is untested, therefore disabled

# class NimObjectPrinter:
#   pattern = re.compile(r'^tyObject_([A-Za-z0-9]+)__(_?[A-Za-z0-9]*)(:? \*)?$')

#   def __init__(self, val):
#     self.val = val
#     self.valType = None
#     self.valTypeNimName = None

#   def display_hint(self):
#     return 'object'

#   def _determineValType(self):
#     if self.valType is None:
#       vt = self.val.type
#       if vt.name is None:
#         target = vt.target()
#         self.valType = target.pointer()
#         self.fields = target.fields()
#         self.valTypeName = target.name
#         self.isPointer = True
#       else:
#         self.valType = vt
#         self.fields = vt.fields()
#         self.valTypeName = vt.name
#         self.isPointer = False

#   def to_string(self):
#     if self.valTypeNimName is None:
#       self._determineValType()
#       match = self.pattern.match(self.valTypeName)
#       self.valTypeNimName = match.group(1)

#     return self.valTypeNimName

#   def children(self):
#     self._determineValType()
#     if self.isPointer and int(self.val) == 0:
#       return
#     self.baseVal = self.val.referenced_value() if self.isPointer else self.val

#     for c in self.handleFields(self.baseVal, getNimRti(self.valTypeName)):
#       yield c
  
#   def handleFields(self, currVal, rti, fields = None):
#     rtiSons = None
#     discField = (0, None)
#     seenSup = False
#     if fields is None:
#       fields = self.fields
#     try: # XXX: remove try after finished debugging this method
#       for (i, field) in enumerate(fields):
#         if field.name == "Sup": # inherited data
#           seenSup = True
#           baseRef = rti['base']
#           if baseRef:
#             baseRti = baseRef.referenced_value()
#             baseVal = currVal['Sup']
#             baseValType = baseVal.type
#             if baseValType.name is None:
#               baseValType = baseValType.target().pointer()
#               baseValFields = baseValType.target().fields()
#             else:
#               baseValFields = baseValType.fields()
            
#             for c in self.handleFields(baseVal, baseRti, baseValFields):
#               yield c
#         else:
#           if field.type.code == gdb.TYPE_CODE_UNION:
#             # if not rtiSons:
#             rtiNode = rti['node'].referenced_value()
#             rtiSons = rtiNode['sons']

#             if not rtiSons and int(rtiNode['len']) == 0 and str(rtiNode['name']) != "0x0":
#               rtiSons = [rti['node']] # sons are dereferenced by the consumer
            
#             if not rtiSons:
#               printErrorOnce(self.valTypeName, f"NimObjectPrinter: UNION field can't be displayed without RTI {self.valTypeName}, using fallback.\n")
#               # yield (field.name, self.baseVal[field]) # XXX: this fallback seems wrong
#               return # XXX: this should probably continue instead?

#             if int(rtiNode['len']) != 0 and str(rtiNode['name']) != "0x0":
#               gdb.write(f"wtf IT HAPPENED {self.valTypeName}\n", gdb.STDERR)

#             discNode = rtiSons[discField[0]].referenced_value()
#             if not discNode:
#               raise ValueError("Can't find union discriminant field in object RTI")
            
#             discNodeLen = int(discNode['len'])
#             discFieldVal = int(currVal[discField[1].name])

#             unionNodeRef = None
#             if discFieldVal < discNodeLen:
#               unionNodeRef = discNode['sons'][discFieldVal]
#             if not unionNodeRef:
#               unionNodeRef = discNode['sons'][discNodeLen]

#             if not unionNodeRef:
#               printErrorOnce(self.valTypeName + "no union node", f"wtf is up with sons {self.valTypeName} {unionNodeRef} {rtiNode['offset']} {discNode} {discFieldVal} {discNodeLen} {discField[1].name} {field.name} {field.type}\n")
#               continue

#             unionNode = unionNodeRef.referenced_value()
            
#             fieldName = "" if field.name == None else field.name.lower()
#             unionNodeName = "" if not unionNode['name'] else unionNode['name'].string("utf-8", "ignore")
#             if not unionNodeName or unionNodeName.lower() != fieldName:
#               unionFieldName = f"_{discField[1].name.lower()}_{int(rti['node'].referenced_value()['len'])}"
#               gdb.write(f"wtf i: {i} union: {unionFieldName} field: {fieldName} type: {field.type.name} tag: {field.type.tag}\n", gdb.STDERR)
#             else:
#               unionFieldName = unionNodeName

#             if discNodeLen == 0:
#               yield (unionFieldName, currVal[unionFieldName])
#             else:
#               unionNodeLen = int(unionNode['len'])
#               if unionNodeLen > 0:
#                 for u in range(unionNodeLen):
#                   un = unionNode['sons'][u].referenced_value()['name'].string("utf-8", "ignore")
#                   yield (un, currVal[unionFieldName][un])
#               else:
#                 yield(unionNodeName, currVal[unionFieldName])
#           else:
#             discIndex = i - 1 if seenSup else i
#             discField = (discIndex, field) # discriminant field is the last normal field
#             yield (field.name, currVal[field.name])
#     except GeneratorExit:
#       raise
#     except:
#       gdb.write(f"wtf {self.valTypeName} {i} fn: {field.name} df: {discField} rti: {rti} rtiNode: {rti['node'].referenced_value()} rtiSons: {rtiSons} {sys.exc_info()} {traceback.format_tb(sys.exc_info()[2], limit = 10)}\n", gdb.STDERR)
#       gdb.write(f"wtf {self.valTypeName} {i} {field.name}\n", gdb.STDERR)
      
#       # seenSup = False
#       # for (i, field) in enumerate(fields):
#       #   # if field.name:
#       #   #   val = currVal[field.name]
#       #   # else:
#       #   #   val = None
#       #   rtiNode = rti['node'].referenced_value()
#       #   rtiLen = int(rtiNode['len'])
#       #   if int(rtiNode['len']) > 0:
#       #     sons = rtiNode['sons']
#       #   elif int(rti['len']) == 0 and str(rti['name']) != "0x0":
#       #     sons = [rti['node']] # sons are dereferenced by the consumer
#       #   sonsIdx = i - 1 if seenSup else i
#       #   s = sons[sonsIdx].referenced_value()
#       #   addr = int(currVal.address)
#       #   off = addr + int(rtiNode['offset'])
#       #   seenSup = seenSup or field.name == "Sup"

#       #   gdb.write(f"wtf: i: {i} sonsIdx: {sonsIdx} field: {field.name} rtiLen: {rtiLen} rti: {rti} rtiNode: {rtiNode} isUnion: {field.type.code == gdb.TYPE_CODE_UNION} s: {s}\n", gdb.STDERR)

#       raise


################################################################################

class NimFrameFilter:
  def __init__(self):
    self.name = "nim-frame-filter"
    self.enabled = True
    self.priority = 100
    self.hidden =  {"NimMainInner","NimMain", "main"}

  def filter(self, iterator):
    for framedecorator in iterator:
      if framedecorator.function() not in self.hidden:
        yield framedecorator

################################################################################

def makematcher(klass):
  def matcher(val):
    typeName = str(val.type)
    try:
      if hasattr(klass, 'pattern') and hasattr(klass, '__name__'):
        # print(typeName + " <> " + klass.__name__)
        if klass.pattern.match(typeName):
          return klass(val)
    except Exception as e:
      print(klass)
      printErrorOnce(typeName, "No matcher for type '" + typeName + "': " + str(e) + "\n")
  return matcher

def register_nim_pretty_printers_for_object(objfile):
  nimMainSym = gdb.lookup_global_symbol("NimMain", gdb.SYMBOL_FUNCTIONS_DOMAIN)
  if nimMainSym and nimMainSym.symtab.objfile == objfile:
    print("set Nim pretty printers for ", objfile.filename)

    gdb.types.register_type_printer(objfile, NimTypePrinter())
    objfile.pretty_printers = [makematcher(var) for var in list(globals().values()) if hasattr(var, 'pattern')]

# Register pretty printers for all objfiles that are already loaded.
for old_objfile in gdb.objfiles():
  register_nim_pretty_printers_for_object(old_objfile)

# Register an event handler to register nim pretty printers for all future objfiles.
def new_object_handler(event):
  register_nim_pretty_printers_for_object(event.new_objfile)

gdb.events.new_objfile.connect(new_object_handler)

gdb.frame_filters = {"nim-frame-filter": NimFrameFilter()}
