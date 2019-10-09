======================
Nim教程 (II)
======================

:Author: Andreas Rumpf
:Version: |nimversion|

.. contents::


引言
============

  "重复让荒谬合理。" -- Norman Wildberger

本文档是 *Nim* 编程语言的高级构造部分。 **注意本文档有些过时** 因为 `manual <manual.html>`_  **包含更多高级语言特性的样例** 。


编译指示（Pragmas）
=======

编译指示是Nim中不用引用大量新关键字，给编译器附加信息、命令的方法。编译指示用特殊的 ``{.`` 和 ``.}`` 花括号括起来。本教程不讲pragmas。
可用编译指示的描述见 `manual <manual.html#pragmas>`_ 或 `user guide <nimc.html#additional-features>`_ .


面向对象编程
===========================

虽然Nim对面向对象编程（OOP）的支持很简单，但可以使用强大的OOP技术。OOP看作 *一种* 程序设计方式，不是 *唯一* 方式。通常过程的解决方法有更简单和高效的代码。
特别是，首选组合是比继承更好的设计。


继承
-----------

继承在Nim中是完全可选的。对象需要用运行时类型信息使用继承 
要使用运行时类型信息启用继承，对象需要从 ``RootObj`` 继承。
这可以直接完成，也可以通过从继承自 ``RootObj``  的对象继承来间接完成。
通常，具有继承的类型也被标记为“ref”类型，即使这不是严格执行的。要在运行时检查某个对象是否属于某种类型，可以使用 ``of`` 运算符。

.. code-block:: nim
    :test: "nim c $1"
  type
    Person = ref object of RootObj
      name*: string  # *表示 `name`可以从其它模块访问
      age: int       # 没有*表示字段对其它模块隐藏

    Student = ref object of Person # Student从Person继承
      id: int                      # 有一个id字段

  var
    student: Student
    person: Person
  assert(student of Student) # is true
  # 对象构造:
  student = Student(name: "Anton", age: 5, id: 2)
  echo student[]


继承是使用 ``object of`` 语法完成的。目前不支持多重继承。如果一个对象类型没有合适的祖先， ``RootObj`` 可以用作它的祖先，但这只是一个约定。
没有祖先的对象是隐式的“final”。你可以使用 ``inheritable`` 编译指示来引入除 ``system.RootObj`` 之外的新对象根。 （例如，GTK封装使用了这种方法。）

只要使用继承，就应该使用Ref对象。它不是必须的，但是对于非ref对象赋值，例如 ``let person：Person = Student（id：123）`` 将截断子类字段。

**注意** ：对于简单的代码重用，组合（*has-a* 关系）通常优于继承（*is-a* 关系）。由于对象是Nim中的值类型，因此组合与继承一样有效。

相互递归类型
------------------------

对象、元组和引用可以模拟相互依赖的非常复杂的数据结构; 它们是 *相互递归的* 。在Nim中，这些类型只能在单个类型部分中声明。（即任何其他因为需要任意符号先行减慢编译速度的类型。）

示例：

.. code-block:: nim
    :test: "nim c $1"
  type
    Node = ref object  # 对具有以下字段的对象的引用：
      le, ri: Node     # 左右子树
      sym: ref Sym     # 叶节点包含Sym的引用

    Sym = object       # 符号
      name: string     # 符号名
      line: int        # 符号声明的行
      code: Node       # 符号的抽象语法树


类型转换
----------------
Nim区分 `type casts`:idx: 和 `type conversions`:idx: 。使用 ``cast`` 运算符完成转换，并强制编译器将位模式解释为另一种类型。

类型转换是将类型转换为另一种类型的更友好的方式：它们保留抽象 *值* ，不一定是 *位模式* 。如果无法进行类型转换，则编译器会引发异常。

类型转换语法 ``destination_type(expression_to_convert)`` (像平时的调用):

.. code-block:: nim
  proc getID(x: Person): int =
    Student(x).id

如果 ``x`` 不是 ``Student`` ，则引发 ``InvalidObjectConversionError`` 异常。


对象变体
---------------

在需要简单变体类型的某些情况下，对象层次结构通常是过度的。

一个示例:

