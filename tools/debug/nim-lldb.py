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


def colored(in_str, *args, **kwargs):
    # TODO: Output in color if user is in terminal
    return in_str


def reprEnum(val, typ):
    """
    this is a port of the nim runtime function `reprEnum` to python
    NOTE: DOES NOT WORK WITH ORC
    """
    val = int(val)
    n = typ["node"]
    sons_type = n["sons"].type.GetPointeeType().GetPointeeType()
    sons = n["sons"].deref.Cast(sons_type.GetPointerType().GetArrayType(3))
    flags = int(typ["flags"].unsigned)
    # 1 << 6 is {ntfEnumHole}
    if ((1 << 6) & flags) == 0:
        offset = val - sons[0]["offset"].unsigned
        if offset >= 0 and 0 < n["len"].unsigned:
            return NCSTRING(sons[offset]["name"])[1:-1]
    else:
        # ugh we need a slow linear search:
        for i in range(n["len"].unsigned):
            if sons[i]["offset"].unsigned == val:
                return NCSTRING(sons[i]["name"])[1:-1]

    return str(val) + " (invalid data!)"


def get_nti(value, nim_name=None):
    """DOES NOT WORK WITH ORC"""
    name_split = value.type.name.split("_")
    type_nim_name = nim_name or name_split[1]
    id_string = name_split[-1].split(" ")[0]

    type_info_name = "NTI" + type_nim_name.lower() + "__" + id_string + "_"
    print("TYPEINFONAME: ", type_info_name)
    nti = value.target.FindFirstGlobalVariable(type_info_name)
    if nti is None:
        type_info_name = "NTI" + "__" + id_string + "_"
        nti = value.target.FindFirstGlobalVariable(type_info_name)
    if nti is None:
        print(
            f"NimEnumPrinter: lookup global symbol: '{type_info_name}' failed for {value.type.name}.\n"
        )
    return type_nim_name, nti


def enum_to_string(value):
    type_nim_name, nti = get_nti(value)
    if nti is None:
        return type_nim_name + "(" + str(value.unsigned) + ")"
    return reprEnum(value.signed, nti), nti


def to_string(value):
    # For getting NimStringDesc * value
    data = value["data"]
    try:
        size = int(value["Sup"]["len"].unsigned)
        if size > 2**14:
            return None
    except TypeError:
        return None

    cast = data.Cast(value.target.FindFirstType("char").GetArrayType(size))
    return bytearray(cast.data.uint8s).decode("utf-8")


def to_stringV2(value: lldb.SBValue):
    # For getting NimStringDesc * value
    data = value["p"]["data"]
    try:
        size = int(value["len"].signed)
        if size > 2**14:
            return "... (too long)"
    except TypeError:
        return ""

    base_data_type = data.type.GetArrayElementType().GetTypedefedType()
    cast = data.Cast(base_data_type.GetArrayType(size))
    return bytearray(cast.data.uint8s).decode("utf-8")


def NimStringDesc(value, internal_dict):
    res = to_string(value)
    if res:
        return colored('"' + res + '"', "red")
    else:
        return str(value)


def NimStringV2(value: lldb.SBValue, internal_dict):
    res = to_stringV2(value.GetNonSyntheticValue())
    if res is not None:
        return colored('"' + res + '"', "red")
    else:
        return str(value)


def NCSTRING(value: lldb.SBValue, internal_dict=None):
    ty = value.Dereference().type
    val = value.target.CreateValueFromAddress(
        value.name or "temp", lldb.SBAddress(value.unsigned, value.target), ty
    ).AddressOf()
    return val.summary


