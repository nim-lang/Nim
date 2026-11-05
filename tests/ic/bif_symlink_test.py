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
    active = next(d for d in (cache / 'configs').iterdir()
                  if 'unusedexample' in (d / 'ic_build_args.txt').read_text().lower())
    active_link = next(active.rglob('*.s.bif'))
    missing_object = active_link.resolve()
    missing_object.unlink()
    assert active_link.is_symlink() and not active_link.exists()
    assert build('-d:unusedExample') == '3', 'missing object must trigger rebuild'
    assert active_link.exists(), 'the active configuration must restore the link target'

    scheduler = nim.parent / 'nifmake'
    assert subprocess.check_output([str(scheduler), '--nimBifLinksSupport'],
                                   text=True).strip() == 'nim-bif-links-v1'
    force_dir = root / 'force'
    force_dir.mkdir()
    force_target = force_dir / 'object'
    force_target.write_text('object')
    os.utime(force_target, (10, 10))
    force_link = force_dir / 'test.s.bif'
    force_link.symlink_to(force_target)
    os.utime(force_link, (20, 20), follow_symlinks=False)
    graph = force_dir / 'build.nif'
    graph.write_text('(stmts (cmd :run "/usr/bin/true" (input) (output)) '
                     f'(do run (input) (output "{force_link}")))\n')
    subprocess.run([str(scheduler), 'run', '--force', str(graph)], check=True)
    assert force_link.lstat().st_mtime_ns > 20_000_000_000
    assert force_target.stat().st_mtime_ns == 10_000_000_000

    # Isolate object publication from the IC driver's concurrency limitations.
    fixture = root / 'writer.nim'
    fixture.write_text("""import std/os
import compiler/[ast, icnifcore]
let semDir = paramStr(1)
createDir(semDir)
var b = newIcBuilder()
b.openTag(\"payload\")
b.addStrLit(\"shared content\")
b.closeTag()
storeBifShared(b, semDir / \"demo.s.bif\", \".demo\", semDir)
""")
    writer = root / 'writer'
    repo = Path(__file__).resolve().parents[2]
    subprocess.run([str(nim), 'c', '--hints:off', '--warnings:off', '--path:' + str(repo),
                    '--out:' + str(writer), str(fixture)], check=True)
    publication = root / 'publication'
    sem_dirs = [publication / 'configs' / str(i) / 'sem' for i in range(8)]
    procs = [subprocess.Popen([str(writer), str(d)]) for d in sem_dirs]
    statuses = [p.wait() for p in procs]
    assert all(status == 0 for status in statuses), 'concurrent publication failed'
    links = [d / 'demo.s.bif' for d in sem_dirs]
    assert all(p.is_symlink() and p.exists() for p in links)
    targets = {p.resolve() for p in links}
    assert len(targets) == 1, 'concurrent publishers must share one object'
    target = targets.pop()
    target.write_bytes(b'corrupt')
    corrupt_dir = publication / 'configs' / 'corrupt' / 'sem'
    failed = subprocess.run([str(writer), str(corrupt_dir)], capture_output=True, text=True)
    assert failed.returncode != 0 and 'corruption' in failed.stderr
    assert not (corrupt_dir / 'demo.s.bif').exists()
    # Source pragmas must not change the storage mode selected by the driver.
    pragma_dir = root / 'pragma'
    pragma_dir.mkdir()
    pragma_main = pragma_dir / 'main.nim'
    pragma_cache = pragma_dir / 'cache'
    pragma_binary = pragma_dir / 'main'

    def build_pragma(value, enabled=False, internal=False):
        pragma = 'undef' if enabled else 'define'
        pragma_main.write_text(f'{{. {pragma}: icBifDedup .}}\necho {value}\n')
        args = [str(nim), 'ic', '--hints:off', '-d:icJobs=2',
                '--nimcache:' + str(pragma_cache), '--out:' + str(pragma_binary)]
        if enabled:
            args.append('-d:icBifDedup')
        if internal:
            args.append('--icBifLinks')
        subprocess.run(args + [str(pragma_main)], check=True)
        return subprocess.check_output([str(pragma_binary)], text=True).strip()

    for value in (3, 4, 3):
        assert build_pragma(value) == str(value)
    assert all(not p.is_symlink() for p in pragma_cache.rglob('*.s.bif'))
    assert build_pragma(6, internal=True) == '6'
    assert all(not p.is_symlink() for p in pragma_cache.rglob('*.s.bif'))
    for value in (5, 6, 5):
        assert build_pragma(value, enabled=True) == str(value)
    main_links = list(pragma_cache.glob('configs/*/sem/main/*/*.s.bif'))
    assert any(p.is_symlink() for p in main_links)

    # A replayed config file cannot enable the driver's private child switch.
    config_dir = root / 'config-switch'
    config_dir.mkdir()
    (config_dir / 'nim.cfg').write_text('--icBifLinks\n')
    config_main = config_dir / 'main.nim'
    config_cache = config_dir / 'cache'
    config_binary = config_dir / 'main'
    for value in (11, 12, 11):
        config_main.write_text(f'echo {value}\n')
        subprocess.run([str(nim), 'ic', '--hints:off', '-d:icJobs=2',
                        '--nimcache:' + str(config_cache), '--out:' + str(config_binary),
                        str(config_main)], check=True)
        assert subprocess.check_output([str(config_binary)], text=True).strip() == str(value)
    assert all(not p.is_symlink() for p in config_cache.rglob('*.s.bif'))
print('BIF symlink incremental test passed')
