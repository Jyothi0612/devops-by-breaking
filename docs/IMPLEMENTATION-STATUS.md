# Implementation status and next work

Updated: 2026-11-16 (Europe/Stockholm).

This is the handoff for the current local continuation of `devops-by-breaking`.
Baseline commit: `f264e78`, branch `v0.2/docker-labs`. Changes described below are
local and uncommitted; no release, merge or publication was performed. The local
`PLAN.md` is gitignored. This tracked document is the portable handoff.

## What the project is

A local DevOps troubleshooting curriculum. Each lab starts broken, gives the learner
a ticket, and checks the outcome. Maintainer verification proves the initial failure,
rejects shipped shortcuts, applies a reference repair, checks restart survival where
implemented, and cleans up resources. Scripted repairs do not establish blind solves.

## Implemented before this continuation

- Twenty lab implementations: all twelve planned through v0.2 plus eight v0.3 labs.
- Five runtimes: Rocky/systemd server, Docker, k3s, Terraform and Ansible.
- CLI for doctor, list/filter, start, shell/exec, hints, check, reset, solution,
  status, stop/nuke, next and verification; JSON output and local progress.
- Tickets, captures, hints, reference repairs and shortcut scripts for every lab.
- Thirteen explicit restart-survival scripts; no such script for lnx-01,
  tf-01/02, ans-01/02 or sec-01/02. Some need different durability semantics.
- Learning paths, README catalog generation, lab lint, shell checks and a CI matrix
  for amd64 and arm64 with a manual soak option.
- A GHCR server-image workflow, pull-first fallback and VHS demo tape.
  Their existence does not establish publication or a finished demo GIF.

| Track | Implemented labs |
|---|---|
| Linux | lnx-01, lnx-03, lnx-05, lnx-07 |
| Networking | net-01 |
| Containers | ctr-01, ctr-02 |
| Kubernetes | k8s-01, k8s-02, k8s-04, k8s-06 |
| Terraform | tf-01, tf-02 |
| Ansible | ans-01, ans-02 |
| Security | sec-01, sec-02, sec-03, sec-04, sec-05 |

## Completed during this continuation

### Progress and navigation

- Reconciled stale twelve-lab claims with the twenty implemented labs.
- Expanded the author checklist to cover all seventeen additions beyond v0.1.
- Fixed `dbb next`: it called a nonexistent lookup helper and falsely reported
  completed paths. Path names now match literally, not as regex patterns.
- Added navigation regression coverage and CI execution.

### Technical content

- Corrected the Terraform `prevent_destroy` rename claim. Protection does not
  survive removal of the old configuration; a move must be declared or performed.
- Corrected monitoring examples: nginx OSS request totals lack a status label;
  the SSH counter needs a log collector; HTTP probes need explicit exporter setup.
- Corrected the Kubernetes Service timeout generalization and clarified that a
  server-side dry-run does not populate a preview environment.
- Replaced the Ansible check's syntax ban with creation, drift-repair, truthful
  change-reporting and convergence checks. Added a shortcut that hides file changes
  and a positive test accepting a read-only `changed_when: false` task.
- Added conversational AI-drafted practice interview answers to all twenty labs,
  as requested. They do not invent personal experience. Updated the local plan and
  checklist to permit AI drafts while retaining author review and blind solves.

### Agent runner

- Replaced the host-process/temp-directory runner with a containerized agent and
  a separate trusted Docker broker. No host Python prerequisite was added.
- The agent receives only the ticket, shim and broker socket. It has no repository,
  answer-key, workspace, host-home or Docker-socket mount.
- Added non-root execution, read-only root filesystem, dropped capabilities,
  no-new-privileges, resource limits and default network isolation.
- Implemented broker-side atomic command reservations, serialized lab execution,
  bounded request/output sizes and a wall-clock deadline.
- Agent-container removal terminates its entire process tree, including detached
  children. Timeout, exceeded budget, failed agent exit and broker failures skip
  scoring and produce a failed result.
- Preserved checker exit status and per-objective results. Passing one objective
  never overrides overall failure. Agent output is retained for diagnosis.
- Refused existing learner sessions and concurrent agent runners; automated runs
  do not record learner solves. Added label-based cleanup.
- Routed commands for server, k3s, Terraform and Ansible through lab containers.
  Terraform/Ansible tools use the host user's numeric UID/GID for workspace files.
- Explicitly rejected the four Docker-runtime labs rather than exposing a host
  shell or unrestricted Docker daemon. See the remaining work below.
- Added unit, adversarial-input and real-Docker integration tests and CI steps.

## Validation evidence

See `PROGRESS.md` for older commit-specific CI links. Do not apply old soak results
to this uncommitted continuation.

