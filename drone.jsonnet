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
  local image = if arch == "arm" then "ghcr.io/alaviss/nim-ci:sha-8eb1e7b@sha256:1da6b7101fcbae025c09cc1fb51f84a3737d18ed4dc67c0d58ea0bb17e89d280" else "ghcr.io/alaviss/nim-ci:sha-8eb1e7b@sha256:aad1d7b6c95cde34b2a90efe7f8f2a271513ed788ed2d4256cb60906e1ac54f0",
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