.. code-block:: nim
    :test: "nim c $1"

  # 这是一个如何在Nim中建模抽象语法树的示例
  type
    NodeKind = enum  # 不同节点类型
      nkInt,          # 整型值叶节点
      nkFloat,        # 浮点型叶节点
      nkString,       # 字符串叶节点
      nkAdd,          # 加法
      nkSub,          # 减法
      nkIf            # if语句
    Node = ref object
      case kind: NodeKind  # ``kind`` 字段是鉴别字段
      of nkInt: intVal: int
      of nkFloat: floatVal: float
      of nkString: strVal: string
      of nkAdd, nkSub:
        leftOp, rightOp: Node
      of nkIf:
        condition, thenPart, elsePart: Node

  var n = Node(kind: nkFloat, floatVal: 1.0)
  # 以下语句引发了一个`FieldError`异常，因为 n.kind的值不匹配：
  n.strVal = ""

从该示例可以看出，对象层次结构的优点是不需要在不同对象类型之间进行转换。但是，访问无效对象字段会引发异常。


方法调用语法
------------------

调用例程有一个语法糖：语法 ``obj.method（args）`` 可以用来代替 ``method（obj，args）`` 。如果没有剩余的参数，则可以省略括号： ``obj.len`` （而不是 ``len（obj）`` ）。

此方法调用语法不限于对象，它可以用于任何类型：


.. code-block:: nim
    :test: "nim c $1"
  import strutils

  echo "abc".len # is the same as echo len("abc")
  echo "abc".toUpperAscii()
  echo({'a', 'b', 'c'}.card)
  stdout.writeLine("Hallo") # the same as writeLine(stdout, "Hallo")

（查看方法调用语法的另一种方法是它提供了缺少的后缀表示法。）


所以“纯面向对象”代码很容易编写：

.. code-block:: nim
    :test: "nim c $1"
  import strutils, sequtils

  stdout.writeLine("Give a list of numbers (separated by spaces): ")
  stdout.write(stdin.readLine.splitWhitespace.map(parseInt).max.`$`)
  stdout.writeLine(" is the maximum!")


属性
----------
如上例所示，Nim不需要 *get-properties* ：使用 *方法调用语法* 调用的普通get-procedures实现相同。但设定值是不同的；为此需要一个特殊的setter语法：

.. code-block:: nim
    :test: "nim c $1"

  type
    Socket* = ref object of RootObj
      h: int # 由于缺少星号，无法从模块外部访问

  proc `host=`*(s: var Socket, value: int) {.inline.} =
    ## setter of host address
    s.h = value

  proc host*(s: Socket): int {.inline.} =
    ## getter of host address
    s.h

  var s: Socket
  new s
  s.host = 34  # same as `host=`(s, 34)

（该示例还显示了 ``inline`` 程序。）


可以重载 ``[]`` 数组访问运算符来提供 `数组属性`:idx: ：

.. code-block:: nim
    :test: "nim c $1"
  type
    Vector* = object
      x, y, z: float

  proc `[]=`* (v: var Vector, i: int, value: float) =
    # setter
    case i
    of 0: v.x = value
    of 1: v.y = value
    of 2: v.z = value
    else: assert(false)

  proc `[]`* (v: Vector, i: int): float =
    # getter
    case i
    of 0: result = v.x
    of 1: result = v.y
    of 2: result = v.z
    else: assert(false)

这个例子可以更好的用元组展示，元组提供 ``v[]`` 访问。


动态分发
----------------

程序总是使用静态调度。对于动态调度，用 ``method`` 替换 ``proc`` 关键字：

.. code-block:: nim
    :test: "nim c $1"
  type
    Expression = ref object of RootObj ## abstract base class for an expression
    Literal = ref object of Expression
      x: int
    PlusExpr = ref object of Expression
      a, b: Expression

  # 注意：'eval'依赖于动态绑定
  method eval(e: Expression): int {.base.} =
    # 重写基方法
    quit "to override!"

  method eval(e: Literal): int = e.x
  method eval(e: PlusExpr): int = eval(e.a) + eval(e.b)

  proc newLit(x: int): Literal = Literal(x: x)
  proc newPlus(a, b: Expression): PlusExpr = PlusExpr(a: a, b: b)

  echo eval(newPlus(newPlus(newLit(1), newLit(2)), newLit(4)))

