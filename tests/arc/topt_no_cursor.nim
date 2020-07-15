discard """
  output: '''(repo: "", package: "meo", ext: "")'''
  cmd: '''nim c --gc:arc --expandArc:newTarget --hint:Performance:off $file'''
  nimout: '''--expandArc: newTarget

var
  splat
  :tmp
  :tmp_1
  :tmp_2
splat = splitFile(path)
:tmp = splat.dir
wasMoved(splat.dir)
:tmp_1 = splat.name
wasMoved(splat.name)
:tmp_2 = splat.ext
wasMoved(splat.ext)
result = (
  let blitTmp = :tmp
  blitTmp,
  let blitTmp_1 = :tmp_1
  blitTmp_1,
  let blitTmp_2 = :tmp_2
  blitTmp_2)
`=destroy`(splat)
-- end of expandArc ------------------------'''
"""

import os

type Target = tuple[repo, package, ext: string]

proc newTarget*(path: string): Target =
  let splat = path.splitFile
  result = (repo: splat.dir, package: splat.name, ext: splat.ext)

echo newTarget("meo")
