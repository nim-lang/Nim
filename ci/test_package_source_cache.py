#!/usr/bin/env python3
"""Small local Git repositories exercise the transport without network access."""

import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

import package_source_cache as cache


class SourceCacheTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nim-package-cache-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(os.environ)
        for key in list(self.env):
            if key.startswith("GIT_") or key.startswith("NIM_CI_GIT_"):
                del self.env[key]
        self.env.update(
            GIT_CONFIG_GLOBAL=str(self.root / "baseconfig"), GIT_CONFIG_NOSYSTEM="1",
            GIT_AUTHOR_NAME="Cache test", GIT_AUTHOR_EMAIL="cache@example.invalid",
            GIT_COMMITTER_NAME="Cache test", GIT_COMMITTER_EMAIL="cache@example.invalid",
            NIM_CI_GIT_POPULATE="true",
        )
        # file:// is only enabled for these fixtures, never by CI setup.
        self.git("config", "--global", "protocol.file.allow", "always")
        self.origin = self.repo("upstream")
        self.first = self.commit(self.origin, "one")
        self.commit(self.origin, "two")
        self.git("-C", self.origin, "tag", "v1.0.0", self.first)
        self.url = self.origin.as_uri()
        self.cache = self.root / "cache"
        self.cached = self.session("first")

    def git(self, *args, env=None, check=True):
        result = subprocess.run(["git", *map(str, args)], env=env or self.env,
                                capture_output=True, text=True)
        if check and result.returncode:
            self.fail(result.stderr)
        return result

    def repo(self, name):
        path = self.root / name
        self.git("init", "-b", "main", path)
        return path

    def commit(self, repo, content):
        (repo / "value").write_text(content)
        self.git("-C", repo, "add", ".")
        self.git("-C", repo, "commit", "-m", content)
        return self.git("-C", repo, "rev-parse", "HEAD").stdout.strip()

    def session(self, name, populate=True):
        env = dict(self.env, NIM_CI_GIT_POPULATE=str(populate).lower())
        return cache.configure(self.cache, self.root / name, env, prefixes=("file://",))

    def clone(self, name, env=None):
        dest = self.root / name
        self.git("clone", "--depth", "1", self.url, dest, env=env or self.cached)
        return dest

    def mirror(self, url=None):
        key = hashlib.sha256((url or self.url).encode()).hexdigest()
        return self.cache / "repos" / (key + ".git")

    def test_shallow_clone_fetch_tags_and_canonical_urls(self):
        dest = self.clone("clone with spaces")
        self.assertTrue(self.mirror().is_dir())
        self.assertEqual(self.git("-C", dest, "rev-list", "--count", "HEAD").stdout.strip(), "1")
        for args in [("remote", "get-url", "origin"), ("config", "remote.origin.url")]:
            self.assertEqual(self.git("-C", dest, *args, env=self.cached).stdout.strip(), self.url)
        self.git("-C", dest, "fetch", "--depth", "1", "origin", "tag", "v1.0.0", env=self.cached)
        self.git("-C", dest, "checkout", "v1.0.0", env=self.cached)
        self.assertEqual(self.git("-C", dest, "rev-parse", "HEAD").stdout.strip(), self.first)

    def test_restored_cache_refreshes_heads_tags_and_default_branch(self):
        self.clone("old")
        self.git("-C", self.origin, "checkout", "-b", "new-default")
        latest = self.commit(self.origin, "new head")
        self.git("-C", self.origin, "tag", "v2.0.0")
        env = self.session("restored", populate=False)
        dest = self.clone("fresh", env)
        self.assertEqual(self.git("-C", dest, "rev-parse", "HEAD").stdout.strip(), latest)
        self.assertEqual(self.git("-C", dest, "branch", "--show-current").stdout.strip(), "new-default")
        self.assertIn("refs/tags/v2.0.0", self.git("ls-remote", self.url, env=env).stdout)

    def test_new_ref_after_first_access_falls_back_upstream(self):
        dest = self.clone("clone")
        self.git("-C", self.origin, "checkout", "--orphan", "new-ref")
        latest = self.commit(self.origin, "unseen commit")
        self.git("-C", self.origin, "tag", "new-tag")
        # The mirror was already checked this session and cannot serve this ref.
        self.git("-C", dest, "fetch", "--depth", "1", "origin", "new-ref", env=self.cached)
        self.assertEqual(self.git("-C", dest, "rev-parse", "FETCH_HEAD").stdout.strip(), latest)
        self.assertIn(latest, self.git("ls-remote", self.url, "refs/tags/new-tag", env=self.cached).stdout)

    def test_consumer_cache_miss_and_version_discovery_use_upstream(self):
        env = self.session("consumer", populate=False)
        self.clone("miss", env)
        self.assertFalse(self.mirror().exists())
        self.git("ls-remote", "--tags", self.url, env=self.cached)
        self.assertFalse(self.mirror().exists())

    def test_invalid_mirror_does_not_break_a_clone(self):
        self.mirror().mkdir(parents=True)
        (self.mirror() / "invalid").write_text("bad cache entry")
        self.clone("fallback")

    def test_failed_clone_preserves_existing_destination(self):
        dest = self.root / "existing"
        dest.mkdir()
        (dest / "keep").write_text("unrelated work")
        result = self.git("clone", "--recurse-submodules", "--", self.url, dest,
                          env=self.cached, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((dest / "keep").read_text(), "unrelated work")

    def test_failed_upstream_is_not_hidden_by_stale_cache(self):
        self.clone("seed")
        shutil.rmtree(self.origin)
        env = self.session("offline", populate=False)
        result = self.git("clone", "--depth", "1", self.url, self.root / "offline-clone",
                          env=env, check=False)
        self.assertNotEqual(result.returncode, 0)

    def test_relative_submodule_with_spaces_and_missing_mirror(self):
        child = self.repo("child")
        self.commit(child, "child one")
        self.commit(child, "child two")
        self.git("-C", self.origin, "submodule", "add", "../child", "sub dir")
        self.git("-C", self.origin, "commit", "-am", "add submodule")
        dest = self.clone("parent clone")
        self.git("-C", dest, "submodule", "update", "--init", "--recursive", "--depth", "1",
                 env=self.cached)
        self.assertTrue(self.mirror(child.as_uri()).is_dir())
        self.assertEqual(self.git("-C", dest / "sub dir", "remote", "get-url", "origin",
                                  env=self.cached).stdout.strip(), child.as_uri())
        self.assertEqual(self.git("-C", dest / "sub dir", "rev-list", "--count", "HEAD").stdout.strip(), "1")
        shutil.rmtree(self.mirror(child.as_uri()))
        env = self.session("submodule-miss", populate=False)
        dest = self.clone("parent restored", env)
        self.git("-C", dest, "submodule", "update", "--init", "--recursive", env=env)
        self.assertFalse(self.mirror(child.as_uri()).exists())

    def test_recursive_clone_uses_upstream(self):
        self.git("clone", "--recurse-submodules", self.url, self.root / "recursive", env=self.cached)
        self.assertFalse(self.mirror().exists())

    def test_nimble_recursive_clone_retries_failed_submodule(self):
        child = self.repo("recursive-child")
        self.commit(child, "submodule")
        self.git("-C", self.origin, "submodule", "add", "../recursive-child", "sub dir")
        self.git("-C", self.origin, "commit", "-am", "add submodule")
        # Force a cache failure specifically during recursive submodule setup.
        broken = self.mirror(child.as_uri())
        broken.mkdir(parents=True)
        (broken / "invalid").touch()
        dest = self.root / "nimble clone"
        result = self.git("clone", "--config", "core.autocrlf=false", "--config", "core.eol=lf",
                          "--recurse-submodules", "--depth", "1", "--", self.url, dest, env=self.cached)
        self.assertIn("retrying the original command upstream", result.stderr)
        self.assertTrue(self.mirror().is_dir())
        self.assertTrue((dest / "sub dir" / "value").is_file())
        self.assertEqual(self.git("-C", dest, "remote", "get-url", "origin",
                                  env=self.cached).stdout.strip(), self.url)
        self.assertEqual(self.git("-C", dest / "sub dir", "remote", "get-url", "origin",
                                  env=self.cached).stdout.strip(), child.as_uri())

    def test_concurrent_clones_share_one_mirror(self):
        processes = [subprocess.Popen(
            ["git", "clone", "--depth", "1", self.url, str(self.root / name)],
            env=self.cached, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        ) for name in ("parallel-one", "parallel-two")]
        for process in processes:
            _, errors = process.communicate(timeout=30)
            self.assertEqual(process.returncode, 0, errors.decode())
        self.assertEqual(len(list((self.cache / "repos").glob("*.git"))), 1)

    def test_actions_setup_preserves_global_config_and_exports_environment(self):
        files = {name: self.root / name for name in ["GITHUB_ENV", "GITHUB_PATH", "GITHUB_OUTPUT"]}
        env = dict(self.env, **{name: str(path) for name, path in files.items()})
        result = subprocess.run(
            [sys.executable, str(Path(cache.__file__)), "setup", str(self.cache), str(self.root / "actions")],
            env=env, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        for line in files["GITHUB_ENV"].read_text().splitlines():
            key, value = line.split("=", 1)
            env[key] = value
        env["PATH"] = files["GITHUB_PATH"].read_text().strip() + os.pathsep + env["PATH"]
        self.assertEqual(files["GITHUB_OUTPUT"].read_text(), "populate=true\n")
        self.assertEqual(self.git("config", "--global", "protocol.file.allow", env=env).stdout.strip(), "always")
        self.assertEqual(self.git("--version", env=env).stdout, self.git("--version").stdout)


if __name__ == "__main__":
    unittest.main()
