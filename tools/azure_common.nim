import strutils, os

proc getAzureEnv*(env: string): string =
  # Conversion rule at:
  # https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables#set-variables-in-pipeline
  env.toUpperAscii().replace('.', '_').getEnv

