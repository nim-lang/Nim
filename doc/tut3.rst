=======================
Nim教程 (III)
=======================

:Author: Arne Döring
:Version: |nimversion|

.. contents::


引言
============

  "能力越大，责任越大。" -- 蜘蛛侠的叔叔

本文档是关于Nim宏系统的教程。宏是编译期执行的函数，把Nim语法树变换成不同的树。

用宏可以实现的功能示例：

* 一个断言宏，如果断言失败打印比较运算符两边的数， ``myAssert(a == b)`` 转换成 ``if a != b: quit($a " != " $b)``

* 一个调试宏，打印符号的值和名字。 ``myDebugEcho(a)`` 转换成 ``echo "a: ", a``

* 表达式的象征性区别。
  ``diff(a*pow(x,3) + b*pow(x,2) + c*x + d, x)`` 转换成
  ``3*a*pow(x,2) + 2*b*x + c``
  (译者注：ax^3+bx^2+cx+d 微分的结果是 3ax^2+2bx+c)


宏实参
---------------

宏的实参有两面性。一面用来重载解析，另一面在宏体内使用。例如，如果 ``macro foo(arg: int)`` 在表达式 ``foo(x)`` 中调用， ``x`` 必须是与整型兼容的类型，
但在宏体 *内* ``arg`` 的类型是 ``NimNode`` ， 而不是 ``int`` ！这么做的原因会在我们见到具体的示例时明白。

有两种给宏传递实参的方式，实参必须是 ``typed`` 或 ``untyped`` 中的一种。


无类型（untyped）实参
-----------------

无类型宏实参在语义检查前传递给宏。这表示传给宏的语法树Nim尚不需要理解，唯一的限制是它必须是可以解析的。通常宏不检查实参但在变换结果中使用。编译器会检查宏展开的结果，所以除了
一些错误消息没有其它坏事情发生。

``untyped`` 实参的缺点是对重载解析不利。

无类型实参的优点是语法树可以预知，也比 ``typed`` 简单。


类型化（typed）实参
---------------

对于类型化实参，语义检查器在它传给宏之前对其进行检查并进行变换。这里标识符节点解析成符号，
树中的隐式类型转换被看作调用，模板被展开，最重要的是节点有类型信息。类型化实参的实参列表可以有 ``typed`` 类型。
但是其它所有类型，例如 ``int``, ``float`` 或 ``MyObjectType`` 也是类型化实参，它们作为一个语法树传递给宏。


静态实参
----------------

静态实参是向宏传递值而不是语法树的方法。例如对于 ``macro foo(arg: static[int])`` 来说， ``foo(x)`` 表达式中的 ``x`` 需要是整型常量，
但在宏体中 ``arg`` 只是一个普通的 ``int`` 类型。

.. code-block:: nim

  import macros

  macro myMacro(arg: static[int]): untyped =
    echo arg # 只是int (7), 不是 ``NimNode``

  myMacro(1 + 2 * 3)


代码块实参
------------------------


可以在具有缩进的单独代码块中传递调用表达式的最后一个参数。
例如下面的代码示例是合法的（不推荐的）调用 ``echo`` 的方法：

.. code-block:: nim

  echo "Hello ":
    let a = "Wor"
    let b = "ld!"
    a & b

对于宏来说这样的调用很有用；任意复杂度的语法树可以用这种标记传给宏。


语法树
---------------

为了构建Nim语法树，我们需要知道如何用语法树表示Nim源码， 能被Nim编译器理解的树看起来是什么样子的。 
Nim语法树节点记载在 `macros <macros.html>`_ 模块。
一个更加互动性的学习Nim语法树的方法是用 ``macros.treeRepr`` ，它把语法树转换成一个多行字符串打印到控制台。
它也可以用来探索实参表达式如何用树的形式表示，
以及生成的语法树的调试打印。 ``dumpTree`` 是一个预定义的宏，以树的形式打印它的实参。树表示的示例：

.. code-block:: nim

  dumpTree:
    var mt: MyType = MyType(a:123.456, b:"abcdef")

  # 输出:
  #   StmtList
  #     VarSection
  #       IdentDefs
  #         Ident "mt"
  #         Ident "MyType"
  #         ObjConstr
  #           Ident "MyType"
  #           ExprColonExpr
  #             Ident "a"
  #             FloatLit 123.456
  #           ExprColonExpr
  #             Ident "b"
  #             StrLit "abcdef"


自定义语义检查
-----------------------

宏对实参做的第一件事是检查实参是否是正确的形式。不是每种类型的错误输入都需要在这里捕获，但是应该捕获在宏求值期间可能导致崩溃的任何内容并创建一个很好的错误消息。
``macros.expectKind`` 和 ``macros.expectLen`` 是一个好的开始。如果检查需要更加复杂，任意错误消息可以用 ``macros.error`` 过程创建。

.. code-block:: nim

  macro myAssert(arg: untyped): untyped =
    arg.expectKind nnkInfix


