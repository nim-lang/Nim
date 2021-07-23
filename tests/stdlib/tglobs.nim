import std/private/globs

template main =
  when defined(windows):
    doAssert nativeToUnixPath("C:") == "/C"
    doAssert nativeToUnixPath(r"D:\") == "/D/"
    doAssert nativeToUnixPath(r"E:\a") == "/E/a"
    doAssert nativeToUnixPath(r"E:\a1\") == "/E/a1/"
    doAssert nativeToUnixPath(r"E:\a1\bc") == "/E/a1/bc"
    doAssert nativeToUnixPath(r"\a1\bc") == "/a1/bc"
    doAssert nativeToUnixPath(r"a1\bc") == "a1/bc"
    doAssert nativeToUnixPath("a1") == "a1"
    doAssert nativeToUnixPath("") == ""
    doAssert nativeToUnixPath(".") == "."
    doAssert nativeToUnixPath("..") == ".."
    doAssert nativeToUnixPath(r"..\") == "../"
    doAssert nativeToUnixPath(r"..\..\.\") == "../.././"

static: main()
main()
