discard """
  output: '''done'''
"""
# Issue #21252: Compiler SIGSEGV when not instantiating generic proc correctly
# https://github.com/nim-lang/Nim/issues/21252

type
  Addr = object
    layerIdx: int

type Msg0 = object
  address: Addr
  selSample: tuple[inArrays: seq[seq[float64]], target: seq[float64], gradientStrength: float64]

type WeightUpdate = object
  address: Addr

proc workerThread[
  layer0StimulusWidth: static int
  ]() =
  discard

proc z*[
  layer0StimulusWidth: static int,
  nUnitsPerLayer: static seq[int],
  targetLen: static int
  ]() =
  workerThread[layer0StimulusWidth]()

when isMainModule:
  const layer0StimulusWidth: int = 5*29
  const nUnitsPerLayer: seq[int] = @[50, 5]
  const targetLen: int = 5
  z[layer0StimulusWidth, nUnitsPerLayer, targetLen]()
  echo "done"
