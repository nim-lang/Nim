#
#
#              The Nim Tester
#        (c) Copyright 2019 Leorize
#
#    Look at license.txt for more info.
#    All rights reserved.

import base64, json, httpclient, os, strutils, uri
import specs

const
  RunIdEnv = "TESTAMENT_AZURE_RUN_ID"
  CacheSize = 8 # How many results should be cached before uploading to
                # Azure Pipelines. This prevents throttling that might arise.

proc getAzureEnv(env: string): string =
  # Conversion rule at:
  # https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables#set-variables-in-pipeline
  env.toUpperAscii().replace('.', '_').getEnv

template getRun(): string =
  ## Get the test run attached to this instance
  getEnv(RunIdEnv)

template setRun(id: string) =
  ## Attach a test run to this instance and its future children
  putEnv(RunIdEnv, id)

template delRun() =
  ## Unattach the test run associtated with this instance and its future children
  delEnv(RunIdEnv)

template warning(args: varargs[untyped]) =
  ## Add a warning to the current task
  stderr.writeLine "##vso[task.logissue type=warning;]", args

let
  ownRun = not existsEnv RunIdEnv
    ## Whether the test run is owned by this instance
  accessToken = getAzureEnv("System.AccessToken")
    ## Access token to Azure Pipelines

var
  active = false ## Whether the backend should be activated
  requestBase: Uri ## Base URI for all API requests
  requestHeaders: HttpHeaders ## Headers required for all API requests
  results: JsonNode ## A cache for test results before uploading

proc request(api: string, httpMethod: HttpMethod, body = ""): Response {.inline.} =
  let client = newHttpClient(timeout = 3000)
  defer: close client
  result = client.request($(requestBase / api), httpMethod, body, requestHeaders)
  if result.code != Http200:
    raise newException(CatchableError, "Request failed")

proc init*() =
  ## Initialize the Azure Pipelines backend.
  ##
  ## If an access token is provided and no test run is associated with the
  ## current instance, this proc will create a test run named after the current
  ## Azure Pipelines' job name, then associate it to the current testament
  ## instance and its future children. Should this fail, the backend will be
  ## disabled.
  if isAzure and accessToken.len > 0:
    active = true
    requestBase = parseUri(getAzureEnv("System.TeamFoundationCollectionUri")) /
      getAzureEnv("System.TeamProjectId") / "_apis" ? {"api-version": "5.0"}
    requestHeaders = newHttpHeaders {
      "Accept": "application/json",
      "Authorization": "Basic " & encode(':' & accessToken),
      "Content-Type": "application/json"
    }
    results = newJArray()
    if ownRun:
      try:
        let resp = request(
          "test/runs",
          HttpPost,
          $ %* {
            "automated": true,
            "build": { "id": getAzureEnv("Build.BuildId") },
            "buildPlatform": hostCPU,
            "controller": "nim-testament",
            "name": getAzureEnv("Agent.JobName")
          }
        )
        setRun $resp.body.parseJson["id"].getInt
      except:
        warning "Couldn't create test run for Azure Pipelines integration"
        # Set run id to empty to prevent child processes from trying to request
        # for yet another test run id, which wouldn't be shared with other
        # instances.
        setRun ""
        active = false
    elif getRun().len == 0:
      # Disable integration if there aren't any valid test run id
      active = false

proc uploadAndClear() =
  ## Upload test results from cache to Azure Pipelines. Then clear the cache
  ## after.
  if results.len > 0:
    try:
      discard request("test/runs/" & getRun() & "/results", HttpPost, $results)
    except:
      for i in results:
        warning "Couldn't log test result to Azure Pipelines: ",
          i["automatedTestName"], ", outcome: ", i["outcome"]
    results = newJArray()

proc finalize*() {.noconv.} =
  ## Finalize the Azure Pipelines backend.
  ##
  ## If a test run has been associated and is owned by this instance, it will
  ## be marked as complete.
  if active:
    if ownRun:
      uploadAndClear()
      try:
        discard request("test/runs/" & getRun(), HttpPatch,
                        $ %* {"state": "Completed"})
      except:
        warning "Couldn't update test run ", getRun(), " on Azure Pipelines"
      delRun()

proc addTestResult*(name, category: string; durationInMs: int; errorMsg: string;
                    outcome: TResultEnum) =
  if not active:
    return

  let outcome = case outcome
                of reSuccess: "Passed"
                of reDisabled, reJoined: "NotExecuted"
                else: "Failed"

  results.add(%* {
      "automatedTestName": name,
      "automatedTestStorage": category,
      "durationInMs": durationInMs,
      "errorMessage": errorMsg,
      "outcome": outcome,
      "testCaseTitle": name
  })

  if results.len > CacheSize:
    uploadAndClear()
