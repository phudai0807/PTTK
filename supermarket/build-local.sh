#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

for tool in javac jar; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing $tool. Install JDK 21 before building." >&2
        exit 1
    fi
done

mkdir -p build
staging=$(mktemp -d "$PWD/build/war-linux-XXXXXXXX")
trap 'rm -rf -- "$staging"' EXIT
classes="$staging/WEB-INF/classes"
mkdir -p "$classes"

mapfile -d '' sources < <(find src -type f -name '*.java' -print0)
if ((${#sources[@]} == 0)); then
    echo 'No Java source files found in src.' >&2
    exit 1
fi

javac --release 21 -encoding UTF-8 \
    -cp 'WebContent/WEB-INF/lib/*' -d "$classes" "${sources[@]}"
jar --create --file "$staging/supermarket.war" \
    -C WebContent . -C "$staging" WEB-INF/classes

mv -f -- "$staging/supermarket.war" build/supermarket.war
echo "Built $PWD/build/supermarket.war"
