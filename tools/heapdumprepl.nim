
include std/prelude
import intsets

type
  NodeKind = enum
    internal, local, localInvalid, global, globalInvalid
  Color = enum
    white, grey, black
  Node = ref object
    id, rc: int
    kids: seq[int]
    k: NodeKind
    col: Color
  Graph = object
    nodes: Table[int, Node]
    roots: Table[int, NodeKind]

proc add(father: Node; son: int) =
  if father.kids.isNil: father.kids = @[]
  father.kids.add(son)

proc renderNode(g: Graph; id: int) =
  let n = g.nodes[id]
  echo n[]

proc toNodeId(aliases: var Table[string,int]; s: string): int =
  result = aliases.getOrDefault(s)
  if result == 0:
    if s.startsWith("x"):
      discard s.parseHex(result, 1)
    else:
      result = s.parseInt

proc parseHex(s: string): int =
  discard parseutils.parseHex(s, result, 0)

proc reachable(g: Graph; stack: var seq[int]; goal: int): bool =
  var t = initIntSet()
  while stack.len > 0:
    let it = stack.pop
    if not t.containsOrIncl(it):
      if it == goal: return true
      if it in g.nodes:
        for kid in g.nodes[it].kids:
          stack.add(kid)

const Help = """
quit          -- quits this REPL
locals, l     -- output the list of local stack roots
globals, g    -- output the list of global roots
alias name addr -- give addr a name. start 'addr' with 'x' for hexadecimal
                   notation
print name|addr  -- print a node by name or address
reachable,r  l|g|node  dest   -- outputs TRUE or FALSE depending on whether
                    dest is reachable by (l)ocals, (g)lobals or by the
                    other given node. Nodes can be node names or node
                    addresses.
"""

proc repl(g: Graph) =
  var aliases = initTable[string,int]()
  while true:
    let line = stdin.readLine()
    let data = line.split()
    if data.len == 0: continue
    case data[0]
    of "quit":
      break
    of "help":
      echo Help
    of "locals", "l":
      for k,v in g.roots:
        if v == local: renderNode(g, k)
    of "globals", "g":
      for k,v in g.roots:
        if v == global: renderNode(g, k)
    of "alias", "a":
      # generate alias
      if data.len == 3:
        aliases[data[1]] = toNodeId(aliases, data[2])
    of "print", "p":
      if data.len == 2:
        renderNode(g, toNodeId(aliases, data[1]))
    of "reachable", "r":
      if data.len == 3:
        var stack: seq[int] = @[]
        case data[1]
        of "locals", "l":
          for k,v in g.roots:
            if v == local: stack.add k
        of "globals", "g":
          for k,v in g.roots:
            if v == global: stack.add k
        else:
          stack.add(toNodeId(aliases, data[1]))
        let goal = toNodeId(aliases, data[2])
        echo reachable(g, stack, goal)
    else: discard

proc importData(input: string): Graph =
  #c_fprintf(file, "%s %p %d rc=%ld color=%c\n",
  #          msg, c, kind, c.refcount shr rcShift, col)
  # cell  0x10a908190 22 rc=2 color=w
  var i: File
  var
    nodes = initTable[int, Node]()
    roots = initTable[int, NodeKind]()
  if open(i, input):
    var currNode: Node
    for line in lines(i):
      let data = line.split()
      if data.len == 0: continue
      case data[0]
      of "end":
        currNode = nil
      of "cell":
        let rc = parseInt(data[3].substr("rc=".len))
        let col = case data[4].substr("color=".len)
                  of "b": black
                  of "w": white
                  of "g": grey
                  else: (assert(false); grey)
        let id = parseHex(data[1])
        currNode = Node(id: id,
          k: roots.getOrDefault(id),
          rc: rc, col: col)
        nodes[currNode.id] = currNode
      of "child":
        assert currNode != nil
        currNode.add parseHex(data[1])
      of "global_root":
        roots[data[1].parseHex] = global
      of "global_root_invalid":
        roots[data[1].parseHex] = globalInvalid
      of "onstack":
        roots[data[1].parseHex] = local
      of "onstack_invalid":
        roots[data[1].parseHex] = localInvalid
      else: discard
    close(i)
  else:
    quit "error: cannot open " & input
  shallowCopy(result.nodes, nodes)
  shallowCopy(result.roots, roots)

if paramCount() == 1:
  repl(importData(paramStr(1)))
else:
  quit "usage: heapdumprepl inputfile"
