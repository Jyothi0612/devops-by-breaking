# sec-01 · Solution

## Root cause

`Dockerfile` runs `COPY . /app` and then `RUN rm -f /app/.env`. Because OCI image
layers are immutable and additive, `RUN rm` only adds a whiteout entry in a later
layer. The `.env` file and its secret (`DBB_DEMO_SECRET_NOT_REAL_01`) remain inside
the `COPY . /app` layer tarball.

## How to find it

Inspect the `Dockerfile`, `docker history`, and the exported image layers:

```sh
cat workspace/sec-01/Dockerfile
docker history dbb-sec-01:app --no-trunc
docker save dbb-sec-01:app | grep -a 'DBB_DEMO_SECRET_NOT_REAL_01'
```

The captured `docker history` in `captures/symptom.txt` shows `COPY . /app` followed by
`RUN rm -f /app/.env`.

## Fix

**Rotate first, then clean up:** if a real secret was ever pushed to a registry in an
image layer, rotate/revoke it immediately before rebuilding.

Add `.env` to `workspace/sec-01/.dockerignore` so the file never enters the build
context, and rebuild `dbb-sec-01:app`:

```sh
printf '.env\n' > workspace/sec-01/.dockerignore
(cd workspace/sec-01 && ./build.sh)
```

Then run `./dbb check` from the repository root.

## Why the obvious fix is wrong

- `delete-env-on-host`: deleting `.env` from the working directory without adding
  `.dockerignore` leaves the build unprotected the next time `.env` exists locally.
- `rm-layer-only`: rebuilding with `RUN rm -f /app/.env` still bakes `.env` into the
  earlier `COPY` layer.

## Prevention

Exclude `.env`, `*.pem`, and `.git` in `.dockerignore`, use BuildKit `--mount=type=secret`
for build-time credentials, and scan built images in CI (e.g. Trivy) before pushing.

## In production this looks like

A developer runs `docker build .` on a laptop or CI runner with `.env` or `.aws/` in
the directory, deletes it in a later `RUN` step, and pushes the image — exposing
credentials to anyone who pulls the image layers.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“Deleting a secret in a later image layer doesn't erase it from an earlier layer. I'd
rotate the credential first, exclude the file from the build context, and rebuild and
inspect the image. For build-time credentials, I'd use a secret mount instead of copying
them into the image.”

## Further reading

- [Docker: .dockerignore file](https://docs.docker.com/build/concepts/context/#dockerignore-files)
- [Docker: Build secrets](https://docs.docker.com/build/building/secrets/)
