# sec-02 · Secret "deleted" last week is still in the repo

Security · Level 2 · about 20 min · Maps to: CKS (supply chain security) · Tags: security

## The ticket

> **Security Alert — payments-service — secret still in repository**
>
> A secret scanner flagged `DBB_DEMO_GIT_SECRET_NOT_REAL_02` in `workspace/sec-02/repo`.
> The team already ran `git rm .env` and committed the deletion last week, so `.env`
> is no longer in the working tree, yet the scanner still fails.

## What you see

```
$ ls -la workspace/sec-02/repo
total 16
drwxr-xr-x@  5 sivajyothipamarthy  staff  160 Nov 16 04:50 .
drwxr-xr-x@  6 sivajyothipamarthy  staff  192 Nov 16 04:50 ..
drwxr-xr-x@ 12 sivajyothipamarthy  staff  384 Nov 16 04:50 .git
-rw-r--r--@  1 sivajyothipamarthy  staff   35 Nov 16 04:50 README.md
-rw-r--r--@  1 sivajyothipamarthy  staff   10 Nov 16 04:50 app.conf

$ git -C workspace/sec-02/repo log --oneline
0a0cf72 Update README
05b4924 Remove accidental .env file
37b944e Add service config
6c8e76b Initial commit
```

## Your goal

`./dbb check` verifies each of these:

- [ ] `workspace/sec-02/repo` remains a valid git repository with `README.md` and `app.conf` intact
- [ ] No reachable commit contains `DBB_DEMO_GIT_SECRET_NOT_REAL_02`
- [ ] `.gitignore` excludes `.env`

## Predict first

Before you type anything: `.env` was removed with `git rm .env` and committed. Why
can anyone who clones the repo still read `DBB_DEMO_GIT_SECRET_NOT_REAL_02`?

## Skills you'll practise

`git log -S` · git object immutability · history rewriting (`git filter-branch` / `git filter-repo`) · `git gc --prune=now` · `.gitignore`
