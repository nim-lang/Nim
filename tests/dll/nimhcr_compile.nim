discard """
  output: '''
41
101
21
102
'''
"""

# bug #13367: with hot code reloading, each module becomes its own library.
# The object of a file from `{.compile.}` must be linked into the libraries
# that call its functions, here the one of nimhcr_compile_a and the main
# program, and an imported C function must be called directly, not through a
# pointer that the runtime never sets.

import nimhcr_compile_a

echo answer()
echo headerAnswer()
echo nimhcrCompileAnswer(10)
echo nimhcrCompileHeader(2)
