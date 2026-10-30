"""Run Hermes task files from the inbox, one step at a time, with no LLM in the driver seat.

A task is a markdown file with YAML front matter (see docs in the vault). The runner makes a
worktree, runs each step with `opencode run -m <provider/model>`, checks the result, and writes
state so a reboot or power cut resumes at the last finished step. A model that is rate limited
goes into cooldown and the next model in the task's list takes over. Handoff between models is by
files in <worktree>/.hermes/, because an opencode session cannot move to another provider.
"""

import json
import os
import re
import select
import signal
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

import yaml

SLUG = re.compile(r"^[a-z0-9][a-z0-9-]{0,40}$")
LIMITED = re.compile(r"rate.?limit|usage limit|FreeUsageLimit|quota|too many requests", re.I)
AUTH = re.compile(r"expired|unauthori[sz]ed|invalid api key|forbidden", re.I)
# opencode prints its own errors on stderr as: level=ERROR ... error.error="<message>"
LOG_ERROR = re.compile(r'level=ERROR .*?error\.error="([^"]*)')
# Providers a task may use per sensitivity. Free tiers may train on prompts, so personal data
# stays on the paid OpenCode Go key. Work tasks wait for the Claude tier (not built yet).
PROVIDERS = {"public": {"opencode-go", "nvidia", "google"}, "personal": {"opencode-go"}}
WORKER_ENV = (
    "PATH", "HOME", "LANG", "SSL_CERT_FILE", "NIX_SSL_CERT_FILE", "NVIDIA_API_KEY",
    "GOOGLE_GENERATIVE_AI_API_KEY",
)
# Written for the worker, never passed through from the runner's own environment.
BASE_CONFIG = "HERMES_OPENCODE_BASE_CONFIG"
HANDOFF = (
    "Handoff rules: read .hermes/PLAN.md and .hermes/PROGRESS.md first if they exist. Before you "
    "stop, append to .hermes/PROGRESS.md what you did, what is left, and the output of any failing "
    "command. Never push to a default branch. Never merge."
)


def now():
    return time.time()


def write_atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text)
    os.replace(tmp, path)


def parse_task(path):
    text = Path(path).read_text()
    m = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.S)
    if not m:
        raise ValueError("no YAML front matter")
    task = yaml.safe_load(m.group(1)) or {}
    if not isinstance(task, dict):
        raise ValueError("front matter is not a mapping")
    task["body"] = m.group(2).strip()
    task.setdefault("slug", Path(path).stem)
    return task


def provider(model):
    return model.split("/", 1)[0]


def allowed(model, sensitivity):
    """Why a model may not be used for this sensitivity, or None."""
    if re.search(r"contributor|-free$", model):
        return "free or contributor model"
    if provider(model) not in PROVIDERS.get(sensitivity, set()):
        return f"provider {provider(model)} is not allowed for {sensitivity} tasks"
    return None


def validate(task):
    """First problem in a task file, or None. Approval modes and Claude tiers come later."""
    if not SLUG.match(str(task["slug"])):
        return "slug must match [a-z0-9-], 41 characters at most"
    if not task.get("repo"):
        return "repo is missing"
    if task.get("sensitivity") not in PROVIDERS:
        return "sensitivity must be public or personal (work tasks are not supported yet)"
    if task.get("approved") is not True:
        return "approved is not true (the spec-first mode is not built yet)"
    models = task.get("models")
    if not isinstance(models, list) or not models:
        return "models must be a non-empty list"
    for m in models:
        if "/" not in str(m):
            return f"model {m} must look like provider/model"
        why = allowed(m, task["sensitivity"])
        if why:
            return f"model {m}: {why}"
    steps = task.get("steps")
    if not isinstance(steps, list) or not steps:
        return "steps must be a non-empty list"
    ids = set()
    for s in steps:
        if not isinstance(s, dict) or not SLUG.match(str(s.get("id", ""))) or not s.get("prompt"):
            return "every step needs an id ([a-z0-9-]) and a prompt"
        if s["id"] in ids:
            return f"duplicate step id {s['id']}"
        ids.add(s["id"])
    return None


