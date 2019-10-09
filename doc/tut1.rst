=====================
Nim教程 (I)
=====================

:Author: Andreas Rumpf
:Version: |nimversion|

.. contents::

引言
============

.. raw:: html
  <blockquote><p>
  "人是一种视觉动物 -- 我渴望美好事物。"
  </p></blockquote>

本文是编程语言Nim的教程。该教程认为你熟悉基本的编程概念如变量、类型和语句但非常基础。 `manual <manual.html>`_  包含更多的高级特性示例。本教程的代码示例和其它的Nim文档遵守 `Nim style guide <nep1.html>`_ 。


第一个程序
=================
我们从一个调整过的"hello world"程序开始：

.. code-block:: Nim
    :test: "nim c $1"
  # 这是注释
  echo "What's your name? "
  var name: string = readLine(stdin)
  echo "Hi, ", name, "!"

保存到文件"greetings.nim"，编译运行：

  nim compile --run greetings.nim

用 ``--run`` `switch <nimc.html#compiler-usage-command-line-switches>`_ Nim在编译之后自动执行文件。你可以在文件名后给程序追加命令行参数nim compile --run greetings.nim arg1 arg2

经常使用的命令和开关有缩写，所以你可以用::

  nim c -r greetings.nim

编译发布版使用::

  nim c -d:release greetings.nim

Nim编译器默认生成大量运行时检查，旨在方便调试。用 ``-d:release``  `关闭一些检查并且打开优化<nimc.html#compiler-usage-compile-time-symbols>`_ 。
（译者注，-d:release的功能在最近的版本已经发生变化，现在会打开运行时检查，使用-d:danger来替代，以生成更好性能的代码）

程序的作用显而易见，需要解释下语法：没有缩进的语句会在程序开始时执行。缩进是Nim语句进行分组的方式。缩进仅允许空格，不允许制表符。

字符串字面值用双引号括起来。 ``var`` 语句声明一个新的名为 ``name`` ，类型为 ``string`` ，值为 `readLine <system.html#readLine,File>`_ 方法返回值的变量名。
因为编译器知道 `readLine <system.html#readLine,File>`_ 返回一个字符串，你可以省略声明中的类型(这叫作 `局部类型推导`:idx: )。所以也可以这样：

.. code-block:: Nim
    :test: "nim c $1"
  var name = readLine(stdin)

请注意，这基本上是Nim中存在的唯一类型推导形式：兼顾简洁与可读。

"hello world"程序包括一些编译器已知的标识符： ``echo`` ， `readLine <system.html#readLine,File>`_ 等。这些内置声名在 system_ 模块中，system_ 模块通过其它模块隐式的导出。

词法元素
================

让我们看看Nim词法元素的更多细节：像其它编程语言一样，Nim由（字符串）字面值、标识符、关键字、注释、操作符、和其它标点符号构成。


字符串和字符字面值
-----------------------------

字符串字面值通过双引号括起来；字符字面值用单引号。特殊字符通过 ``\`` 转义: ``\n`` 表示换行， ``\t`` 表示制表符等，还有 *原始* 字符串字面值：

.. code-block:: Nim
  r"C:\program files\nim"

在原始字面值中反斜杠不是转义字符。

第三种也是最后一种写字符串字面值的方法是 *长字符串字面值* 。用三引号 ``"""..."""`` 写，他们可以跨行并且 ``\`` 也不是转义字符。例如它们对嵌入HTML代码模板很有用。


注释
--------

注释在任何字符串或字符字面值之外，以哈希字符 ``#`` 开始，文档以 ``##`` 开始：

.. code-block:: nim
    :test: "nim c $1"
  # 注释。

  var myVariable: int ## 文档注释


文档注释是令牌；它们只允许在输入文件中的某些位置，因为它们属于语法树！这个功能可实现更简单的文档生成器。

多行注释以 ``#[`` 开始，以 ``]#`` 结束。多行注释也可以嵌套。

.. code-block:: nim
    :test: "nim c $1"
  #[
  You can have any Nim code text commented
  out inside this with no indentation restrictions.
        yes("May I ask a pointless question?")
    #[
       Note: these can be nested!!
    ]#
  ]#

你也可以和 *长字符串字面值* 一起使用 `discard语句 <#procedures-discard-statement>`_ 来构建块注释。

.. code-block:: nim
    :test: "nim c $1"
  discard """ You can have any Nim code text commented
  out inside this with no indentation restrictions.
        yes("May I ask a pointless question?") """


数字
-------

数字字面值与其它大多数语言一样。作为一个特别的地方，为了更好的可读性，允许使用下划线： ``1_000_000`` (一百万)。
包含点（或者'e'或'E'）的数字是浮点字面值： ``1.0e9`` （十亿）。十六进制字面值前缀是 ``0x`` ，二进制字面值用 ``0b`` ，八进制用 ``0o`` 。
单独一个前导零不产生八进制。


var语句
=================
var语句声明一个本地或全局变量:

.. code-block::
  var x, y: int # 声明x和y拥有类型 ``int`` 

缩进可以用在 ``var`` 关键字后来列一个变量段。

.. code-block::
    :test: "nim c $1"
  var
    x, y: int
    # 可以有注释
    a, b, c: string


赋值语句
========================

赋值语句为一个变量赋予新值或者更一般地，赋值到一个存储地址：

.. code-block::
  var x = "abc" # 引入一个新变量`x`并且赋值给它
  x = "xyz"     # 赋新值给 `x`

``=`` 是 *赋值操作符* 。赋值操作符可以重载。你可以用一个赋值语句声明多个变量并且所有的变量具有相同的类型：

.. code-block::
    :test: "nim c $1"
  var x, y = 3  # 给变量`x`和`y`赋值3
  echo "x ", x  # 输出 "x 3"
  echo "y ", y  # 输出 "y 3"
  x = 42        # 改变`x`为42而不改变`y`
  echo "x ", x  # 输出"x 42"
  echo "y ", y  # 输出"y 3"

注意，使用过程对声明的多个变量进行赋值时可能会产生意外结果：编译器会 *展开* 赋值并多次调用该过程。
如果程序的结果取决于副作用，变量可能最终会有不同的值。为了安全起见，多赋值时使用没有副作用的过程。


常量
=========

常量是绑定在一个值上的符号。常量值不能改变。编译器必须能够在编译期对常量声明进行求值：

.. code-block:: nim
    :test: "nim c $1"
  const x = "abc" # 常量x包含字符串"abc"

可以在 ``const`` 关键字之后使用缩进来列出整个常量部分：

.. code-block::
    :test: "nim c $1"
  const
    x = 1
    # 这也可以有注释
    y = 2
    z = y + 5 # 计算是可能的


let语句
=================
``let`` 语句像 ``var`` 语句一样但声明的符号是 *单赋值* 变量：初始化后它们的值将不能改变。

.. code-block::
  let x = "abc" # 引入一个新变量`x`并绑定一个值
  x = "xyz"     # 非法: 给`x`赋值

