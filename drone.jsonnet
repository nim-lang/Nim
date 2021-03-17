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
  local image = if arch == "arm" then "ghcr.io/alaviss/nim-ci:sha-1d368dc@sha256:a4aeeca1daeb33b56aed80c1a6745f7e65192716f175c0122fbe88e64caf76c6" else "ghcr.io/alaviss/nim-ci:sha-1d368dc@sha256:b03ad81192e7e14dec4471b63a3d98c78ceada2e675d9075151193d972814b26",
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
