# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

import json, os, strformat
import common, options, jsonhelpers, version, cli

type
  NimbleDataJsonKeys* = enum
    ndjkVersion = "version"
    ndjkRevDep = "reverseDeps"
    ndjkRevDepName = "name"
    ndjkRevDepVersion = "version"
    ndjkRevDepChecksum = "checksum"
    ndjkRevDepPath = "path"

const
  nimbleDataFileName* = "nimbledata2.json"
  nimbleDataFileVersion = 1

var isNimbleDataFileLoaded = false

proc saveNimbleData(filePath: string, nimbleData: JsonNode) =
  # TODO: This file should probably be locked.
  if isNimbleDataFileLoaded:
    writeFile(filePath, nimbleData.pretty)
    displayInfo(&"Nimble data file \"{filePath}\" has been saved.", LowPriority)

proc saveNimbleDataToDir(nimbleDir: string, nimbleData: JsonNode) =
  saveNimbleData(nimbleDir / nimbleDataFileName, nimbleData)

proc saveNimbleData*(options: Options) =
  saveNimbleDataToDir(options.getNimbleDir(), options.nimbleData)

proc newNimbleDataNode*(): JsonNode =
  %{ $ndjkVersion: %nimbleDataFileVersion, $ndjkRevDep: newJObject() }

proc removeDeadDevelopReverseDeps*(options: var Options) =
  template revDeps: var JsonNode = options.nimbleData[$ndjkRevDep]
  var hasDeleted = false
  for name, versions in revDeps:
    for version, hashSums in versions:
      for hashSum, dependencies in hashSums:
        for dep in dependencies:
          if dep.hasKey($ndjkRevDepPath) and
             not dep[$ndjkRevDepPath].str.dirExists:
            dep.delete($ndjkRevDepPath)
            hasDeleted = true
  if hasDeleted:
    options.nimbleData[$ndjkRevDep] = cleanUpEmptyObjects(revDeps)

proc loadNimbleData*(options: var Options) =
  let
    nimbleDir = options.getNimbleDir()
    fileName = nimbleDir / nimbleDataFileName

  if fileExists(fileName):
    options.nimbleData = parseFile(fileName)
    removeDeadDevelopReverseDeps(options)
    displayInfo(&"Nimble data file \"{fileName}\" has been loaded.",
                LowPriority)
  else:
    displayWarning(&"Nimble data file \"{fileName}\" is not found.",
                   LowPriority)
    options.nimbleData = newNimbleDataNode()

  isNimbleDataFileLoaded = true
