# atlas
The Atlas Package cloner. It manages an isolated workspace that contains projects and dependencies.

# Installation

Upcoming Nim version 2.0 will ship with `atlas`. Building from source:

```sh
git clone https://github.com/nim-lang/atlas.git
cd atlas
nim c src/atlas.nim
# copy src/atlas[.exe] somewhere in your PATH
```

# Tutorial

Create a new workspace. A workspace contains everything we need and can safely be deleted after
this tutorial:

```sh
mkdir workspace
cd workspace
atlas init
```

Create a new project inside the workspace:

```sh
mkdir myproject
cd myproject
```

Tell Atlas we want to use the "malebolgia" library:

```sh
atlas use malebolgia
```

Now `import malebolgia` in your Nim code and run the compiler as usual:

```sh
echo "import malebolgia" >myproject.nim
nim c myproject.nim
```

## Using URLs and local folders

```sh
atlas use https://github.com/zedeus/nitter
atlas use file://../../existingDepdency/
```

## Debugging

Sometimes it's helpful to understand what Atlas is doing. You can run commands with: `atlas --verbosity:<trace|debug>` to get more information. 

# Installing Nim with Atlas

```sh
atlas env 2.0.0
source $WORKSPACE/nim-2.0.0/activate.sh
```

# Vendoring with Atlas

Atlas also supports vendoring using an "inverted workspace". The project layout is where the workspace is a top-level subfolder like `vendor/` or `deps/` in your project. Like this:

```
someProject/vendor/atlas.workspace
someProject/vendor/dep1/
...
```

This is especially helpful for working with projects that have dependencies pinned as git submodules, which was common in the pre-Atlas era.
