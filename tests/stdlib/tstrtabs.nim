import strtabs

var tab = newStringTable({"key1": "val1", "key2": "val2"},
                         modeStyleInsensitive)
for i in 0..80:
  tab["key_" & $i] = "value" & $i

for key, val in pairs(tab):
  writeln(stdout, key, ": ", val)
writeln(stdout, "length of table ", $tab.len)

writeln(stdout, `%`("$key1 = $key2; ${PATH}", tab, {useEnvironment}))
