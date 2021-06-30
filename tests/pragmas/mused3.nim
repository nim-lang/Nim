#[
ran from trunner
]#






# line 10
when defined case1:
  from mused3a import nil
  from mused3b import nil
  mused3a.fn1()

when defined case2:
  from mused3a as m1 import nil
  m1.fn1()

when defined case3:
  from mused3a import fn1
  fn1()

when defined case4:
  from mused3a as m1 import fn1
  m1.fn1()

when defined case5:
  import mused3a as m1
  fn1()

when defined case6:
  import mused3a except nonexistent
  fn1()

when defined case7:
  import mused3a
  mused3a.fn1()

when defined case8:
  # re-export test
  import mused3a except nonexistent
  gn1()

when defined case9:
  # re-export test
  import mused3a
  gn1()

when defined case10:
  #[
  edge case which happens a lot in compiler code:
  don't report UnusedImport for mused3b here even though it works without `import mused3b`,
  because `a.b0.f0` is accessible from both mused3a and mused3b (fields are given implicit access)
  ]#
  import mused3a
  import mused3b
  var a: Bar
  discard a.b0.f0

when false:
  when defined case11:
    #[
    xxx minor bug: this should give:
    Warning: imported and not used: 'm2' [UnusedImport]
    but doesn't, because currently implementation in `markOwnerModuleAsUsed`
    only looks at `fn1`, not fully qualified call `m1.fn1()
    ]#
    from mused3a as m1 import nil
    from mused3a as m2 import nil
    m1.fn1()

when defined case12:
  import mused3a
  import mused3a
  fn1()