class Limits:
    """Per-provider cooldowns and daily request counts, kept in one JSON file."""

    BASE, CAP = 1800, 21600

    def __init__(self, path, caps=None):
        self.path, self.caps = Path(path), caps or {}
        try:
            self.d = json.loads(self.path.read_text())
        except (OSError, ValueError):
            self.d = {}
        self.d.setdefault("cooldown", {})
        self.d.setdefault("count", {})

    def save(self):
        write_atomic(self.path, json.dumps(self.d, indent=1))

    def until(self, prov):
        return self.d["cooldown"].get(prov, {}).get("until", 0)

    def available(self, prov, t=None):
        t = now() if t is None else t
        if self.until(prov) > t:
            return False
        cap = self.caps.get(prov)
        used = self.d["count"].get(time.strftime("%Y-%m-%d", time.gmtime(t)), {}).get(prov, 0)
        return cap is None or used < cap

    def strike(self, prov, retry_after=None, t=None):
        t = now() if t is None else t
        c = self.d["cooldown"].setdefault(prov, {"strikes": 0})
        wait = retry_after or min(self.BASE * 2 ** c["strikes"], self.CAP)
        c["strikes"] += 1
        c["until"] = t + wait
        self.save()

    def ok(self, prov):
        self.d["cooldown"].pop(prov, None)
        self.save()

    def count(self, prov, t=None):
        day = time.strftime("%Y-%m-%d", time.gmtime(now() if t is None else t))
        self.d["count"] = {day: self.d["count"].get(day, {})}
        self.d["count"][day][prov] = self.d["count"][day].get(prov, 0) + 1
        self.save()


def worker_env():
    return {k: os.environ[k] for k in WORKER_ENV if k in os.environ}


def worker_config(base, model, dest):
    """Write an opencode config that pins every model to this task's model.

    The host config sets model, small_model and every agent to a free Zen model, and -m only
    overrides the main one. Titles and summaries would still go to the free tier."""
    cfg = json.loads(Path(base).read_text())
    cfg["model"] = cfg["small_model"] = model
    for agent in (cfg.get("agent") or {}).values():
        if isinstance(agent, dict):
            agent.pop("model", None)
    write_atomic(dest, json.dumps(cfg))
    return str(dest)


def run_worker(model, prompt, cwd, runs_file, session, timeout, idle, on_session):
    """Run one opencode call. Returns a dict: rc, session, cost, limited, auth, hang, error."""
    cmd = ["opencode", "run", "-m", model, "--format", "json", "--print-logs", "--log-level", "ERROR",
           "--dir", str(cwd)]
    if session:
        cmd += ["-s", session]
    cmd.append(prompt)
    res = {"rc": None, "session": session, "cost": 0.0, "limited": False, "auth": False,
           "hang": False, "error": ""}
    runs_file.parent.mkdir(parents=True, exist_ok=True)
    env = worker_env()
    if os.environ.get(BASE_CONFIG):
        env["OPENCODE_CONFIG"] = worker_config(os.environ[BASE_CONFIG], model, runs_file.with_suffix(".opencode.json"))

    def handle(line):
        try:
            ev = json.loads(line)
        except ValueError:
            # Plain text is stderr: opencode's own error log. Model output is JSON, so it never gets here.
            m = LOG_ERROR.search(line)
            msg = m.group(1)[:300] if m else (line.strip()[:300] if LIMITED.search(line) else "")
            if msg:
                res["error"] = msg
                res["limited"] |= bool(LIMITED.search(msg))
                res["auth"] |= bool(AUTH.search(msg))
            return
        if not isinstance(ev, dict):
            return
        if ev.get("sessionID") and not res["session"]:
            res["session"] = ev["sessionID"]
            on_session(res["session"])
        cost = (ev.get("part") or {}).get("cost")
        if isinstance(cost, (int, float)):
            res["cost"] += cost
        if ev.get("type") == "error":
            data = (ev.get("error") or {}).get("data") or {}
            res["error"] = str(data.get("message") or ev.get("error"))[:300]
            code = data.get("statusCode")
            res["limited"] |= code == 429 or bool(LIMITED.search(res["error"]))
            res["auth"] |= code in (401, 403)

    start = last = now()
    buf = b""
    with open(runs_file, "ab") as out:
        p = subprocess.Popen(cmd, cwd=cwd, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, start_new_session=True)
        fd = p.stdout.fileno()
        while True:
            if select.select([fd], [], [], 1.0)[0]:
                chunk = os.read(fd, 65536)
                if not chunk:
                    break
                last = now()
                out.write(chunk)
                buf += chunk
                *lines, buf = buf.split(b"\n")
                for line in lines:
                    handle(line.decode(errors="replace"))
            if res["limited"] or res["auth"]:
                # opencode retries a limit or auth error by itself and stays silent. Stop it now.
                os.killpg(p.pid, signal.SIGKILL)
                break
            if now() - start > timeout or now() - last > idle:
                res["hang"] = True
                res["error"] = res["error"] or ("step timeout" if now() - start > timeout else "no output for %d s" % idle)
                os.killpg(p.pid, signal.SIGKILL)
                break
        if buf:
            handle(buf.decode(errors="replace"))
    p.wait()
    p.stdout.close()
    res["rc"] = p.returncode
    return res


def git(*args, cwd=None):
    r = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError("git %s: %s" % (" ".join(args[:2]), r.stderr.strip()[-300:]))
    return r.stdout.strip()


