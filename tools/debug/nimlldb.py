import lldb
from collections import OrderedDict
from typing import Union


def sbvaluegetitem(self: lldb.SBValue, name: Union[int, str]) -> lldb.SBValue:
    if isinstance(name, str):
        return self.GetChildMemberWithName(name)
    else:
        return self.GetChildAtIndex(name)


# Make this easier to work with
lldb.SBValue.__getitem__ = sbvaluegetitem

NIM_IS_V2 = True


def get_nti(value: lldb.SBValue, nim_name=None):
    name_split = value.type.name.split("_")
    type_nim_name = nim_name or name_split[1]
    id_string = name_split[-1].split(" ")[0]

    type_info_name = "NTI" + type_nim_name.lower() + "__" + id_string + "_"
    nti = value.target.FindFirstGlobalVariable(type_info_name)
    if not nti.IsValid():
        type_info_name = "NTI" + "__" + id_string + "_"
        nti = value.target.FindFirstGlobalVariable(type_info_name)
    if not nti.IsValid():
        print(f"NimEnumPrinter: lookup global symbol: '{type_info_name}' failed for {value.type.name}.\n")
    return type_nim_name, nti


def enum_to_string(value: lldb.SBValue, int_val=None, nim_name=None):
    tname = nim_name or value.type.name.split("_")[1]

    enum_val = value.signed
    if int_val is not None:
        enum_val = int_val

    default_val = f"{tname}.{str(enum_val)}"

    fn_syms = value.target.FindFunctions("reprEnum")
    if not fn_syms.GetSize() > 0:
        return default_val

    fn_sym: lldb.SBSymbolContext = fn_syms.GetContextAtIndex(0)

    fn: lldb.SBFunction = fn_sym.function

    fn_type: lldb.SBType = fn.type
    arg_types: lldb.SBTypeList = fn_type.GetFunctionArgumentTypes()
    if arg_types.GetSize() < 2:
        return default_val

    arg1_type: lldb.SBType = arg_types.GetTypeAtIndex(0)
    arg2_type: lldb.SBType = arg_types.GetTypeAtIndex(1)

    ty_info_name, nti = get_nti(value, nim_name=tname)

    if not nti.IsValid():
        return default_val

    call = f"{fn.name}(({arg1_type.name}){enum_val}, ({arg2_type.name})" + str(nti.GetLoadAddress()) + ");"

    res = executeCommand(call)

    if res.error.fail:
        return default_val

    return f"{tname}.{res.summary[1:-1]}"


def to_string(value: lldb.SBValue):
    # For getting NimStringDesc * value
    value = value.GetNonSyntheticValue()

    # Check if data pointer is Null
    if value.type.is_pointer and value.unsigned == 0:
        return None

    size = int(value["Sup"]["len"].unsigned)

    if size == 0:
        return ""

    if size > 2**14:
        return "... (too long) ..."

    data = value["data"]

    # Check if first element is NULL
    base_data_type = value.target.FindFirstType("char")
    cast = data.Cast(base_data_type)

    if cast.unsigned == 0:
        return None

    cast = data.Cast(value.target.FindFirstType("char").GetArrayType(size))
    return bytearray(cast.data.uint8s).decode("utf-8")


def to_stringV2(value: lldb.SBValue):
    # For getting NimStringV2 value
    value = value.GetNonSyntheticValue()

    data = value["p"]["data"]

    # Check if data pointer is Null
    if value["p"].unsigned == 0:
        return None

    size = int(value["len"].signed)

    if size == 0:
        return ""

    if size > 2**14:
        return "... (too long) ..."

    # Check if first element is NULL
    base_data_type = data.type.GetArrayElementType().GetTypedefedType()
    cast = data.Cast(base_data_type)

    if cast.unsigned == 0:
        return None

    cast = data.Cast(base_data_type.GetArrayType(size))
    return bytearray(cast.data.uint8s).decode("utf-8")


