#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
generated_dir="$repo_root/generated"
version="${1-}"

export COPYFILE_DISABLE=1

for package in nonfree-search-engines-data nonfree-onboarding-assets; do
  archive="$generated_dir/$package${version:+-$version}.tar.gz"

  if [[ ! -d "$generated_dir/$package" ]]; then
    printf 'Error: Generated directory not found: %s\n' "$generated_dir/$package" >&2
    exit 1
  fi

  tar \
    --format ustar \
    --no-acls \
    --no-xattrs \
    --no-fflags \
    --no-mac-metadata \
    --exclude '.DS_Store' \
    --exclude '*/.DS_Store' \
    --exclude '._*' \
    --exclude '*/._*' \
    -czf "$archive" \
    -C "$generated_dir/$package" \
    .

  printf 'Packaged: %s\n' "$archive"
done
