local Pipeline(arch) = {
  kind: "pipeline",
  type: "docker",
  name: "nim-on-" + arch,

  platform: {
    os: "linux",
    arch: arch
  },

  clone: {
    depth: 1
  },

  local valgrind = if arch == "arm64" then " valgrind libc6-dbg" else "",
  steps: [
    {
      name: "runci",
      image: "gcc:10.2",
      commands: [
        "apt-get update -yq",
        "apt-get install --no-install-recommends -yq" + valgrind + " libgc-dev libsdl1.2-dev libsfml-dev",
        "git clone --depth 1 https://github.com/nim-lang/csources.git",
        "export PATH=$PWD/bin:$PATH",
        "make -C csources -j$(nproc)",
        "nim c koch",
        "./koch runCI"
      ]
    }
  ]
};

[
  Pipeline("arm64"),
  Pipeline("arm")
]
