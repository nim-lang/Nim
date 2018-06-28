
import gdb
import re
import sys

################################################################################
#####  Type pretty printers
################################################################################

gdb.write("Loading Nim Runtime support.", gdb.STDERR)

errorSet = set()
def printError(id, message):
  global errorSet
  if id not in errorSet:
    errorSet.add(id)
    gdb.write(message, gdb.STDERR)

nimobjfile = gdb.current_objfile() or gdb.objfiles()[0]
nimobjfile.type_printers = []

class NimTypePrinter(gdb.types.TypePrinter):
  "Nim type printer, one printer for all Nim types"

  type_hash_regex = re.compile("^(.+?)_([A-Za-z0-9]+)$")

  type_map_static = {
    'NI': 'int',  'NI8': 'int8', 'NI16': 'int16',  'NI32': 'int32',  'NI64': 'in64',
    'NU': 'uint', 'NU8': 'uint8','NU16': 'uint16', 'NU32': 'uint32', 'NU64': 'uint64',
    'NF': 'float', 'NF32': 'float32', 'NF32': 'float64',
    'NIM_BOOL': 'bool', 'NIM_CHAR': 'char', 'NCSTRING': 'cstring',
    'NimStringDesc': 'string'
  }

  def __init__ (self):
    super (NimTypePrinter, self).__init__ ("NimTypePrinter")

  @staticmethod
  def rti(type_name):
    "Get static const TNimType variable, should be available for every non trivial Nim type"

    m = NimTypePrinter.type_hash_regex.match(type_name)
    if m is not None:
      try:
        return gdb.parse_and_eval("NTI_" + m.group(2) + "_")
      except:
       return None

  def instantiate(self):
    return self._recognizer()

  class _recognizer(object):

    def recognize(self, type_obj):

      tname = ""
      if type_obj.tag is not None:
        tname = type_obj.tag
      elif type_obj.name is not None:
        tname = type_obj.name
      else:
        return None

      result = NimTypePrinter.type_map_static.get(tname, None)
      if result is not None:
        return result

      rti = NimTypePrinter.rti(tname)
      if rti is None:
        return None

      return str(rti['name'])

nimobjfile.type_printers = [NimTypePrinter()]

################################################################################
#####  GDB Function, equivalent of Nim's $ operator
################################################################################

class DollarPrintFunction (gdb.Function):
  "Nim's equivalent of $ operator as a gdb function, available in expressions `print $dollar(myvalue)"

  _gdb_dollar_functions = gdb.execute("info functions dollar__", True, True)
  dollar_functions = re.findall('NimStringDesc \*(dollar__[A-z0-9_]+?)\(([^,)]*)\);', _gdb_dollar_functions)

  def __init__ (self):
    super (DollarPrintFunction, self).__init__("dollar")

  @staticmethod
  def invoke_static(arg):

    for func, arg_typ in DollarPrintFunction.dollar_functions:

      if arg.type.name == arg_typ:
        func_value = gdb.lookup_global_symbol(func, gdb.SYMBOL_FUNCTIONS_DOMAIN).value()
        return func_value(arg)

      if arg.type.name + " *" == arg_typ:
        func_value = gdb.lookup_global_symbol(func, gdb.SYMBOL_FUNCTIONS_DOMAIN).value()
        return func_value(arg.address)

    typeName = arg.type.name
    printError(typeName, "No suitable Nim $ operator found for type: " + typeName)

  def invoke(self, arg):
    return self.invoke_static(arg)

DollarPrintFunction()


################################################################################
#####  GDB Command, equivalent of Nim's $ operator
################################################################################

class DollarPrintCmd (gdb.Command):
  """Dollar print command for Nim, `$ expr` will invoke Nim's $ operator"""

  def __init__ (self):
    super (DollarPrintCmd, self).__init__ ("$", gdb.COMMAND_DATA, gdb.COMPLETE_EXPRESSION)

  def invoke (self, arg, from_tty):
    param = gdb.parse_and_eval(arg)
    gdb.write(str(DollarPrintFunction.invoke_static(param)) + "\n", gdb.STDOUT)

DollarPrintCmd()


################################################################################
#####  Value pretty printers
################################################################################

