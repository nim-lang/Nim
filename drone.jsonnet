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

  local cpu = if arch == "arm" then " ucpu=arm" else "",
  local image = if arch == "arm" then "ghcr.io/alaviss/nim-ci:sha-f673d96@sha256:b6c99973ca31d35f95508193d49306c5fa933e3f6090b8ffb56fee16b32705fc" else "ghcr.io/alaviss/nim-ci:sha-f673d96@sha256:a9c72fa9a13dc5d2b2db7080632792f5c04cd0e0b19c1d995356e634449777ea",
  steps: [
    {
      name: "runci",
      image: image,
      commands: [
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