``let`` 和 ``const`` 的区别在于: ``let`` 引入一个变量不能重新赋值。 ``const`` 表示"强制编译期求值并放入数据段":

.. code-block::
  const input = readLine(stdin) # 错误: 需要常量表达式

.. code-block::
    :test: "nim c $1"
  let input = readLine(stdin)   # 可以


流程控制语句
=======================

greetings程序由三个顺序执行的语句构成。只有最原始的程序可以不需要分支和循环。


If语句
------------

if语句是分支流程控制的一种方法:

.. code-block:: nim
    :test: "nim c $1"
  let name = readLine(stdin)
  if name == "":
    echo "Poor soul, you lost your name?"
  elif name == "name":
    echo "Very funny, your name is name."
  else:
    echo "Hi, ", name, "!"

可以没有或多个 ``elif`` ，并且 ``else`` 是可选的， ``elif`` 关键字是 ``else if`` 的简写，并且避免过度缩进。（ ``""`` 是空字符串，不包含字符。）


Case语句
--------------

另一个分支的方法是case语句。case语句是多分支：

.. code-block:: nim
    :test: "nim c $1"
  let name = readLine(stdin)
  case name
  of "":
    echo "Poor soul, you lost your name?"
  of "name":
    echo "Very funny, your name is name."
  of "Dave", "Frank":
    echo "Cool name!"
  else:
    echo "Hi, ", name, "!"

可以看出，对于分支允许使用逗号分隔的值列表。

case语句可以处理整型、其它序数类型和字符串。（序数类型后面会讲到）
对整型或序数类型值，也可以用范围：

.. code-block:: nim
  # 这段语句将会在后面解释:
  from strutils import parseInt

  echo "A number please: "
  let n = parseInt(readLine(stdin))
  case n
  of 0..2, 4..7: echo "The number is in the set: {0, 1, 2, 4, 5, 6, 7}"
  of 3, 8: echo "The number is 3 or 8"

上面的代码不能编译: 原因是你必须覆盖每个 ``n`` 可能包含的值，但代码里只处理了 ``0..8`` 。
因为列出来每个可能的值不现实（尽管范围可以实现），我们通过告诉编译器不处理其它值来修复：

.. code-block:: nim
  ...
  case n
  of 0..2, 4..7: echo "The number is in the set: {0, 1, 2, 4, 5, 6, 7}"
  of 3, 8: echo "The number is 3 or 8"
  else: discard

空 `discard语句`_ 是一个 *什么都不做* 的语句。编译器知道带有else部分的case语句不会失败，因此错误消失。
请注意，不可能覆盖所有可能的字符串值：这就是字符串情况总是需要else分支的原因。

通常情况下，case语句用于枚举的子范围类型，其中编译器对检查您是否覆盖了任何可能的值有很大帮助。


While语句
---------------

while语句是一个简单的循环结构:

.. code-block:: nim
    :test: "nim c $1"

  echo "What's your name? "
  var name = readLine(stdin)
  while name == "":
    echo "Please tell me your name: "
    name = readLine(stdin)
    # 没有 ``var`` ， 因为我们没有声明一个新变量

示例使用while循环来不断的询问用户的名字，只要用户什么都没有输入（只按回车）。


For语句
-------------

``for`` 语句是一个循环遍历迭代器提供的任何元素的构造。示例使用内置的 `countup <system.html#countup>`_ 迭代器:

.. code-block:: nim
    :test: "nim c $1"
  echo "Counting to ten: "
  for i in countup(1, 10):
    echo i
  # --> Outputs 1 2 3 4 5 6 7 8 9 10 on different lines

变量 ``i`` 通过 ``for`` 循环隐式的声明并具有 ``int`` 类型, 因为这里 `countup <system.html#countup>`_ 返回的。
``i`` 遍历 1, 2, .., 10，每个值被 ``echo`` 。 这段代码作用是一样的:

.. code-block:: nim
  echo "Counting to 10: "
  var i = 1
  while i <= 10:
    echo i
    inc(i) # increment i by 1
  # --> Outputs 1 2 3 4 5 6 7 8 9 10 on different lines


倒数可以轻松实现 (但不常需要):

.. code-block:: nim
  echo "Counting down from 10 to 1: "
  for i in countdown(10, 1):
    echo i
  # --> Outputs 10 9 8 7 6 5 4 3 2 1 on different lines

计数在程序中经常出现，Nim有一个 `..<system.html#...i,S,T>`_ 迭代器作用是一样的

.. code-block:: nim
  for i in 1..10:
    ...

零索引计数有两个简写 ``..<`` 和 ``..^`` ，为了简化计数到较高索引的前一位。

.. code-block:: nim
  for i in 0..<10:
    ...  # 0..9

or

.. code-block:: nim
  var s = "some string"
  for i in 0..<s.len:
    ...

其它有用的迭代器（如数组和序列）是
* ``items`` 和 ``mitems`` ，提供不可改变和可改变元素，
* ``pairs`` 和 ``mpairs`` 提供元素和索引数字。

.. code-block:: nim
    :test: "nim c $1"
  for index, item in ["a","b"].pairs:
    echo item, " at index ", index
  # => a at index 0
  # => b at index 1

作用域和块语句
------------------------------
控制流语句有一个还没有讲的特性: 它们有自己的作用域。这意味着在下面的示例中, ``x`` 在作用域外是不可访问的:

.. code-block:: nim
    :test: "nim c $1"
    :status: 1
  while false:
    var x = "hi"
  echo x # 不行

一个while(for)语句引入一个隐式块。标识符是只在它们声明的块内部可见。 ``block`` 语句可以用来显式地打开一个新块：

.. code-block:: nim
    :test: "nim c $1"
    :status: 1
  block myblock:
    var x = "hi"
  echo x # 不行

块的 *label* (本例中的 ``myblock`` ) 是可选的。


Break语句
---------------
块可以用一个 ``break`` 语句跳出。break语句可以跳出一个 ``while``, ``for``, 或 ``block`` 语句. 它跳出最内层的结构, 除非给定一个块标签:

.. code-block:: nim
    :test: "nim c $1"
  block myblock:
    echo "entering block"
    while true:
      echo "looping"
      break # 跳出循环,但不跳出块
    echo "still in block"

  block myblock2:
    echo "entering block"
    while true:
      echo "looping"
      break myblock2 # 跳出块 (和循环)
    echo "still in block"


Continue语句
------------------
像其它编程语言一样， ``continue`` 语句立刻开始下一次迭代:

.. code-block:: nim
    :test: "nim c $1"
  while true:
    let x = readLine(stdin)
    if x == "": continue
    echo x


When语句
--------------

示例:

.. code-block:: nim
    :test: "nim c $1"

  when system.hostOS == "windows":
    echo "running on Windows!"
  elif system.hostOS == "linux":
    echo "running on Linux!"
  elif system.hostOS == "macosx":
    echo "running on Mac OS X!"
  else:
    echo "unknown operating system"

``when`` 语句几乎等价于 ``if`` 语句, 但有以下区别:

