
include std/prelude

proc main(input, output: string) =
  type NodeKind = enum
    local, localInvalid, global, globalInvalid
  #c_fprintf(file, "%s %p %d rc=%ld color=%c\n",
  #          msg, c, kind, c.refcount shr rcShift, col)
  # cell  0x10a908190 22 rc=2 color=w
  var i, o: File
  var roots = initTable[string, NodeKind]()
  if open(i, input):
    if open(o, output, fmWrite):
      o.writeLine("digraph $1 {\n" % extractFilename(input))
      var currNode = ""
      for line in lines(i):
        let data = line.split()
        if data.len == 0: continue
        case data[0]
        of "end":
          currNode = ""
        of "cell":
          currNode = data[1]
          let rc = data[3].substr("rc=".len)
          let col = case data[4].substr("color=".len)
                    of "b": "black"
                    of "w": "green"
                    of "g": "grey"
                    else: ""
          o.write("N" & currNode)
          if currNode in roots:
            let v = roots[currNode]
            case v
            of local: o.write(" [label=\"local \\N\" fillcolor=$1]" % col)
            of localInvalid: o.write(" [label=\"local invalid \\N\" fillcolor=$1]" % col)
            of global: o.write(" [label=\"global \\N\" fillcolor=$1]" % col)
            of globalInvalid: o.write(" [label=\"global invalid \\N\" fillcolor=$1]" % col)
          else:
            o.write(" [fillcolor=$1]" % col)
          o.writeLine(";")
        of "child":
          assert currNode.len > 0
          o.writeLine("N$1 -> N$2;" % [currNode, data[1]])
        of "global_root":
          roots[data[1]] = global
        of "global_root_invalid":
          roots[data[1]] = globalInvalid
        of "onstack":
          roots[data[1]] = local
        of "onstack_invalid":
          roots[data[1]] = localInvalid
        else: discard
      close(i)
      o.writeLine("\n}")
      close(o)
    else:
      quit "error: cannot open " & output
  else:
    quit "error: cannot open " & input

if paramCount() == 1:
  main(paramStr(1), changeFileExt(paramStr(1), "dot"))
elif paramCount() == 2:
  main(paramStr(1), paramStr(2))
else:
  quit "usage: heapdump2dot inputfile outputfile"