def ObjectV1(value, internal_dict):
    if not value.num_children and not value.value:
        return ""

    ignore_fields = set()
    if "colonObjectType" in value.type.name:
        value = value.Dereference()
        ignore_fields.add("Sup")

    if not value.type.name:
        return ""

    summary = value.summary
    if summary is not None:
        return summary

    if "_" in value.type.name:
        obj_name = value.type.name.split("_")[1].replace("colonObjectType", "")
    else:
        obj_name = value.type.name

    obj_name = colored(obj_name, "green")

    num_children = value.num_children

    fields = ", ".join(
        [
            value[i].name
            + ": "
            + (value[i].summary or value[i].value or value[i].type.name or "not found")
            for i in range(num_children)
            if value[i].name not in ignore_fields
        ]
    )

    res = f"{obj_name}({fields})"
    return res


def ObjectV2(value: lldb.SBValue, internal_dict):
    custom_summary = get_summary(value)
    if not custom_summary is None:
        return custom_summary

    orig_value = value.GetNonSyntheticValue()
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
    while value.type.is_pointer:
        value = value.Dereference()
    return colored(str(value.signed), "yellow")


def Float(value: lldb.SBValue, internal_dict):
    while value.type.is_pointer:
        value = value.Dereference()
    return colored(str(value.value), "yellow")


def UnsignedNumber(value: lldb.SBValue, internal_dict):
    while value.type.is_pointer:
        value = value.Dereference()
    return colored(str(value.unsigned), "yellow")


def Bool(value: lldb.SBValue, internal_dict):
    while value.type.is_pointer:
        value = value.Dereference()
    return colored(str(value.GetValue()), "red")


def CharArray(value: lldb.SBValue, internal_dict):
    return str([colored(f"'{char}'", "red") for char in value.uint8s])


def Array(value: lldb.SBValue, internal_dict):
    value = value.GetNonSyntheticValue()
    return "[" + ", ".join([value[i].summary for i in range(value.num_children)]) + "]"


def Tuple(value: lldb.SBValue, internal_dict):
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


def Enum(value, internal_dict):
    tname = value.type.name.split("_")[1]
    return colored(f"{tname}." + str(value.signed), "blue")


def EnumSet(value, internal_dict):
    type_nim_name = value.type.name.split("_")[2]
    # type_nim_name, nti = get_nti(value, type_nim_name)

    val = int(value.signed)
    # if nti:
    #     enum_strings = []
    #     i = 0
    #     while val > 0:
    #         if (val & 1) == 1:
    #             enum_strings.append(reprEnum(i, nti))
    #         val = val >> 1
    #         i += 1

    #     return '{' + ', '.join(enum_strings) + '}'
    return colored(f"{type_nim_name}." + str(val), "blue")


def Set(value, internal_dict):
    vals = []
    max_vals = 7
    for child in value.children:
        vals.append(child.value)
        if len(vals) > max_vals:
            vals.append("...")
            break

    return "{" + ", ".join(vals) + "}"


def Table(value: lldb.SBValue, internal_dict):
    fields = []

    for i in range(value.num_children):
        key = value[i].name
        val = value[i].summary
        fields.append(f"{key}: {val}")

    table_suffix = "Table"
    return "{" + ", ".join(fields) + f"}}.{table_suffix}"


def HashSet(value: lldb.SBValue, internal_dict):
    fields = []

    for i in range(value.num_children):
        fields.append(f"{value[i].summary}")

    table_suffix = "HashSet"

    return "{" + ", ".join(fields) + f"}}.{table_suffix}"


def StringTable(value: lldb.SBValue, internal_dict):
    table = value.GetNonSyntheticValue()
    mode = table["mode"].unsigned

    table_suffix = "StringTable"

    table_mode = ""
    if mode == 0:
        table_mode = "Case Sensitive"
    elif mode == 1:
        table_mode = "Case Insensitive"
    elif mode == 2:
        table_mode = "Style Insensitive"

    fields = []

    for i in range(value.num_children):
        key = value[i].name
        val = value[i].summary
        fields.append(f"{key}: {val}")

    return "{" + ", ".join(fields) + f"}}.{table_suffix}({table_mode})"


