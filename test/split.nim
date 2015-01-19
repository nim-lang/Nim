import unittest, strutils
include nre

suite "string splitting":
  test "splitting strings":
    check("12345".split(re("")) == @["1", "2", "3", "4", "5"])
    check("1 2 3 4 5 6 ".split(re" ") == @["1", "2", "3", "4", "5", "6", ""])
    check("1  2  ".split(re(" ")) == @["1", "", "2", "", ""])
    check("1 2".split(re(" ")) == @["1", "2"])
    check("foo".split(re("foo")) == @["", ""])

  test "captured patterns":
    check("12".split(re"(\d)") == @["", "1", "", "2", ""])

  test "maxsplit":
    check("123".split(re"", maxsplit = 1) == @["1", "23"])
    check("123".split(re"", maxsplit = 0) == @["123"])
    check("123".split(re"", maxsplit = -1) == @["1", "2", "3"])

  test "perl split tests":
    check("forty-two"                    .split(re"")      .join(",") == "f,o,r,t,y,-,t,w,o")
    check("forty-two"                    .split(re"", 3)   .join(",") == "f,o,rty-two")
    check("split this string"            .split(re" ")     .join(",") == "split,this,string")
    check("split this string"            .split(re" ", 2)  .join(",") == "split,this string")
    check("try$this$string"              .split(re"\$")    .join(",") == "try,this,string")
    check("try$this$string"              .split(re"\$", 2) .join(",") == "try,this$string")
    check("comma, separated, values"     .split(re", ")    .join("|") == "comma|separated|values")
    check("comma, separated, values"     .split(re", ", 2) .join("|") == "comma|separated, values")
    check("Perl6::Camelia::Test"         .split(re"::")    .join(",") == "Perl6,Camelia,Test")
    check("Perl6::Camelia::Test"         .split(re"::", 2) .join(",") == "Perl6,Camelia::Test")
    check("split,me,please"              .split(re",")     .join("|") == "split|me|please")
    check("split,me,please"              .split(re",", 2)  .join("|") == "split|me,please")
    check("Hello World    Goodbye   Mars".split(re"\s+")   .join(",") == "Hello,World,Goodbye,Mars")
    check("Hello World    Goodbye   Mars".split(re"\s+", 3).join(",") == "Hello,World,Goodbye   Mars")
    check("Hello test"                   .split(re"(\s+)") .join(",") == "Hello, ,test")
    check("this will be split"           .split(re" ")     .join(",") == "this,will,be,split")
    check("this will be split"           .split(re" ", 3)  .join(",") == "this,will,be split")
    check("a.b"                          .split(re"\.")    .join(",") == "a,b")
    check(""                             .split(re"")      .len       == 0)
    check(":"                            .split(re"")      .len       == 1)
