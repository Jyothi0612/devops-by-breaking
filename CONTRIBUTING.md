# Contributing a lab

A good lab is a failure you have actually seen, reduced to the smallest system that
still shows it.

## The bar

Your pull request is ready when these pass:

```
tools/lint-lab.sh
bash tests/proof.sh
./dbb verify <your-lab-id>
```

`verify` proves five things: the lab starts broken, every shortcut in `solution/cheats/`
is rejected, `solution/fix.sh` passes the check, the fix survives `survive.sh` (if the
lab has one), and nothing is left behind.

## Layout

```
labs/<track>-<nn>-<symptom-slug>/
  lab.env                 TITLE TRACK LEVEL MINUTES RUNTIME TAGS MAPS_TO RELEASE
  README.md               the ticket
  setup.sh                build the healthy system, then break it
  check.sh                outcome checks
  hints.txt               exactly 3 hints, separated by a line containing ---
  survive.sh              optional: restart something, the fix must still hold
  files/                  anything copied into the lab
  captures/               real output from the broken lab
  solution/SOLUTION.md    8 fixed sections (copy an existing lab)
  solution/fix.sh         the answer key
  solution/cheats/*.sh    shortcuts that must FAIL the check
```

Copy the closest existing lab and change it.

## Rules

1. **Name the folder after the symptom, never the cause.** `lnx-01-disk-full-du-empty`,
   not `lnx-01-deleted-open-file`.
2. **Check outcomes, not methods.** If two different fixes are both correct, both must
   pass. Never grep for a specific command.
3. **Every lab has at least one cheat.** Think about what a tired engineer would do to
   make the alert go away, and make the check reject it.
4. **No guessed output.** Everything under "What you see" is pasted from a real run and
   saved in `captures/`.
5. **Checks never sleep blindly.** Use `wait_for <seconds> <command>`.
6. **bash 3.2.** No associative arrays, no `mapfile`, no `${var,,}`.
7. **Pin every image** in `images.lock`. Labs must work with no network after the first start.
8. **Fake secrets must look fake.** Never use a real key format.
9. **Further reading links to official documentation only.**

## Helpers available in lab scripts

| Runtime | Helpers |
|---|---|
| `server` | `srv <cmd>`, `srv_sh '<script>'`, `srv_put <file> <path>` |
| `k8s` | `k <kubectl args>`, `k_apply <file>` |
| `terraform` | `tf <args>`, `tf_sh '<script>'`, files live in `$DBB_WORK` |
| all | `check "<objective>" <cmd>`, `wait_for <secs> <cmd>`, `state_set <key> <value>`, `state_get <key>` |

Check scripts must finish successfully and emit objectives through `check`. A nonzero
script exit or no objectives is a checker error (exit 2), not a broken-lab result
(exit 1). Cheat and restart scripts must also exit successfully for `verify` to
accept their evidence.
