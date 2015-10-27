import strtabs

var tab = newStringTable({"key1": "val1", "key2": "val2"},
                         modeStyleInsensitive)
for i in 0..80:
  tab["key_" & $i] = "value" & $i

for key, val in pairs(tab):
  writeLine(stdout, key, ": ", val)
writeLine(stdout, "length of table ", $tab.len)

writeLine(stdout, `%`("$key1 = $key2; ${PATH}", tab, {useEnvironment}))
