discard """
  joinable: false
  output: '''
d
b
c
a
'''
"""

# The remaining statements of the modules of a group run in the order an
# ordinary recursive import would check them: depth first, a module after
# the modules it imports.
import order/morder_b {.cyclic.}, order/morder_c {.cyclic.}
echo "a"