def NimString(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    if NIM_IS_V2:
        res = to_stringV2(value)
    else:
        res = to_string(value)

    if res is not None:
        return f'"{res}"'
    else:
        return "nil"


def rope_helper(value: lldb.SBValue) -> str:
    value = value.GetNonSyntheticValue()
    if value.type.is_pointer and value.unsigned == 0:
        return ""

    if value["length"].unsigned == 0:
        return ""

    if NIM_IS_V2:
        str_val = to_stringV2(value["data"])
    else:
        str_val = to_string(value["data"])

    if str_val is None:
        str_val = ""

    return rope_helper(value["left"]) + str_val + rope_helper(value["right"])


def Rope(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    rope_str = rope_helper(value)

    if len(rope_str) == 0:
        rope_str = "nil"
    else:
        rope_str = f'"{rope_str}"'

    return f"Rope({rope_str})"


def NCSTRING(value: lldb.SBValue, internal_dict=None):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    ty = value.Dereference().type
    val = value.target.CreateValueFromAddress(
        value.name or "temp", lldb.SBAddress(value.unsigned, value.target), ty
    ).AddressOf()
    return val.summary


def ObjectV2(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    orig_value = value.GetNonSyntheticValue()
    if orig_value.type.is_pointer and orig_value.unsigned == 0:
        return "nil"

    custom_summary = get_custom_summary(value)
    if custom_summary is not None:
        return custom_summary

    while orig_value.type.is_pointer:
        orig_value = orig_value.Dereference()

    if "_" in orig_value.type.name:
        obj_name = orig_value.type.name.split("_")[1].replace("colonObjectType", "")
    else:
        obj_name = orig_value.type.name

    num_children = value.num_children
    fields = []

    for i in range(num_children):
        fields.append(f"{value[i].name}: {value[i].summary}")

    res = f"{obj_name}(" + ", ".join(fields) + ")"
    return res


def Number(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    if value.type.is_pointer and value.signed == 0:
        return "nil"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    return str(value.signed)


def Float(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    return str(value.value)


def UnsignedNumber(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    return str(value.unsigned)


def Bool(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    return str(value.value)


def CharArray(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    return str([f"'{char}'" for char in value.uint8s])


def Array(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    value = value.GetNonSyntheticValue()
    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    value = value.GetNonSyntheticValue()
    return "[" + ", ".join([value[i].summary for i in range(value.num_children)]) + "]"


def Tuple(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    while value.type.is_pointer:
        value = value.Dereference()

    num_children = value.num_children

    fields = []

    for i in range(num_children):
        key = value[i].name
        val = value[i].summary
        if key.startswith("Field"):
            fields.append(f"{val}")
        else:
            fields.append(f"{key}: {val}")

    return "(" + ", ".join(fields) + f")"


def is_local(value: lldb.SBValue) -> bool:
    line: lldb.SBLineEntry = value.frame.GetLineEntry()
    decl: lldb.SBDeclaration = value.GetDeclaration()

    if line.file == decl.file and decl.line != 0:
        return True

    return False


def is_in_scope(value: lldb.SBValue) -> bool:
    line: lldb.SBLineEntry = value.frame.GetLineEntry()
    decl: lldb.SBDeclaration = value.GetDeclaration()

    if is_local(value) and decl.line < line.line:
        return True

    return False


def Enum(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_value_summary(value)
    if custom_summary is not None:
        return custom_summary

    return enum_to_string(value)


def EnumSet(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    vals = []
    max_vals = 7
    for child in value.children:
        vals.append(child.summary)
        if len(vals) > max_vals:
            vals.append("...")
            break

    return "{" + ", ".join(vals) + "}"


def Set(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if custom_summary is not None:
        return custom_summary

    vals = []
    max_vals = 7
    for child in value.children:
        vals.append(child.value)
        if len(vals) > max_vals:
            vals.append("...")
            break

    return "{" + ", ".join(vals) + "}"


def Table(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if custom_summary is not None:
        return custom_summary

    fields = []

    for i in range(value.num_children):
        key = value[i].name
        val = value[i].summary
        fields.append(f"{key}: {val}")

    return "Table({" + ", ".join(fields) + "})"


def HashSet(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if custom_summary is not None:
        return custom_summary

    fields = []

    for i in range(value.num_children):
        fields.append(f"{value[i].summary}")

    return "HashSet({" + ", ".join(fields) + "})"


def StringTable(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    fields = []

    for i in range(value.num_children - 1):
        key = value[i].name
        val = value[i].summary
        fields.append(f"{key}: {val}")

    mode = value[value.num_children - 1].summary

    return "StringTable({" + ", ".join(fields) + f"}}, mode={mode})"


def Sequence(value: lldb.SBValue, internal_dict):
    if is_local(value):
        if not is_in_scope(value):
            return "undefined"

    custom_summary = get_custom_summary(value)
    if not custom_summary is None:
        return custom_summary

    return "@[" + ", ".join([value[i].summary for i in range(value.num_children)]) + "]"


class StringChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.data_type: lldb.SBType
        if not NIM_IS_V2:
            self.data_type = self.value.target.FindFirstType("char")

        self.first_element: lldb.SBValue
        self.update()
        self.count = 0

    def num_children(self):
        return self.count

    def get_child_index(self, name):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        offset = index * self.data_size
        return self.first_element.CreateChildAtOffset("[" + str(index) + "]", offset, self.data_type)

    def get_data(self) -> lldb.SBValue:
        return self.value["p"]["data"] if NIM_IS_V2 else self.value["data"]

    def get_len(self) -> int:
        if NIM_IS_V2:
            if self.value["p"].unsigned == 0:
                return 0

            size = int(self.value["len"].signed)

            if size == 0:
                return 0

            data = self.value["p"]["data"]

            # Check if first element is NULL
            base_data_type = data.type.GetArrayElementType().GetTypedefedType()
            cast = data.Cast(base_data_type)

            if cast.unsigned == 0:
                return 0
        else:
            if self.value.type.is_pointer and self.value.unsigned == 0:
                return 0

            size = int(self.value["Sup"]["len"].unsigned)

            if size == 0:
                return 0

            data = self.value["data"]

            # Check if first element is NULL
            base_data_type = self.value.target.FindFirstType("char")
            cast = data.Cast(base_data_type)

            if cast.unsigned == 0:
                return 0

        return size

    def update(self):
        if is_local(self.value):
            if not is_in_scope(self.value):
                return

        data = self.get_data()
        size = self.get_len()

        self.count = size
        self.first_element = data

        if NIM_IS_V2:
            self.data_type = data.type.GetArrayElementType().GetTypedefedType()

        self.data_size = self.data_type.GetByteSize()

    def has_children(self):
        return bool(self.num_children())


class ArrayChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.data_type: lldb.SBType
        self.first_element: lldb.SBValue
        self.update()

    def num_children(self):
        return self.has_children() and self.value.num_children

    def get_child_index(self, name: str):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        offset = index * self.value[index].GetByteSize()
        return self.first_element.CreateChildAtOffset("[" + str(index) + "]", offset, self.data_type)

    def update(self):
        if not self.has_children():
            return

        self.first_element = self.value[0]
        self.data_type = self.value.type.GetArrayElementType()

    def has_children(self):
        if is_local(self.value):
            if not is_in_scope(self.value):
                return False
        return bool(self.value.num_children)


class SeqChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.data_type: lldb.SBType
        self.first_element: lldb.SBValue
        self.data: lldb.SBValue
        self.count = 0
        self.update()

    def num_children(self):
        return self.count

    def get_child_index(self, name: str):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        offset = index * self.data[index].GetByteSize()
        return self.first_element.CreateChildAtOffset("[" + str(index) + "]", offset, self.data_type)

    def get_data(self) -> lldb.SBValue:
        return self.value["p"]["data"] if NIM_IS_V2 else self.value["data"]

    def get_len(self) -> lldb.SBValue:
        return self.value["len"] if NIM_IS_V2 else self.value["Sup"]["len"]

    def update(self):
        self.count = 0

        if is_local(self.value):
            if not is_in_scope(self.value):
                return

        self.count = self.get_len().unsigned

        if not self.has_children():
            return

        data = self.get_data()
        self.data_type = data.type.GetArrayElementType()

        self.data = data.Cast(self.data_type.GetArrayType(self.num_children()))
        self.first_element = self.data

    def has_children(self):
        return bool(self.num_children())


class ObjectChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.data_type: lldb.SBType
        self.first_element: lldb.SBValue
        self.data: lldb.SBValue
        self.children: OrderedDict[str, int] = OrderedDict()
        self.child_list: list[lldb.SBValue] = []
        self.update()

    def num_children(self):
        return len(self.children)

    def get_child_index(self, name: str):
        return self.children[name]

    def get_child_at_index(self, index):
        return self.child_list[index]

    def populate_children(self):
        self.children.clear()
        self.child_list = []

        if is_local(self.value):
            if not is_in_scope(self.value):
                return

        stack = [self.value.GetNonSyntheticValue()]

        index = 0

        while stack:
            cur_val = stack.pop()
            if cur_val.type.is_pointer and cur_val.unsigned == 0:
                continue

            while cur_val.type.is_pointer:
                cur_val = cur_val.Dereference()

            # Add super objects if they exist
            if cur_val.num_children > 0 and cur_val[0].name == "Sup" and cur_val[0].type.name.startswith("tyObject"):
                stack.append(cur_val[0])

            for child in cur_val.children:
                child = child.GetNonSyntheticValue()
                if child.name == "Sup":
                    continue
                self.children[child.name] = index
                self.child_list.append(child)
                index += 1

    def update(self):
        self.populate_children()

    def has_children(self):
        return bool(self.num_children())


class HashSetChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.child_list: list[lldb.SBValue] = []
        self.update()

    def num_children(self):
        return len(self.child_list)

    def get_child_index(self, name: str):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        return self.child_list[index]

    def get_data(self) -> lldb.SBValue:
        return self.value["data"]["p"]["data"] if NIM_IS_V2 else self.value["data"]["data"]

    def get_len(self) -> lldb.SBValue:
        return self.value["data"]["len"] if NIM_IS_V2 else self.value["data"]["Sup"]["len"]

    def update(self):
        self.child_list = []

        if is_local(self.value):
            if not is_in_scope(self.value):
                return

        tuple_len = int(self.get_len().unsigned)
        tuple = self.get_data()

        base_data_type = tuple.type.GetArrayElementType()

        cast = tuple.Cast(base_data_type.GetArrayType(tuple_len))

        index = 0
        for i in range(tuple_len):
            el = cast[i]
            field0 = int(el[0].unsigned)
            if field0 == 0:
                continue
            key = el[1]
            child = key.CreateValueFromAddress(f"[{str(index)}]", key.GetLoadAddress(), key.GetType())
            index += 1

            self.child_list.append(child)

    def has_children(self):
        return bool(self.num_children())


class SetCharChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.ty = self.value.target.FindFirstType("char")
        self.child_list: list[lldb.SBValue] = []
        self.update()

    def num_children(self):
        return len(self.child_list)

    def get_child_index(self, name: str):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        return self.child_list[index]

    def update(self):
        self.child_list = []
        if is_local(self.value):
            if not is_in_scope(self.value):
                return

        cur_pos = 0
        for child in self.value.children:
            child_val = child.signed
            if child_val != 0:
                temp = child_val
                num_bits = 8
                while temp != 0:
                    is_set = temp & 1
                    if is_set == 1:
                        data = lldb.SBData.CreateDataFromInt(cur_pos)
                        child = self.value.synthetic_child_from_data(f"[{len(self.child_list)}]", data, self.ty)
                        self.child_list.append(child)
                    temp = temp >> 1
                    cur_pos += 1
                    num_bits -= 1
                cur_pos += num_bits
            else:
                cur_pos += 8

    def has_children(self):
        return bool(self.num_children())


def create_set_children(value: lldb.SBValue, child_type: lldb.SBType, starting_pos: int) -> list[lldb.SBValue]:
    child_list: list[lldb.SBValue] = []
    cur_pos = starting_pos

    if value.num_children > 0:
        children = value.children
    else:
        children = [value]

    for child in children:
        child_val = child.signed
        if child_val != 0:
            temp = child_val
            num_bits = 8
            while temp != 0:
                is_set = temp & 1
                if is_set == 1:
                    data = lldb.SBData.CreateDataFromInt(cur_pos)
                    child = value.synthetic_child_from_data(f"[{len(child_list)}]", data, child_type)
                    child_list.append(child)
                temp = temp >> 1
                cur_pos += 1
                num_bits -= 1
            cur_pos += num_bits
        else:
            cur_pos += 8

    return child_list


class SetIntChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.ty = self.value.target.FindFirstType(f"NI64")
        self.child_list: list[lldb.SBValue] = []
        self.update()

    def num_children(self):
        return len(self.child_list)

    def get_child_index(self, name: str):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        return self.child_list[index]

    def update(self):
        self.child_list = []
        if is_local(self.value):
            if not is_in_scope(self.value):
                return
        bits = self.value.GetByteSize() * 8
        starting_pos = -(bits // 2)
        self.child_list = create_set_children(self.value, self.ty, starting_pos)

    def has_children(self):
        return bool(self.num_children())


class SetUIntChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.ty = self.value.target.FindFirstType(f"NU64")
        self.child_list: list[lldb.SBValue] = []
        self.update()

    def num_children(self):
        return len(self.child_list)

    def get_child_index(self, name: str):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        return self.child_list[index]

    def update(self):
        self.child_list = []
        if is_local(self.value):
            if not is_in_scope(self.value):
                return
        self.child_list = create_set_children(self.value, self.ty, starting_pos=0)

    def has_children(self):
        return bool(self.num_children())


class SetEnumChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.ty = self.value.target.FindFirstType(self.value.type.name.replace("tySet_", ""))
        self.child_list: list[lldb.SBValue] = []
        self.update()

    def num_children(self):
        return len(self.child_list)

    def get_child_index(self, name: str):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        return self.child_list[index]

    def update(self):
        if is_local(self.value):
            if not is_in_scope(self.value):
                return
        self.child_list = create_set_children(self.value, self.ty, starting_pos=0)

    def has_children(self):
        return bool(self.num_children())


class TableChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.children: OrderedDict[str, int] = OrderedDict()
        self.child_list: list[lldb.SBValue] = []

        self.update()

    def num_children(self):
        return len(self.child_list)

    def get_child_index(self, name: str):
        return self.children[name]

    def get_child_at_index(self, index):
        return self.child_list[index]

    def get_data(self) -> lldb.SBValue:
        return self.value["data"]["p"]["data"] if NIM_IS_V2 else self.value["data"]["data"]

    def get_len(self) -> lldb.SBValue:
        return self.value["data"]["len"] if NIM_IS_V2 else self.value["data"]["Sup"]["len"]

    def update(self):
        self.child_list = []
        if is_local(self.value):
            if not is_in_scope(self.value):
                return

        tuple_len = int(self.get_len().unsigned)
        tuple = self.get_data()

        base_data_type = tuple.type.GetArrayElementType()

        cast = tuple.Cast(base_data_type.GetArrayType(tuple_len))

        index = 0
        for i in range(tuple_len):
            el = cast[i]
            field0 = int(el[0].unsigned)
            if field0 == 0:
                continue
            key = el[1]
            val = el[2]
            key_summary = key.summary
            child = self.value.CreateValueFromAddress(key_summary, val.GetLoadAddress(), val.GetType())
            self.child_list.append(child)
            self.children[key_summary] = index
            index += 1

    def has_children(self):
        return bool(self.num_children())


class StringTableChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.children: OrderedDict[str, int] = OrderedDict()
        self.child_list: list[lldb.SBValue] = []
        self.update()

    def num_children(self):
        return len(self.child_list)

    def get_child_index(self, name: str):
        return self.children[name]

    def get_child_at_index(self, index):
        return self.child_list[index]

    def get_data(self) -> lldb.SBValue:
        return self.value["data"]["p"]["data"] if NIM_IS_V2 else self.value["data"]["data"]

    def get_len(self) -> lldb.SBValue:
        return self.value["data"]["len"] if NIM_IS_V2 else self.value["data"]["Sup"]["len"]

    def update(self):
        self.children.clear()
        self.child_list = []

        if is_local(self.value):
            if not is_in_scope(self.value):
                return

        tuple_len = int(self.get_len().unsigned)
        tuple = self.get_data()

        base_data_type = tuple.type.GetArrayElementType()

        cast = tuple.Cast(base_data_type.GetArrayType(tuple_len))

        index = 0
        for i in range(tuple_len):
            el = cast[i]
            field0 = int(el[2].unsigned)
            if field0 == 0:
                continue
            key = el[0]
            val = el[1]
            child = val.CreateValueFromAddress(key.summary, val.GetLoadAddress(), val.GetType())
            self.child_list.append(child)
            self.children[key.summary] = index
            index += 1

        self.child_list.append(self.value["mode"])
        self.children["mode"] = index

    def has_children(self):
        return bool(self.num_children())


class LLDBDynamicObjectProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        value = value.GetNonSyntheticValue()
        self.value: lldb.SBValue = value[0]
        self.children: OrderedDict[str, int] = OrderedDict()
        self.child_list: list[lldb.SBValue] = []

        while self.value.type.is_pointer:
            self.value = self.value.Dereference()

        self.update()

    def num_children(self):
        return len(self.child_list)

    def get_child_index(self, name: str):
        return self.children[name]

    def get_child_at_index(self, index):
        return self.child_list[index]

    def update(self):
        self.children.clear()
        self.child_list = []

        for i, child in enumerate(self.value.children):
            name = child.name.strip('"')
            new_child = child.CreateValueFromAddress(name, child.GetLoadAddress(), child.GetType())

            self.children[name] = i
            self.child_list.append(new_child)

    def has_children(self):
        return bool(self.num_children())


class LLDBBasicObjectProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value: lldb.SBValue = value

    def num_children(self):
        if self.value is not None:
            return self.value.num_children
        return 0

    def get_child_index(self, name: str):
        return self.value.GetIndexOfChildWithName(name)

    def get_child_at_index(self, index):
        return self.value.GetChildAtIndex(index)

    def update(self):
        pass

    def has_children(self):
        return self.num_children() > 0


class CustomObjectChildrenProvider:
    """
    This children provider handles values returned from lldbDebugSynthetic*
    Nim procedures
    """

    def __init__(self, value: lldb.SBValue, internalDict):
        self.value: lldb.SBValue = get_custom_synthetic(value) or value
        if "lldbdynamicobject" in self.value.type.name.lower():
            self.provider = LLDBDynamicObjectProvider(self.value, internalDict)
        else:
            self.provider = LLDBBasicObjectProvider(self.value, internalDict)

    def num_children(self):
        return self.provider.num_children()

    def get_child_index(self, name: str):
        return self.provider.get_child_index(name)

    def get_child_at_index(self, index):
        return self.provider.get_child_at_index(index)

    def update(self):
        self.provider.update()

    def has_children(self):
        return self.provider.has_children()


def echo(debugger: lldb.SBDebugger, command: str, result, internal_dict):
    debugger.HandleCommand("po " + command)


SUMMARY_FUNCTIONS: dict[str, lldb.SBFunction] = {}
SYNTHETIC_FUNCTIONS: dict[str, lldb.SBFunction] = {}


def get_custom_summary(value: lldb.SBValue) -> Union[str, None]:
    """Get a custom summary if a function exists for it"""
    value = value.GetNonSyntheticValue()
    if value.GetAddress().GetOffset() == 0:
        return None

    base_type = get_base_type(value.type)

    fn = SUMMARY_FUNCTIONS.get(base_type.name)
    if fn is None:
        return None

    fn_type: lldb.SBType = fn.type

    arg_types: lldb.SBTypeList = fn_type.GetFunctionArgumentTypes()
    first_type = arg_types.GetTypeAtIndex(0)

    while value.type.is_pointer:
        value = value.Dereference()

    if first_type.is_pointer:
        command = f"{fn.name}(({first_type.name})" + str(value.GetLoadAddress()) + ");"
    else:
        command = f"{fn.name}(*({first_type.GetPointerType().name})" + str(value.GetLoadAddress()) + ");"

    res = executeCommand(command)

    if res.error.fail:
        return None

    return res.summary.strip('"')


def get_custom_value_summary(value: lldb.SBValue) -> Union[str, None]:
    """Get a custom summary if a function exists for it"""

    fn: lldb.SBFunction = SUMMARY_FUNCTIONS.get(value.type.name)
    if fn is None:
        return None

    command = f"{fn.name}(({value.type.name})" + str(value.signed) + ");"
    res = executeCommand(command)

    if res.error.fail:
        return None

    return res.summary.strip('"')


def get_custom_synthetic(value: lldb.SBValue) -> Union[lldb.SBValue, None]:
    """Get a custom synthetic object if a function exists for it"""
    value = value.GetNonSyntheticValue()
    if value.GetAddress().GetOffset() == 0:
        return None

    base_type = get_base_type(value.type)

    fn = SYNTHETIC_FUNCTIONS.get(base_type.name)
    if fn is None:
        return None

    fn_type: lldb.SBType = fn.type

    arg_types: lldb.SBTypeList = fn_type.GetFunctionArgumentTypes()
    first_type = arg_types.GetTypeAtIndex(0)

    while value.type.is_pointer:
        value = value.Dereference()

    if first_type.is_pointer:
        first_arg = f"({first_type.name}){value.GetLoadAddress()}"
    else:
        first_arg = f"*({first_type.GetPointerType().name}){value.GetLoadAddress()}"

    if arg_types.GetSize() > 1 and fn.GetArgumentName(1) == "Result":
        ret_type = arg_types.GetTypeAtIndex(1)
        ret_type = get_base_type(ret_type)

        command = f"""
            {ret_type.name} lldbT;
            nimZeroMem((void*)(&lldbT), sizeof({ret_type.name}));
            {fn.name}(({first_arg}), (&lldbT));
            lldbT;
        """
    else:
        command = f"{fn.name}({first_arg});"

    res = executeCommand(command)

    if res.error.fail:
        print(res.error)
        return None

    return res


def get_base_type(ty: lldb.SBType) -> lldb.SBType:
    """Get the base type of the type"""
    temp = ty
    while temp.IsPointerType():
        temp = temp.GetPointeeType()
    return temp


def use_base_type(ty: lldb.SBType) -> bool:
    types_to_check = [
        "NF",
        "NF32",
        "NF64",
        "NI",
        "NI8",
        "NI16",
        "NI32",
        "NI64",
        "bool",
        "NIM_BOOL",
        "NU",
        "NU8",
        "NU16",
        "NU32",
        "NU64",
    ]

    for type_to_check in types_to_check:
        if ty.name.startswith(type_to_check):
            return False

    return True


def breakpoint_function_wrapper(frame: lldb.SBFrame, bp_loc, internal_dict):
    """This allows function calls to Nim for custom object summaries and synthetic children"""
    debugger = lldb.debugger

    global SUMMARY_FUNCTIONS
    global SYNTHETIC_FUNCTIONS

    global NIM_IS_V2

    for tname, fn in SYNTHETIC_FUNCTIONS.items():
        debugger.HandleCommand(f"type synthetic delete -w nim {tname}")

    SUMMARY_FUNCTIONS = {}
    SYNTHETIC_FUNCTIONS = {}

    target: lldb.SBTarget = debugger.GetSelectedTarget()

    NIM_IS_V2 = target.FindFirstType("TNimTypeV2").IsValid()

    module = frame.GetSymbolContext(lldb.eSymbolContextModule).module

    for sym in module:
        if (
            not sym.name.startswith("lldbDebugSummary")
            and not sym.name.startswith("lldbDebugSynthetic")
            and not sym.name.startswith("dollar___")
        ):
            continue

        fn_syms: lldb.SBSymbolContextList = target.FindFunctions(sym.name)
        if not fn_syms.GetSize() > 0:
            continue

        fn_sym: lldb.SBSymbolContext = fn_syms.GetContextAtIndex(0)

        fn: lldb.SBFunction = fn_sym.function
        fn_type: lldb.SBType = fn.type
        arg_types: lldb.SBTypeList = fn_type.GetFunctionArgumentTypes()

        if arg_types.GetSize() > 1 and fn.GetArgumentName(1) == "Result":
            pass # don't continue
        elif arg_types.GetSize() != 1:
            continue

        arg_type: lldb.SBType = arg_types.GetTypeAtIndex(0)
        if use_base_type(arg_type):
            arg_type = get_base_type(arg_type)

        if sym.name.startswith("lldbDebugSummary") or sym.name.startswith("dollar___"):
            SUMMARY_FUNCTIONS[arg_type.name] = fn
        elif sym.name.startswith("lldbDebugSynthetic"):
            SYNTHETIC_FUNCTIONS[arg_type.name] = fn
            debugger.HandleCommand(
                f"type synthetic add -w nim -l {__name__}.CustomObjectChildrenProvider {arg_type.name}"
            )


def executeCommand(command, *args):
    debugger = lldb.debugger
    process = debugger.GetSelectedTarget().GetProcess()
    frame: lldb.SBFrame = process.GetSelectedThread().GetSelectedFrame()

    expr_options = lldb.SBExpressionOptions()
    expr_options.SetIgnoreBreakpoints(False)
    expr_options.SetFetchDynamicValue(lldb.eDynamicCanRunTarget)
    expr_options.SetTimeoutInMicroSeconds(30 * 1000 * 1000)  # 30 second timeout
    expr_options.SetTryAllThreads(True)
    expr_options.SetUnwindOnError(False)
    expr_options.SetGenerateDebugInfo(True)
    expr_options.SetLanguage(lldb.eLanguageTypeC)
    expr_options.SetCoerceResultToId(True)
    res = frame.EvaluateExpression(command, expr_options)

    return res


def __lldb_init_module(debugger, internal_dict):
    # fmt: off
    debugger.HandleCommand(f"breakpoint command add -F {__name__}.breakpoint_function_wrapper --script-type python 1")
    debugger.HandleCommand(f"type summary add -w nim -n sequence -F  {__name__}.Sequence -x tySequence_+[[:alnum:]]+$")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SeqChildrenProvider -x tySequence_+[[:alnum:]]+$")

    debugger.HandleCommand(f"type summary add -w nim -n chararray -F  {__name__}.CharArray -x char\s+[\d+]")
    debugger.HandleCommand(f"type summary add -w nim -n array -F  {__name__}.Array -x tyArray_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.ArrayChildrenProvider -x tyArray_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n string -F  {__name__}.NimString NimStringDesc")

    debugger.HandleCommand(f"type summary add -w nim -n stringv2 -F {__name__}.NimString -x NimStringV2$")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.StringChildrenProvider -x NimStringV2$")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.StringChildrenProvider -x NimStringDesc$")

    debugger.HandleCommand(f"type summary add -w nim -n cstring -F  {__name__}.NCSTRING NCSTRING")

    debugger.HandleCommand(f"type summary add -w nim -n object -F  {__name__}.ObjectV2 -x tyObject_+[[:alnum:]]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.ObjectChildrenProvider -x tyObject_+[[:alnum:]]+_+[[:alnum:]]+$")

    debugger.HandleCommand(f"type summary add -w nim -n tframe -F  {__name__}.ObjectV2 -x TFrame$")

    debugger.HandleCommand(f"type summary add -w nim -n rootobj -F  {__name__}.ObjectV2 -x RootObj$")

    debugger.HandleCommand(f"type summary add -w nim -n enum -F  {__name__}.Enum -x tyEnum_+[[:alnum:]]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n hashset -F  {__name__}.HashSet -x tyObject_+HashSet_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.HashSetChildrenProvider -x tyObject_+HashSet_+[[:alnum:]]+")

    debugger.HandleCommand(f"type summary add -w nim -n rope -F  {__name__}.Rope -x tyObject_+Rope[[:alnum:]]+_+[[:alnum:]]+")

    debugger.HandleCommand(f"type summary add -w nim -n setuint -F  {__name__}.Set -x tySet_+tyInt_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetIntChildrenProvider -x tySet_+tyInt[0-9]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n setint -F  {__name__}.Set -x tySet_+tyInt[0-9]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n setuint2 -F  {__name__}.Set -x tySet_+tyUInt[0-9]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetUIntChildrenProvider -x tySet_+tyUInt[0-9]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetUIntChildrenProvider -x tySet_+tyInt_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n setenum -F  {__name__}.EnumSet -x tySet_+tyEnum_+[[:alnum:]]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetEnumChildrenProvider -x tySet_+tyEnum_+[[:alnum:]]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n setchar -F  {__name__}.Set -x tySet_+tyChar_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetCharChildrenProvider -x tySet_+tyChar_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n table -F  {__name__}.Table -x tyObject_+Table_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.TableChildrenProvider -x tyObject_+Table_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n stringtable -F  {__name__}.StringTable -x tyObject_+StringTableObj_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.StringTableChildrenProvider -x tyObject_+StringTableObj_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n tuple2 -F  {__name__}.Tuple -x tyObject_+Tuple_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n tuple -F  {__name__}.Tuple -x tyTuple_+[[:alnum:]]+")

    debugger.HandleCommand(f"type summary add -w nim -n float -F  {__name__}.Float NF")
    debugger.HandleCommand(f"type summary add -w nim -n float32 -F  {__name__}.Float NF32")
    debugger.HandleCommand(f"type summary add -w nim -n float64 -F  {__name__}.Float NF64")
    debugger.HandleCommand(f"type summary add -w nim -n integer -F  {__name__}.Number -x NI")
    debugger.HandleCommand(f"type summary add -w nim -n integer8 -F  {__name__}.Number -x NI8")
    debugger.HandleCommand(f"type summary add -w nim -n integer16 -F  {__name__}.Number -x NI16")
    debugger.HandleCommand(f"type summary add -w nim -n integer32 -F  {__name__}.Number -x NI32")
    debugger.HandleCommand(f"type summary add -w nim -n integer64 -F  {__name__}.Number -x NI64")
    debugger.HandleCommand(f"type summary add -w nim -n bool -F  {__name__}.Bool -x bool")
    debugger.HandleCommand(f"type summary add -w nim -n bool2 -F  {__name__}.Bool -x NIM_BOOL")
    debugger.HandleCommand(f"type summary add -w nim -n uinteger -F  {__name__}.UnsignedNumber -x NU")
    debugger.HandleCommand(f"type summary add -w nim -n uinteger8 -F  {__name__}.UnsignedNumber -x NU8")
    debugger.HandleCommand(f"type summary add -w nim -n uinteger16 -F  {__name__}.UnsignedNumber -x NU16")
    debugger.HandleCommand(f"type summary add -w nim -n uinteger32 -F  {__name__}.UnsignedNumber -x NU32")
    debugger.HandleCommand(f"type summary add -w nim -n uinteger64 -F  {__name__}.UnsignedNumber -x NU64")
    debugger.HandleCommand("type category enable nim")
    debugger.HandleCommand(f"command script add -f  {__name__}.echo echo")
    # fmt: on
