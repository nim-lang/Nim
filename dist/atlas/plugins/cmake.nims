# Plugin for overly simplistic cmake integration

builder "CMakeLists.txt":
  mkDir "build"
  withDir "build":
    exec "cmake .."
    exec "cmake --build . --config Release"
