#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a zip archive creator/reader/modifier.

import 
  streams, libzip, times, os

type
  TZipArchive* = object of TObject ## represents a zip archive
    mode: TFileMode
    w: PZip


proc zipError(z: var TZipArchive) = 
  var e: ref EIO
  new(e)
  e.msg = $zip_strerror(z.w)
  raise e
  
proc open*(z: var TZipArchive, filename: string, mode: TFileMode = fmRead): bool =
  ## Opens a zip file for reading, writing or appending. All file modes are 
  ## supported. Returns true iff successful, false otherwise.
  var err, flags: int32
  case mode
  of fmRead, fmReadWriteExisting, fmAppend: flags = 0
  of fmWrite:                               
    if existsFile(filename): removeFile(filename)
    flags = ZIP_CREATE or ZIP_EXCL
  of fmReadWrite: flags = ZIP_CREATE
  z.w = zip_open(filename, flags, addr(err))
  z.mode = mode
  result = z.w != nil

proc close*(z: var TZipArchive) =
  ## Closes a zip file.
  zip_close(z.w)
 
proc createDir*(z: var TZipArchive, dir: string) = 
  ## Creates a directory within the `z` archive. This does not fail if the
  ## directory already exists. Note that for adding a file like 
  ## ``"path1/path2/filename"`` it is not necessary
  ## to create the ``"path/path2"`` subdirectories - it will be done 
  ## automatically by ``addFile``. 
  assert(z.mode != fmRead) 
  discard zip_add_dir(z.w, dir)
  zip_error_clear(z.w)

proc addFile*(z: var TZipArchive, dest, src: string) = 
  ## Adds the file `src` to the archive `z` with the name `dest`. `dest`
  ## may contain a path that will be created. 
  assert(z.mode != fmRead) 
  var zipsrc = zip_source_file(z.w, src, 0, -1)
  if zipsrc == nil:
    #echo("Dest: " & dest)
    #echo("Src: " & src)
    zipError(z)
  if zip_add(z.w, dest, zipsrc) < 0'i32:
    zip_source_free(zipsrc)
    zipError(z)

proc addFile*(z: var TZipArchive, file: string) = 
  ## A shortcut for ``addFile(z, file, file)``, i.e. the name of the source is
  ## the name of the destination.
  addFile(z, file, file)
  
proc mySourceCallback(state, data: pointer, len: int, 
                      cmd: Tzip_source_cmd): int {.cdecl.} = 
  var src = cast[PStream](state)
  case cmd
  of ZIP_SOURCE_OPEN: 
    if src.setPosition != nil: src.setPosition(src, 0) # reset
  of ZIP_SOURCE_READ:
    result = src.readData(src, data, len)
  of ZIP_SOURCE_CLOSE: src.close(src)
  of ZIP_SOURCE_STAT: 
    var stat = cast[PZipStat](data)
    zip_stat_init(stat)
    stat.size = high(int32)-1 # we don't know the size
    stat.mtime = getTime()
    result = sizeof(TZipStat)
  of ZIP_SOURCE_ERROR:
    var err = cast[ptr array[0..1, cint]](data)
    err[0] = ZIP_ER_INTERNAL
    err[1] = 0
    result = 2*sizeof(cint)
  of constZIP_SOURCE_FREE: GC_unref(src)
  else: assert(false)
  
proc addFile*(z: var TZipArchive, dest: string, src: PStream) = 
  ## Adds a file named with `dest` to the archive `z`. `dest`
  ## may contain a path. The file's content is read from the `src` stream.
  assert(z.mode != fmRead)
  GC_ref(src)
  var zipsrc = zip_source_function(z.w, mySourceCallback, cast[pointer](src))
  if zipsrc == nil: zipError(z)
  if zip_add(z.w, dest, zipsrc) < 0'i32:
    zip_source_free(zipsrc)
    zipError(z)
  
# -------------- zip file stream ---------------------------------------------

type
  TZipFileStream = object of TStream
    f: Pzip_file

  PZipFileStream* = 
    ref TZipFileStream ## a reader stream of a file within a zip archive 

proc fsClose(s: PZipFileStream) = zip_fclose(s.f)
proc fsReadData(s: PZipFileStream, buffer: pointer, bufLen: int): int = 
  result = zip_fread(s.f, buffer, bufLen)

proc newZipFileStream(f: PZipFile): PZipFileStream = 
  new(result)
  result.f = f
  result.close = fsClose
  result.readData = fsReadData
  # other methods are nil!

# ----------------------------------------------------------------------------
  
proc getStream*(z: var TZipArchive, filename: string): PZipFileStream = 
  ## returns a stream that can be used to read the file named `filename`
  ## from the archive `z`. Returns nil in case of an error.
  ## The returned stream does not support the `setPosition`, `getPosition`, 
  ## `writeData` or `atEnd` methods.
  var x = zip_fopen(z.w, filename, 0'i32)
  if x != nil: result = newZipFileStream(x)
  
iterator walkFiles*(z: var TZipArchive): string = 
  ## walks over all files in the archive `z` and returns the filename 
  ## (including the path).
  var i = 0
  var num = int(zip_get_num_files(z.w))
  while i < num:
    yield $zip_get_name(z.w, i, 0'i32)
    inc(i)
