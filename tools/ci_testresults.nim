## Print summary of failed tests for CI

import os, json, sets, strformat

const skip = toHashSet(["reDisabled", "reIgnored", "reSuccess", "reJoined"])

proc showTestResults*(): string =
  result.add "showTestResults:\n"
  for fn in walkFiles("testresults/*.json"):
    let entries = fn.readFile().parseJson()
    for j in entries:
      let res = j["result"].getStr()
      if skip.contains(res):
        continue
      result.add fmt """
Category: {j["category"].getStr()}
Name: {j["name"].getStr()}
Action: {j["action"].getStr()}
Result: {res}
-------- Expected -------
{j["expected"].getStr()}
--------- Given  --------
{j["given"].getStr()}
-------------------------
""" & "\n"

when isMainModule:
  echo showTestResults()
