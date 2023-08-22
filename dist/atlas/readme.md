# atlas
The Atlas Package cloner. It manages an isolated workspace that contains projects and dependencies.

# Installation

Upcoming Nim version 2.0 will ship with `atlas`. Building from source:

```
git clone https://github.com/nim-lang/atlas.git
cd atlas
nim c src/atlas.nim
# copy src/atlas[.exe] somewhere in your PATH
```

# Tutorial

Create a new workspace. A workspace contains everything we need and can safely be deleted after
this tutorial:

```
mkdir workspace
cd workspace
atlas init
```

Create a new project inside the workspace:

```
mkdir myproject
cd myproject
```

Tell Atlas we want to use the "malebolgia" library:

```
atlas use malebolgia
```

Now `import malebolgia` in your Nim code and run the compiler as usual:

```
echo "import malebolgia" >myproject.nim
nim c myproject.nim
```