生成代码
---------------

生成代码有两种方式。通过用含有多个 ``newTree`` 和 ``newLit`` 调用的表达式创建语法树，或者用 ``quote do:`` 表达式。
第一种为语法树生成提供最好的底层控制，第二种简短很多。如果你选择用 ``newTree`` 和 ``newLit`` 创建语法树，
``marcos.dumpAstGen`` 宏可以帮你很多。 ``quote do:`` 允许你直接写希望生成的代码，反引号用来插入来自 ``NimNode`` 符号的代码到生成的表达式中。
这表示你无法在 ``quote do:`` 使用反引号做除了注入符号之外的事情。确保只注入 ``NimNode`` 类型的符号到生成的语法树中。
你可以使用 ``newLit`` 把任意值转换成 ``NimNode`` 表达式树类型， 以便安全地注入到树中。


.. code-block:: nim
    :test: "nim c $1"

  import macros

  type
    MyType = object
      a: float
      b: string

  macro myMacro(arg: untyped): untyped =
    var mt: MyType = MyType(a:123.456, b:"abcdef")

    # ...

    let mtLit = newLit(mt)

    result = quote do:
      echo `arg`
      echo `mtLit`

  myMacro("Hallo")

调用``myMacro``将生成下面的代码：

.. code-block:: nim
  echo "Hallo"
  echo MyType(a: 123.456'f64, b: "abcdef")


构建你的第一个宏
-------------------------

为了给写宏一个开始，我们展示如何实现之前提到的 ``myDebug`` 宏。 
首先要构建一个宏使用的示例，接着打印实参。这可以看出一个正确的实参是什么样子。

.. code-block:: nim
    :test: "nim c $1"

  import macros

  macro myAssert(arg: untyped): untyped =
    echo arg.treeRepr

  let a = 1
  let b = 2

  myAssert(a != b)

.. code-block::

  Infix
    Ident "!="
    Ident "a"
    Ident "b"


从输出可以看出实参信息是一个中缀操作符（节点类型是"Infix"）， 两个操作数在索引1和2的位置。用这个信息可以写真正的宏。

.. code-block:: nim
    :test: "nim c $1"

  import macros

  macro myAssert(arg: untyped): untyped =
    # 所有节点类型标识符用前缀 "nnk"
    arg.expectKind nnkInfix
    arg.expectLen 3
    # 操作符作字符串字面值
    let op  = newLit(" " & arg[0].repr & " ")
    let lhs = arg[1]
    let rhs = arg[2]

    result = quote do:
      if not `arg`:
        raise newException(AssertionError,$`lhs` & `op` & $`rhs`)

  let a = 1
  let b = 2

  myAssert(a != b)
  myAssert(a == b)


这是即将生成的代码。 调试生成的宏可以在宏最后一行用 ``echo result.repr`` 语句。它也是用于获取此输出的语句。

.. code-block:: nim
  if not (a != b):
    raise newException(AssertionError, $a & " != " & $b)

能力与责任
-------------------------------

宏非常强大。
宏可以改变表达式的语义，让不知道宏做什么的人难以理解。
可以使用模板或泛型实现的相同逻辑，最好不要使用宏。
当宏用于某种用途时，应当有一个优秀的文档。
说自己写的代码一目了然的人实现宏时，需要足够的文档。

限制
-----------

因为宏由Nim虚拟机的编译器求值，它有Nim虚拟机的所有限制。
必须用纯Nim代码实现，宏可以在shell打开外部进程，不能调用除了编译器内置外的C函数。


更多示例
=============

本教程讲解了宏系统的基础。对于宏能够做的事情，有些宏可以给你灵感。


Strformat
---------

在Nim标准库中， ``strformat`` 库提供了一个在编译时解析字符串字面值的宏。通常不建议像这样在宏中解析字符串。
解析的AST不能具有类型信息，并且在VM上实现的解析通常不是非常快。在AST节点上操作几乎总是推荐的方式。
但 ``strformat`` 仍然是宏实际应用的一个很好的例子，它比 ``assert`` 宏稍微复杂一些。

`Strformat <https://github.com/nim-lang/Nim/blob/5845716df8c96157a047c2bd6bcdd795a7a2b9b1/lib/pure/strformat.nim#L280>`_

抽象语法树模式匹配（Ast Pattern Matching）
--------------------

Ast Pattern Matching是一个宏库，可以帮助编写复杂的宏。这可以看作是如何使用新语义重新利用Nim语法树的一个很好的例子。

`Ast Pattern Matching <https://github.com/krux02/ast-pattern-matching>`_

OpenGL沙盒
--------------

这个项目有一个完全用宏编写的Nim到GLSL编译器。它通过递归扫描所有使用的函数符号来编译它们，以便可以在GPU上执行交叉库函数。

`OpenGL Sandbox <https://github.com/krux02/opengl-sandbox>`_
