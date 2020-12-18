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
  local cpu = if arch == "arm" then " ucpu=arm" else "",
  steps: [
    {
      name: "runci",
      image: "gcc:10.2",
      commands: [
        "apt-get update -yq",
        "apt-get install --no-install-recommends -yq" + valgrind + " libgc-dev libsdl1.2-dev libsfml-dev",
        "git clone --depth 1 https://github.com/nim-lang/csources.git",
        "export PATH=$PWD/bin:$PATH",
        "make -C csources -j$(nproc)" + cpu,
        "nim c koch",
        |||
          if ! ./koch runCI; then
            nim c -r tools/ci_testresults
            exit 1
          fi
        |||,
      ]
    }
  ]
};

[
  Pipeline("arm64"),
  Pipeline("arm")
]
