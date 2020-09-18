discard """
  output: '''BEGIN
END
END 2
cpu.nes false
cpu step nes is nil? - false
0'''
  cmd: '''nim c --gc:orc $file'''
"""

# extracted from thavlak.nim

type
  BasicBlock = ref object
    inEdges: seq[BasicBlock]
    outEdges: seq[BasicBlock]
    name: int

proc newBasicBlock(name: int): BasicBlock =
  result = BasicBlock(
    inEdges: newSeq[BasicBlock](),
    outEdges: newSeq[BasicBlock](),
    name: name
  )

type
  Cfg = object
    basicBlockMap: seq[BasicBlock]
    startNode: BasicBlock

proc newCfg(): Cfg =
  result = Cfg(
    basicBlockMap: newSeq[BasicBlock](),
    startNode: nil)

proc createNode(cfg: var Cfg, name: int): BasicBlock =
  if name < cfg.basicBlockMap.len:
    result = cfg.basicBlockMap[name]
  else:
    result = newBasicBlock(name)
    cfg.basicBlockMap.setLen name+1
    cfg.basicBlockMap[name] = result

proc newBasicBlockEdge(cfg: var Cfg, fromName, toName: int) =
  echo "BEGIN"
  let fr = cfg.createNode(fromName)
  let to = cfg.createNode(toName)

  fr.outEdges.add(to)
  to.inEdges.add(fr)

proc run(cfg: var Cfg) =
  cfg.startNode = cfg.createNode(0) # RC = 2
  newBasicBlockEdge(cfg, 0, 1) #
  echo "END"

  discard cfg.createNode(1)

proc main =
  var c = newCfg()
  c.run
  echo "END 2"

# bug #14159
type
  NES = ref object
    cpu: CPU
    apu: APU

  CPU = ref object
    nes: NES

  APU = object
    nes: NES
    cpu: CPU

proc initAPU(nes: sink NES): APU {.nosinks.} =
  result.nes = nes
  result.cpu = nes.cpu

proc step(cpu: CPU): int =
  echo "cpu.nes ", cpu.isNil
  echo "cpu step nes is nil? - ", cpu.nes.isNil()

proc newNES(): NES =
  new result
  result.cpu = CPU(nes: result)
  result.apu = initAPU(result)

proc bug14159 =
  var nesConsole = newNES()
  discard nesConsole.cpu.step()

let mem = getOccupiedMem()
main()
bug14159()
GC_fullCollect()
echo getOccupiedMem() - mem
