#!/usr/bin/env python3
"""Optional, source-only Git cache for the package CI jobs.

Git's remote-helper protocol connects clients to local bare mirrors through
upload-pack. This supports shallow fetches without an HTTP server and leaves
the upstream URLs in working repositories unchanged.
"""

import argparse
import contextlib
import fcntl
import hashlib
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
from urllib.parse import urlsplit


PREFIXES = ("https://", "http://", "git://", "ssh://", "git@")
NETWORK_COMMANDS = {"clone", "fetch", "ls-remote", "submodule"}


def upstream_env(env):
    result = dict(env)
    result["GIT_CONFIG_GLOBAL"] = env["NIM_CI_GIT_BASE_CONFIG"]
    result["NIM_CI_GIT_BYPASS"] = "1"
    return result


def run_git(env, *args, capture=False):
    return subprocess.run(
        [env["NIM_CI_REAL_GIT"], *map(str, args)],
        env=upstream_env(env), check=True,
        stdout=subprocess.PIPE if capture else sys.stderr,
        stderr=sys.stderr, text=True,
    ).stdout


@contextlib.contextmanager
def repository_lock(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield


def mirror_for(url, env):
    # Never put credentials from a URL into a shared Actions cache.
    parsed = urlsplit(url)
    if parsed.scheme in ("http", "https") and parsed.username is not None:
        raise ValueError("credential-bearing URLs bypass the source cache")
    key = hashlib.sha256(url.encode()).hexdigest()
    cache = Path(env["NIM_CI_GIT_CACHE"])
    session = Path(env["NIM_CI_GIT_SESSION"])
    mirror = cache / "repos" / (key + ".git")
    checked = session / "checked" / key
    with repository_lock(session / "locks" / key):
        if checked.exists() and mirror.is_dir():
            return mirror
        if mirror.is_symlink():
            raise ValueError("source cache contains a repository symlink")
        if mirror.exists():
            bare = run_git(env, "--git-dir", mirror, "rev-parse",
                           "--is-bare-repository", capture=True).strip()
            origin = run_git(env, "--git-dir", mirror, "config",
                             "remote.origin.url", capture=True).strip()
            if bare != "true" or origin != url:
                raise ValueError("source cache repository does not match its URL")
            run_git(env, "--git-dir", mirror, "fetch", "--prune", "origin")
        else:
            if env.get("NIM_CI_GIT_POPULATE") != "true":
                raise ValueError("repository is not in the source cache")
            mirror.parent.mkdir(parents=True, exist_ok=True)
            # Keep the rename on the same filesystem as the final mirror.
            staging = mirror.parent / (key + ".staging-" + str(os.getpid()))
            try:
                run_git(env, "clone", "--mirror", url, staging)
                staging.replace(mirror)
            finally:
                if staging.exists():
                    shutil.rmtree(staging)
        # A repository can change its default branch between cache snapshots.
        head = run_git(env, "ls-remote", "--symref", url, "HEAD", capture=True)
        for line in head.splitlines():
            if line.startswith("ref: ") and line.endswith("\tHEAD"):
                branch = line[5:].split("\t", 1)[0]
                run_git(env, "--git-dir", mirror, "symbolic-ref", "HEAD", branch)
                break
        checked.parent.mkdir(parents=True, exist_ok=True)
        checked.touch()
    return mirror


def remote(args, env):
    if len(args) != 2:
        raise ValueError("Git remote helper requires a remote name and URL")
    url = args[1]
    # Git waits for the connect response before sending protocol packets.
    # Read commands without buffering past that boundary.
    stream = sys.stdin.buffer.raw
    while True:
        line = stream.readline().decode().rstrip("\n")
        if not line:
            return 0
        if line == "capabilities":
            print("connect\n", flush=True)
        elif line.startswith("option "):
            print("unsupported", flush=True)
        elif line == "connect git-upload-pack":
            mirror = mirror_for(url, env)
            print("", flush=True)
            return subprocess.call(
                [env["NIM_CI_REAL_GIT"], "upload-pack", str(mirror)],
                env=upstream_env(env),
            )
        else:
            raise ValueError("unsupported source-cache request: " + line)


def command_name(args):
    index = 0
    while index < len(args):
        arg = args[index]
        if arg in ("-C", "-c", "--git-dir", "--work-tree", "--namespace"):
            index += 2
        elif arg.startswith("-"):
            index += 1
        else:
            return arg, args[index + 1:]
    return "", []


def git(args, env):
    command, rest = command_name(args)
    recursive_clone = command == "clone" and any(
        arg == "--recursive" or arg.startswith("--recurse-submodules") for arg in rest)
    if env.get("NIM_CI_GIT_BYPASS") == "1":
        os.execve(env["NIM_CI_REAL_GIT"], [env["NIM_CI_REAL_GIT"], *args], upstream_env(env))
    if recursive_clone:
        # Nimble supplies an explicit "-- URL DIRECTORY". Split its recursive
        # clone so a failed submodule download can retry in the existing clone.
        # Leave other clone variants to Git rather than guessing destinations.
        separator = rest.index("--") if "--" in rest else -1
        unsupported = ("--bare", "--mirror", "--no-checkout", "-n", "--shallow-submodules",
                       "--remote-submodules", "--also-filter-submodules")
        supported = (separator >= 0 and len(rest[separator + 1:]) == 2 and
                     not any(arg in unsupported or arg.startswith("--recurse-submodules=")
                             for arg in rest[:separator]))
        if not supported:
            os.execve(env["NIM_CI_REAL_GIT"], [env["NIM_CI_REAL_GIT"], *args], upstream_env(env))
        leading = args[:len(args) - len(rest) - 1]
        clone_args = [arg for arg in rest[:separator]
                      if arg not in ("--recursive", "--recurse-submodules")]
        result = git([*leading, "clone", *clone_args, *rest[separator:]], env)
        if result:
            return result
        destination = rest[-1]
        run_git(env, *leading, "-C", destination, "config", "--add", "submodule.active", ".")
        return git([*leading, "-C", destination, "submodule", "update", "--init", "--recursive"], env)
    network = command in NETWORK_COMMANDS or (command == "remote" and rest[:1] == ["update"])
    if not network:
        os.execve(env["NIM_CI_REAL_GIT"], [env["NIM_CI_REAL_GIT"], *args], upstream_env(env))
    if command == "ls-remote":
        # Version discovery can inspect many repositories that are never
        # installed. Only use a mirror once a clone/fetch has populated it.
        urls = [arg for arg in rest if "://" in arg or arg.startswith("git@")]
        if not urls or not (Path(env["NIM_CI_GIT_CACHE"]) / "repos" /
                            (hashlib.sha256(urls[0].encode()).hexdigest() + ".git")).is_dir():
            os.execve(env["NIM_CI_REAL_GIT"], [env["NIM_CI_REAL_GIT"], *args], upstream_env(env))
        result = subprocess.run([env["NIM_CI_REAL_GIT"], *args], env=env,
                                stdout=subprocess.PIPE)
        if result.returncode == 0 and result.stdout:
            sys.stdout.buffer.write(result.stdout)
            return 0
        # An empty result may mean a new tag appeared after the first access.
        return subprocess.call([env["NIM_CI_REAL_GIT"], *args], env=upstream_env(env))
    result = subprocess.call([env["NIM_CI_REAL_GIT"], *args], env=env)
    if result:
        # A deleted/unadvertised revision, failed refresh, or corrupt/missing
        # cache must not become a failure that ordinary upstream Git avoids.
        print("Git source cache: retrying the original command upstream", file=sys.stderr)
        result = subprocess.call([env["NIM_CI_REAL_GIT"], *args], env=upstream_env(env))
    return result


def configure(cache, session, env, prefixes=PREFIXES):
    env = dict(env)
    cache = Path(cache).absolute()
    session = Path(session).absolute()
    session.mkdir(parents=True, exist_ok=True)
    cache.mkdir(parents=True, exist_ok=True)
    real_git = env.get("NIM_CI_REAL_GIT") or shutil.which("git", path=env.get("PATH"))
    if not real_git:
        raise ValueError("Git was not found")
    base = env.get("NIM_CI_GIT_BASE_CONFIG") or env.get("GIT_CONFIG_GLOBAL")
    base = str(Path(base).absolute()) if base else str(Path.home() / ".gitconfig")
    env.update(NIM_CI_REAL_GIT=real_git, NIM_CI_GIT_BASE_CONFIG=base,
               NIM_CI_GIT_CACHE=str(cache), NIM_CI_GIT_SESSION=str(session))
    env.setdefault("NIM_CI_GIT_POPULATE", "false")
    config = session / "gitconfig"
    config.write_text("")
    if Path(base).is_file():
        run_git(env, "config", "--file", config, "include.path", base)
    run_git(env, "config", "--file", config, "protocol.nim-ci.allow", "always")
    if env.get("NIM_CI_GIT_POPULATE") == "true":
        rewrites = prefixes
    else:
        # PR jobs use existing mirrors but send cache misses directly upstream.
        # Only trusted refresh jobs pay for new, complete mirror clones.
        rewrites = []
        for mirror in sorted((cache / "repos").glob("*.git")):
            if mirror.is_dir() and not mirror.is_symlink():
                try:
                    url = run_git(env, "--git-dir", mirror, "config",
                                  "remote.origin.url", capture=True).strip()
                    if any(url.startswith(prefix) for prefix in prefixes):
                        rewrites.append(url)
                except subprocess.CalledProcessError:
                    pass
    for prefix in rewrites:
        run_git(env, "config", "--file", config, "--add",
                "url.nim-ci::" + prefix + ".insteadOf", prefix)
    bindir = session / "bin"
    bindir.mkdir(exist_ok=True)
    tool = str(Path(__file__).absolute())
    for name, mode in [("git", "git"), ("git-remote-nim-ci", "remote")]:
        script = bindir / name
        script.write_text("#!/bin/sh\nexec " + shlex.quote(sys.executable) + " " +
                          shlex.quote(tool) + " " + mode + ' "$@"\n')
        script.chmod(0o755)
    env["GIT_CONFIG_GLOBAL"] = str(config)
    env["PATH"] = str(bindir) + os.pathsep + env.get("PATH", "")
    return env


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["setup", "git", "remote"])
    parser.add_argument("args", nargs=argparse.REMAINDER)
    options = parser.parse_args()
    if options.mode == "setup":
        if len(options.args) != 2:
            parser.error("setup requires a cache directory and a per-job session directory")
        env = configure(*options.args, os.environ)
        with open(os.environ["GITHUB_ENV"], "a") as output:
            for key in ["NIM_CI_REAL_GIT", "NIM_CI_GIT_BASE_CONFIG", "NIM_CI_GIT_CACHE",
                        "NIM_CI_GIT_SESSION", "NIM_CI_GIT_POPULATE", "GIT_CONFIG_GLOBAL"]:
                output.write(key + "=" + env[key] + "\n")
        with open(os.environ["GITHUB_PATH"], "a") as output:
            output.write(str(Path(env["NIM_CI_GIT_SESSION"]) / "bin") + "\n")
        with open(os.environ["GITHUB_OUTPUT"], "a") as output:
            output.write("populate=" + env["NIM_CI_GIT_POPULATE"] + "\n")
        return 0
    if options.mode == "git":
        return git(options.args, os.environ)
    return remote(options.args, os.environ)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print("Git source cache: " + str(error), file=sys.stderr)
        sys.exit(1)