- The earlier local audit completed all twenty lab proof sequences successfully.
  Its wrapper exited 2 after `All verified.` because `dbb` was edited while it was
  executing. This was **not a clean exit-zero full-suite run**. A fresh ctr-01 run
  subsequently passed with exit 0. Logs: `.dbb/review-2026-11-16/`.
- The content correction passed a fresh `./dbb verify ans-01`: three shortcuts
  rejected, repair accepted, cleanup complete. The valid read-only-task regression
  also passed without recording a learner solve.
- Nine agent broker unit tests passed: concurrent budgets, closed/deadline behavior,
  mount configuration, request schema, fixed-target routing, tool-user setup,
  cleanup failure reporting, scoring and framing.
- Live server tests passed: solution-file mount separation, reference repair,
  simultaneous requests with a three-command budget, timeout with a detached
  TERM-ignoring child, failed-agent scoring, preservation of an existing session,
  and resource cleanup.
- Real Terraform, Kubernetes and Ansible repairs passed through the broker.
  Ansible exposed a numeric-UID/OpenSSH incompatibility; trusted tool initialization
  now creates the required passwd entry and the repair test passes.
- ShellCheck, Bash 3.2 compatibility checks, shell regression tests, lab lint,
  README catalog validation and whitespace checks passed during this continuation.
- New amd64/arm64 CI runs and release soak have **not** been run or claimed here.

Agent integration logs are retained locally under `.dbb/review-2026-11-16/`
(`agent-integration.log`, `agent-terraform.log`, `agent-ansible.log`, and
`agent-kubernetes.log`). The most recent `results/lnx-01.json` may deliberately show
a failure from the negative test; inspect the integration log for its expected outcome.

These are scripted integration tests, not measurements of a real AI model's
troubleshooting ability, and not a full adversarial security audit.

## What still needs to be done

### Next engineering work

1. **Finish agent runtime coverage.** Implement constrained operations for ctr-01,
   ctr-02, sec-01 and sec-02. Their current host-shell/Docker paths are intentionally
   unsupported. Never solve this by mounting the Docker socket into the agent.
2. **Review the security boundary.** Privileged server/k3s lab commands can undermine
   host isolation. Current solution-file separation is for cooperative agents;
   adversarial agents need a disposable VM. Define that VM execution path before
   claiming hostile-code isolation.
3. **Real agent configuration.** Define a credential/provider interface without
   forwarding host home directories or baking secrets into images. Verify a real
   AI CLI; current evidence uses scripted reference repairs.
4. **Image-cache hardening.** Older runtimes still accept cached plain tags, and
   locally built image caches lack source/lock provenance checks. Enforce pinned
   references and define safe rebuild invalidation.
5. **Durability policy.** Document appropriate survival checks for all runtimes.
   Restarting orders-api contradicts lnx-01's same-process goal; Terraform already
   runs in fresh tool containers. Do not blindly add restarts to every lab.
6. **Final clean validation.** Freeze executable files, run `./dbb verify all` to
   exit 0, then run five consecutive verifications per lab on amd64 and arm64.
   Tie evidence to the exact committed code. Fix any failures before release.

### Packaging and release

- Verify GHCR publication, multi-architecture pulls and fallback behavior.
- Render and review the VHS demo GIF.
- Spike Codespaces runtimes; publish only verified support claims.
- Time a clean-machine quickstart and obtain macOS, Linux and WSL2 tester evidence.
- Review/commit the local changes, complete required author gates, then prepare
  release notes/changelog and a tag. No v0.3-complete claim yet.

### Author work

- Solve the seventeen new labs blind and record times/evidence in
  `AUTHOR-CHECKLIST.md`.
- Review the AI interview drafts and explain the concepts without reading them.
- Explain why each shortcut fails. Automated PASS results do not complete this gate.

### Later curriculum and community work

- Nineteen planned labs remain: twelve for v1.0 and seven for v1.1, including the
  multi-cause incidents. Follow the catalog in the local plan.
- Add the scaffold command, missing learning/reference docs, postmortem materials,
  issue templates, code of conduct and release/community assets from the plan.
- Complete a broader editorial and alternative-solution audit before claiming
  every explanation and every correct repair path has been validated.

## Useful commands

```sh
bash tests/proof.sh
bash tests/agent-run.sh
bash tests/paths.sh
tools/lint-lab.sh
tools/gen-index.sh --check

. ./images.lock
docker run --rm --network none -v "$PWD:/repo:ro" -w /repo "$IMG_ANSIBLE_BASE" python tests/agent_broker.py
bash tests/agent-integration.sh
bash tests/agent-runtimes.sh tf-01
bash tests/agent-runtimes.sh ans-01
bash tests/agent-runtimes.sh k8s-01
bash tests/ansible-content.sh

# Run only with no active learner lab, and do not edit scripts during execution:
./dbb verify all
```
