mode = ScriptMode.Verbose

case paramStr(3):
  of "test1":
    #543
    block:
      let s = "abc"
      discard s[len(s)]
  of "test2":
    #537
    block:
      var s = "abc"
      s[len(s)] = 'd'
  of "test3":
    #588
    block:
      let arr = ['a', 'b', 'c']
      discard arr[len(arr)]
  of "test4":
    #588
    block:
      var arr = ['a', 'b', 'c']
      arr[len(arr)] = 'd'
