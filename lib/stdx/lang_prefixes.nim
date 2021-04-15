##[
Templates that can be used by a syntax highlighter to highlight a string
literal in a specified syntax.
]##

runnableExamples:
  when defined(c):
    {.emit: cLang"""
    #include <stdio.h>
    void fn(){} /* comment */
    """.}

  when defined(cpp):
    {.emit: cppLang"""
    #include <vector>
    typedef std::vector<int> VInt; // some comment
    """.}

  when false:
    # `asm """ ... """` would work too but the syntax highlighter can't
    # tell whether `asm` should highlight as assembly or js code, which can
    # cause catastrophic results, e.g. with """ var a = 1; """, which
    # messes up syntax highlight for the remainder of the file due to `;`
    # being a comment in asm.
    {.emit: asmLang"""
    mov eax, ecx ; comment
    mov ecx, edx
    xor edx, edx
    call `raiseOverflow` ; backtick syntax
    ret """.}

  when defined(js):
    {.emit: jsLang"""console.log(typeof(12n) == "bigint");""".}
  
  # this can be used outside of `emit`, e.g.:
  discard cLang"""
    #include <stdio.h>
    void fn(){}
    """

  # another example using defered emit:
  const jsMathTrunc = jsLang"""
if (!Math.trunc) {
  Math.trunc = function(v) {
    v = +v;
    if (!isFinite(v)) return v;
    return (v - v % 1) || (v < 0 ? -0 : v === 0 ? v : 0);
  };
}
"""
  when defined(js): {.emit: jsMathTrunc.}

#[
xxx support in compiler asm with a non-string-literal, e.g.:
  asm sLang"""console.log(typeof(12n) == "bigint");"""
  asm asmLang"""mov eax, ecx"""
  asm cppLang"""#include <stdio.h>"""
]#

template cLang*(a: string{lit}): string = a
template cppLang*(a: string{lit}): string = a
template jsLang*(a: string{lit}): string = a
template asmLang*(a: string{lit}): string = a
template pyLang*(a: string{lit}): string = a
# add more as needed
