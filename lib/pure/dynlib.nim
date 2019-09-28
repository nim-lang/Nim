#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## 该模块实现了一些访问动态共享库中符号的方法。在 Posix 系统上使用的是`dlsym`机制，
## 而在 windows 平台，则是`LoadLibrary`。
##
## 例子
## ========
##
## 加载一个简单的 c 函数
## ---------------------------
##
## 下面的例子演示了从某个动态库中加载一个名为`greet`的函数，在运行时导入哪个库取决于语言的选择。
## 如果该库导入失败或者`greet`函数没有找到，代码会以返回错误码的方式结束。
##
## .. code-block::nim
##
##   import dynlib
##
##   type
##     greetFunction = proc(): cstring {.gcsafe, stdcall.}
##
##   let lang = stdin.readLine()
##
##   let lib = case lang
##   of "french":
##     loadLib("french.dll")
##   else:
##     loadLib("english.dll")
##
##   if lib == nil:
##     echo "Error loading library"
##     quit(QuitFailure)
##
##   let greet = cast[greetFunction](lib.symAddr("greet"))
##
##   if greet == nil:
##     echo "Error loading 'greet' function from library"
##     quit(QuitFailure)
##
##   let greeting = greet()
##
##   echo greeting
##
##   unloadLib(lib)
##

import strutils

type
  LibHandle* = pointer ## 一个指向动态加载库的句柄

proc loadLib*(path: string, globalSymbols=false): LibHandle {.gcsafe.}
  ## 从路径`path`导入一个库。如果该路径的库无法导入，则返回`nil`。

proc loadLib*(): LibHandle {.gcsafe.}
  ## 从当前可执行文件获取动态库的句柄，如果库无法加载，则返回 nil

proc unloadLib*(lib: LibHandle) {.gcsafe.}
  ## 卸载库`lib`

proc raiseInvalidLibrary*(name: cstring) {.noinline, noreturn.} =
  ## 触发一个`EInvalidLibrary`异常。
  raise newException(LibraryError, "could not find symbol: " & $name)

proc symAddr*(lib: LibHandle, name: cstring): pointer {.gcsafe.}
  ## 从库`lib`中获取一个过程或变量的地址。如果符号无法找到，则返回`nil`。

proc checkedSymAddr*(lib: LibHandle, name: cstring): pointer =
  ## 从库`lib`中获取一个过程或变量的地址。如果符号无法找到，则会触发`EInvalidLibrary`异常。
  result = symAddr(lib, name)
  if result == nil: raiseInvalidLibrary(name)

proc libCandidates*(s: string, dest: var seq[string]) =
  ## 给定一个匹配的库名称`s`，将可能的库名称写入`desc`
  var le = strutils.find(s, '(')
  var ri = strutils.find(s, ')', le+1)
  if le >= 0 and ri > le:
    var prefix = substr(s, 0, le - 1)
    var suffix = substr(s, ri + 1)
    for middle in split(substr(s, le + 1, ri - 1), '|'):
      libCandidates(prefix & middle & suffix, dest)
  else:
    add(dest, s)

proc loadLibPattern*(pattern: string, globalSymbols=false): LibHandle =
  ## 以名称匹配的方式导入库，行为与`dlimport`注解类似。如果库无法导入，则返回`nil`。
  ## 警告：该过程涉及到 GC，因此不能用来加载 GC 相关的库。
  var candidates = newSeq[string]()
  libCandidates(pattern, candidates)
  for c in candidates:
    result = loadLib(c, globalSymbols)
    if not result.isNil: break

when defined(posix) and not defined(nintendoswitch):
  #
  # =========================================================================
  # 这是一个基于 dlfcn 接口的实现。
  # dlfcn 接口在 Linux, SunOS, Solaris, IRIX, FreeBSD, NetBSD, AIX 4.2, HPUX 11 
  # 系统上可用， 或许在其他 Unix 变种上也可以使用，至少是作为一个建立在原生函数之上的模拟层
  # =========================================================================
  #
  import posix

  proc loadLib(path: string, globalSymbols=false): LibHandle =
    let flags =
      if globalSymbols: RTLD_NOW or RTLD_GLOBAL
      else: RTLD_NOW

    dlopen(path, flags)

  proc loadLib(): LibHandle = dlopen(nil, RTLD_NOW)
  proc unloadLib(lib: LibHandle) = discard dlclose(lib)
  proc symAddr(lib: LibHandle, name: cstring): pointer = dlsym(lib, name)

elif defined(nintendoswitch):
  #
  # =========================================================================
  # Nintendo switch DevkitPro sdk 没有这些. 如果调用会触发错误.
  # 
  # =========================================================================
  #

  proc dlclose(lib: LibHandle) =
    raise newException(OSError, "dlclose not implemented on Nintendo Switch!")
  proc dlopen(path: cstring, mode: int): LibHandle =
    raise newException(OSError, "dlopen not implemented on Nintendo Switch!")
  proc dlsym(lib: LibHandle, name: cstring): pointer =
    raise newException(OSError, "dlsym not implemented on Nintendo Switch!")
  proc loadLib(path: string, global_symbols=false): LibHandle =
    raise newException(OSError, "loadLib not implemented on Nintendo Switch!")
  proc loadLib(): LibHandle =
    raise newException(OSError, "loadLib not implemented on Nintendo Switch!")
  proc unloadLib(lib: LibHandle) =
    raise newException(OSError, "unloadLib not implemented on Nintendo Switch!")
  proc symAddr(lib: LibHandle, name: cstring): pointer =
    raise newException(OSError, "symAddr not implemented on Nintendo Switch!")

elif defined(windows) or defined(dos):
  #
  # =======================================================================
  # 原生 Windows 实现
  # =======================================================================
  #
  type
    HMODULE {.importc: "HMODULE".} = pointer
    FARPROC  {.importc: "FARPROC".} = pointer

  proc FreeLibrary(lib: HMODULE) {.importc, header: "<windows.h>", stdcall.}
  proc winLoadLibrary(path: cstring): HMODULE {.
      importc: "LoadLibraryA", header: "<windows.h>", stdcall.}
  proc getProcAddress(lib: HMODULE, name: cstring): FARPROC {.
      importc: "GetProcAddress", header: "<windows.h>", stdcall.}

  proc loadLib(path: string, globalSymbols=false): LibHandle =
    result = cast[LibHandle](winLoadLibrary(path))
  proc loadLib(): LibHandle =
    result = cast[LibHandle](winLoadLibrary(nil))
  proc unloadLib(lib: LibHandle) = FreeLibrary(cast[HMODULE](lib))

  proc symAddr(lib: LibHandle, name: cstring): pointer =
    result = cast[pointer](getProcAddress(cast[HMODULE](lib), name))

else:
  {.error: "no implementation for dynlib".}
