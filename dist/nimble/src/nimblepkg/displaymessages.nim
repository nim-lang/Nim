# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

## This module contains procedures producing some of the displayed by Nimble
## error messages in order to facilitate testing by removing the requirement
## the message to be repeated both in Nimble and the testing code.

import strformat, strutils
import version, packageinfotypes, sha1hashes

const
  validationFailedMsg* = "Validation failed."

  pathGivenButNoPkgsToDownloadMsg* =
    "Path option is given but there are no given packages for download."
  
  developOptionsWithoutDevelopFileMsg* =
    "Options 'add', 'remove', 'include' and 'exclude' cannot be given " &
    "when no develop file is specified."

  developWithDependenciesWithoutPackagesMsg* =
    "Option 'with-dependencies' is given without packages for develop."

  dependencyNotInRangeErrorHint* =
    "Update the version of the dependency package in its Nimble file or " &
    "update its required version range in the dependent's package Nimble file."

  notADependencyErrorHint* =
    "Add the dependency package as a requirement to the Nimble file of the " &
    "dependent package."

  multiplePathOptionsGivenMsg* = "Multiple path options are given."

  multipleDevelopFileOptionsGivenMsg* =
    "Multiple develop file options are given."

  ignoringCompilationFlagsMsg* =
    "Ignoring compilation flags for installed package."

  updatingTheLockFileMsg* = "Updating the lock file..."
  generatingTheLockFileMsg* = "Generating the lock file..."
  lockFileIsUpdatedMsg* = "The lock file is updated."
  lockFileIsGeneratedMsg* = "The lock file is generated."

proc fileAlreadyExistsMsg*(path: string): string =
  &"Cannot create file \"{path}\" because it already exists."

proc developFileSavedMsg*(path: string): string =
  &"The develop file \"{path}\" has been saved."

proc pkgSetupInDevModeMsg*(pkgName, pkgPath: string): string =
  &"\"{pkgName}\" set up in develop mode successfully to \"{pkgPath}\"."

proc pkgInstalledMsg*(pkgName: string): string =
  &"{pkgName} installed successfully."

proc pkgNotFoundMsg*(pkg: PkgTuple): string = &"Package {pkg} not found."

proc pkgDepsAlreadySatisfiedMsg*(dep: PkgTuple): string =
  &"Dependency on {dep} already satisfied"

proc invalidPkgMsg*(path: string): string =
  &"The package at \"{path}\" is invalid."

proc invalidDevFileMsg*(path: string): string =
  &"The develop file \"{path}\" is invalid."

proc notAValidDevFileJsonMsg*(devFilePath: string): string =
  &"The file \"{devFilePath}\" has not a valid develop file JSON schema."

proc pkgAlreadyPresentAtDifferentPathMsg*(
    pkgName, otherPath, fileName: string): string =
  &"A package with a name \"{pkgName}\" at different path \"{otherPath}\" " &
   "is already present in the develop file \"{fileName}\"."

proc pkgAddedInDevFileMsg*(pkg, path, fileName: string): string =
  &"The package \"{pkg}\" at path \"{path}\" is added to the develop file " &
  &"\"{fileName}\"."

proc pkgAlreadyInDevFileMsg*(pkg, path, fileName: string): string =
  &"The package \"{pkg}\" at path \"{path}\" is already present in the " &
  &"develop file \"{fileName}\"."

proc pkgRemovedFromDevFileMsg*(pkg, path, fileName: string): string =
  &"The package \"{pkg}\" at path \"{path}\" is removed from the develop " &
  &"file \"{fileName}\"."

proc pkgPathNotInDevFileMsg*(path, fileName: string): string =
  &"The path \"{path}\" is not in the develop file \"{fileName}\"."

proc pkgNameNotInDevFileMsg*(pkgName, fileName: string): string =
  &"A package with name \"{pkgName}\" is not in the develop file " &
  &"\"{fileName}\"."

