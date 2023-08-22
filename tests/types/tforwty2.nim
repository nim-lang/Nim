# Test for a hard to fix internal error
# occurred in the SDL library

{.push dynlib: "SDL.dll", callconv: cdecl.}

type
  PSDL_semaphore = ptr TSDL_semaphore
  TSDL_semaphore {.final.} = object
    sem: pointer             #PSem_t;
    when not defined(USE_NAMED_SEMAPHORES):
      sem_data: int
    when defined(BROKEN_SEMGETVALUE):
      # This is a little hack for MacOS X -
      # It's not thread-safe, but it's better than nothing
      sem_value: cint

type
  PSDL_Sem = ptr TSDL_Sem
  TSDL_Sem = TSDL_Semaphore

proc SDL_CreateSemaphore(initial_value: int32): PSDL_Sem {.
  importc: "SDL_CreateSemaphore".}