请注意，在示例中，构造函数 ``newLit`` 和 ``newPlus`` 是procs，因为它们使用静态绑定更有意义，但 ``eval`` 是一种方法，因为它需要动态绑定。

**注意：** 从Nim 0.20开始，要使用多方法，必须在编译时明确传递 ``--multimethods：on`` 。

在多方法中，所有具有对象类型的参数都用于分发：

.. code-block:: nim
    :test: "nim c --multiMethods:on $1"

  type
    Thing = ref object of RootObj
    Unit = ref object of Thing
      x: int

  method collide(a, b: Thing) {.inline.} =
    quit "to override!"

  method collide(a: Thing, b: Unit) {.inline.} =
    echo "1"

  method collide(a: Unit, b: Thing) {.inline.} =
    echo "2"

  var a, b: Unit
  new a
  new b
  collide(a, b) # output: 2


如示例所示，多方法的调用不能有歧义：collide2比collide1更受欢迎，因为解析是从左到右的。因此 ``Unit，Thing`` 比 ``Thing，Unit`` 更准确。

**性能说明**: Nim不会生成虚函数表，但会生成调度树。这避免了方法调用的昂贵间接分支并启用内联。但是，其他优化（如编译时评估或死代码消除）不适用于方法。


异常
==========

在Nim中，异常是对象。按照惯例，异常类型后缀为“Error”。 `system <system.html>`_ 模块定义了异常层次结构。异常来自 ``system.Exception`` ，它提供了通用接口。


必须在堆上分配异常，因为它们的生命周期是未知的。编译器将阻止您引发在栈上创建的异常。所有引发的异常应该至少指定在 ``msg`` 字段中引发的原因。


一个约定是只在异常情况下应该引发异常：例如，如果无法打开文件，不应引发异常，这很常见（文件可能不存在）。

Raise语句
---------------
发起一个异常用 ``raise`` 语句：

.. code-block:: nim
    :test: "nim c $1"
  var
    e: ref OSError
  new(e)
  e.msg = "the request to the OS failed"
  raise e

如果 ``raise`` 关键字后面没有表达式，则最后一个异常是 *re-raised* 。为了避免重复这种常见的代码模式，可以使用 ``system`` 模块中的模板 ``newException`` ：

.. code-block:: nim
  raise newException(OSError, "the request to the OS failed")


Try语句
-------------

``try`` 语句处理异常：

.. code-block:: nim
    :test: "nim c $1"
  from strutils import parseInt

  # 读取应包含数字的文本文件的前两行并尝试添加
  var
    f: File
  if open(f, "numbers.txt"):
    try:
      let a = readLine(f)
      let b = readLine(f)
      echo "sum: ", parseInt(a) + parseInt(b)
    except OverflowError:
      echo "overflow!"
    except ValueError:
      echo "could not convert string to integer"
    except IOError:
      echo "IO error!"
    except:
      echo "Unknown exception!"
      # reraise the unknown exception:
      raise
    finally:
      close(f)


除非引发异常，否则执行 ``try`` 之后的语句。然后执行适当的 ``except`` 部分。

如果存在未明确列出的异常，则执行空的 ``except`` 部分。它类似于 ``if`` 语句中的 ``else`` 部分。

如果有一个 ``finally`` 部分，它总是在异常处理程序之后执行。

在 ``except`` 部分中 *消耗* 异常。如果未处理异常，则通过调用堆栈传播该异常。这意味着程序的其余部分 - 不在 ``finally`` 子句中 - 通常不会被执行（如果发生异常）。

如果你需要*访问 ``except`` 分支中的实际异常对象或消息，你可以使用来自 `system <system.html>`_ 模块的 `getCurrentException()<system.html#getCurrentException>`_ 和
 `getCurrentExceptionMsg()<system.html#getCurrentExceptionMsg>`_ 的过程。例：

.. code-block:: nim
  try:
    doSomethingHere()
  except:
    let
      e = getCurrentException()
      msg = getCurrentExceptionMsg()
    echo "Got exception ", repr(e), " with message ", msg


