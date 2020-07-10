discard """
  valgrind: true
  cmd: "nim c --gc:arc -d:useMalloc $file"
"""

type
  ImportMaterial* = object
    # Adding a field here makes the problem go away.

  Mesh* = object
    vertices: seq[float32]
    material: ImportMaterial

  ImportedScene* = object
    meshes*: seq[Mesh]

proc bork() : ImportedScene =
  var mats: seq[ImportMaterial]

  setLen(mats, 1)
  add(result.meshes, Mesh(material: mats[0]))

var s = bork()
