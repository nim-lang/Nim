#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## 这个模块定义了编译时关于类型的反射procs。
##
## 未稳定的 API.

export system.`$` # for backward compatibility


proc name*(t: typedesc): string {.magic: "TypeTrait".}
  ## 返回给定类型的名字。
  ##
  ## 从v0.20开始，这个proc是system模块 \`$\`(t) 的别名。

proc arity*(t: typedesc): int {.magic: "TypeTrait".} =
  ## 返回给定类型的参数个数。
  ## 这是 "类型" 的元素的个数或者给定类型 ``t`` 具有的泛型参数的个数。 
  runnableExamples:
    assert arity(seq[string]) == 1
    assert arity(array[3, int]) == 2
    assert arity((int, int, float, string)) == 4

proc genericHead*(t: typedesc): typedesc {.magic: "TypeTrait".}
  ## 接受一个实例化的泛型类型并返回其未实例化的形式。 
  ##
  ## 例如:
  ## * `seq[int].genericHead` 返回的只是 `seq`
  ## * `seq[int].genericHead[float]` 返回的是 `seq[float]`
  ##
  ## 如果提供的类型是非泛型，则产生成编译时错误。 
  ## 
  ##
  ## 另请参阅:
  ## * `stripGenericParams <#stripGenericParams,typedesc>`_
  ##
  ## 例子:
  ##
  ## .. code-block:: nim
  ##   type
  ##     Functor[A] = concept f
  ##       type MatchedGenericType = genericHead(f.type)
  ##         # `f` 将是 `Option[T]` 之类类型的值
  ##         # `MatchedGenericType` 将成为 `Option` 类型


proc stripGenericParams*(t: typedesc): typedesc {.magic: "TypeTrait".}
  ## 这个 trait 和 `genericHead <#genericHead,typedesc>`_ 相似，
  ## 不同的是，对于非泛型的类型，这个proc只会原封不动地返回它们 ，而不是产一个错误。

proc supportsCopyMem*(t: typedesc): bool {.magic: "TypeTrait".}
  ## 如果类型 ``t`` 可以安全地用于 `copyMem`:idx: ，则此trait返回true。 
  ##
  ## 其他语言命名的类型类似于 `blob`:idx: 。

proc isNamedTuple*(T: typedesc): bool =
  ## 如果是命名的元组，返回true，否则返回falase。
  when T isnot tuple: result = false
  else:
    var t: T
    for name, _ in t.fieldPairs:
      when name == "Field0":
        return compiles(t.Field0)
      else:
        return true
    # empty tuple should be un-named,
    # see https://github.com/nim-lang/Nim/issues/8861#issue-356631191
    return false


when isMainModule:
  static:
    doAssert $type(42) == "int"
    doAssert int.name == "int"

  const a1 = name(int)
  const a2 = $(int)
  const a3 = $int
  doAssert a1 == "int"
  doAssert a2 == "int"
  doAssert a3 == "int"

  proc fun[T: typedesc](t: T) =
    const a1 = name(t)
    const a2 = $(t)
    const a3 = $t
    doAssert a1 == "int"
    doAssert a2 == "int"
    doAssert a3 == "int"
  fun(int)
