import json
import shutil
import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

import hermes_tasks as ht


def sh(*args, cwd=None):
    subprocess.run(args, cwd=cwd, check=True, capture_output=True)


class Pure(unittest.TestCase):
    def task(self, **kw):
        t = {"slug": "m11", "repo": "o/r", "sensitivity": "public", "approved": True,
             "models": ["opencode-go/kimi-k3"], "steps": [{"id": "s1", "prompt": "p"}]}
        t.update(kw)
        return t

    def test_valid(self):
        self.assertIsNone(ht.validate(self.task()))

    def test_rejections(self):
        for kw in (
            {"sensitivity": "work"}, {"slug": "../x"}, {"models": []},
            {"models": ["opencode-go/muse-spark-1.3-contributor"]}, {"models": ["opencode-go/beam-free"]},
            {"models": ["nvidia/nemotron"], "sensitivity": "personal"}, {"models": ["opencode/big-pickle"]},
            {"steps": [{"id": "a", "prompt": "p"}, {"id": "a", "prompt": "p"}]}, {"repo": ""},
        ):
            self.assertIsNotNone(ht.validate(self.task(**kw)), kw)

    def test_free_provider_ok_for_public(self):
        self.assertIsNone(ht.validate(self.task(models=["opencode-go/kimi-k3", "nvidia/x", "google/y"])))

    def test_limits(self):
        with tempfile.TemporaryDirectory() as d:
            lim = ht.Limits(Path(d) / "l.json", caps={"nvidia": 2})
            self.assertTrue(lim.available("go", 0))
            lim.strike("go", t=100)
            self.assertFalse(lim.available("go", 101))
            self.assertTrue(lim.available("go", 100 + 1800 + 1))
            lim.strike("go", t=100)  # second strike doubles the wait
            self.assertEqual(lim.until("go"), 100 + 3600)
            lim.ok("go")
            self.assertTrue(lim.available("go", 101))
            lim.count("nvidia"), lim.count("nvidia")
            self.assertFalse(lim.available("nvidia"))
            self.assertTrue(ht.Limits(Path(d) / "l.json", caps={"nvidia": 2}).d["cooldown"] == {})


