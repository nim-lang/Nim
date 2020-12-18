local Pipeline(arch) = {
  kind: "pipeline",
  type: "docker",
  name: "nim-on-" + arch,

  platform: {
    os: "linux",
    arch: arch
  },

  steps: [
    {
      name: "runci",
      image: "gcc",
      commands: [
        "apt-get install --no-install-recommends -yq valgrind libc6-dbg libgc-dev libsdl1.2-dev libsfml-dev",
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