* 每个条件必须是常量表达式，因为它被编译器求值。
* 分支内的语句不打开新作用域。
* 编译器检查语义并 *仅* 为属于第一个求值为true的条件生成代码。

``when`` 语句在写平台特定代码时有用，类似于C语言中的 ``#ifdef`` 结构。


语句和缩进
==========================

既然我们覆盖了基本的控制流语句, 让我们回到Nim缩进规则。

在Nim中 *简单语句* 和 *复杂语句* 有区别。 *简单语句* 不能包含其它语句：属于简单语句的赋值, 过程调用或 ``return`` 语句。 *复杂语句* 像 ``if`` 、 ``when`` 、 ``for`` 、 ``while`` 可以包含其它语句。
为了避免歧义，复杂语句必须缩进, 但单个简单语句不必:

.. code-block:: nim
  # 单个赋值语句不需要缩进:
  if x: x = false

  # 嵌套if语句需要缩进:
  if x:
    if y:
      y = false
    else:
      y = true

  # 需要缩进, 因为条件后有两个语句：
  if x:
    x = false
    y = false


*表达式* 是语句通常有一个值的部分。 例如，一个if语句中的条件是表达式。表达式为了更好的可读性可以在某些地方缩进：

.. code-block:: nim

  if thisIsaLongCondition() and
      thisIsAnotherLongCondition(1,
         2, 3, 4):
    x = true

根据经验，表达式中的缩进允许在操作符、开放的小括号和逗号后。

用小括号和分号 ``(;)`` 可以在只允许表达式的地方使用语句：

.. code-block:: nim
    :test: "nim c $1"
  # 编译期计算fac(4) :
  const fac4 = (var x = 1; for i in 1..4: x *= i; x)


过程
==========

为了在示例中定义如 `echo <system.html#echo>`_ 和 `readLine <system.html#readLine,File>`_ 的新命令, 需要 `procedure` 的概念。
(一些语言叫 *方法* 或 *函数* 。) 在Nim中新的过程用 ``proc`` 关键字定义:

.. code-block:: nim
    :test: "nim c $1"
  proc yes(question: string): bool =
    echo question, " (y/n)"
    while true:
      case readLine(stdin)
      of "y", "Y", "yes", "Yes": return true
      of "n", "N", "no", "No": return false
      else: echo "Please be clear: yes or no"

  if yes("Should I delete all your important files?"):
    echo "I'm sorry Dave, I'm afraid I can't do that."
  else:
    echo "I think you know what the problem is just as well as I do."

这个示例展示了一个名叫 ``yes`` 的过程，它问用户一个 ``question`` 并返回true如果他们回答"yes"（或类似的回答），返回false当他们回答"no"（或类似的回答）。一个 ``return`` 语句立即跳出过程。
``(question: string): bool`` 语法描述过程需要一个名为 ``question`` ，类型为 ``string`` 的变量，并且返回一个 ``bool`` 值。 ``bool`` 类型是内置的：合法的值只有 ``true`` 和 ``false`` 。if或while语句中的条件必须是 ``bool`` 类型。

一些术语: 示例中 ``question`` 叫做一个(形) *参*, ``"Should I..."`` 叫做 *实参* 传递给这个参数。


Result变量
---------------
一个返回值的过程有一个隐式 ``result`` 变量声明代表返回值。一个没有表达式的 ``return`` 语句是 ``return result`` 的简写。 ``result`` 总在过程的结尾自动返回如果退出时没有 ``return`` 语句.

.. code-block:: nim
    :test: "nim c $1"
  proc sumTillNegative(x: varargs[int]): int =
    for i in x:
      if i < 0:
        return
      result = result + i

  echo sumTillNegative() # echos 0
  echo sumTillNegative(3, 4, 5) # echos 12
  echo sumTillNegative(3, 4 , -1 , 6) # echos 7

``result`` 变量已经隐式地声明在函数的开头，那么比如再次用'var result'声明， 将用一个相同名字的普通变量遮蔽它。result变量也已经用返回类型的默认值初始化过。
注意引用数据类型将是 ``nil`` 在过程的开头，因此可能需要手动初始化。


形参
----------
形参在过程体中不可改变。默认地，它们的值不能被改变，这允许编译器以最高效的方式实现参数传递。如果在一个过程内需要可以改变的变量，它必须在过程体中用 ``var`` 声明。 遮蔽形参名是可能的，实际上是一个习语：

.. code-block:: nim
    :test: "nim c $1"
  proc printSeq(s: seq, nprinted: int = -1) =
    var nprinted = if nprinted == -1: s.len else: min(nprinted, s.len)
    for i in 0 .. <nprinted:
      echo s[i]

如果过程需要为调用者修改实参，可以用 ``var`` 参数:

.. code-block:: nim
    :test: "nim c $1"
  proc divmod(a, b: int; res, remainder: var int) =
    res = a div b        # 整除
    remainder = a mod b  # 整数取模操作

  var
    x, y: int
  divmod(8, 5, x, y) # 修改x和y
  echo x
  echo y

示例中, ``res`` 和 ``remainder`` 是 `var parameters` 。Var参数可以被过程修改，改变对调用者可见。注意上面的示例用一个元组作为返回类型而不是var参数会更好。


Discard语句
-----------------
调用仅为其副作用返回值并忽略返回值的过程, **必须** 用 ``discard`` 语句。Nim不允许静默地扔掉一个返回值：

.. code-block:: nim
  discard yes("May I ask a pointless question?")


返回类型可以被隐式地忽略如果调用的方法、迭代器已经用 ``discardable`` pragma声明过。

.. code-block:: nim
    :test: "nim c $1"
  proc p(x, y: int): int {.discardable.} =
    return x + y

  p(3, 4) # now valid

在 `Comments`_ 段中描述 ``discard`` 语句也可以用于创建块注释。


命名参数
---------------

通常一个过程有许多参数而且参数的顺序不清晰。这在构造一个复杂数据类型时尤为突出。因此可以对传递给过程的实参命名，以便于看清哪个实参属于哪个形参：

.. code-block:: nim
  proc createWindow(x, y, width, height: int; title: string;
                    show: bool): Window =
     ...

  var w = createWindow(show = true, title = "My Application",
                       x = 0, y = 0, height = 600, width = 800)

既然我们使用命名实参来调用 ``createWindow`` 实参的顺序不再重要。有序实参和命名实参混合起来用也没有问题，但不是很好读：

.. code-block:: nim
  var w = createWindow(0, 0, title = "My Application",
                       height = 600, width = 800, true)

编译器检查每个形参只接收一个实参。


默认值
--------------
为了使 ``createWindow`` 方法更易于使用，它应当提供 `默认值` ；这些值在调用者没有指定时用作实参：

.. code-block:: nim
  proc createWindow(x = 0, y = 0, width = 500, height = 700,
                    title = "unknown",
                    show = true): Window =
     ...

  var w = createWindow(title = "My Application", height = 600, width = 800)

