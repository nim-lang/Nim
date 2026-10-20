===================================
      Hot code reloading
===================================

.. default-role:: code
.. include:: rstcommon.rst

The `hotCodeReloading`:idx: option enables special compilation mode where
changes in the code can be applied automatically to a running program.
The code reloading happens at the granularity of an individual module.
When a module is reloaded, any newly added global variables will be
initialized, but all other top-level code appearing in the module won't
be re-executed and the state of all existing global variables will be
preserved.
A thread-local variable (`{.threadvar.}`) is preserved in the same way,
with one value for each thread: its storage belongs to the HCR runtime and
not to the library of its module, and any module can read and write it.


Basic workflow
==============

Currently, hot code reloading does not work for the main module itself,
so we have to use a helper module where the major logic we want to change
during development resides.

In this example, we use SDL2 to create a window and we reload the logic
code when `F9` is pressed. The important lines are marked with `#***`.
To install SDL2 you can use `nimble install sdl2`:cmd:.


  ```nim
  # logic.nim
  import sdl2

  #*** import the hotcodereloading stdlib module ***
  import std/hotcodereloading

  var runGame*: bool = true
  var window: WindowPtr
  var renderer: RendererPtr
  var evt = sdl2.defaultEvent

  proc init*() =
    discard sdl2.init(INIT_EVERYTHING)
    window = createWindow("testing", SDL_WINDOWPOS_UNDEFINED.cint, SDL_WINDOWPOS_UNDEFINED.cint, 640, 480, 0'u32)
    assert(window != nil, $sdl2.getError())
    renderer = createRenderer(window, -1, RENDERER_SOFTWARE)
    assert(renderer != nil, $sdl2.getError())

  proc destroy*() =
    destroyRenderer(renderer)
    destroyWindow(window)

  var posX: cint = 1
  var posY: cint = 0
  var dX: cint = 1
  var dY: cint = 1

  proc update*() =
    while pollEvent(evt):
      if evt.kind == QuitEvent:
        runGame = false
        break
      if evt.kind == KeyDown:
        if evt.key.keysym.scancode == SDL_SCANCODE_ESCAPE: runGame = false
        elif evt.key.keysym.scancode == SDL_SCANCODE_F9:
          #*** reload this logic.nim module on the F9 keypress ***
          performCodeReload()

    # draw a bouncing rectangle:
    posX += dX
    posY += dY

    if posX >= 640: dX = -2
    if posX <= 0: dX = +2
    if posY >= 480: dY = -2
    if posY <= 0: dY = +2

    discard renderer.setDrawColor(0, 0, 255, 255)
    discard renderer.clear()
    discard renderer.setDrawColor(255, 128, 128, 0)

    var rect: Rect = (x: posX - 25, y: posY - 25, w: 50.cint, h: 50.cint)
    discard renderer.fillRect(rect)
    delay(16)
    renderer.present()
  ```


  ```nim
  # mymain.nim
  import logic

  proc main() =
    init()
    while runGame:
      update()
    destroy()

  main()
  ```


Compile this example via:

  ```cmd
  nim c --hotcodereloading:on mymain.nim
  ```

Now start the program and KEEP it running!

  ```cmd
  # Unix:
  mymain &
  # or Windows (click on the .exe)
  mymain.exe
  # edit
  ```

For example, change the line:

  ```nim
  discard renderer.setDrawColor(255, 128, 128, 0)
  ```

into:

  ```nim
  discard renderer.setDrawColor(255, 255, 128, 0)
  ```

(This will change the color of the rectangle.)

Then recompile the project, but do not restart or quit the mymain.exe program!

  ```cmd
  nim c --hotcodereloading:on mymain.nim
  ```

Now give the `mymain` SDL window the focus, press F9, and watch the
updated version of the program.



Reloading API
=============

One can use the special event handlers `beforeCodeReload` and
`afterCodeReload` to reset the state of a particular variable or to force
the execution of certain statements:

  ```Nim
  var
   settings = initTable[string, string]()
   lastReload: Time

  for k, v in loadSettings():
    settings[k] = v

  initProgram()

  afterCodeReload:
    lastReload = now()
    resetProgramState()
  ```

On each code reload, Nim will first execute all `beforeCodeReload`:idx:
handlers registered in the previous version of the program and then all
`afterCodeReload`:idx: handlers appearing in the newly loaded code. Please note
that any handlers appearing in modules that weren't reloaded will also be
executed. To prevent this behavior, one can guard the code with the
`hasModuleChanged()`:idx: API:

  ```Nim
  import mydb

  var myCache = initTable[Key, Value]()

  afterCodeReload:
    if hasModuleChanged(mydb):
      resetCache(myCache)
  ```

The hot code reloading is based on dynamic library hot swapping in the native
targets and direct manipulation of the global namespace in the JavaScript
target. The Nim compiler does not specify the mechanism for detecting the
conditions when the code must be reloaded. Instead, the program code is
expected to call `performCodeReload()`:idx: every time it wishes to reload
its code.

It's expected that most projects will implement the reloading with a suitable
build-system triggered IPC notification mechanism, but a polling solution is
also possible through the provided `hasAnyModuleChanged()`:idx: API.

