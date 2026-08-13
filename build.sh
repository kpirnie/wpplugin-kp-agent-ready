#!/usr/bin/env bash
set -euo pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC="${ROOT}/source"
DIST="${ROOT}/distribute"
OWNER="$( stat -c '%U' "${ROOT}" )"
GROUP="$( stat -c '%G' "${ROOT}" )"

# pull the version from the plugin header, the constant, and the readme stable tag
SLUG="$( grep -m1 'Text Domain:' "${SRC}"/*.php | sed 's/.*Text Domain:[[:space:]]*//' | tr -d '\r' )"
VERSION="$( grep -m1 '^ \* Version:' "${SRC}/${SLUG}.php" | sed 's/^ \* Version:[[:space:]]*//' | tr -d '\r' )"
STABLE="$( grep -m1 '^Stable tag:' "${SRC}/readme.txt" | sed 's/^Stable tag:[[:space:]]*//' | tr -d '\r' )"
NAME="$( grep -m1 '^ \* Plugin Name:' "${SRC}/${SLUG}.php" | sed 's/^ \* Plugin Name:[[:space:]]*//' | tr -d '\r' )"

# both have to match, otherwise we are shipping a mismatched release
if [ "${VERSION}" != "${STABLE}" ]; then
    echo "! version mismatch: plugin header ${VERSION} vs readme stable tag ${STABLE}"
    exit 1
fi

# both have to be non-empty, otherwise we are shipping a broken plugin
if [ -z "${NAME}" ] || [ -z "${SLUG}" ]; then
    echo "! could not read Plugin Name and/or Text Domain from the plugin header"
    exit 1
fi

# just a note
echo "# Building ${NAME} ${VERSION}"

# clean out the distribution
echo "# Cleaning Up Distribution"
rm -rf "${DIST}"
mkdir -p "${DIST}/languages"

# copy the php, the readme, the license, and the composer manifest
echo "# Working on Templates"
rsync -a --prune-empty-dirs \
    --include='*/' \
    --include='*.php' \
    --exclude='*' \
    "${SRC}/" "${DIST}/"
cp "${SRC}/readme.txt" "${DIST}/readme.txt"
cp "${SRC}/LICENSE" "${DIST}/LICENSE"

# ship the composer manifest and build the autoloader against the distributed tree
echo "# Working on Vendor"
cp "${ROOT}/composer.json" "${DIST}/composer.json"
composer install --no-dev --no-interaction --quiet \
    --optimize-autoloader --classmap-authoritative \
    --working-dir="${DIST}"
rm -f "${DIST}/composer.lock"

# generate the translation template
echo "# Working on Languages"
wp i18n make-pot "${DIST}" "${DIST}/languages/${SLUG}.pot" \
    --slug="${SLUG}" \
    --domain="${SLUG}" \
    --exclude=vendor \
    --allow-root \
    --quiet

echo "# Done"
