# Handle small allocations efficiently
# We allocate and manage memory by pages. All objects within a page belong to
# the same type. Thus, we safe the type field. Minimum requested block is
# 8 bytes. Alignment is 8 bytes. 


type
  TChunk {.pure.} = object
    kind: TChunkKind
    prev, next: ptr TChunk
    
  TSmallChunk = object of TChunk # all objects of the same size
    typ: PNimType
    free: int
    data: array [0.., int]
  
proc allocSmall(typ: PNimType): pointer =
  
  