In order to access `beforeCodeReload`, `afterCodeReload`, `hasModuleChanged`
or `hasAnyModuleChanged` one must import the `hotcodereloading`:idx: module.


Native code targets
===================

Native projects using the hot code reloading option will be implicitly
compiled with the `-d:useNimRtl`:option: option and they will depend on both
the `nimrtl` library and the `nimhcr` library which implements the
hot code reloading run-time. Both libraries can be found in the `lib`
folder of Nim and can be compiled into dynamic libraries to satisfy
runtime demands of the example code above. An example of compiling
``nimhcr.nim`` and ``nimrtl.nim`` when the source dir of Nim is installed
with choosenim follows.

  ```console
  # Unix/MacOS
  # Make sure you are in the directory containing your .nim files
  $ cd your-source-directory

  # Compile two required files and set their output directory to current dir
  $ nim c --outdir:$PWD ~/.choosenim/toolchains/nim-#devel/lib/nimhcr.nim
  $ nim c --outdir:$PWD ~/.choosenim/toolchains/nim-#devel/lib/nimrtl.nim

  # verify that you have two files named libnimhcr and libnimrtl in your
  # source directory (.dll for Windows, .so for Unix, .dylib for MacOS)
  ```

All modules of the project will be compiled to separate dynamic link
libraries placed in the `nimcache` directory. Please note that during
the execution of the program, the hot code reloading run-time will load
only copies of these libraries in order to not interfere with any newly
issued build commands.

The main module of the program is considered non-reloadable. Please note
that procs from reloadable modules should not appear in the call stack of
program while `performCodeReload` is being called. Thus, the main module
is a suitable place for implementing a program loop capable of calling
`performCodeReload`.

Please note that reloading won't be possible when any of the type definitions
in the program has been changed. When closure iterators are used (directly or
through async code), the reloaded definitions will affect only newly created
instances. Existing iterator instances will execute their original code to
completion.

Supported configurations
------------------------

Hot code reloading depends on the operating system, the CPU and the memory
management mode: the run-time writes machine code for a jump table and loads
every module as a dynamic library. The test suite (`tests/dll`) runs the
reloading tests in these configurations, which are the ones to rely on:

==================  =========  ======================  =================
Operating system    CPU        Memory management       Backend
==================  =========  ======================  =================
Linux (glibc)       amd64      `orc`, `refc`           C
Linux (musl)        amd64      `orc`, `refc`           C
Linux (musl)        arm64      `orc`, `refc`           C
Windows             amd64      `orc`, `refc`           C
macOS               arm64      `orc`, `refc`           C, C++
==================  =========  ======================  =================

Each of them is tested as a debug and as a release build, with
`--threads:off`:option:.

Outside this table:

- `--mm:arc`:option: uses the same code as `orc` and is known to work on
  macOS, but no test runs it.
- Programs that use threads are not tested, apart from one test that keeps
  thread-local variables of two threads apart across a reload with
  `--mm:orc --threads:on`:option:.
- The jump table is implemented for x86, x86-64, and for arm64 on macOS and
  on musl. Other combinations (arm64 on glibc among them) have no
  implementation, and the HCR runtime does not compile for them.
- Nim does not detect musl by itself: on musl, pass `-d:musl`:option:.
  Without it, arm64 counts as one of the combinations above.
- The tests are disabled on OpenBSD and NetBSD, and are not run with
  `--mm:boehm`:option:.

Things to know when the memory management mode is `arc` or `orc`:

- A library that a reload replaces stays loaded: string and sequence literals
  are not copied when they are stored, so a global variable can keep pointing
  into the old library. Every reload therefore costs memory.
- Global variables are not destroyed when the program ends. The main module
  cannot be replaced while it runs, so it must not contain code that depends
  on what the other modules declare; a destructor with a side effect does
  not run at exit.

On macOS on arm64 the jump table is mapped with `MAP_JIT`. A binary signed
with the hardened runtime needs the `com.apple.security.cs.allow-jit`
entitlement for that.

Finding the libraries at run-time
---------------------------------

The program loads `nimrtl`, `nimhcr` and the libraries of its modules when it
starts. `could not load: libnimhcr.so` means the dynamic loader did not find
them. The two run-time libraries are looked up by name, so their directory
has to be on the loader's search path:

  ```console
  # Linux and the BSDs
  $ LD_LIBRARY_PATH=$PWD ./myprogram

  # macOS
  $ DYLD_LIBRARY_PATH=$PWD ./myprogram
  ```

On Windows the directory of the executable is searched, so nothing is needed
when the two DLLs are next to it. Instead of the environment variable, the
directory can be recorded in the executable when it is linked, for example
with `--passL:"-Wl,-rpath,\$ORIGIN"`:option: on Linux or
`--passL:-rpath --passL:@loader_path`:option: on macOS.

`nimrtl` and `nimhcr` have to be compiled with the same memory management
mode as the program.

JavaScript target
=================

Once your code is compiled for hot reloading, a convenient solution for implementing the actual reloading
in the browser using a framework such as [LiveReload](https://livereload.com/)
or [BrowserSync](https://browsersync.io/).
