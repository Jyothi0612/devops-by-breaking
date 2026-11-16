# sec-01 · Scan: secret found in image

Security · Level 2 · about 20 min · Maps to: CKS (supply chain security) · Tags: security

## The ticket

> **CI Security Gate — dbb-sec-01:app — secret detected in image**
>
> The image scanner flagged `DBB_DEMO_SECRET_NOT_REAL_01` inside `dbb-sec-01:app`.
> The developer checked `docker run --rm dbb-sec-01:app ls -la /app` and `.env` is
> not there, because the `Dockerfile` runs `RUN rm -f /app/.env`.

## What you see

```
$ cat workspace/sec-01/Dockerfile
FROM busybox:1.37
LABEL dbb.lab=sec-01
WORKDIR /app
COPY . /app
RUN rm -f /app/.env
CMD ["sh", "/app/app.sh"]

$ docker history dbb-sec-01:app --no-trunc | head -n 5
IMAGE                                                                     CREATED          CREATED BY                                  SIZE      COMMENT
sha256:d525eea6c618c693c536922503e00225ee48ed185dd9f92104ce0f79dfd5d7ad   32 minutes ago   CMD ["sh" "/app/app.sh"]                    0B        buildkit.dockerfile.v0
<missing>                                                                 32 minutes ago   RUN /bin/sh -c rm -f /app/.env # buildkit   16.4kB    buildkit.dockerfile.v0
<missing>                                                                 32 minutes ago   COPY . /app # buildkit                      32.8kB    buildkit.dockerfile.v0
<missing>                                                                 32 minutes ago   WORKDIR /app                                8.19kB    buildkit.dockerfile.v0
```

## Your goal

`./dbb check` verifies each of these:

- [ ] Rebuilt image `dbb-sec-01:app` runs and prints `orders-worker ready`
- [ ] No layer of `dbb-sec-01:app` contains `DBB_DEMO_SECRET_NOT_REAL_01`
- [ ] `.dockerignore` excludes `.env` from the build context

## Predict first

Before you type anything: `.env` is deleted inside the `Dockerfile`, so it is absent
when a container starts. Why can an image scanner still extract the secret?

## Skills you'll practise

OCI image layers · `docker history` · `docker save` inspection · `.dockerignore` · build context hygiene