现在调用 ``createWindow`` 只需要设置不同于默认值的值。

现在形参可以由默认值进行类型推导；例如，没有必要写 ``title: string = "unknown"`` 。


重载过程
---------------------
Nim提供类似C++的过程重载能力：

.. code-block:: nim
  proc toString(x: int): string = ...
  proc toString(x: bool): string =
    if x: result = "true"
    else: result = "false"

  echo toString(13)   # calls the toString(x: int) proc
  echo toString(true) # calls the toString(x: bool) proc

(注意 ``toString`` 通常是Nim中的 `$ <system.html#$>`_ 。) 编译器为 ``toString`` 调用选择最合适的过程。 
重载解析算法不在这里讨论（会在手册中具体说明）。 不论如何，它不会导致意外，并且基于一个非常简单的统一算法。有歧义的调用会作为错误报告。


操作符
---------
Nim库重度使用重载，一个原因是每个像 ``+`` 的操作符就是一个重载过程。解析器让你在 `中缀标记` (``a + b``)或 `前缀标记` (``+ a``)中使用操作符。
一个中缀操作符总是有两个实参，一个前缀操作符总是一个。(后缀操作符是不可能的，因为这有歧义： ``a @ @ b`` 表示 ``(a) @ (@b)`` 还是 ``(a@) @ (b)`` ？它总是表示 ``(a) @ (@b)`` , 
因为Nim中没有后缀操作符。

除了几个内置的关键字操作符如 ``and`` 、 ``or`` 、 ``not`` ，操作符总是由以下符号构成： ``+  -  *  \  /  <  >  =  @  $  ~  &  %  !  ?  ^  .  |``

允许用户定义的操作符。没有什么阻止你定义自己的 ``@!?+~`` 操作符，但这么做降低了可读性。

操作符优先级由第一个字符决定。细节可以在手册中找到。

用反引号"``"括起来定义一个新操作符：

.. code-block:: nim
  proc `$` (x: myDataType): string = ...
  # 现在$操作符对myDataType生效，重载解析确保$对内置类型像之前一样工作。

"``"标记也可以来用调用一个像任何其它过程的操作符:

.. code-block:: nim
    :test: "nim c $1"
  if `==`( `+`(3, 4), 7): echo "True"


前向声明
--------------------

每个变量、过程等，需要使用前向声明。前向声明不能互相递归：

.. code-block:: nim
  # 前向声明:
  proc even(n: int): bool

.. code-block:: nim
  proc odd(n: int): bool =
    assert(n >= 0) # 确保我们没有遇到负递归
    if n == 0: false
    else:
      n == 1 or even(n-1)

  proc even(n: int): bool =
    assert(n >= 0) # 确保我们没有遇到负递归
    if n == 1: false
    else:
      n == 0 or odd(n-1)

这里 ``odd`` 取决于 ``even`` 反之亦然。因此 ``even`` 需要在完全定义前引入到编译器。前向声明的语法很简单：直接忽略 ``=`` 和过程体。 ``assert`` 只添加边界条件，将在 `模块`_ 段中讲到。

语言的后续版本将弱化前向声明的要求。

示例也展示了一个过程体可以由一个表达式构成，其值之后被隐式返回。


迭代器
=========

让我们回到简单的计数示例：

.. code-block:: nim
    :test: "nim c $1"
  echo "Counting to ten: "
  for i in countup(1, 10):
    echo i

一个 `countup <system.html#countup>`_ 过程可以支持这个循环吗？让我们试试：

.. code-block:: nim
  proc countup(a, b: int): int =
    var res = a
    while res <= b:
      return res
      inc(res)

这不行,问题在于过程不应当只 ``return`` ，但是迭代器后的return和 **continue** 已经完成。这 *return and continue* 叫做 `yield` 语句。现在只剩下用 ``iterator`` 替换 ``proc`` 关键字，
它来了——我们的第一个迭代器：

.. code-block:: nim
    :test: "nim c $1"
  iterator countup(a, b: int): int =
    var res = a
    while res <= b:
      yield res
      inc(res)

迭代器看起来像过程，但有几点重要的差异：

* 迭代器只能从循环中调用。
* 迭代器不能包含 ``return`` 语句（过程不能包含 ``yield`` 语句）。
* 迭代器没有隐式 ``result`` 变量。
* 迭代器不支持递归。
* 迭代器不能前向声明，因为编译器必须能够内联迭代器。（这个限制将在编译器的未来版本中消失。）

你也可以用 ``closure`` 迭代器得到一个不同的限制集合。详见 `一等迭代器<manual.html#iterators-and-the-for-statement-first-class-iterators>`_ 。 迭代器可以和过程有同样的名字和形参，因为它们有自己的命名空间。
因此，通常的做法是将迭代器包装在同名的proc中，这些迭代器会累积结果并将其作为序列返回, 像 `strutils模块<strutils.html>`_ 中的 ``split`` 。


基本类型
===========

本章处理基本内置类型和它们的操作细节。

布尔值
--------

Nim的布尔类型叫做 ``bool`` ，由两个预先定义好的值 ``true`` 和 ``false`` 构成。while、if、elif和when语句中的条件必须是布尔类型。

为布尔类型定义操作符 ``not, and, or, xor, <, <=, >, >=, !=, ==`` 。 ``and`` 和 ``or`` 操作符执行短路求值。例如：

.. code-block:: nim

  while p != nil and p.name != "xyz":
    # 如果p == nil，p.name不被求值
    p = p.next


字符
----------
字符类型叫做 ``char`` 。大小总是一字节，所以不能表示大多数UTF-8字符；但可以表示组成多字节UTF-8字符的一个字节。原因是为了效率：对于绝大多数用例，程序依然可以正确处理UTF-8因为UTF-8是专为此设计的。
字符字面值用单引号括起来。

字符可以用 ``==``, ``<``, ``<=``, ``>``, ``>=`` 操作符比较。 ``$`` 操作符将一个 ``char`` 转换成一个 ``string`` 。字符不能和整型混合；用 ``ord`` 过程得到一个 ``char`` 的序数值。
从整型到 ``char`` 转换使用 ``chr`` 过程。


字符串
-------
字符串变量是 **可以改变的** ， 字符串可以追加，而且非常高效。Nim中的字符串有长度字段，以零结尾。一个字符串长度可以用内置 ``len`` 过程获取；长度不计结尾的零。访问结尾零是一个错误，它只为Nim字符串无拷贝转换为 ``cstring`` 存在。

字符串赋值会产生拷贝。你可以用 ``&`` 操作符拼接字符串和 ``add`` 追加到一个字符串。

字符串用字典序比较，支持所有比较操作符。通过转换，所有字符串是UTF-8编码过的，但不是强制。例如，当从进制文件读取字符串时，他们只是一串字节序列。索引操作符 ``s[i]`` 表示 ``s`` 的第i个 *字符* , 不是第i个 *unichar* 。

一个字符串变量用空字符串初始化 ``""`` 。


整型
--------
Nim有以下内置整型：
``int int8 int16 int32 int64 uint uint8 uint16 uint32 uint64`` 。

默认整型是 ``int`` 。整型字面值可以用 *类型前缀* 来指定一个非默认整数类型：


.. code-block:: nim
    :test: "nim c $1"
  let
    x = 0     # x是 ``int``
    y = 0'i8  # y是 ``int8``
    z = 0'i64 # z是 ``int64``
    u = 0'u   # u是 ``uint``

多数常用整数用来计数内存中的对象，所以 ``int`` 和指针具有相同的大小。

整数支持通用操作符 ``+ - * div mod  <  <=  ==  !=  >  >=`` 。 也支持 ``and or xor not`` 操作符，并提供 *按位* 操作。 左移用 ``shl`` ，右移用 ``shr`` 。位移操作符实参总是被当作 *无符号整型* 。 
普通乘法或除法可以做 `算术位移`:idx: 。

无符号操作不会引起上溢和下溢。

无损 `自动类型转换`:idx: 在表达式中使用不同类型的整数时执行。如果失真，会抛出 `EOutOfRange`:idx: 异常（如果错误没能在编译时检查出来）。


浮点
------
Nim有这些内置浮点类型： ``float float32 float64`` 。

默认浮点类型是 ``float`` 。在当前的实现， ``float`` 是64位。

浮点字面值可以有 *类型前缀* 来指定非默认浮点类型：

.. code-block:: nim
    :test: "nim c $1"
  var
    x = 0.0      # x是 ``float``
    y = 0.0'f32  # y是 ``float32``
    z = 0.0'f64  # z是 ``float64``

浮点类型支持通用操作符 ``+ - * /  <  <=  ==  !=  >  >=`` 并遵循IEEE-754标准。

自动类型转换在表达式中使用不同类型时执行：短类型转换为长类型。整数类型 **不** 会自动转换为浮点类型，反之亦然。使用 `toInt <system.html#toInt>`_ 和 `toFloat <system.html#toFloat>`_ 过程来转换。


类型转换
---------------
数字类型转换通过使用类型来执行：

.. code-block:: nim
    :test: "nim c $1"
  var
    x: int32 = 1.int32   # 与调用int32(1)相同
    y: int8  = int8('a') # 'a' == 97'i8
    z: float = 2.5       # int(2.5)向下取整为2
    sum: int = int(x) + int(y) + int(z) # sum == 100


内部类型表示
============================

之前提到过，内置的 `$ <system.html#$>`_ （字符串化）操作符将基本类型转换成字符串，这样可以用 ``echo`` 过程将内容打印到控制台上。但是高级类型和你自定义的类型，需要定义 ``$`` 操作符才能使用。
有时你只想在没有写一个高级类型的 ``$`` 操作符时调试当前的值，那么你可以用 `repr <system.html#repr>`_ 过程，它可以用于任何类型甚至复杂的有环数据图。下面的示例展示了  ``$`` and ``repr`` 在即使基本类型输出上也有不同：

.. code-block:: nim
    :test: "nim c $1"
  var
    myBool = true
    myCharacter = 'n'
    myString = "nim"
    myInteger = 42
    myFloat = 3.14
  echo myBool, ":", repr(myBool)
  # --> true:true
  echo myCharacter, ":", repr(myCharacter)
  # --> n:'n'
  echo myString, ":", repr(myString)
  # --> nim:0x10fa8c050"nim"
  echo myInteger, ":", repr(myInteger)
  # --> 42:42
  echo myFloat, ":", repr(myFloat)
  # --> 3.1400000000000001e+00:3.1400000000000001e+00


高级类型
==============

在Nim中新类型可以在 ``type`` 语句里定义：

.. code-block:: nim
    :test: "nim c $1"
  type
    biggestInt = int64      # 可用的最大整数类型
    biggestFloat = float64  # 可用的最大浮点类型

枚举和对象类型只能定义在 ``type`` 语句中。


枚举
------------
枚举类型的变量只能赋值为枚举指定的值。这些值是有序符号的集合。每个符号映射到内部的一个整数类型。第一个符号用运行时的0表示，第二个用1，以此类推。例如：

.. code-block:: nim
    :test: "nim c $1"

  type
    Direction = enum
      north, east, south, west

  var x = south     # `x`是`Direction`; 值是`south`
  echo x            # 向标准输出写"south"

所有对比操作符可以用枚举类型。

枚举符号

枚举的符号可以被限定以避免歧义： ``Direction.south`` 。

``$`` 操作符可以将任何枚举值转换为它的名字， ``ord`` 过程可以转换为它底层的整数类型。

为了更好的对接其它编程语言，枚举类型可以赋一个显式的序数值，序数值必须是升序。


序数类型
-------------
枚举、整型、 ``char`` 、 ``bool`` （和子范围）叫做序数类型。序数类型有一些特殊操作：

-----------------     --------------------------------------------------------
Operation             Comment
-----------------     --------------------------------------------------------
``ord(x)``            返回表示 `x` 的整数值
``inc(x)``            `x` 递增1
``inc(x, n)``         `x` 递增 `n`; `n` 是整数
``dec(x)``            `x` 递减1
``dec(x, n)``         `x` 递减 `n`; `n` 是整数
``succ(x)``           返回 `x` 的下一个值
``succ(x, n)``        返回 `x` 后的第n个值
``pred(x)``           返回 `x` 的前一个值
``pred(x, n)``        返回 `x` 前的第n个值
-----------------     --------------------------------------------------------

`inc <system.html#inc>`_, `dec <system.html#dec>`_, `succ <system.html#succ>`_ 和 `pred <system.html#pred>`_ 操作通过抛出 `EOutOfRange` 或 `EOverflow` 异常而失败。
（如果代码编译时打开了运行时检查。）


子范围
---------
一个子范围是一个整型或枚举类型值（基本类型）的范围。例如：

.. code-block:: nim
    :test: "nim c $1"
  type
    MySubrange = range[0..5]


``MySubrange`` 是只包含0到5的 ``int`` 范围。赋任何其它值给 ``MySubrange`` 类型的变量是编译期或运行时错误。允许给子范围赋值它的基类型，反之亦然。

``system`` 模块定义了重要的 `Natural <system.html#Natural>`_ 类型 ``range[0..high(int)]`` (`high <system.html#high>`_ 返回最大值）。其它编程语言可能建议使用无符号整数。这通常是 **不明智的** : 
你不希望因为数字不能是负值而使用无符号算术。Nim的 ``Natural`` 类型帮助避免这个编程错误。


集合类型
----

集合模拟了数学集合的概念。 集合的基类型只能是固定大小的序数类型，它们是:

* ``int8``-``int16``
* ``uint8``/``byte``-``uint16``
* ``char``
* ``enum``

或等价类型。对有符号整数集合的基类型被定义为在 ``0 .. MaxSetElements-1`` 的范围内， 其中 ``MaxSetElements`` 目前是2^16。

原因是集合被实现为高性能位向量。尝试声明具有更大类型的集将导致错误：

.. code-block:: nim

  var s: set[int64] # 错误: 集合太大

集合可以通过集合构造器来构造： ``{}`` 是空集合。 空集合与其它具体的集合类型兼容。构造器也可以用来包含元素（和元素范围）：

.. code-block:: nim
  type
    CharSet = set[char]
  var
    x: CharSet
  x = {'a'..'z', '0'..'9'} # 构造一个包含'a'到'z'和'0'到'9'的集合 

集合支持的操作符：

==================    ========================================================
操作符                 含义
==================    ========================================================
``A + B``             并集
``A * B``             交集
``A - B``             差集
``A == B``            相等
``A <= B``            子集
``A < B``             真子集
``e in A``            元素
``e notin A``         A不包含元素e
``contains(A, e)``    包含元素e
``card(A)``           A的基 (集合A中的元素数量)
``incl(A, elem)``     同 ``A = A + {elem}``
``excl(A, elem)``     同 ``A = A - {elem}``
==================    ========================================================

位字段
~~~~~~~~~~

集合经常用来定义过程的 *标示* 。这比定义必须或在一起的整数常量清晰并且类型安全。

枚举、集合和强转可以一起用：

.. code-block:: nim

  type
    MyFlag* {.size: sizeof(cint).} = enum
      A
      B
      C
      D
    MyFlags = set[MyFlag]

  proc toNum(f: MyFlags): int = cast[cint](f)
  proc toFlags(v: int): MyFlags = cast[MyFlags](v)

  assert toNum({}) == 0
  assert toNum({A}) == 1
  assert toNum({D}) == 8
  assert toNum({A, C}) == 5
  assert toFlags(0) == {}
  assert toFlags(7) == {A, B, C}

注意集合如何把枚举变成2的指数。

如果和C一起使用枚举和集合，使用distinct cint。

为了和C互通见 `bitsize pragma <#implementation-specific-pragmas-bitsize-pragma>`_ 。

数组
------
数组是固定长度的容器。数组中的元素具有相同的类型。数组索引类型可以是任意序数类型。

数组可以用 ``[]`` 来构造：

.. code-block:: nim
    :test: "nim c $1"

  type
    IntArray = array[0..5, int] # 一个索引为0..5的数​组
  var
    x: IntArray
  x = [1, 2, 3, 4, 5, 6]
  for i in low(x)..high(x):
    echo x[i]

``x[i]`` 标记用来访问 ``x`` 的第i个元素。数组访问总是有边界检查的 （编译期或运行时）。这些检查可以通过pragmas或调用编译器的命令行开关 ``--bound_checks:off`` 来关闭。

数组是值类型，和任何其它Nim类型一样。赋值操作符拷贝整个数组内容。

内置 `len <system.html#len,TOpenArray>`_ 过程返回数组长度。 `low(a) <system.html#low>`_ 返回数组a的最小索引， `high(a) <system.html#high>`_ 返回最大索引。

.. code-block:: nim
    :test: "nim c $1"
  type
    Direction = enum
      north, east, south, west
    BlinkLights = enum
      off, on, slowBlink, mediumBlink, fastBlink
    LevelSetting = array[north..west, BlinkLights]
  var
    level: LevelSetting
  level[north] = on
  level[south] = slowBlink
  level[east] = fastBlink
  echo repr(level)  # --> [on, fastBlink, slowBlink, off]
  echo low(level)   # --> north
  echo len(level)   # --> 4
  echo high(level)  # --> west

嵌套数组的语法，即其它语言中的多维数组，实际上是追加更多中括号因为通常每个维度限制为和其它一样的索引类型。
在Nim中你可以在不同的维度有不同索引类型，所以嵌套语法稍有不同。
基于上面的例子，其中层数定义为枚举的数组被另一个枚举索引，我们可以添加下面的行来添加一个在层数上进行再分割的灯塔类型：

.. code-block:: nim
  type
    LightTower = array[1..10, LevelSetting]
  var
    tower: LightTower
  tower[1][north] = slowBlink
  tower[1][east] = mediumBlink
  echo len(tower)     # --> 10
  echo len(tower[1])  # --> 4
  echo repr(tower)    # --> [[slowBlink, mediumBlink, ...more output..
  # 下面的行不能编译因为类型不匹配
  #tower[north][east] = on
  #tower[0][1] = on

注意内置 ``len`` 过程如何只返回数组的第一维长度。另一个定义 ``LightTower`` 的方法来更好的说明它的嵌套本质是忽略上面定义的 ``LevelSetting`` 类型，取而代之是直接将它以第一维类型嵌入。

.. code-block:: nim
  type
    LightTower = array[1..10, array[north..west, BlinkLights]]

从零开始对数组很普遍，有从零到指定索引减1的范围简写语法：

.. code-block:: nim
    :test: "nim c $1"
  type
    IntArray = array[0..5, int] # 一个索引为0..5的数​组
    QuickArray = array[6, int]  # 一个索引为0..5的数​组
  var
    x: IntArray
    y: QuickArray
  x = [1, 2, 3, 4, 5, 6]
  y = x
  for i in low(x)..high(x):
    echo x[i], y[i]


序列
---------
序列类似数组但是动态长度，可以在运行时改变（像字符串）。因为序列是大小可变的它们总是分配在堆上，被垃圾回收。

序列总是以从零开始的 ``int`` 类型索引。 `len <system.html#len,seq[T]>`_ , `low <system.html#low>`_ 和 `high <system.html#high>`_ 操作符也可用于序列。 ``x[i]`` 标记可以用于访问 ``x`` 的第i个元素。

序列可以用数组构造器 ``[]`` 数组到序列操作符 ``@`` 构成。另一个为序列分配空间的方法是调用内置 `newSeq <system.html#newSeq>`_ 过程。

序列可以传递给一个开放数组形参。

Example:

.. code-block:: nim
    :test: "nim c $1"

  var
    x: seq[int] # 整数序列引用
  x = @[1, 2, 3, 4, 5, 6] # @ 把数组转成分配在堆上的序列

序列变量用 ``@[]`` 初始化。

``for`` 语句可以用一到两个变量当和序列一起使用。当你使用一个变量的形式，变量持有序列提供的值。 ``for`` 语句是在 `system <system.html>`_ 模块中的 `items() <system.html#items.i,seq[T]>`_ 迭代器结果上迭代。
但如果你使用两个变量形式，第一个变量将持有索引位置，第二个变量持有值。这里 ``for`` 语句是在 `system <system.html>`_ 模块中的 `pairs() <system.html#pairs.i,seq[T]>`_ 迭代器结果上迭代。例如：

.. code-block:: nim
    :test: "nim c $1"
  for value in @[3, 4, 5]:
    echo value
  # --> 3
  # --> 4
  # --> 5

  for i, value in @[3, 4, 5]:
    echo "index: ", $i, ", value:", $value
  # --> index: 0, value:3
  # --> index: 1, value:4
  # --> index: 2, value:5


开放数组
-----------
**注意**: 开放数组只用于形参。

固定大小的数组经常被证明是不够灵活的；过程应当能够处理不同大小的数组。 `开放数组`:idx: 类型允许这样。开放数组总是以0开始的 ``int`` 索引。
`len <system.html#len,TOpenArray>`_, `low <system.html#low>`_ 和 `high <system.html#high>`_ 操作符也可以用于开放数组。任何兼容基类型的数组可以传递给开放数组形参, 与索引类型无关。

.. code-block:: nim
    :test: "nim c $1"
  var
    fruits:   seq[string]       # 字符串序列用 '@[]' 初始化
    capitals: array[3, string]  # 固定大小的字符串数组

  capitals = ["New York", "London", "Berlin"]   # 数组 'capitals' 允许只有三个元素的赋值
  fruits.add("Banana")          # 序列 'fruits' 在运行时动态扩展
  fruits.add("Mango")

  proc openArraySize(oa: openArray[string]): int =
    oa.len

  assert openArraySize(fruits) == 2     # 过程接受一个序列作为形参
  assert openArraySize(capitals) == 3   # 也可以是一个数组

开放数组类型无法嵌套：多维开放数组不支持，因为这个需求很少见且不能有效的实现。


可变参数
-------

``varargs`` 参数像开放数组形参。 它也表示实现传递数量可变的实参给过程。 编译器将实参列表自动转换为数组：

.. code-block:: nim
    :test: "nim c $1"
  proc myWriteln(f: File, a: varargs[string]) =
    for s in items(a):
      write(f, s)
    write(f, "\n")

  myWriteln(stdout, "abc", "def", "xyz")
  # 编译器转为:
  myWriteln(stdout, ["abc", "def", "xyz"])

转换只在可变形参是过程头部的最后一个形参时完成。它也可以在这个情景执行类型转换：

.. code-block:: nim
    :test: "nim c $1"
  proc myWriteln(f: File, a: varargs[string, `$`]) =
    for s in items(a):
      write(f, s)
    write(f, "\n")

  myWriteln(stdout, 123, "abc", 4.0)
  # 编译器转为:
  myWriteln(stdout, [$123, $"abc", $4.0])

在示例中 `$ <system.html#$>`_ 适用于任何传递给形参 ``a`` 的实参。注意 `$ <system.html#$>`_ 适用于空字符串指令。


切片
------

切片语法看起来像子范围但用于不同的场景。切片只是一个包含两个边界 `a` and `b` 的切片类型对象。
它自己不是很有用，但是其它收集类型定义接受切片对象来定义范围的操作符。

.. code-block:: nim
    :test: "nim c $1"

  var
    a = "Nim is a progamming language"
    b = "Slices are useless."

  echo a[7..12] # --> 'a prog'
  b[11..^2] = "useful"
  echo b # --> 'Slices are useful.'

在上面的例子中切片用于修改字符串的一部分。切片边界可以持有任何它们的类型支持的值，但它是使用切片对象的过程，它定义了接受的值。

为了理解指定字符串、数组、序列等索引的不同方法， 必须记住Nim使用基于零的索引。

所以字符串 ``b`` 长度是19, 两个不同的指定索引的方法是

.. code-block:: nim

  "Slices are useless."
   |          |     |
   0         11    17   使用索引
  ^19        ^8    ^2   使用^

其中 ``b[0..^1]`` 等价于 ``b[0..b.len-1]`` 和 ``b[0..<b.len]`` ，它可以看作 ``^1`` 提供一个指定 ``b.len-1`` 的简写。

在上面的例子中，因为字符串在句号中结束，来获取字符串中"useless"的部分并替换为"useful"。

``b[11..^2]`` 是"useless"的部分， ``b[11..^2] = "useful"`` 用"useful"替换"useless"，得到结果"Slices are useful."

注意: 可选方法是 ``b[^8..^2] = "useful"`` 或 ``b[11..b.len-2] = "useful"`` 或 as ``b[11..<b.len-1] = "useful"`` 。

对象
-------

在具有名称的单个结构中将不同值打包在一起的默认类型是对象类型。对象是值类型，意味关当对象赋值给一个新变量时它所有的组成部分也一起拷贝。

每个对象类型 ``Foo`` 有一个构造函数 ``Foo(field: value, ...)`` 其中它的所有字段可以被初始化。没有指定的字段将获得它们的默认值。

.. code-block:: nim
  type
    Person = object
      name: string
      age: int

  var person1 = Person(name: "Peter", age: 30)

  echo person1.name # "Peter"
  echo person1.age  # 30

  var person2 = person1 # 复制person 1

  person2.age += 14

  echo person1.age # 30
  echo person2.age # 44


  # 顺序可以改变
  let person3 = Person(age: 12, name: "Quentin")

  # 不需要指定每个成员
  let person4 = Person(age: 3)
  # 未指定的成员将用默认值初始化。本例中它是一个空字符串。
  doAssert person4.name == ""


在定义的模块外可见的对象字段需要加上 ``*`` 。

.. code-block:: nim
    :test: "nim c $1"

  type
    Person* = object # 其它模块可见
      name*: string  # 这个类型的字段在其它模块可见
      age*: int

元组
------

元组和你目前见到的对象很像。它们是赋值时拷贝每个组成部分的值类型。与对象类型不同的是，元组类型是结构化类型，这意味着不同的元组类型是 *等价的* 如果它们以相同的顺序指定相同类型和相同名称的字段。

构造函数 ``()`` 可以用来构造元组。构造函数中字段的顺序必须与元组定义中的顺序匹配。但与对象不同，此处可能不使用元组类型的名称。

如对象类型， ``t.field`` 用来访问一个元组的字段。 另一个对象不可用的标记法是 ``t[i]`` 访问第 ``i``' 个字段。这里 ``i`` 必须是一个常整数。

.. code-block:: nim
    :test: "nim c $1"
  type
    # 类型表示一个人:
    # 一个人有名字和年龄。
    Person = tuple
      name: string
      age: int

    # 等价类型的语法。
    PersonX = tuple[name: string, age: int]

    # 匿名字段语法
    PersonY = (string, int)

  var
    person: Person
    personX: PersonX
    personY: PersonY

  person = (name: "Peter", age: 30)
  # Person和PersonX等价
  personX = person

  # 用匿名字段创建一个元组：
  personY = ("Peter", 30)

  # 有匿名字段元组兼容有字段名元组。
  person = personY
  personY = person

  # 通常用于短元组初始化语法
  person = ("Peter", 30)

  echo person.name # "Peter"
  echo person.age  # 30

  echo person[0] # "Peter"
  echo person[1] # 30

  # 你不需要在一个独立类型段中声明元组。
  var building: tuple[street: string, number: int]
  building = ("Rue del Percebe", 13)
  echo building.street

  # 下面的行不能编译，它们是不同的元组。
  #person = building
  # --> Error: type mismatch: got (tuple[street: string, number: int])
  #     but expected 'Person'

即使你不需要为元组声明类型就可以使用，不同字段名创建的元组将认为是不同的对象，尽管有相同的字段类型。

元组只有在变量赋值期间可以 *解包* 。 这方便将元组字段直接一个个赋值给命名变量。一个例子是 `os module <os.html>`_ 模块中的 `splitFile <os.html#splitFile>`_ 过程，
它同时返回一个路径的目录、名称和扩展名。元组解包必须使用小括号括住你想赋值的解包变量，否则你将为每个变量赋同样的值！例如：

.. code-block:: nim
    :test: "nim c $1"

  import os

  let
    path = "usr/local/nimc.html"
    (dir, name, ext) = splitFile(path)
    baddir, badname, badext = splitFile(path)
  echo dir      # 输出 `usr/local`
  echo name     # 输出 `nimc`
  echo ext      # 输出 `.html`
  # 下面输出同样的行:
  # `(dir: usr/local, name: nimc, ext: .html)`
  echo baddir
  echo badname
  echo badext

元组字段总是公有的，你不必像对象类型字段显式的标记来导出。

引用和指针类型
---------------------------
引用（类似其它编程语言中的指针）是引入多对一关系的方式。这表示不同的引用可以指向和修改相同的内存位置。

Nim区分 `被追踪`:idx: 和 `未追踪`:idx: 引用。未追踪引用也被称为 *指针* 。追踪的引用指向垃圾回收堆里的对象，未追踪引用指向手动分配对象或内存中其它地方的对象。因此未追踪引用是 *不安全的* 。
为了某些低级的操作（例如，访问硬件），未追踪的引用是必须的。

追踪的引用用 **ref** 关键字声明；未追踪引用用 **ptr** 关键字声明。

空 ``[]`` 下标标记可以用来 *解引用* 一个引用，表示获取引用指向的内容。 ``.`` （访问一个元组/对象字段操作符）和 ``[]`` (数组/字符串/序列索引操作符）操作符为引用类型执行隐式解引用操作：

.. code-block:: nim
    :test: "nim c $1"

  type
    Node = ref object
      le, ri: Node
      data: int
  var
    n: Node
  new(n)
  n.data = 9
  # 不必写n[].data; 实际上n[].data是不提倡的!

为了分配一个新追踪的对象，必须使用内置过程 ``new`` 。 为了处理未追踪内存， 可以用 ``alloc``, ``dealloc`` 和 ``realloc`` 。 `system <system.html>`_ 模块文档包含更多细节。

如果一个引用指向 *nothing*, 它的值是 ``nil`` 。


过程类型
---------------
过程类型是指向过程的指针。 ``nil`` 是过程类型变量允许的值。Nim使用过程类型达到 `函数式`:idx: 编程技术。

Example:

.. code-block:: nim
    :test: "nim c $1"
  proc echoItem(x: int) = echo x

  proc forEach(action: proc (x: int)) =
    const
      data = [2, 3, 5, 7, 11]
    for d in items(data):
      action(d)

  forEach(echoItem)

过程类型的一个小问题是调用规约影响类型兼容性：过程类型只兼容如果他们有相同的调用规约。不同的调用规约列在 `manual <manual.html#types-procedural-type>`_ 。

Distinct类型
-------------
一个Distinct类型允许用于创建“非基本类型的子类型”。你必须 **显式** 定义distinct类型的所有行为。
为了帮助这点，distinct类型和它的基类型可以相互强转。
示例提供在 `manual <manual.html#types-distinct-type>`_ 。

模块
=======
Nim支持用模块的概念把一个程序拆分成片段。每个模块在它自己的文件里。模块实现了 `信息隐藏`:idx: 和 `编译隔离`:idx: 。一个模块可以通过 `import`:idx: 语句访问另一个模块符号。
只有标记了星号(``*``)的顶级符号被导出：

.. code-block:: nim
  # Module A
  var
    x*, y: int

  proc `*` *(a, b: seq[int]): seq[int] =
    # 分配新序列：
    newSeq(result, len(a))
    # 两个序列相乘：
    for i in 0..len(a)-1: result[i] = a[i] * b[i]

  when isMainModule:
    # 测试序列乘 ``*`` :
    assert(@[1, 2, 3] * @[1, 2, 3] == @[1, 4, 9])

上面的模块导出 ``x`` 和 ``*``, 但没有 ``y`` 。

一个模块的顶级语句在程序开始时执行，比如这可以用来初始化复杂数据结构。

每个模块有特殊的魔法常量 ``isMainModule`` 在作为主文件编译时为真。 如上面所示，这对模块内的嵌入测试非常有用。

一个模块的符号 *可以* 用 ``module.symbol`` 语法 *限定* 。如果一个符号有歧义，它 *必须* 被限定。一个符号有歧义如果定义在两个或多个不同的模块并且被第三个模块导入：

.. code-block:: nim
  # Module A
  var x*: string

.. code-block:: nim
  # Module B
  var x*: int

.. code-block:: nim
  # Module C
  import A, B
  write(stdout, x) # error: x 有歧义
  write(stdout, A.x) # okay: 用了限定

  var x = 4
  write(stdout, x) # 没有歧义: 使用模块C的x


但这个规则不适用于过程或迭代器。重载规则适用于:

.. code-block:: nim
  # Module A
  proc x*(a: int): string = $a

.. code-block:: nim
  # Module B
  proc x*(a: string): string = $a

.. code-block:: nim
  # Module C
  import A, B
  write(stdout, x(3))   # no error: A.x is called
  write(stdout, x(""))  # no error: B.x is called

  proc x*(a: int): string = discard
  write(stdout, x(3))   # 歧义: 调用哪个 `x` ?


排除符号
-----------------

普通的 ``import`` 语句将带来所有导出的符号。这可以用 ``except`` 标识符点名限制哪个符号应当被排除。

.. code-block:: nim
  import mymodule except y


From语句
--------------

我们已经看到简单的 ``import`` 语句导入所有导出的符号。一个只导入列出来的符号的可选方法是使用 ``from import`` 语句：

.. code-block:: nim
  from mymodule import x, y, z

``from`` 语句也可以强制限定符号的命名空间，因此可以使符号可用，但需要限定。

.. code-block:: nim
  from mymodule import x, y, z

  x()           # 没有任何限定使用x

.. code-block:: nim
  from mymodule import nil

  mymodule.x()  # 必须用模块名前缀限定x

  x()           # 没有限定使用x是编译错误

因为模块普遍比较长方便描述，你也可以在限定符号时使用短的别名。

.. code-block:: nim
  from mymodule as m import nil

  m.x()         # m是mymodule别名


Include语句
-----------------
``include`` 语句和导入一个模块做不同的基础工作：它只包含一个文件的内容。 ``include`` 语句在把一个大模块拆分为几个文件时有用：

.. code-block:: nim
  include fileA, fileB, fileC



Part 2
======

那么, 既然我们完成了基本的，让我们看看Nim除了为过程编程提供漂亮的语法外还有哪些： `Part II <tut2.html>`_


.. _strutils: strutils.html
.. _system: system.html
