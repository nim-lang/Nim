import std/tempfiles


doAssert createTempDir("nim", "tmp") != createTempDir("nim", "tmp")
doAssert createTempFile("nim", ".tmp") != createTempFile("nim", ".tmp")
