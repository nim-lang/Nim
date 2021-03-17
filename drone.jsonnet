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
  local image = if arch == "arm" then "ghcr.io/alaviss/nim-ci:sha-cbaa8fd@sha256:8d99e0d3cf03e61200cd08a63ed13b4cfb8d342b95fdb49ec99c3be71faa180f" else "ghcr.io/alaviss/nim-ci:sha-cbaa8fd@sha256:5416ad30a5d65ac19fa4cc2684e6f62fd7222d092f841548b9df297bc7c0cac8",
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
