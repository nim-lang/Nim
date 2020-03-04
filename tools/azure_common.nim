import strutils, os

proc getAzureEnv*(env: string): string =
  # Conversion rule at:
  # https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables#set-variables-in-pipeline
  # Predefined variables:
  # https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml
  env.toUpperAscii().replace('.', '_').getEnv

proc isAzureCI*(): bool =
  existsEnv("TF_BUILD")
