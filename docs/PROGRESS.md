# Build progress

Reviewed 2026-11-15 against the local v2 build plan and commit `34a8e70`.
The project is at the v0.1 foundation stage, with some v0.2 CLI work already present.

## Implemented

- Bash 3.2 CLI: doctor, list/filter, next, start, shell/exec, hints, check,
  reset, solution, status, stop/nuke, and verify.
- JSON output for list, start, check and status; local progress and workspaces.
- Server (Rocky/systemd with private cgroups), Kubernetes (k3s), and offline
  Terraform runtimes; image lockfile and update helper.
- Three labs: lnx-01, k8s-01 and tf-01, with tickets, captures, hints, solutions
  and shortcut scripts. Only k8s-01 currently has a restart-survival script.
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
lab lint and the README catalog check passed. These changes have not been pushed
or tested on the GitHub amd64/arm64 matrix yet.

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
- Image reuse currently trusts an existing local tag; enforcing the lockfile
  digest even when a tag already exists remains a runtime hardening task.
- No Docker or Ansible runtime, security labs, incidents, agent harness,
  scaffold command, learning paths or remaining curriculum yet.

## Next build slices

1. Run the strengthened harness in both-architecture CI and repeat the soak
   before claiming release evidence for these changes.
2. Resolve restart semantics and image-cache digest enforcement; record the
   author gate separately from automated checks.
3. Continue v0.2: add the Docker runtime and ctr-01/ctr-02, then lnx-03,
   lnx-05, lnx-07, net-01, k8s-02, k8s-06 and tf-02. Capture actual symptoms
   and prove every shortcut for each lab before counting it as shipped.
4. Add GHCR publishing and the demo GIF. Reset, progress tracking and the
   catalog generator are already implemented; do not rebuild them.

The full roadmap remains in the local, gitignored `PLAN.md`; this file tracks
what is actually present and which release claims still need evidence.