def ensure_worktree(root, task, state):
    name = str(task["repo"]).rstrip("/").split("/")[-1].removesuffix(".git")
    repo = root / name
    if not repo.exists():
        local = "://" in task["repo"] or task["repo"].startswith("/")
        url = task["repo"] if local else f"https://github.com/{task['repo']}.git"
        git("clone", url, str(repo))
    git("fetch", "origin", cwd=repo)
    if task.get("base"):
        base = "origin/" + str(task["base"]).removeprefix("origin/")
    else:
        try:
            base = git("symbolic-ref", "--short", "refs/remotes/origin/HEAD", cwd=repo)
        except RuntimeError:
            git("remote", "set-head", "origin", "-a", cwd=repo)
            base = git("symbolic-ref", "--short", "refs/remotes/origin/HEAD", cwd=repo)
    wt = root / "wt" / task["slug"]
    if not wt.exists():
        state.setdefault("branch", "hermes/%s-%s" % (time.strftime("%Y-%m-%d"), task["slug"]))
        git("worktree", "add", str(wt), "-b", state["branch"], base, cwd=repo)
        state["base"] = base
    common = Path(git("rev-parse", "--git-common-dir", cwd=wt))
    exclude = (common if common.is_absolute() else wt / common) / "info" / "exclude"
    exclude.parent.mkdir(parents=True, exist_ok=True)
    if ".hermes/" not in (exclude.read_text() if exclude.exists() else ""):
        with open(exclude, "a") as f:
            f.write(".hermes/\n")
    (wt / ".hermes").mkdir(exist_ok=True)
    return wt


def notify(text):
    token, users = os.environ.get("TELEGRAM_BOT_TOKEN"), os.environ.get("TELEGRAM_ALLOWED_USERS")
    if not token or not users:
        return
    data = urllib.parse.urlencode({"chat_id": users.split(",")[0].strip(), "text": text}).encode()
    try:
        urllib.request.urlopen(f"https://api.telegram.org/bot{token}/sendMessage", data, timeout=15)
    except Exception as e:  # a failed message must not fail the task
        print("notify failed:", type(e).__name__, file=sys.stderr)