proc failedToInclInDevFileMsg*(inclFile, devFile: string): string =
  &"Failed to include \"{inclFile}\" to the develop file \"{devFile}\""

proc inclInDevFileMsg*(path, fileName: string): string =
  &"The develop file \"{path}\" is successfully included into the develop " &
  &"file \"{fileName}\""

proc alreadyInclInDevFileMsg*(path, fileName: string): string =
  &"The develop file \"{path}\" is already included in the develop file " &
  &"\"{fileName}\"."

proc exclFromDevFileMsg*(path, fileName: string): string =
  &"The develop file \"{path}\" is successfully excluded from the develop " &
  &"file \"{fileName}\"."

proc notInclInDevFileMsg*(path, fileName: string): string =
  &"The file \"{path}\" is not included in the develop file \"{fileName}\"."

proc failedToLoadFileMsg*(path: string): string =
  &"Failed to load \"{path}\"."

proc cannotUninstallPkgMsg*(pkgName: string, pkgVersion: Version,
                            deps: seq[string]): string =
  assert deps.len > 0, "The sequence must have at least one package."
  result = &"Cannot uninstall {pkgName} ({pkgVersion}) because\n"
  result &= deps.join("\n")
  result &= "\ndepend" & (if deps.len == 1: "s" else: "") & " on it"

proc promptRemovePkgsMsg*(pkgs: seq[string]): string =
  assert pkgs.len > 0, "The sequence must have at least one package."
  result = "The following packages will be removed:\n"
  result &= pkgs.join("\n")
  result &= "\nDo you wish to continue?"

proc pkgWorkingCopyNeedsSyncingMsg*(pkgName, pkgPath: string): string =
  &"Package \"{pkgName}\" working copy at path \"{pkgPath}\" needs syncing."

proc pkgWorkingCopyIsSyncedMsg*(pkgName, pkgPath: string): string =
  &"Working copy of package  \"{pkgName}\" at \"{pkgPath}\" is synced."

proc notInRequiredRangeMsg*(
    dependencyPkgName, dependencyPkgPath, dependencyPkgVersion,
    dependentPkgName, dependentPkgPath, requiredVersionRange: string): string =
  &"The version of the package \"{dependencyPkgName}\" at " &
  &"\"{dependencyPkgPath}\" is \"{dependencyPkgVersion}\" and it does not " &
  &"match the required by the package \"{dependentPkgName}\" at " &
  &"\"{dependentPkgPath}\" version \"{requiredVersionRange}\"."
  
proc invalidDevelopDependenciesVersionsMsg*(errors: seq[string]): string =
  result = "Some of the develop mode dependencies are with versions which " &
           "are not in the required by other package's Nimble file range."
  for error in errors:
    result &= "\n"
    result &= error

proc pkgAlreadyExistsInTheCacheMsg*(name, version, checksum: string): string =
  &"A package \"{name}@{version}\" with checksum \"{checksum}\" already " &
   "exists the the cache."

proc pkgAlreadyExistsInTheCacheMsg*(pkgInfo: PackageInfo): string =
  pkgAlreadyExistsInTheCacheMsg(
     pkgInfo.basicInfo.name,
    $pkgInfo.basicInfo.version,
    $pkgInfo.basicInfo.checksum)

proc skipDownloadingInAlreadyExistingDirectoryMsg*(dir, name: string): string =
  &"The download directory \"{dir}\" already exists.\n" &
  &"Skipping the download of \"{name}\"."

proc binaryNotDefinedInPkgMsg*(binaryName, pkgName: string): string =
  &"Binary '{binaryName}' is not defined in '{pkgName}' package."

proc notFoundPkgWithNameInPkgDepTree*(pkgName: string): string =
  &"Not found package with name '{pkgName}' in the current package's " &
   "dependency tree."

proc pkgLinkFileSavedMsg*(path: string): string =
  &"Package link file \"{path}\" is saved."