class EndToEnd(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        t = Path(self.tmp.name)
        self.root, self.status, self.log = t / "ws", t / "status", t / "calls.log"
        self.sessions = t / "sessions.log"
        self.configs = t / "configs.log"
        self.approvals = t / "approvals"
        self.approvals.mkdir()
        self.root.mkdir(), self.status.mkdir()
        env = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
               "GIT_COMMITTER_EMAIL": "t@t", "HOME": str(t), "PATH": f"{t}/bin:" + os.environ["PATH"]}
        os.environ.update(env)
        os.environ.pop("TELEGRAM_BOT_TOKEN", None)
        # origin with a default branch "trunk" and a feature branch that holds an extra file.
        seed = t / "seed"
        sh("git", "init", "-q", "-b", "trunk", str(seed))
        (seed / "a.txt").write_text("a")
        sh("git", "-C", str(seed), "add", ".")
        sh("git", "-C", str(seed), "commit", "-qm", "a")
        sh("git", "-C", str(seed), "checkout", "-qb", "feature")
        (seed / "feature.txt").write_text("f")
        sh("git", "-C", str(seed), "add", "."), sh("git", "-C", str(seed), "commit", "-qm", "f")
        sh("git", "-C", str(seed), "checkout", "-q", "trunk")
        sh("git", "clone", "-q", "--bare", str(seed), str(t / "origin.git"))
        self.origin = str(t / "origin.git")
        # Fake opencode: model a/* hits a rate limit, others write out.txt.
        (t / "bin").mkdir()
        fake = t / "bin" / "opencode"
        fake.write_text(textwrap.dedent(f"""\
            #!{shutil.which("bash")}
            while [ $# -gt 0 ]; do case "$1" in -m) m="$2"; shift 2;; --dir) d="$2"; shift 2;; -s) s="$2"; shift 2;; *) p="$1"; shift;; esac; done
            echo "${{s:-none}}" >> {self.sessions}
            [ -n "$OPENCODE_CONFIG" ] && cat "$OPENCODE_CONFIG" >> {self.configs} && echo >> {self.configs}
            echo "$m" >> {self.log}
            echo '{{"type":"step_start","sessionID":"ses_'"${{m//\\//_}}"'"}}'
            case "$m" in
              a/*) echo '{{"type":"error","sessionID":"ses_x","error":{{"data":{{"message":"slow down","statusCode":429}}}}}}'; exit 1;;
              r/*|*/r) case "$p" in *"Approved scope"*) echo ok > "$d/out.txt";; esac; echo '{{"type":"step_finish","part":{{"cost":0.01}}}}';;
              h/*) sleep 30;;
              l/*) echo 'timestamp=t level=ERROR run=x message="stream error" providerID=l error.error="AI_APICallError: Go usage limit exceeded"' >&2; sleep 30;;
              d/*) echo '{{"type":"error","sessionID":"ses_x","error":{{"data":{{"message":"key expired","statusCode":401}}}}}}'; exit 1;;
              *) echo ok > "$d/out.txt"; echo '{{"type":"step_finish","part":{{"cost":0.01}}}}';;
            esac
            """))
        fake.chmod(0o755)

    def approve(self, task, scope="do the job", task_hash=None):
        (self.approvals / f"{task['slug']}.md").write_text(
            f"---\napproved: true\nscope: \"{scope}\"\ntask: {task_hash or ht.task_hash(task)}\n---\n")

    def run_task(self, approve=True, **kw):
        task = {"slug": "job", "repo": self.origin, "models": ["a/x", "b/y"], "max_attempts_per_step": 2,
                "steps": [{"id": "s1", "prompt": "p", "check": "test -f out.txt"}], "body": "ctx"}
        task.update(kw)
        if approve:
            self.approve(task)
        cfg = {"root": self.root, "inbox": self.root, "status_dir": self.status, "approvals": self.approvals}
        lim = ht.Limits(self.root / "limits.json")
        t = ht.Task(cfg, task, lim)
        t.run()
        return t, lim

    def calls(self):
        return self.log.read_text().split() if self.log.exists() else []

    def test_fallback_then_resume_and_default_base(self):
        t, lim = self.run_task()
        self.assertEqual(t.state["status"], "done")
        self.assertEqual(t.state["steps"]["s1"]["model"], "b/y")
        self.assertEqual(self.calls(), ["a/x", "b/y"])
        self.assertFalse(lim.available("a"))
        wt = self.root / "wt" / "job"
        self.assertTrue((wt / "out.txt").exists())
        self.assertFalse((wt / "feature.txt").exists(), "default base is origin/HEAD = trunk")
        self.assertEqual(t.state["base"], "origin/trunk")
        self.assertIn("State: **done**", (self.status / "job-status.md").read_text())
        self.assertNotIn(".hermes", subprocess.run(["git", "status", "--short"], cwd=wt, capture_output=True, text=True).stdout)
        # A second run, as after a reboot, repeats nothing.
        self.run_task()
        self.assertEqual(self.calls(), ["a/x", "b/y"])

    def test_base_from_task(self):
        self.run_task(slug="job2", base="feature")
        self.assertTrue((self.root / "wt" / "job2" / "feature.txt").exists())

    def test_resume_skips_finished_step(self):
        steps = [{"id": "s1", "prompt": "p"}, {"id": "s2", "prompt": "p"}]
        d = self.root / "tasks" / "job3"
        d.mkdir(parents=True)
        (d / "state.json").write_text(json.dumps({"status": "running", "steps": {"s1": {"status": "done", "attempts": 1}}}))
        t, _ = self.run_task(slug="job3", models=["b/y"], steps=steps)
        self.assertEqual(self.calls(), ["b/y"], "only s2 ran")
        self.assertEqual(t.state["status"], "done")

    def test_all_limited_parks_without_calls(self):
        lim = ht.Limits(self.root / "limits.json")
        lim.strike("a"), lim.strike("b")
        t, _ = self.run_task()
        self.assertEqual(t.state["status"], "limited")
        self.assertEqual(self.calls(), [])
        self.assertGreater(t.state["retry_after"], ht.now())

    def test_auth_error_cools_provider_for_hours(self):
        t, lim = self.run_task(models=["d/z", "b/y"])
        self.assertEqual(t.state["status"], "done")
        self.assertGreaterEqual(lim.until("d") - ht.now(), 21000)

    def test_check_failure_stops_after_max_attempts(self):
        t, _ = self.run_task(models=["b/y"], steps=[{"id": "s1", "prompt": "p", "check": "false"}])
        self.assertEqual(t.state["status"], "failed")
        self.assertEqual(t.state["steps"]["s1"]["attempts"], 2)
        self.assertEqual(self.calls(), ["b/y", "b/y"])

    def test_hang_cools_provider_and_falls_back(self):
        steps = [{"id": "s1", "prompt": "p", "idle_min": 0.03}]
        t, lim = self.run_task(models=["h/z", "b/y"], steps=steps)
        self.assertEqual(t.state["status"], "done")
        self.assertFalse(lim.available("h"))

    def test_killed_mid_step_resumes_same_session(self):
        d = self.root / "tasks" / "job4"
        d.mkdir(parents=True)
        (d / "state.json").write_text(json.dumps({
            "status": "running", "inflight": {"step": "s1", "model": "b/y"},
            "steps": {"s1": {"status": "pending", "attempts": 0, "model": "b/y", "session": "ses_old"}}}))
        t, _ = self.run_task(slug="job4", models=["b/y"])
        self.assertEqual(t.state["status"], "done")
        self.assertEqual(self.sessions.read_text().split(), ["ses_old"])

    def test_other_model_does_not_reuse_session(self):
        d = self.root / "tasks" / "job5"
        d.mkdir(parents=True)
        (d / "state.json").write_text(json.dumps({
            "status": "running", "inflight": {"step": "s1", "model": "a/x"},
            "steps": {"s1": {"status": "pending", "attempts": 0, "model": "a/x", "session": "ses_old"}}}))
        self.run_task(slug="job5", models=["b/y"])
        self.assertEqual(self.sessions.read_text().split(), ["none"])

    def test_main_blocks_invalid_and_runs_valid(self):
        inbox = self.root / "inbox"
        inbox.mkdir()
        (inbox / "bad.md").write_text("---\nrepo: x\napproved: false\n---\n")
        (inbox / "good.md").write_text(
            f"---\nrepo: {self.origin}\nsensitivity: public\napproved: true\nmodels: [opencode-go/r]\n"
            "steps:\n  - id: s1\n    prompt: p\n---\nctx\n")
        os.environ.update(HERMES_TASK_ROOT=str(self.root), HERMES_TASK_INBOX=str(inbox),
                          HERMES_TASK_STATUS_DIR=str(self.status))
        ht.main()
        self.assertIn("State: **blocked**", (self.status / "bad-status.md").read_text())
        self.assertIn("State: **done**", (self.status / "good-status.md").read_text())

    def test_log_error_limit_stops_the_worker_at_once(self):
        t0 = ht.now()
        t, lim = self.run_task(models=["l/q", "b/y"])
        self.assertLess(ht.now() - t0, 15, "did not wait for the 30 s sleep or the idle timer")
        self.assertEqual(t.state["status"], "done")
        self.assertFalse(lim.available("l"))

    def test_all_models_limited_status_names_the_reason(self):
        t, _ = self.run_task(models=["l/q"])
        self.assertEqual(t.state["status"], "limited")
        self.assertIn("Go usage limit exceeded", t.state["reason"])
        self.assertIn("Go usage limit exceeded", (self.status / "job-status.md").read_text())

    def test_worker_gets_a_config_pinned_to_its_model(self):
        base = self.root / "base.json"
        base.write_text(json.dumps({"model": "opencode/big-pickle", "small_model": "opencode/big-pickle",
                                    "mcp": {"x": {}}, "agent": {"title": {"model": "opencode/big-pickle", "prompt": "p"}}}))
        os.environ[ht.BASE_CONFIG] = str(base)
        self.addCleanup(os.environ.pop, ht.BASE_CONFIG)
        self.run_task(models=["b/y"])
        cfg = json.loads(self.configs.read_text().strip().splitlines()[0])
        self.assertEqual((cfg["model"], cfg["small_model"]), ("b/y", "b/y"))
        self.assertNotIn("model", cfg["agent"]["title"])
        self.assertEqual(cfg["agent"]["title"]["prompt"], "p")
        self.assertIn("mcp", cfg)

    TWO = [{"id": "spec", "prompt": "write the spec"}, {"id": "build", "prompt": "build it", "check": "test -f out.txt"}]

    def test_unapproved_task_runs_step_one_then_waits(self):
        t, _ = self.run_task(approve=False, models=["r/q"], steps=self.TWO)
        self.assertEqual(t.state["status"], "waiting")
        self.assertEqual(t.state["steps"]["spec"]["status"], "done")
        self.assertNotEqual(t.state["steps"].get("build", {}).get("status"), "done")
        self.assertEqual(self.calls(), ["r/q"])
        note = (self.status / "job-status.md").read_text()
        self.assertIn("Waiting for your approval before step `build`", note)
        self.assertIn(ht.task_hash(t.t), note)
        self.assertIn("AI/Approvals/job.md", note)

    def test_approval_lets_the_rest_run_and_the_prompt_carries_the_scope(self):
        t, _ = self.run_task(approve=False, models=["r/q", "b/y"], steps=self.TWO)
        self.assertEqual(t.state["status"], "waiting")
        task = t.t
        self.approve(task, scope="only the build")
        t2, _ = self.run_task(approve=False, models=["r/q", "b/y"], steps=self.TWO)
        self.assertEqual(t2.state["status"], "done")
        self.assertEqual(self.calls(), ["r/q", "r/q"], "step one ran once, then build ran on the first usable model")

    def test_editing_the_task_voids_the_approval(self):
        task = {"slug": "job", "repo": self.origin, "models": ["r/q"], "steps": self.TWO, "body": "ctx"}
        self.approve(task)
        t, _ = self.run_task(approve=False, models=["r/q"], steps=self.TWO, body="edited after approval")
        self.assertEqual(t.state["status"], "waiting")
        self.assertIn("different version", t.state["reason"])

    def test_approval_without_scope_does_not_count(self):
        task = {"slug": "job", "repo": self.origin, "models": ["r/q"], "steps": self.TWO, "body": "ctx", "max_attempts_per_step": 2}
        (self.approvals / "job.md").write_text(f"---\napproved: true\ntask: {ht.task_hash(task)}\n---\n")
        t, _ = self.run_task(approve=False, models=["r/q"], steps=self.TWO)
        self.assertEqual(t.state["status"], "waiting")
        self.assertIn("no scope", t.state["reason"])

    def test_task_file_cannot_approve_itself(self):
        t, _ = self.run_task(approve=False, models=["r/q"], steps=self.TWO, approved=True, scope="trust me")
        self.assertEqual(t.state["status"], "waiting")

    def test_step_one_that_changes_the_repo_fails_the_task(self):
        t, _ = self.run_task(approve=False, models=["b/y"], steps=[{"id": "spec", "prompt": "p"}])
        self.assertEqual(t.state["status"], "failed")
        self.assertIn("changed the repo before approval", t.state["reason"])
        self.assertIn("out.txt", t.state["reason"])

    def test_main_skips_a_waiting_task_without_touching_it(self):
        inbox = self.root / "inbox"
        inbox.mkdir()
        (inbox / "w.md").write_text(
            f"---\nrepo: {self.origin}\nsensitivity: public\nmodels: [opencode-go/r]\n"
            "steps:\n  - id: a\n    prompt: p\n  - id: b\n    prompt: p\n---\nctx\n")
        os.environ.update(HERMES_TASK_ROOT=str(self.root), HERMES_TASK_INBOX=str(inbox),
                          HERMES_TASK_STATUS_DIR=str(self.status), HERMES_TASK_APPROVALS=str(self.approvals))
        self.addCleanup(os.environ.pop, "HERMES_TASK_APPROVALS")
        ht.main()
        self.assertIn("State: **waiting**", (self.status / "w-status.md").read_text())
        before = len(self.calls())
        ht.main()
        self.assertEqual(len(self.calls()), before, "a waiting task is not run again")

    def test_worker_config_denies_pushes_to_default_branches_and_merges(self):
        base = self.root / "base2.json"
        base.write_text(json.dumps({"permission": {"edit": "allow", "bash": {"git status*": "allow", "git push*main*": "allow"}}}))
        os.environ[ht.BASE_CONFIG] = str(base)
        self.addCleanup(os.environ.pop, ht.BASE_CONFIG)
        self.run_task(models=["b/y"])
        cfg = json.loads(self.configs.read_text().strip().splitlines()[0])
        bash = cfg["permission"]["bash"]
        rules = list(bash)
        self.assertEqual(rules[0], "*")
        self.assertEqual(cfg["permission"]["edit"], "allow")
        for pat in ("gh pr merge*", "git push --force*", "git push*main*", "git push*master*", "git push*trunk*"):
            self.assertEqual(bash[pat], "deny", pat)
            self.assertGreater(rules.index(pat), rules.index("git status*"), "deny rules come last")

    def test_worker_env_has_no_secrets(self):
        os.environ["GH_TOKEN"], os.environ["TELEGRAM_BOT_TOKEN"] = "x", "y"
        self.addCleanup(os.environ.pop, "GH_TOKEN"), self.addCleanup(os.environ.pop, "TELEGRAM_BOT_TOKEN")
        env = ht.worker_env()
        self.assertNotIn("GH_TOKEN", env)
        self.assertNotIn("TELEGRAM_BOT_TOKEN", env)


if __name__ == "__main__":
    unittest.main()