引发异常的procs注释
---------------------------------------

通过使用可选的 ``{.raises.}`` pragma，你可以指定过程是为了引发一组特定的异常，或者根本没有异常。如果使用 ``{.raises.}`` 编译指示，编译器将验证这是否为真。例如，如果指定过程引发
``IOError`` ，并且在某些时候它（或它调用的一个过程）开始引发一个新的异常，编译器将阻止该过程进行编译。用法示例：


.. code-block:: nim
  proc complexProc() {.raises: [IOError, ArithmeticError].} =
    ...

  proc simpleProc() {.raises: [].} =
    ...

一旦你有这样的代码，如果引发的异常列表发生了变化，编译器就会停止，并指出过程停止验证编译指示的行，没有捕获的异常和它的行数以及文件。
正在引发未捕获的异常，这可能有助于您找到已更改的有问题的代码。

如果你想将 ``{.raises.}`` 编译指示添加到现有代码中，编译器也可以帮助你。你可以在你的过程中添加 ``{.effects.}`` 编译指示语句，
编译器将输出所有推断的效果直到那一点（异常跟踪是Nim效果系统的一部分）。
查找proc引发的异常列表的另一种更迂回的方法是使用Nim ``doc2`` 命令，该命令为整个模块生成文档，并使用引发的异常列表来装饰所有过程。
您可以在手册中阅读有关Nim的 `效果系统和相关编译指示的更多信息<manual.html＃effect-system>`_ 。

泛型
========

泛型是Nim用 `类型化参数`:idx: 参数化过程，迭代器或类型的方法。它们对于高效型安全容器很有用：

.. code-block:: nim
    :test: "nim c $1"
  type
    BinaryTree*[T] = ref object # 二叉树是左右子树用泛型参数 ``T`` 可能nil的泛型
      le, ri: BinaryTree[T]     
      data: T                   # 数据存储在节点

  proc newNode*[T](data: T): BinaryTree[T] =
    # 节点构造
    new(result)
    result.data = data

  proc add*[T](root: var BinaryTree[T], n: BinaryTree[T]) =
    # 插入节点
    if root == nil:
      root = n
    else:
      var it = root
      while it != nil:
        # 比较数据; 使用对任何有 ``==`` and ``<`` 操作符的类型有用的泛型 ``cmp`` 过程
        var c = cmp(it.data, n.data)
        if c < 0:
          if it.le == nil:
            it.le = n
            return
          it = it.le
        else:
          if it.ri == nil:
            it.ri = n
            return
          it = it.ri

  proc add*[T](root: var BinaryTree[T], data: T) =
    # 方便过程:
    add(root, newNode(data))

  iterator preorder*[T](root: BinaryTree[T]): T =
    # 二叉树前序遍历。
    # 因为递归迭代器没有实现，用显式的堆栈(更高效):
    var stack: seq[BinaryTree[T]] = @[root]
    while stack.len > 0:
      var n = stack.pop()
      while n != nil:
        yield n.data
        add(stack, n.ri)  # 右子树push到堆栈
        n = n.le          # 跟随左指针

  var
    root: BinaryTree[string] # 用 ``string`` 实例化一个二叉树 
  add(root, newNode("hello")) # 实例化 ``newNode`` 和 ``add``
  add(root, "world")          # 实例化第二个 ``add`` 过程
  for str in preorder(root):
    stdout.writeLine(str)

该示例显示了通用二叉树。根据上下文，括号用于引入类型参数或实例化通用过程、迭代器或类型。如示例所示，泛型使用重载：使用“add”的最佳匹配。
序列的内置 ``add`` 过程没有隐藏，而是在 ``preorder`` 迭代器中使用。


模板
=========

模板是一种简单的替换机制，可以在Nim的抽象语法树上运行。模板在编译器的语义传递中处理。它们与语言的其余部分很好地集成，并且没有C的预处理器宏缺陷。

要 *调用* 模板，将其作为过程。


Example:

.. code-block:: nim
  template `!=` (a, b: untyped): untyped =
    # 此定义存在于system模块中
    not (a == b)

  assert(5 != 6) # 编译器将其重写为：assert（not（5 == 6））

