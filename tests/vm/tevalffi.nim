discard """
  cmd: "nim c --experimental:compiletimeFFI $file"
  nimout: '''
foo
foo:100
foo:101
foo:102:103
foo:102:103:104
foo:0.03:asdf:103:105
ret={s1:foobar s2:foobar age:25 pi:3.14}
'''
  output: '''
foo
foo:100
foo:101
foo:102:103
foo:102:103:104
foo:0.03:asdf:103:105
ret={s1:foobar s2:foobar age:25 pi:3.14}
'''
  disabled: "true"
"""

# re-enable for windows once libffi can be installed in koch.nim
# With win32 (not yet win64), libffi on windows works and this test passes.

when defined(linux):
  {.passL: "-lm".} # for exp
proc c_exp(a: float64): float64 {.importc: "exp", header: "<math.h>".}

proc c_printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}

const snprintfName = when defined(windows): "_snprintf" else: "snprintf"
proc c_snprintf*(buffer: pointer, buf_size: uint, format: cstring): cint {.importc: snprintfName, header: "<stdio.h>", varargs .}

proc c_malloc(size:uint):pointer {.importc:"malloc", header: "<stdlib.h>".}
proc c_free(p: pointer) {.importc:"free", header: "<stdlib.h>".}

proc fun() =
  block: # c_exp
    var x = 0.3
    let b = c_exp(x)
    let b2 = int(b*1_000_000) # avoids floating point equality
    doAssert b2 == 1349858
    doAssert c_exp(0.3) == c_exp(x)
    const x2 = 0.3
    doAssert c_exp(x2) == c_exp(x)

  block: # c_printf
    c_printf("foo\n")
    c_printf("foo:%d\n", 100)
    c_printf("foo:%d\n", 101.cint)
    c_printf("foo:%d:%d\n", 102.cint, 103.cint)
    let temp = 104.cint
    c_printf("foo:%d:%d:%d\n", 102.cint, 103.cint, temp)
    var temp2 = 105.cint
    c_printf("foo:%g:%s:%d:%d\n", 0.03, "asdf", 103.cint, temp2)

  block: # c_snprintf, c_malloc, c_free
    let n: uint = 50
    var buffer2: pointer = c_malloc(n)
    var s: cstring = "foobar"
    var age: cint = 25
    let j = c_snprintf(buffer2, n, "s1:%s s2:%s age:%d pi:%g", s, s, age, 3.14)
    c_printf("ret={%s}\n", buffer2)
    c_free(buffer2) # not sure it has an effect

  block: # c_printf bug
    var a = 123
    var a2 = a.addr
    #[
    bug: different behavior between CT RT in this case:
    at CT, shows foo2:a=123
    at RT, shows foo2:a=<address as int>
    ]#
    if false:
      c_printf("foo2:a=%d\n", a2)

static:
  fun()
fun()
