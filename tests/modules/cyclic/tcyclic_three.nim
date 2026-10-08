discard """
  joinable: false
  matrix: "--experimental:cyclicImports"
  output: '''
3
x
'''
"""

# the group is entered via a module that is not part of it:
import mcyclic_three1, mcyclic_three2, mcyclic_three3

echo countNodes(Node1(next: Node2(next: Node3())))
echo Gen[string](val: Node3(name: "x")).val.name
