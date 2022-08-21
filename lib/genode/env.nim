#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#
# This file contains the minimum required definitions
# for interacting with the initial Genode environment.
# It is reserved for use only within the standard
# library. See `componentConstructHook` in the system
# module for accessing the Genode environment after the
# standard library has finished initializating.
#

when not defined(genode):
  {.error: "Genode only include".}

type
  GenodeEnvObj {.importcpp: "Genode::Env", header: "<base/env.h>", pure.} = object
  GenodeEnvPtr = ptr GenodeEnvObj

const runtimeEnvSym = "nim_runtime_env"

when not defined(nimscript):
  var runtimeEnv {.importcpp: runtimeEnvSym.}: GenodeEnvPtr
