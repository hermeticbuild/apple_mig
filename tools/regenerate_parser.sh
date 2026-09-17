#!/usr/bin/env bash
set -euo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly repo_root="$(cd "${script_dir}/.." && pwd)"
readonly source_dir="${repo_root}/migcom.tproj"
readonly scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/apple-mig-parser.XXXXXX")"

cleanup() {
    rm -rf "${scratch_dir}"
}
trap cleanup EXIT

case "${1:-}" in
    "") readonly mode="check" ;;
    --write) readonly mode="write" ;;
    *) echo "usage: $0 [--write]" >&2; exit 2 ;;
esac

if [[ "$(/usr/bin/bison --version | head -1)" != "bison (GNU Bison) 2.3" ]]; then
    echo "Apple Bison 2.3 is required" >&2
    exit 1
fi
if [[ "$(/usr/bin/flex --version)" != "flex 2.6.4 Apple(flex-35)" ]]; then
    echo "Apple Flex 2.6.4 (flex-35) is required" >&2
    exit 1
fi

cp "${source_dir}/parser.y" "${source_dir}/lexxer.l" "${scratch_dir}/"
(
    cd "${scratch_dir}"
    /usr/bin/bison -d -o parser.c parser.y
    /usr/bin/flex -o lexxer.c lexxer.l
)

for generated_file in lexxer.c parser.c parser.h; do
    if [[ "${mode}" == "write" ]]; then
        cp "${scratch_dir}/${generated_file}" "${source_dir}/${generated_file}"
    else
        cmp "${scratch_dir}/${generated_file}" "${source_dir}/${generated_file}"
    fi
done

if [[ "${mode}" == "write" ]]; then
    echo "updated generated parser sources"
else
    echo "generated parser sources are reproducible"
fi
