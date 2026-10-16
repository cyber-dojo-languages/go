#!/bin/sh -eu

# Records the Go this image holds, in the shape every image shares. The
# installed toolchain is asked, so the version is one the image can run rather
# than one written down when someone last edited this file.
# go env GOVERSION prints "go1.27.1".
readonly LANGUAGE_VERSION=$(go env GOVERSION | cut -c3-)

if [ -z "${LANGUAGE_VERSION}" ]; then
  echo 'Could not read a version from go env GOVERSION' >&2
  exit 1
fi

cat > /versions.json <<EOF
{
  "language": {
    "name": "Go",
    "version": "${LANGUAGE_VERSION}"
  },
  "test_frameworks": []
}
EOF
