"""Exercise content sharing and incremental invalidation with the opt-in compiler."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

nim = Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory(prefix="nim-bif-links-") as tmp:
    root = Path(tmp)
    source = root / "libdemo.nim"
    main = root / "main.nim"
    main.write_text('import libdemo\necho value()\n')
    source.write_text('proc value*(): int = 3\n')
    cache = root / "cache"
    binary = root / "main"

    def build(*flags):
        subprocess.run([str(nim), 'ic', '--hints:off', '-d:icBifDedup',
                        '-d:icJobs=2', '--nimcache:' + str(cache),
                        '--out:' + str(binary), *flags, str(main)], check=True)
        return subprocess.check_output([str(binary)], text=True).strip()

    assert build() == '3'
    paths = list(cache.rglob('*.s.bif')) + list(cache.rglob('*.t.bif'))
    assert paths and all(p.is_symlink() for p in paths)
    assert all(not p.is_symlink() for p in cache.rglob('*.iface.bif'))
    stamps = {p: p.lstat().st_mtime_ns for p in paths}
    assert build() == '3'
    assert stamps == {p: p.lstat().st_mtime_ns for p in paths}
    # Make shared targets old: their mtimes must not govern the link's freshness.
    for p in paths:
        os.utime(p.resolve(), (1, 1))
    source.write_text('proc value*(): int = 4\n')
    assert build() == '4'
    source.write_text('proc value*(): int = 3\n')
    assert build() == '3'
    assert build('-d:unusedExample') == '3'
    paths = list(cache.rglob('*.s.bif')) + list(cache.rglob('*.t.bif'))
    targets = [os.readlink(p) for p in paths]
    assert len(set(targets)) < len(targets), 'configurations should share content'
    paths[0].resolve().unlink()
    assert build('-d:unusedExample') == '3', 'missing object must trigger rebuild'
print('BIF symlink incremental test passed')
