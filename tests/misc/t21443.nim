import std/envvars

# bug #19292
putEnv("NimPutEnvTest", "test")
# bug #21122
doAssert getEnv("NimPutEnvTest") == "test"