``!=``, ``>``, ``>=``, ``in``, ``notin``, ``isnot`` 操作符实际是模板：这对重载自动可用的 ``==`` ,  ``!=`` 操作符有好处。 
（除了IEEE浮点数 -  NaN打破了基本的布尔逻辑。）

``a > b`` 变换成 ``b < a`` 。
``a in b`` 变换成 ``contains(b, a)`` 。
``notin`` 和 ``isnot`` 顾名思义。


模板对于延迟计算特别有用。看一个简单的日志记录过程：

.. code-block:: nim
    :test: "nim c $1"
  const
    debug = true

  proc log(msg: string) {.inline.} =
    if debug: stdout.writeLine(msg)

  var
    x = 4
  log("x has the value: " & $x)

这段代码有一个缺点：如果 ``debug`` 有一天设置为false，那么仍然会执行 ``$`` 和 ``&`` 操作！ （程序的参数求值是 *急切* ）。

将 ``log`` 过程转换为模板解决了这个问题：

.. code-block:: nim
    :test: "nim c $1"
  const
    debug = true

  template log(msg: string) =
    if debug: stdout.writeLine(msg)

  var
    x = 4
  log("x has the value: " & $x)

参数的类型可以是普通类型，也可以是元类型 ``untyped`` ， ``typed`` 或 ``type`` 。 ``type`` 表示只有一个类型符号可以作为参数给出， 
``untyped`` 表示符号查找，并且在表达式传递给模板之前不执行类型解析。

如果模板没有显式返回类型，则使用 ``void`` 与过程和方法保持一致。

要将一个语句块传递给模板，请使用 ``untyped`` 作为最后一个参数：

.. code-block:: nim
    :test: "nim c $1"

  template withFile(f: untyped, filename: string, mode: FileMode,
                    body: untyped) =
    let fn = filename
    var f: File
    if open(f, fn, mode):
      try:
        body
      finally:
        close(f)
    else:
      quit("cannot open: " & fn)

  withFile(txt, "ttempl3.txt", fmWrite):
    txt.writeLine("line 1")
    txt.writeLine("line 2")

在示例中，两个 ``writeLine`` 语句绑定到 ``body`` 参数。 ``withFile`` 模板包含样板代码，有助于避免忘记关闭文件的常见错误。
注意 ``let fn = filename`` 语句如何确保 ``filename`` 只被求值一次。

示例: 提升过程
----------------------

.. code-block:: nim
    :test: "nim c $1"
  import math

  template liftScalarProc(fname) =
    ## 使用一个标量参数提升一个proc并返回一个
    ## 标量值（例如 ``proc sssss[T](x: T): float``）,
    ## 来提供模板过程可以处理单个seq[T]形参或嵌套seq[seq[]]或同样的类型
    ##
    ## .. code-block:: Nim
    ##  liftScalarProc(abs)
    ##  现在 abs(@[@[1,-2], @[-2,-3]]) == @[@[1,2], @[2,3]]
    proc fname[T](x: openarray[T]): auto =
      var temp: T
      type outType = type(fname(temp))
      result = newSeq[outType](x.len)
      for i in 0..<x.len:
        result[i] = fname(x[i])

  liftScalarProc(sqrt)   # 让sqrt()可以用于序列
  echo sqrt(@[4.0, 16.0, 25.0, 36.0])   # => @[2.0, 4.0, 5.0, 6.0]

编译成Javascript
=========================

Nim代码可以编译成JavaScript。为了写JavaScript兼容的代码你要记住以下几个方面：
- ``addr`` 和 ``ptr`` 在JavaScript中有略微不同的语义。你不确定它们是怎样编译成JavaScript，建议避免使用。
- 在JavaScript中的 ``cast[T](x)`` 被转换为 ``(x)`` ，除了在有符号/无符号整数之间进行转换，在这种情况下，它在C语言中表现为静态强制转换。
- ``cstring`` 在JavaScript中表示JavaScript字符串。 只有在语义上合适时才使用 ``cstring`` 是一个好习惯。例如。不要使用 ``cstring`` 作为二进制数据缓冲区。


Part 3
======

下一部分将是完全关于使用宏的元编程： `Part III <tut3.html>`_
