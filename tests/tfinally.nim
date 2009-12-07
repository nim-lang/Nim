# Test return in try statement:

proc main: int = 
  try:
    return 1
  finally: 
    echo "came here"
    
echo main()

