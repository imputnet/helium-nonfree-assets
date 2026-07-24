#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
nonfree_dir="$repo_root/nonfree"
browser_dir="$repo_root/generated/browsers"
output_dir="$repo_root/generated/nonfree-onboarding-assets"
package_source="$repo_root/resources/onboarding-package.json"

if ! command -v avifenc >/dev/null; then
  printf 'Error: avifenc is required. Install it with: brew install libavif\n' >&2
  exit 1
fi

if [[ ! -f "$package_source" ]]; then
  printf 'Error: Package file not found: %s\n' "$package_source" >&2
  exit 1
fi

shopt -s nullglob

convert_pngs_to_avif() {
  local source_dir="$1"
  local target_dir="$2"
  local png_files=("$source_dir"/*.png)
  local source filename output

  if ((${#png_files[@]} == 0)); then
    printf 'Error: No PNG files found in %s\n' "$source_dir" >&2
    exit 1
  fi

  mkdir -p "$target_dir"

  for source in "${png_files[@]}"; do
    filename="${source##*/}"
    output="$target_dir/${filename%.png}.avif"
    avifenc -q 60 -s 0 "$source" "$output"
    printf 'Generated: %s\n' "$output"
  done
}

convert_pngs_to_avif \
  "$nonfree_dir/password-managers" \
  "$output_dir/password-managers"

search_output_dir="$output_dir/search-engines"
search_files=("$nonfree_dir/search"/*.svg)

if ((${#search_files[@]} == 0)); then
  printf 'Error: No SVG files found in %s\n' "$nonfree_dir/search" >&2
  exit 1
fi

mkdir -p "$search_output_dir"

for source in "${search_files[@]}"; do
  output="$search_output_dir/${source##*/}"
  cp "$source" "$output"
  printf 'Copied: %s\n' "$output"
done

convert_pngs_to_avif \
  "$browser_dir" \
  "$output_dir/browsers"

cp "$package_source" "$output_dir/package.json"
printf 'Copied: %s\n' "$output_dir/package.json"