class NimBoolPrinter:

  pattern = re.compile(r'^NIM_BOOL$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'bool'

  def to_string(self):
    if self.val == 0:
      return "false"
    else:
      return "true"

################################################################

class NimStringPrinter:

  pattern = re.compile(r'^NimStringDesc \*$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'string'

  def to_string(self):
    if self.val:
      l = int(self.val['Sup']['len'])
      return self.val['data'][0].address.string("utf-8", "ignore", l)
    else:
     return ""


################################################################

class NimEnumPrinter:

  pattern = re.compile(r'^tyEnum_(.+?)_([A-Za-z0-9]+)$')

  def __init__(self, val):
    self.val      = val
    self.reprEnum = gdb.lookup_global_symbol("reprEnum", gdb.SYMBOL_FUNCTIONS_DOMAIN)
    typeInfoName = "NTI_" + self.pattern.match(str(self.val.type)).group(2) + "_"
    self.nti = gdb.lookup_global_symbol(typeInfoName)

    if self.reprEnum is None:
      printError('reprEnum', "NimEnumPrinter: lookup global symbol 'reprEnum' failed.\n")
    else:
      self.reprEnum = self.reprEnum.value

    if self.nti is None:
      printError(typeInfoName, "NimEnumPrinter: lookup global symbol '"+typeInfoName+" failed for " + self.val.type.name + ".\n")
    else:
      self.nti = self.nti.value

  def display_hint(self):
    return 'string'

  def to_string(self):
    if self.reprEnum and self.nti:
      return self.reprEnum(self.val, self.nti)
    else:
      return str(int(self.val))

################################################################

class NimSetPrinter:

  pattern = re.compile(r'^tySet_(.+?)_([A-Za-z0-9]+)$')

  def __init__(self, val):
    self.val = val

  def to_string(self):
    try:
      return DollarPrintFunction.invoke_static(self.val)
    except:
      typeString = str(self.val.type)
      printError(typeString, "RTI information not found for set, lik,ely removed by dead code elimination: " + typeString + "\n")
      return str(int(self.val))

################################################################

class NimSeqPrinter:
  pattern = re.compile(r'^tySequence_.*$')

  def __init__(self, val):
    self.val = val

  def display_hint(self):
    return 'array'

  def to_string(self):
    return 'seq'

  def children(self):
    if self.val:
      len = int(self.val['Sup']['len'])
      for i in range(len):
        yield ('[{0}]'.format(i), self.val["data"][i])

################################################################


# class NimObjectPrinter:
#   pattern = re.compile(r'^tyObject_.*$')

#   def __init__(self, val):
#     self.val = val

#   def display_hint(self):
#     return 'object'

#   def to_string(self):
#     return str(self.val.type)

#   def children(self):
#     if not self.val:
#       yield "object", "<nil>"
#       raise StopIteration

#     for (i, field) in enumerate(self.val.type.fields()):
#       if field.type.code == gdb.TYPE_CODE_UNION:
#         yield _union_field
#       else:
#         yield (field.name, self.val[field])

#   def _union_field(self, i, field):
#     rti = NimTypePrinter.rti(self.val.type.name)
#     if rti is None:
#       return (field.name, "UNION field can't be displayed without RTI")

#     node_sons = rti['node'].dereference()['sons']
#     prev_field = self.val.type.fields()[i - 1]

#     descriminant_node = None
#     for i in range(int(node['len'])):
#       son = node_sons[i].dereference()
#       if son['name'].string("utf-8", "ignore") == str(prev_field.name):
#         descriminant_node = son
#         break
#     if descriminant_node is None:
#       raise ValueError("Can't find union descriminant field in object RTI")

#     if descriminant_node is None: raise ValueError("Can't find union field in object RTI")
#     union_node = descriminant_node['sons'][int(self.val[prev_field])].dereference()
#     union_val = self.val[field]

#     for f1 in union_val.type.fields():
#       for f2 in union_val[f1].type.fields():
#         if str(f2.name) == union_node['name'].string("utf-8", "ignore"):
#            return (str(f2.name), union_val[f1][f2])

#     raise ValueError("RTI is absent or incomplete, can't find union definition in RTI")


################################################################################

def makematcher(klass):
  def matcher(val):
    typeName = str(val.type)
    try:
      if klass.pattern.match(typeName):
        return klass(val)
    except Exception as e:
      gdb.write("No matcher for type '" + typeName + "': " + str(e) + "\n", gdb.STDERR)
  return matcher

nimobjfile.pretty_printers = []
nimobjfile.pretty_printers.extend([makematcher(var) for var in list(vars().values()) if hasattr(var, 'pattern')])
