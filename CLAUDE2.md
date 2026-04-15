---
name: Fix Go LTF start-point with external dependencies
description: Step-by-step process for fixing a Go LTF whose test framework is an external module (e.g. testify, goconvey). Covers build cache pre-warming, go.mod/go.sum, and cyber-dojo.sh env vars.
type: project
---

## Context

Each cyber-dojo test run is 100% stateless — a fresh container, no internet access, no caching
between runs. Go LTFs that use external modules (e.g. testify, goconvey) fail or time out unless
the Docker image pre-compiles those modules into a shared build cache.

**Why:** The container has no internet access, so Go must not contact proxy.golang.org or
sum.golang.org. Compilation from source on amd64-emulated-on-ARM takes ~15s (over the limit)
unless the build cache is pre-warmed.

**How to apply:** Follow the steps below whenever a Go LTF start-point is missing go.mod/go.sum,
has an empty go.sum, or times out because its external module is compiled cold every run.

---

## Step 1 — Fix the languages repo `docker/install.sh`

Replace its contents with this pattern:

```bash
#!/bin/bash -Eeu

mkdir cdl && cd cdl

go mod init cdl-go-<name>

cat > dummy.go << 'EOF'
package cdl
import _ "github.com/<org>/<module>/..."
EOF

# Download module and all deps, resolve versions, populate go.mod and go.sum
go mod tidy

# Pre-compile into a shared build cache accessible by all users (including sandbox uid 41966)
mkdir /go/build-cache
GOCACHE=/go/build-cache go build ./...
chmod -R 777 /go/build-cache

rm dummy.go
# Do NOT run go mod tidy again — it would remove the module from go.mod (no .go files left)
```

**Key points:**
- `go mod init` + dummy import + `go mod tidy` resolves the correct module version automatically
- `mkdir /go/build-cache` + `go build ./...` compiles the module during image build
- `chmod -R 777` makes the cache readable by the `sandbox` user (uid 41966) at runtime
- Remove `dummy.go` after building; do NOT re-run `go mod tidy` or the require will be stripped

## Step 2 — Build the new Docker image

From the languages repo:

```bash
./pipe_build_up_test.sh
```

Note the tag from the output line: `Successfully tagged to ghcr.io/cyber-dojo-languages/go_<name>:<SHA>`

## Step 3 — Create `start_point/go.mod`

```
module cdl-go-<name>

go 1.26.1

require github.com/<org>/<module> v<VERSION>

require (
    <indirect dep 1> // indirect
    <indirect dep 2> // indirect
    ...
)
```

The direct module version and indirect deps come from the `pipe_build_up_test.sh` build output
(lines like `go: downloading github.com/... v...`).

## Step 4 — Create `start_point/go.sum`

Fetch hashes from the public checksum database for each module (direct + all indirect):

```
https://sum.golang.org/lookup/<module>@<version>
```

Each response contains two lines to copy into go.sum:
```
github.com/foo/bar vX.Y.Z h1:<HASH>=
github.com/foo/bar vX.Y.Z/go.mod h1:<HASH>=
```

## Step 5 — Fix `start_point/cyber-dojo.sh`

```bash
#!/bin/bash

# There is no internet access so do not contact any module proxy
# to download or resolve modules.
export GOPROXY=off
# There is no internet access so do not verify any module's checksum
# against the public checksum database (sum.golang.org)
export GONOSUMDB='*'
# Use cache pre-populated in the docker image we are running in.
export GOCACHE=/go/build-cache

go test
```

**Why each env var:**
- `GOPROXY=off` — prevents hanging on proxy.golang.org (no internet, would timeout ~15s)
- `GONOSUMDB='*'` — prevents hanging on sum.golang.org (same reason)
- `GOCACHE=/go/build-cache` — points to the pre-compiled artifacts from Step 1

## Step 6 — Update `start_point/manifest.json`

- Set `image_name` to the new SHA tag from Step 2
- Add `go.mod` and `go.sum` to `visible_filenames`

## Step 7 — Run `run_tests.sh`

From the start-points repo:

```bash
./run_tests.sh
```

Expected output: red PASSED, amber PASSED, green PASSED.

---

## Completed examples

| LTF | Languages repo SHA | Module | Module version |
|-----|--------------------|--------|----------------|
| go-testify | a07ae06 | github.com/stretchr/testify | v1.11.1 |
| go-convey | 3026f1d | github.com/smartystreets/goconvey | v1.8.1 |