def Sequence(value: lldb.SBValue, internal_dict):
    value = value.GetNonSyntheticValue()

    data_len = int(value["len"].unsigned)
    data = value["p"]["data"]
    base_data_type = data.type.GetArrayElementType()

    cast = data.Cast(base_data_type.GetArrayType(data_len))

    return (
        "@["
        + ", ".join([cast[i].summary or cast[i].type.name for i in range(data_len)])
        + "]"
    )


class StringChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.data_type: lldb.SBType
        self.first_element: lldb.SBValue
        self.update()
        self.count = 0

    def num_children(self):
        return self.count

    def get_child_index(self, name):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        offset = index * self.data_size
        return self.first_element.CreateChildAtOffset(
            "[" + str(index) + "]", offset, self.data_type
        )

    def update(self):
        data = self.value["p"]["data"]
        size = int(self.value["len"].unsigned)

        self.count = size
        self.first_element = data

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
        return self.value.num_children

    def get_child_index(self, name: str):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        offset = index * self.value[index].GetByteSize()
        return self.first_element.CreateChildAtOffset(
            "[" + str(index) + "]", offset, self.data_type
        )

    def update(self):
        if not self.has_children():
            return

        self.first_element = self.value[0]
        self.data_type = self.value.type.GetArrayElementType()

    def has_children(self):
        return bool(self.num_children())


class SeqChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        self.value = value
        self.data_type: lldb.SBType
        self.first_element: lldb.SBValue
        self.data: lldb.SBValue
        self.update()

    def num_children(self):
        return int(self.value["len"].unsigned)

    def get_child_index(self, name: str):
        return int(name.lstrip("[").rstrip("]"))

    def get_child_at_index(self, index):
        offset = index * self.data[index].GetByteSize()
        return self.first_element.CreateChildAtOffset(
            "[" + str(index) + "]", offset, self.data_type
        )

    def update(self):
        if not self.has_children():
            return

        data = self.value["p"]["data"]
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
        stack = [self.value]

        index = 0

        while stack:
            cur_val = stack.pop()
            while cur_val.type.is_pointer:
                cur_val = cur_val.Dereference()

            if cur_val.num_children > 0 and cur_val[0].name == "m_type":
                if "_" in cur_val.type.name:
                    tname = cur_val.type.name.split("_")[1].replace(
                        "colonObjectType", ""
                    )
                else:
                    tname = cur_val.type.name
                if tname == "TNimTypeV2":
                    # We've reached the end
                    break

            if (
                cur_val.num_children > 0
                and cur_val[0].name == "Sup"
                and cur_val[0].type.name.startswith("tyObject")
            ):
                stack.append(cur_val[0])

            for i in range(cur_val.num_children):
                child = cur_val[i]
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

    def update(self):
        self.child_list = []
        data = self.value["data"]

        tuple_len = int(data["len"].unsigned)
        tuple = data["p"]["data"]

        base_data_type = tuple.type.GetArrayElementType()

        cast = tuple.Cast(base_data_type.GetArrayType(tuple_len))

        index = 0
        for i in range(tuple_len):
            el = cast[i]
            field0 = int(el["Field0"].unsigned)
            if field0 == 0:
                continue
            key = el["Field1"]
            child = key.CreateValueFromAddress(
                f"[{str(index)}]", key.GetLoadAddress(), key.GetType()
            )
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
                        child = self.value.synthetic_child_from_data(
                            f"[{len(self.child_list)}]", data, self.ty
                        )
                        self.child_list.append(child)
                    temp = temp >> 1
                    cur_pos += 1
                    num_bits -= 1
                cur_pos += num_bits
            else:
                cur_pos += 8

    def has_children(self):
        return bool(self.num_children())


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
        bits = self.value.GetByteSize() * 8

        cur_pos = -(bits // 2)

        if self.value.num_children > 0:
            children = self.value.children
        else:
            children = [self.value]

        for child in children:
            child_val = child.signed
            if child_val != 0:
                temp = child_val
                num_bits = 8
                while temp != 0:
                    is_set = temp & 1
                    if is_set == 1:
                        data = lldb.SBData.CreateDataFromInt(cur_pos)
                        child = self.value.synthetic_child_from_data(
                            f"[{len(self.child_list)}]", data, self.ty
                        )
                        self.child_list.append(child)
                    temp = temp >> 1
                    cur_pos += 1
                    num_bits -= 1
                cur_pos += num_bits
            else:
                cur_pos += 8

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

        cur_pos = 0
        if self.value.num_children > 0:
            children = self.value.children
        else:
            children = [self.value]

        for child in children:
            child_val = child.signed
            if child_val != 0:
                temp = child_val
                num_bits = 8
                while temp != 0:
                    is_set = temp & 1
                    if is_set == 1:
                        data = lldb.SBData.CreateDataFromInt(cur_pos)
                        child = self.value.synthetic_child_from_data(
                            f"[{len(self.child_list)}]", data, self.ty
                        )
                        self.child_list.append(child)
                    temp = temp >> 1
                    cur_pos += 1
                    num_bits -= 1
                cur_pos += num_bits
            else:
                cur_pos += 8

    def has_children(self):
        return bool(self.num_children())


class SetEnumChildrenProvider:
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

        cur_pos = 0
        if self.value.num_children > 0:
            children = self.value.children
        else:
            children = [self.value]

        for child in children:
            child_val = child.unsigned
            if child_val != 0:
                temp = child_val
                num_bits = 8
                while temp != 0:
                    is_set = temp & 1
                    if is_set == 1:
                        data = lldb.SBData.CreateDataFromInt(cur_pos)
                        child = self.value.synthetic_child_from_data(
                            f"[{len(self.child_list)}]", data, self.ty
                        )
                        self.child_list.append(child)
                    temp = temp >> 1
                    cur_pos += 1
                    num_bits -= 1
                cur_pos += num_bits
            else:
                cur_pos += 8

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

    def update(self):
        self.child_list = []
        data = self.value["data"]

        tuple_len = int(data["len"].unsigned)
        tuple = data["p"]["data"]

        base_data_type = tuple.type.GetArrayElementType()

        cast = tuple.Cast(base_data_type.GetArrayType(tuple_len))

        index = 0
        for i in range(tuple_len):
            el = cast[i]
            field0 = int(el["Field0"].unsigned)
            if field0 == 0:
                continue
            key = el["Field1"]
            val = el["Field2"]
            child = val.CreateValueFromAddress(
                key.summary, val.GetLoadAddress(), val.GetType()
            )
            self.child_list.append(child)
            self.children[key.summary] = index
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

    def update(self):
        self.children.clear()
        self.child_list = []
        data = self.value["data"]

        tuple_len = int(data["len"].unsigned)
        tuple = data["p"]["data"]

        base_data_type = tuple.type.GetArrayElementType()

        cast = tuple.Cast(base_data_type.GetArrayType(tuple_len))

        index = 0
        for i in range(tuple_len):
            el = cast[i]
            field0 = int(el["Field2"].unsigned)
            if field0 == 0:
                continue
            key = el["Field0"]
            val = el["Field1"]
            child = val.CreateValueFromAddress(
                key.summary, val.GetLoadAddress(), val.GetType()
            )
            self.child_list.append(child)
            self.children[key.summary] = index
            index += 1

    def has_children(self):
        return bool(self.num_children())


class CustomObjectChildrenProvider:
    def __init__(self, value: lldb.SBValue, internalDict):
        print("CUSTOMOBJ: ", value.name)
        self.value: lldb.SBValue = get_synthetic(value) or value
        for child in self.value.children:
            print(child)

    def num_children(self):
        return self.value.num_children

    def get_child_index(self, name: str):
        return self.value.GetIndexOfChildWithName(name)

    def get_child_at_index(self, index):
        return self.value.GetChildAtIndex(index)

    def update(self):
        pass

    def has_children(self):
        return self.num_children() > 0


def echo(debugger: lldb.SBDebugger, command: str, result, internal_dict):
    debugger.HandleCommand("po " + command)


SUMMARY_FUNCTIONS: dict[str, lldb.SBFunction] = {}
SYNTHETIC_FUNCTIONS: dict[str, lldb.SBFunction] = {}


def get_summary(value: lldb.SBValue) -> Union[str, None]:
    base_type = get_base_type(value.type)

    fn = SUMMARY_FUNCTIONS.get(base_type.name)
    if fn is None:
        return None

    res = executeCommand(
        f"{fn.name}(*({base_type.GetPointerType().name})" + str(value.GetLoadAddress()) + ");"
    )

    if res.error.fail:
        return None

    return res.summary.strip('"')


def get_synthetic(value: lldb.SBValue) -> Union[lldb.SBValue, None]:
    base_type = get_base_type(value.type)

    fn = SYNTHETIC_FUNCTIONS.get(base_type.name)
    if fn is None:
        return None

    res = executeCommand(
        f"{fn.name}(*({base_type.GetPointerType().name})" + str(value.GetLoadAddress()) + ");"
    )

    if res.error.fail:
        return None

    return res


def get_base_type(ty: lldb.SBType) -> lldb.SBType:
    temp = ty
    while temp.IsPointerType():
        temp = temp.GetPointeeType()
    return temp


def breakpoint_function_wrapper(frame: lldb.SBFrame, bp_loc, internal_dict):
    """This allows function calls to Nim for custom object summaries and synthetic children"""
    debugger = lldb.debugger

    global SUMMARY_FUNCTIONS
    global SYNTHETIC_FUNCTIONS
    for tname, fn in SYNTHETIC_FUNCTIONS.items():
        print("DELETING SYNTH: ", tname)
        debugger.HandleCommand(f"type synthetic delete -w nim {tname}")

    SUMMARY_FUNCTIONS = {}
    SYNTHETIC_FUNCTIONS = {}

    target: lldb.SBTarget = debugger.GetSelectedTarget()
    print("BREAKPOINT")
    module = frame.GetSymbolContext(lldb.eSymbolContextModule).module

    for sym in module:
        if not sym.name.startswith("lldbDebugSummary") and not sym.name.startswith(
            "lldbDebugSynthetic"
        ):
            continue

        print("SYM: ", sym.name)

        fn_syms: lldb.SBSymbolContextList = target.FindFunctions(sym.name)
        if not fn_syms.GetSize() > 0:
            continue
        fn_sym: lldb.SBSymbolContext = fn_syms.GetContextAtIndex(0)

        print("fn found!")

        fn: lldb.SBFunction = fn_sym.function
        fn_type: lldb.SBType = fn.type
        arg_types: lldb.SBTypeList = fn_type.GetFunctionArgumentTypes()

        if not arg_types.GetSize() > 0:
            continue
        arg_type: lldb.SBType = get_base_type(arg_types.GetTypeAtIndex(0))

        print("FIRST ARG TYPE: ", arg_type.name)

        if sym.name.startswith("lldbDebugSummary"):
            SUMMARY_FUNCTIONS[arg_type.name] = fn
        elif sym.name.startswith("lldbDebugSynthetic"):
            SYNTHETIC_FUNCTIONS[arg_type.name] = fn
            debugger.HandleCommand(
                f"type synthetic add -w nim -l {__name__}.CustomObjectChildrenProvider -x {arg_type.name}$"
            )


def executeCommand(command, *args):
    debugger = lldb.debugger
    process = debugger.GetSelectedTarget().GetProcess()
    frame: lldb.SBFrame = process.GetSelectedThread().GetSelectedFrame()
    # module = frame.GetSymbolContext(lldb.eSymbolContextModule).module
    # for sym in module:
    #     print("SYM: ", sym.name)
    # target = debugger.GetSelectedTarget()

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
    # if res.error.fail:
    #     print("ERROR: ", res.error.GetError())
    #     return str(res.error)
    return res


def __lldb_init_module(debugger, internal_dict):
    # debugger.HandleCommand(f"type summary add -w nim -n any -F  {__name__}.CatchAll -x .*")
    debugger.HandleCommand(f"type summary add -w nim -n sequence -F  {__name__}.Sequence -x tySequence_+[[:alnum:]]+$")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SeqChildrenProvider -x tySequence_+[[:alnum:]]+$")

    debugger.HandleCommand(f"type summary add -w nim -n chararray -F  {__name__}.CharArray -x char\s+[\d+]")
    debugger.HandleCommand(f"type summary add -w nim -n array -F  {__name__}.Array -x tyArray_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.ArrayChildrenProvider -x tyArray_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n string -F  {__name__}.NimStringDesc NimStringDesc")

    debugger.HandleCommand(f"type summary add -w nim -n stringv2 -F {__name__}.NimStringV2 -x NimStringV2$")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.StringChildrenProvider -x NimStringV2$")

    debugger.HandleCommand(f"type summary add -w nim -n cstring -F  {__name__}.NCSTRING NCSTRING")

    debugger.HandleCommand(f"type summary add -w nim -n object -F  {__name__}.ObjectV2 -x tyObject_+[[:alnum:]]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.ObjectChildrenProvider -x tyObject_+[[:alnum:]]+_+[[:alnum:]]+$")

    debugger.HandleCommand(f"type summary add -w nim -n tframe -F  {__name__}.ObjectV2 -x TFrame$")

    debugger.HandleCommand(f"type summary add -w nim -n rootobj -F  {__name__}.ObjectV2 -x RootObj$")

    debugger.HandleCommand(f"type summary add -w nim -n enum -F  {__name__}.Enum -x tyEnum_+[[:alnum:]]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n hashset -F  {__name__}.HashSet -x tyObject_+HashSet_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.HashSetChildrenProvider -x tyObject_+HashSet_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n setuint -F  {__name__}.Set -x tySet_+tyInt_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetIntChildrenProvider -x tySet_+tyInt[0-9]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n setint -F  {__name__}.Set -x tySet_+tyInt[0-9]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n setuint2 -F  {__name__}.Set -x tySet_+tyUInt[0-9]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetUIntChildrenProvider -x tySet_+tyUInt[0-9]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetUIntChildrenProvider -x tySet_+tyInt_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n setenum -F  {__name__}.EnumSet -x tySet_+tyEnum_+[[:alnum:]]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetUIntChildrenProvider -x tySet_+tyEnum_+[[:alnum:]]+_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n setchar -F  {__name__}.Set -x tySet_+tyChar_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.SetCharChildrenProvider -x tySet_+tyChar_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n table -F  {__name__}.Table -x tyObject_+Table_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.TableChildrenProvider -x tyObject_+Table_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n stringtable -F  {__name__}.StringTable -x tyObject_+StringTableObj_+[[:alnum:]]+")
    debugger.HandleCommand(f"type synthetic add -w nim -l {__name__}.StringTableChildrenProvider -x tyObject_+StringTableObj_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n tuple2 -F  {__name__}.Tuple -x tyObject_+Tuple_+[[:alnum:]]+")
    debugger.HandleCommand(f"type summary add -w nim -n tuple -F  {__name__}.Tuple -x tyTuple_+[[:alnum:]]+")
    # debugger.HandleCommand(f"type summary add -w nim -n TNimType -F  {__name__}.Object TNimType")
    debugger.HandleCommand(f"type summary add -w nim -n TNimTypeV2 -F  {__name__}.ObjectV2 TNimTypeV2")
    # debugger.HandleCommand(f"type summary add -w nim -n TNimNode -F  {__name__}.Object TNimNode")
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
    debugger.HandleCommand(f"command script add -f {__name__}.handle_command ddp")
    debugger.HandleCommand(f"breakpoint command add -F {__name__}.breakpoint_function_wrapper --script-type python 1")