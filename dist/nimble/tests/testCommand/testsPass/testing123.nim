
proc myFunc*() =
  when defined(CUSTOM):
    echo "Executing my func"
  else:
    echo "Missing -d:CUSTOM"

