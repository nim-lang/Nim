iterator pragmaHint*[S, T](a: S, b: T, annotation: static string): T {.
  inline, magic: "OmpParFor", sideEffect.} =
  ## Generates `#pragma annotation` codes to optimize for loop.
  ## 
  ## For example `pragmaHint(a, b, "unroll 99")` will generate
  ## C codes like below
  ## 
  ## .. code-block:: c
  ##   #pragma unroll 99
  ##   for (i = a; i <= b; ++i) {  };
  discard

template unroll*(a, b: SomeInteger; factor: static Natural): untyped =
  ## Compile-time unrolled for loop iterator.
  ##
  ## * If `factor` is 0 or 1, unrolling is disabled (ignored).
  ## * If `factor` is more than `1`, unrolling is enabled.
  ## * If `factor` is bigger than the total loop iterations,
  ##   no error is produced and the loop is completely unrolled.
  ##
  ## Example:
  ##
  ## .. code-block:: Nim
  ##   for i in unroll(0, 99, 99): discard
  ##
  ## Compiles to approximately:
  ##
  ## .. code-block:: c
  ##   #pragma unroll 99
  ##   for (i = 0; i <= 99; ++i) {  };
  ##
  ## Nim emits `#pragma unroll` delegating the for loop unrolling to C, see also:
  ## * https://en.wikipedia.org/wiki/Loop_unrolling
  ## * http://gcc.gnu.org/onlinedocs/gcc/Loop-Specific-Pragmas.html#index-pragma-GCC-unroll-n
  ## * http://clang.llvm.org/docs/AttributeReference.html#pragma-unroll-pragma-nounroll
  ## * https://software.intel.com/content/www/us/en/develop/documentation/cpp-compiler-developer-guide-and-reference/top/compiler-reference/pragmas/intel-specific-pragma-reference/unroll-nounroll.html
  ## * Only GCC, ICC and Clang are supported, otherwise a normal `..` iterator is used.
  runnableExamples:
    if false:
      for i in unroll(-9, 9, 5):
        echo i ## Check the generated C or Assembly.

  when not defined(js):
    when defined(gcc):
      pragmaHint(a, b, "GCC unroll " & $factor)
    elif defined(clang) or defined(icc):
      pragmaHint(a, b, "unroll " & $factor)
    else:
      system.`..`(a, b)
  else:
    system.`..`(a, b)
