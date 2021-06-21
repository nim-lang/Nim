discard """
  disabled: "true"
  output: '''
main: HELLO!
main: hasAnyModuleChanged? true
main: before
   0: after
main: after
              The answer is: 1000
main: hasAnyModuleChanged? false
              The answer is: 1000
main: hasAnyModuleChanged? true
   0: before
main: before
   1: print me once!
   1: 1
   1: 2
   1: 3
   1: 4
   1: 5
   1: 5
   1: 5
   1: Type1.a:42
1
bar
   0: after - improved!
main: after
              The answer is: 110
main: hasAnyModuleChanged? true
   0: before - improved!
main: before
   2: random string
max mutual recursion reached!
1
bar
   0: after - closure iterator: 0
   0: after - closure iterator: 1
   0: after - c_2 = [1, 2, 3]
main: after
              The answer is: 9
main: hasAnyModuleChanged? true
   2: before!
main: before
   2: after!
   0: after - closure iterator! after reload! does it remember? :2
   0: after - closure iterator! after reload! does it remember? :3
main: after
              The answer is: 1000
main: hasAnyModuleChanged? true
main: before
main: after
              The answer is: 42
done
'''
"""

#[
xxx disabled: "openbsd" because it would otherwise give:
/home/build/Nim/lib/nimhcr.nim(532) hcrInit
/home/build/Nim/lib/nimhcr.nim(503) initModules
/home/build/Nim/lib/nimhcr.nim(463) initPointerData
/home/build/Nim/lib/nimhcr.nim(346) hcrRegisterProc
/home/build/Nim/lib/pure/reservedmem.nim(223) setLen
/home/build/Nim/lib/pure/reservedmem.nim(97) setLen
/home/build/Nim/lib/pure/includes/oserr.nim(94) raiseOSError
Error: unhandled exception: Not supported [OSError]

After instrumenting code, the stacktrace actually points to the call to `check mprotect`
]#

## This is perhaps the most complex test in the nim test suite - calling the
## compiler on the file itself with the same set or arguments and reloading
## parts of the program at runtime! In the same folder there are a few modules
## with names such as `nimhcr_<number>.nim`. Each of them has a few versions which
## are in the format of `nimhcr_<number>_<version>.nim`. The below code uses the
## `update` proc to say which of the modules should bump its version (and that
## is done by copying `nimhcr_<number>_<version>.nim` onto `nimhcr_<number>.nim`).
## The files should refer to each other (when importing) without the versions.
## A few files can be updated by calling `update` for each of their indexes
## and after that with a single call to `compileReloadExecute` the new version
## of the program will be compiled, reloaded, and the only thing the main module
## calls from `nimhcr_0.nim` (the procedure `getInt` proc) is called for a result.
##
## This test is expected to be executed with arguments - the full nim compiler
## command used for building it - so it can rebuild iself the same way - example:
##
## compiling:
##                   nim c --hotCodeReloading:on --nimCache:<folder> <this_file>.nim
## executing:
##   <this_file>.exe nim c --hotCodeReloading:on --nimCache:<folder> <this_file>.nim

import os, osproc, strutils, hotcodereloading

import nimhcr_0 # getInt() - the only thing we continually call from the main module

proc compileReloadExecute() =
  # Remove the `--forceBuild` option - is there in the first place because:
  # - when `koch test` is ran for the first time the nimcache is empty
  # - when each of the variants are built (debug, release after that, different GCs)
  #   the main executable that gets built into the appropriate nimcache folder
  #   gets copied to the originally intended destination and is executed
  #   (this behaviour is only when the --hotCodeReloading option is used).
  # - when `koch test` is ran again and the nimcache is full the executable files
  #   in the nimcache folder aren't relinked and therefore aren't copied to the
  #   originally intended destination - so when the binary at the intended
  #   destination is executed - it is actually a remnant from a previous execution.
  #   That is a problem because it points to shared objects to load from its own
  #   nimcache folder - the one used for building it - a previous run! And when
  #   this test changes other modules it references but the main module (this file)
  #   remains intact - the binary isn't replaced. `--forceBuild` fixes this but has
  #   to be applied only for the main build - the one done from koch, but when this
  #   binary triggers rebuilding itself here it shouldn't rebuild the main module -
  #   that would lead to replacing the main binary executable which is running!
  let cmd = commandLineParams()[0..^1].join(" ").replace(" --forceBuild")
  doAssert cmd.len > 0
  let (stdout, exitcode) = execCmdEx(cmd)
  if exitcode != 0:
    echo "COMPILATION ERROR!"
    echo "COMMAND: ", cmd
    echo "STDOUT: ", stdout
    quit 1
  echo "main: hasAnyModuleChanged? ", hasAnyModuleChanged()
  performCodeReload()
  echo "              The answer is: ", getInt()

# there are 3 files and all of them start from their 1st version
var vers = [1, 1, 1]
proc update(file: int) =
  proc getfile(mid: string): string =
    let (path, _, _) = splitFile(currentSourcePath())
    return path & "/nimhcr_" & mid & ".nim"
  copyFile(getfile($file & "_" & $vers[file]), getfile($file))
  inc vers[file]

beforeCodeReload:
  echo "main: before"

afterCodeReload:
  echo "main: after"

echo "main: HELLO!"

update 0
compileReloadExecute() # versions are: 1 - -

compileReloadExecute() # no change

update 0
update 1
compileReloadExecute() # versions are: 2 1 -

update 0
update 2
compileReloadExecute() # versions are: 3 1 1

update 0
update 1
update 2
compileReloadExecute() # versions are: 4 2 2

update 0
compileReloadExecute() # versions are: 5 2 2

# final update so there are no git modifications left after everything
# (the last versions are like the first files without a version suffix)
update 0
update 1
update 2

echo "done"