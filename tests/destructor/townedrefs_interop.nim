discard """
  matrix: "--mm:arc; --mm:orc"
  output: '''
changed
3
2 1
'''
"""

# A module without `--experimental:ownedRefs` can still build values whose
# types use `owned`: fresh values may initialize an owned location.
import mownedrefs_types

proc main =
  var head = Node(data: 1)
  head.next = Node(data: 2)
  head.next.next = new(Node)
  head.onChange = proc () = echo "changed"
  head.onChange()
  echo len(head)
  let x: Node = head.next   # owned -> unowned
  head.next = nil
  echo x.data, " ", len(head)

main()
