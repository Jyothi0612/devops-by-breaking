# Build progress

Reviewed 2026-11-16 against the local v2 build plan. The v0.1 foundation is public.
The `v0.2/docker-labs` branch contains all 20 planned v0.3 lab implementations
(including the 12 v0.2 labs), at baseline `f264e78`. Seventeen additions beyond
v0.1 await the author gate. Implementation is not release readiness.

## Implemented

- Bash 3.2 CLI: doctor, list/filter, next, start, shell/exec, hints, check,
  reset, solution, status, stop/nuke, and verify.
- JSON output for list, start, check and status; local progress and workspaces.
- Server (Rocky/systemd with private cgroups), Kubernetes (k3s), Docker, offline
  Terraform and Ansible runtimes; image lockfile and update helper.
- Twenty labs: lnx-01/03/05/07, net-01, ctr-01/02, k8s-01/02/04/06, tf-01/02,
  sec-01..05 and ans-01/02.
  Each has a ticket, captures, hints, solution and shortcut scripts. Thirteen have
  explicit restart-survival scripts; lnx-01, tf-01/02, ans-01/02 and sec-01/02 do
  not. AI-drafted interview answers are available; author review remains pending.
- Lab lint, generated README catalog, two-architecture CI and manual soak input.
- README, contribution guide, security explanation and runtime overview.
- Public repository: https://github.com/Jyothi0612/devops-by-breaking

## Evidence

