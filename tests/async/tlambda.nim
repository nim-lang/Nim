
# bug 2007

import asyncdispatch, asyncnet, logging, json, uri, strutils, sugar

type
  Builder = ref object
    client: Client
    build: Build

  ProgressCB* = proc (message: string): Future[void] {.closure, gcsafe.}

  Build* = ref object
    onProgress*: ProgressCB

  Client = ref ClientObj
  ClientObj = object
    onMessage: proc (client: Client, msg: JsonNode): Future[void]

proc newClient*(name: string,
                onMessage: (Client, JsonNode) -> Future[void]): Client =
  new result
  result.onMessage = onMessage

proc newBuild*(onProgress: ProgressCB): Build =
  new result
  result.onProgress = onProgress

proc start(build: Build, repo, hash: string) {.async.} =
  let path = repo.parseUri().path.toLowerAscii()

proc onProgress(builder: Builder, message: string) {.async.} =
  debug($message)

proc onMessage(builder: Builder, message: JsonNode) {.async.} =
  debug("onMessage")

proc newBuilder(): Builder =
  var cres: Builder
  new cres

  cres.client = newClient("builder", (client, msg) => (onMessage(cres, msg)))
  cres.build = newBuild(
      proc (msg: string): Future[void] {.closure, gcsafe.} = onProgress(cres, msg))
  return cres

proc main() =
  # Set up logging.
  var console = newConsoleLogger(fmtStr = verboseFmtStr)
  addHandler(console)

  var builder = newBuilder()

  # Test {.async.} pragma with do notation: #5995
  builder.client = newClient("builder") do(client: Client, msg: JsonNode) {.async.}:
    await onMessage(builder, msg)

main()
