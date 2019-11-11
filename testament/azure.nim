#
#
#              The Nim Tester
#        (c) Copyright 2019 Leorize
#
#    Look at license.txt for more info.
#    All rights reserved.

import base64, json, httpclient, os, strutils
import specs

const
  ApiRuns = "/_apis/test/runs"
  ApiVersion = "?api-version=5.0"
  ApiResults = ApiRuns & "/$1/results"

var runId* = -1

proc getAzureEnv(env: string): string =
  # Conversion rule at:
  # https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables#set-variables-in-pipeline
  env.toUpperAscii().replace('.', '_').getEnv

proc invokeRest(httpMethod: HttpMethod; api: string; body = ""): Response =
  let http = newHttpClient()
  defer: close http
  result = http.request(getAzureEnv("System.TeamFoundationCollectionUri") &
                        getAzureEnv("System.TeamProjectId") & api & ApiVersion,
                        httpMethod,
                        $body,
                        newHttpHeaders {
                          "Accept": "application/json",
                          "Authorization": "Basic " & encode(':' & getAzureEnv("System.AccessToken")),
                          "Content-Type": "application/json"
                        })
  if not result.code.is2xx:
    raise newException(HttpRequestError, "Server returned: " & result.body)

proc finish*() {.noconv.} =
  if not isAzure or runId < 0:
    return

  try:
    discard invokeRest(HttpPatch,
                       ApiRuns & "/" & $runId,
                       $ %* { "state": "Completed" })
  except:
    stderr.writeLine "##vso[task.logissue type=warning;]Unable to finalize Azure backend"
    stderr.writeLine getCurrentExceptionMsg()

  runId = -1

# TODO: Only obtain a run id if tests are run
# NOTE: We can't delete test runs with Azure's access token
proc start*() =
  if not isAzure:
    return
  try:
    if runId < 0:
      runId = invokeRest(HttpPost,
                         ApiRuns,
                         $ %* {
                           "automated": true,
                           "build": { "id": getAzureEnv("Build.BuildId") },
                           "buildPlatform": hostCPU,
                           "controller": "nim-testament",
                           "name": getAzureEnv("Agent.JobName")
                         }).body.parseJson["id"].getInt(-1)
  except:
    stderr.writeLine "##vso[task.logissue type=warning;]Unable to initialize Azure backend"
    stderr.writeLine getCurrentExceptionMsg()

proc addTestResult*(name, category: string; durationInMs: int; errorMsg: string;
                    outcome: TResultEnum) =
  if not isAzure or runId < 0:
    return
  let outcome = case outcome
                of reSuccess: "Passed"
                of reDisabled, reJoined: "NotExecuted"
                else: "Failed"
  try:
    discard invokeRest(HttpPost,
                       ApiResults % [$runId],
                       $ %* [{
                         "automatedTestName": name,
                         "automatedTestStorage": category,
                         "durationInMs": durationInMs,
                         "errorMessage": errorMsg,
                         "outcome": outcome,
                         "testCaseTitle": name
                       }])
  except:
    stderr.writeLine "##vso[task.logissue type=warning;]Unable to log test case: ",
                     name, ", outcome: ", outcome
    stderr.writeLine getCurrentExceptionMsg()
