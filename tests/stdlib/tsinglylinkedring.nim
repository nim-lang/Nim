discard """
  output: '''[5]
[4, 5]
[3, 4, 5]
[2, 3, 4, 5]
[2, 3, 4, 5, 6]
[2, 3, 4, 5, 6, 7]
[2, 3, 4, 5, 6, 7, 8]
[1, 2, 3, 4, 5, 6, 7, 8]'''
"""
import lists

var r = initSinglyLinkedRing[int]()
r.prepend(5)
echo r
r.prepend(4)
echo r
r.prepend(3)
echo r
r.prepend(2)
echo r
r.append(6)
echo r
r.append(7)
echo r
r.append(8)
echo r
r.prepend(1)
echo r
