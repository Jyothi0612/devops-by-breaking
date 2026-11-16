# Build progress

Reviewed 2026-11-16 against the local v2 build plan. The v0.1 foundation is public.
The `v0.2/docker-labs` branch contains all 12 planned v0.2 lab implementations.
Nine new labs await the author gate before merging; this is not a v0.2 release.

## Implemented

- Bash 3.2 CLI: doctor, list/filter, next, start, shell/exec, hints, check,
  reset, solution, status, stop/nuke, and verify.
- JSON output for list, start, check and status; local progress and workspaces.
- Server (Rocky/systemd with private cgroups), Kubernetes (k3s), and offline
  Terraform runtimes; image lockfile and update helper.
- Twelve labs: lnx-01/03/05/07, net-01, ctr-01/02, k8s-01/02/06 and tf-01/02.
  Each has a ticket, captures, hints, solution and shortcut scripts. All except
  lnx-01 and the Terraform labs have explicit restart-survival checks. New interview
  sections await the author's own answers.
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
- No evidence of the author's blind solves, personal interview answers or
  explanation of each shortcut. CI does not replace this author gate.
- No GHCR image publishing workflow; server images still build locally.
- No Codespaces configuration or recorded runtime spike there.
- No demo GIF, timed clean-machine quickstart or outside tester evidence.
- Restart-survival coverage needs a documented per-runtime policy: restarting
  orders-api violates lnx-01's explicit same-process objective, while Terraform
  already starts a fresh tool container for each command.
- Older runtimes still trust an existing local tag (the Docker runtime uses the
  digest directly); enforcing the lockfile
  digest even when a tag already exists remains a runtime hardening task.
- No Ansible runtime, security labs, incidents, agent harness,
  scaffold command, learning paths or remaining curriculum yet.

## Next build slices

1. Complete the author solve-through checklist before merging the new labs.
   Keep release evidence tied to the exact tested commit.
2. Resolve restart semantics and image-cache digest enforcement; record the
   author gate separately from automated checks.
3. Finish v0.2 packaging and usability gates: GHCR images, demo GIF and
   clean-machine quickstart evidence. The twelve lab implementations are present.
4. Add GHCR publishing and the demo GIF. Reset, progress tracking and the
   catalog generator are already implemented; do not rebuild them.

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

Use [AUTHOR-CHECKLIST.md](AUTHOR-CHECKLIST.md) to record all nine new blind solves.

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
