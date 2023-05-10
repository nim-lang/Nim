## Test `nimscript.patchFile` error conditions
## ===========================================

discard """
  joinable: false # because it incorporates a config and file resolution
  matrix: "--errormax:2" # for the 2 errors below
  action: reject # because this is a test of the 2 errors below
  nimout: '''
mpatchFile_imports_patch_target.nim(2, 11) Error: module 'mpatchFile_imports_patch_target' cannot import itself
mpatchFile_includes_patch_target.nim(2, 1) Error: recursive dependency: 'mpatchFile_includes_patch_target.nim'
'''
  file: mpatchFile_includes_patch_target.nim # FIXME: This line is here because
    # Testament requires the last error's source filename match the test filename.
    # That doesn't work well in a scenario like this test.
"""

import std/oids ##\
  ## This import causes the patch (`mpatchFile_imports_patch_target`) configured
  ## in NimScript file `tpatchFile_errors.nims` to be compiled. However, the
  ## patch tries to import `std/oids` and that leads to the error message:
  ##   module 'mpatchFile_imports_patch_target' cannot import itself

import std/net ##\
  ## This import causes the patch (`mpatchFile_includes_patch_target`) configured
  ## in NimScript file `tpatchFile_errors.nims` to be compiled. However, the
  ## patch tries to include `std/net` and that leads to the error message:
  ##   recursive dependency: 'mpatchFile_includes_patch_target.nim'
