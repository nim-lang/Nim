import std/tempfiles



doAssert mkdtemp("nim", "tmp") != mkdtemp("nim", "tmp")
doAssert mkstemp("nim", ".tmp") != mkstemp("nim", ".tmp")