class Task:
    def __init__(self, cfg, task, limits):
        self.cfg, self.t, self.limits = cfg, task, limits
        self.dir = cfg["root"] / "tasks" / task["slug"]
        try:
            self.state = json.loads((self.dir / "state.json").read_text())
        except (OSError, ValueError):
            self.state = {"status": "new", "steps": {}}

    def save(self, status=None, **extra):
        if status in ("done", "failed", "limited") and status != self.state.get("notified"):
            notify(self.message(status, extra))
            self.state["notified"] = status
        if status:
            self.state["status"] = status
        self.state.update(extra)
        write_atomic(self.dir / "state.json", json.dumps(self.state, indent=1))
        self.write_status()

    def message(self, status, extra):
        s = f"Hermes task {self.t['slug']}: {status}."
        if extra.get("retry_after"):
            s += " Every model is cooling down until " + time.strftime("%H:%M UTC", time.gmtime(extra["retry_after"])) + "."
        if extra.get("reason"):
            s += " " + extra["reason"]
        return s + f" Details: {self.t['slug']}-status.md"

    def write_status(self):
        st = self.state
        rows = "\n".join(
            "| {} | {} | {} | {} | {} | {:.2f} |".format(
                s["id"], st["steps"].get(s["id"], {}).get("status", "pending"),
                st["steps"].get(s["id"], {}).get("attempts", 0),
                st["steps"].get(s["id"], {}).get("model", ""),
                st["steps"].get(s["id"], {}).get("session", ""),
                st["steps"].get(s["id"], {}).get("cost", 0.0))
            for s in self.t["steps"])
        extra = ""
        if st.get("retry_after"):
            extra += "Retry after: %s UTC\n" % time.strftime("%Y-%m-%d %H:%M", time.gmtime(st["retry_after"]))
        if st.get("reason"):
            extra += "Reason: %s\n" % st["reason"]
        text = (
            "---\ntype: task-status\ntitle: \"%s status\"\n"
            "description: \"Which steps of Hermes task %s are done, on which model, and what blocks it.\"\n"
            "updated: %s\n---\n\n# %s\n\nState: **%s**\n\nBranch: %s\n\n%s\n"
            "| step | status | attempts | model | session | cost USD |\n|---|---|---|---|---|---|\n%s\n"
        ) % (self.t["slug"], self.t["slug"], time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
             self.t["slug"], st["status"], st.get("branch", ""), extra, rows)
        write_atomic(self.cfg["status_dir"] / f"{self.t['slug']}-status.md", text)

    def last_note(self):
        notes = [r["note"] for r in self.state["steps"].values() if r.get("note")]
        return notes[-1][:300] if notes else ""

    def pick(self):
        for m in self.t["models"]:
            if self.limits.available(provider(m)):
                return m
        return None

    def prompt(self, step, rec):
        parts = [self.t["body"], "## Step %s\n%s" % (step["id"], step["prompt"]), HANDOFF]
        if rec.get("note"):
            parts.append("The last attempt did not pass. What it reported:\n" + rec["note"])
        return "\n\n".join(p for p in parts if p)

    def run(self):
        wt = ensure_worktree(self.cfg["root"], self.t, self.state)
        self.save("running", reason="")
        for step in self.t["steps"]:
            rec = self.state["steps"].setdefault(step["id"], {"status": "pending", "attempts": 0})
            while rec["status"] != "done":
                if rec["attempts"] >= int(self.t.get("max_attempts_per_step", 2)):
                    rec["status"] = "failed"
                    return self.save("failed", reason=f"step {step['id']} failed {rec['attempts']} times: {rec.get('note', '')[-200:]}")
                model = self.pick()
                if not model:
                    until = min(self.limits.until(provider(m)) for m in self.t["models"])
                    return self.save("limited", retry_after=until, reason=self.last_note())
                self.attempt(step, rec, model, wt)
                self.save()
        return self.save("done", reason="", retry_after=None)

    def attempt(self, step, rec, model, wt):
        prov = provider(model)
        resume = rec.get("session") if rec.get("model") == model and self.state.get("inflight") else None
        rec["model"] = model
        self.state["inflight"] = {"step": step["id"], "model": model}
        self.save()

        def remember(sid):
            rec["session"] = sid
            self.save()

        self.limits.count(prov)
        n = rec["attempts"] + 1
        res = run_worker(
            model, self.prompt(step, rec), wt, self.dir / "runs" / f"{step['id']}-{n}-{prov}.jsonl",
            resume, float(step.get("timeout_min", 30)) * 60, float(step.get("idle_min", 10)) * 60, remember)
        rec["cost"] = rec.get("cost", 0.0) + res["cost"]
        if res["limited"] or res["auth"] or res["hang"]:
            # Not the model's fault in the sense of an attempt: cool the provider and move on.
            self.limits.strike(prov, retry_after=21600 if res["auth"] else None)
            rec["note"] = f"{model}: {res['error']}"
            return
        if res["rc"] == 0 and step.get("check"):
            try:
                r = subprocess.run(["bash", "-c", step["check"]], cwd=wt, env=worker_env(), stdin=subprocess.DEVNULL, capture_output=True,
                                   text=True, timeout=int(step.get("check_timeout_min", 30)) * 60)
                failed, out = r.returncode != 0, r.stdout + r.stderr
            except subprocess.TimeoutExpired:
                failed, out = True, "timed out"
            if failed:
                rec["attempts"] += 1
                rec["note"] = "check `%s` failed:\n%s" % (step["check"], out[-1500:])
                return
        elif res["rc"] != 0:
            rec["attempts"] += 1
            rec["note"] = f"{model} exited {res['rc']}: {res['error']}"
            return
        self.limits.ok(prov)
        self.state["notified"] = None
        rec.update(status="done", note="", finished=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()))
        self.state.pop("inflight", None)


def main():
    cfg = {
        "root": Path(os.environ["HERMES_TASK_ROOT"]),
        "inbox": Path(os.environ["HERMES_TASK_INBOX"]),
        "status_dir": Path(os.environ["HERMES_TASK_STATUS_DIR"]),
    }
    limits = Limits(cfg["root"] / "limits.json", json.loads(os.environ.get("HERMES_PROVIDER_CAPS", "{}")))
    for f in sorted(cfg["inbox"].glob("*.md")):
        try:
            task = parse_task(f)
            problem = validate(task)
            if problem:
                write_atomic(cfg["status_dir"] / f"{f.stem}-status.md",
                             "---\ntype: task-status\ntitle: \"%s status\"\ndescription: \"Why Hermes task %s was not started.\"\n---\n\nState: **blocked**\n\nReason: %s\n" % (f.stem, f.stem, problem))
                continue
            t = Task(cfg, task, limits)
            if t.state["status"] in ("done", "failed"):
                continue
            t.run()
        except Exception as e:  # one bad task must not stop the others
            print(f"{f.name}: {type(e).__name__}: {e}", file=sys.stderr)
            write_atomic(cfg["status_dir"] / f"{f.stem}-status.md",
                         "---\ntype: task-status\ntitle: \"%s status\"\ndescription: \"Why Hermes task %s stopped with an error.\"\n---\n\nState: **error**\n\nReason: %s: %s\n" % (f.stem, f.stem, type(e).__name__, e))


if __name__ == "__main__":
    main()