The original commit passed the [five-run soak on both architectures](https://github.com/Jyothi0612/devops-by-breaking/actions/runs/43720119803):
three labs × five runs × amd64/arm64 = 30 successful verification runs.
This evidence applies to `34a8e70`, not subsequent local edits.

The continuation adds regression coverage for false-green proof results:

- A checker exiting nonzero or emitting no objectives returns environment/error
  code 2, rather than being accepted as a normal broken-lab result.
- Verification rejects checker errors during broken and shortcut phases.
- Shortcut and restart scripts exiting nonzero fail verification.
- `bash tests/proof.sh` runs without Docker and is included in Bash 3.2 CI.

Local validation of the continuation on macOS arm64 with Docker:
`./dbb verify all` passed all three labs, including all seven shortcut scripts,
the Kubernetes restart check and per-lab cleanup. All 12 regression checks passed
both locally and in the pinned Bash 3.2 container. ShellCheck, shell syntax checks,
lab lint and the README catalog check passed. The harness changes were pushed to
main as `0f43231`, followed by test-lint compatibility fix `a8c1dcf`.

The strengthened harness at `a8c1dcf` passed the
[five-run soak on both architectures](https://github.com/Jyothi0612/devops-by-breaking/actions/runs/43764290233):
30 successful verification runs, plus lint and the Bash 3.2 regression suite.

The full development branch at `55a2970` passed its
[five-run soak on both architectures](https://github.com/Jyothi0612/devops-by-breaking/actions/runs/43764330533):
five labs × five runs × two architectures = 50 successful verification runs.
Later documentation-only commits record these results; executable code is unchanged.

## Open gates and gaps

- No tagged release exists as of this review.
- No evidence of the author's blind solves, review of the interview drafts or
  explanation of each shortcut. CI does not replace this author gate.
- GHCR publishing workflow and pull-first server fallback exist; published-image
  availability and clean-machine performance still need recorded evidence.
- No Codespaces configuration or recorded runtime spike there.
- A VHS demo tape exists, but no rendered demo GIF, timed clean-machine quickstart
  or outside tester evidence is recorded.
- Restart-survival coverage needs a documented per-runtime policy: restarting
  orders-api violates lnx-01's explicit same-process objective, while Terraform
  already starts a fresh tool container for each command.
- Older runtimes still trust an existing local tag (the Docker runtime uses the
  digest directly); enforcing the lockfile
  digest even when a tag already exists remains a runtime hardening task.
- Ansible runtime, security labs, learning paths and an initial agent harness exist.
  Agent mode now has a containerized runner, broker-side budgets and whole-agent
  cleanup for four runtimes; Docker-runtime support and privileged-lab isolation
  remain open. See `AGENTS.md` and `IMPLEMENTATION-STATUS.md`. Incidents, scaffold command and the remaining
  curriculum are not implemented.

## Next build slices

1. Complete the author solve-through checklist before merging the new labs.
   Keep release evidence tied to the exact tested commit.
2. Resolve restart semantics and image-cache digest enforcement; record the
   author gate separately from automated checks.
3. Finish v0.2 packaging and usability gates: GHCR images, demo GIF and
   clean-machine quickstart evidence. The twenty lab implementations are present.
4. Harden agent isolation and execution limits before calling v0.3 complete.
   Reset, progress, catalog generation, Ansible and learning paths already exist.

The full roadmap remains in the local, gitignored `PLAN.md`; this file tracks
what is actually present and which release claims still need evidence.

## Docker lab continuation

The development branch adds a host-workspace Docker runtime using the existing pinned
nginx image, without adding Compose or curl to the prerequisites. Both labs proved
the healthy state before introducing one fault, and passed local verification with
shortcut rejection, a post-fix restart and cleanup. Captures are from actual local
runs; the port lab recorded an empty reply rather than assuming a particular curl error.

The initial harness CI run exposed an older ShellCheck diagnostic for test function
overrides. A test-only compatibility annotation addresses it; all 12 regression tests
still pass. The Docker jobs at `55a2970` passed five runs per lab on amd64 and arm64
(20 successful verifications), including restart survival and cleanup.
See the [development branch soak](https://github.com/Jyothi0612/devops-by-breaking/actions/runs/43764330533).

Use [AUTHOR-CHECKLIST.md](AUTHOR-CHECKLIST.md) to record all seventeen new blind solves.

## Remaining v0.2 lab review

The seven additional drafts were reviewed against the plan and exercised locally.
The Terraform count scenario now ties each token to its service name, so removing
the middle item actually plans a replacement. Its check accepts repairs that preserve
the two surviving tokens without requiring one particular HCL construct.

The Kubernetes image-pull lab fails against a local, unavailable registry mirror
instead of requiring internet access. Setup must observe the expected broken pod
state, and the ConfigMap lab checks for stable restart counts after repair.

All seven additional labs passed local verification, with shortcut rejection, fixes
and cleanup. Six include restart checks; Terraform invokes a fresh tool container
for every command. The existing Kubernetes Service lab also passed against the
updated runtime. The offline image-pull fixture produced a generated registry
configuration with only the loopback endpoint, then passed repair and restart.

Full two-architecture CI evidence for this expansion is pending below. The earlier
50-run result applies only to the five-lab checkpoint, not to these seven additions.

## 2026-11-16 continuation review

Reviewed baseline `f264e78` and continued locally without merging or publishing.
The previous status text lagged behind the eight v0.3 additions. The README,
author checklist and this progress record now reflect twenty implemented labs.

Fixed two user-visible regressions:

- Agent results preserve the checker's exit code and derive overall success from
  it. A passing objective no longer makes a failed lab pass. Invalid limits fail
  before startup, and a failed start does not stop an existing learner lab.
- Learning paths use the existing lab lookup helper, so an unsolved path suggests
  the next lab instead of incorrectly claiming completion. Path names match
  literally rather than as regular expressions.

All 23 regression cases passed locally and in the pinned Bash 3.2 container
(12 proof checks, 7 agent-run checks, 4 path checks). ShellCheck, shell parsing,
lab lint, README catalog validation and `git diff --check` passed. These results
apply to the uncommitted continuation, not a published release or a new CI soak.

Agent mode still needs actual solution isolation, process-tree timeout and atomic
command accounting. The current directory/shim approach is documented as a
cooperative-agent harness, not a completed isolation boundary. The author gate
remains pending and has not been inferred from scripted verification.

The local arm64 `verify all` audit completed all twenty lab proof sequences:
broken states, all shipped shortcuts, repairs, thirteen restart scripts and cleanup
all reported success. After printing `All verified.`, the long-running shell
exited 2 while resuming reads of `dbb`, which had been edited during the run.
This is **not a clean exit-zero full-suite run**. The final CLI passes syntax
validation. A fresh `./dbb verify ctr-01` passed with exit 0 on the final CLI,
including shortcut rejection, repair, restart and cleanup. No labelled containers,
networks or volumes remained after verification. Its log is alongside the audit
log as `verify-ctr-01.log`.
The audit log is retained locally in `.dbb/review-2026-11-16/verify-all.log`.
A clean full-suite run and both-architecture soak remain release gates.

## Content corrections and interview drafts

At the author's request, AI-drafted conversational practice answers now appear in
all twenty solutions. They describe a troubleshooting approach rather than invent
personal incident experience. The local plan and author checklist allow AI drafting;
review, blind solves and explaining shortcuts remain separate author gates.

Corrected the Terraform `prevent_destroy` claim: it cannot protect an old address
whose configuration has been removed or renamed. Replaced the nginx status-label
and Kubernetes endpoint alert examples with explicitly configured HTTP probes;
explained the SSH alert's custom log-derived counter and collection prerequisites.
The Kubernetes solution now distinguishes a captured timeout from universal network
behavior and clarifies that dry-run does not create a preview environment.

The Ansible idempotency checker now tests creation, drift repair, truthful change
reporting and convergence instead of grepping for forbidden YAML. It rejects a new
shortcut that reports directory creation but hides configuration repairs. Read-only
`changed_when: false` tasks are valid. The ticket and solution describe these outcomes.

`./dbb verify ans-01` passed with all three shortcuts rejected and cleanup complete.
ShellCheck, Bash 3.2 parsing, lab lint and catalog checks passed for this continuation.

The real-Docker acceptance regression also passed with a read-only command marked
`changed_when: false`. It is included in both architectures’ ans-01 CI jobs and
uses the checker directly so it does not record an automated run as a learner solve.

## Containerized agent continuation

The agent runner now separates the agent container from the trusted Docker broker.
It no longer starts an arbitrary command as the host user or exposes a workspace
symlink. Broker-owned atomic budgets, deadline handling, whole-agent cleanup and
failure-aware scoring replace the cooperative host shim. Server, k3s, Terraform
and Ansible command routes are implemented. Docker-runtime labs fail closed because
their host-shell commands cannot safely be exposed through this interface.

This is ordinary solution-file separation, not hostile-code isolation: privileged
server/k3s lab commands remain powerful. See `AGENTS.md` and `SECURITY.md` for the
boundary, network defaults and remaining restrictions. Scripted repairs are not
real AI benchmark results or human solves. New tests are wired into CI, but no new
remote CI or soak evidence is claimed.

The complete handoff requested by the author is
[IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md), covering completed work,
validation evidence, remaining engineering tasks, author work and release gates.
