# sec-02 · Solution

## Root cause

`git rm .env` only removed `.env` from `HEAD` and subsequent commits. The earlier
commit (`Add service config`) and its blob containing `DBB_DEMO_GIT_SECRET_NOT_REAL_02`
are still reachable in git history, so anyone who clones or runs `git log -p` can
recover the secret.

## How to find it

Search all commits in git history for the secret or `.env` path:

```sh
git -C workspace/sec-02/repo log --all -S DBB_DEMO_GIT_SECRET_NOT_REAL_02 -p
```

The captured output in `captures/symptom.txt` shows both the commit that added `.env`
and the commit that deleted it.

## Fix

**Rotate first, then clean up:** if a real secret was ever committed or pushed, rotate
and revoke it immediately — history rewriting alone does not un-expose a secret that
was already fetched or mirrored.

Rewrite git history to remove `.env` from every commit, expire reflogs, prune
unreachable objects, and add `.env` to `.gitignore`:

```sh
cd workspace/sec-02/repo
git filter-branch -f --index-filter \
  'git rm --cached --ignore-unmatch .env' --prune-empty -- --all
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
printf '.env\n' > .gitignore
git add .gitignore && git commit -m "Ignore .env files"
```

Then run `./dbb check` from the repository root.

## Why the obvious fix is wrong

- `delete-git-dir`: removing `.git` destroys the repository history instead of
  cleaning it.
- `gitignore-only`: adding `.env` to `.gitignore` prevents future commits of `.env`,
  but leaves the secret in past commits.

## Prevention

Use `.gitignore` from the first commit, enable pre-commit secret scanning (e.g.
gitleaks) and GitHub push protection, and never store `.env` files in git.

## In production this looks like

An engineer commits an API key or `.env` file, runs `git rm` in a follow-up commit,
and assumes it is gone — until a secret scanner or attacker pulls the earlier commit.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“Deleting a file in a new commit doesn't remove it from Git history. I'd revoke or
rotate the secret first, then coordinate history cleanup and check all relevant refs.
I'd add ignore rules and secret scanning too. Rewriting our copy can't make other
people's clones or cached copies forget the old secret.”

## Further reading

- [GitHub Docs: Removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Git: git-log(1) -S](https://git-scm.com/docs/git-log#Documentation/git-log.txt--Sltstringgt)
