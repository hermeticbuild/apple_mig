#!/usr/bin/env bash
set -euo pipefail

readonly tag="${1:?release tag is required}"
readonly version="${tag#v}"
readonly module_version="$(sed -n 's/^[[:space:]]*version = "\([^"]*\)",/\1/p' MODULE.bazel)"

if [[ "${tag}" == "${version}" ]]; then
    echo "release tag must start with v: ${tag}" >&2
    exit 1
fi
if [[ "${module_version}" != "${version}" ]]; then
    echo "MODULE.bazel version ${module_version} does not match tag ${tag}" >&2
    exit 1
fi

readonly prefix="apple_mig-${version}"
readonly archive="${prefix}.tar.gz"

git archive --format=tar --prefix="${prefix}/" "${tag}" | gzip -n > "${archive}"

cat <<EOF
## Bzlmod

Add to your \`MODULE.bazel\`:

\`\`\`starlark
bazel_dep(name = "apple_mig", version = "${version}")
\`\`\`
EOF
