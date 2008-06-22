# test another strange bug ... (I hate this compiler; it is much too buggy!)

proc putEnv(key, val: string) =
  # XXX: we have to leak memory here, as we cannot
  # free it before the program ends (says Borland's
  # documentation)
  var
    env: ptr array[0..500000, char]
  env = alloc(length(key) + length(val) + 2)
  for i in 0..length(key)-1: env[i] = key[i]
  env[length(key)] = '='
  for i in 0..length(val)-1:
    env[length(key)+1+i] = val[i]
