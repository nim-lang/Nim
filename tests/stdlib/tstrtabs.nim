discard """
sortoutput: true
output: '''
key1: value1
key2: value2
key_0: value0
key_10: value10
key_11: value11
key_12: value12
key_13: value13
key_14: value14
key_15: value15
key_16: value16
key_17: value17
key_18: value18
key_19: value19
key_20: value20
key_21: value21
key_22: value22
key_23: value23
key_24: value24
key_25: value25
key_26: value26
key_27: value27
key_28: value28
key_29: value29
key_30: value30
key_31: value31
key_32: value32
key_33: value33
key_34: value34
key_35: value35
key_36: value36
key_37: value37
key_38: value38
key_39: value39
key_3: value3
key_40: value40
key_41: value41
key_42: value42
key_43: value43
key_44: value44
key_45: value45
key_46: value46
key_47: value47
key_48: value48
key_49: value49
key_4: value4
key_50: value50
key_51: value51
key_52: value52
key_53: value53
key_54: value54
key_55: value55
key_56: value56
key_57: value57
key_58: value58
key_59: value59
key_5: value5
key_60: value60
key_61: value61
key_62: value62
key_63: value63
key_64: value64
key_65: value65
key_66: value66
key_67: value67
key_68: value68
key_69: value69
key_6: value6
key_70: value70
key_71: value71
key_72: value72
key_73: value73
key_74: value74
key_75: value75
key_76: value76
key_77: value77
key_78: value78
key_79: value79
key_7: value7
key_80: value80
key_8: value8
key_9: value9
length of table 0
length of table 81
value1 = value2
'''
"""

import strtabs

var tab = newStringTable({"key1": "val1", "key2": "val2"},
                         modeStyleInsensitive)
for i in 0..80:
  tab["key_" & $i] = "value" & $i

for key, val in pairs(tab):
  writeLine(stdout, key, ": ", val)
writeLine(stdout, "length of table ", $tab.len)

writeLine(stdout, `%`("$key1 = $key2", tab, {useEnvironment}))
tab.clear
writeLine(stdout, "length of table ", $tab.len)

block:
  var x = {"k": "v", "11": "22", "565": "67"}.newStringTable
  doAssert x["k"] == "v"
  doAssert x["11"] == "22"
  doAssert x["565"] == "67"
  x["11"] = "23"
  doAssert x["11"] == "23"

  x.clear(modeCaseInsensitive)
  x["11"] = "22"
  doAssert x["11"] == "22"
