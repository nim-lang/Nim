# bug #3670

template someTempl(someConst: bool) =
  when someConst:
    var a : int
  if true:
    when not someConst:
      var a : int
    a = 5

someTempl(true)
