#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
source_dir="$repo_root/nonfree/search"
output_dir="$repo_root/generated/nonfree-search-engines-data"
grd_source="$repo_root/resources/search_engines_scaled_resources.grd"

scales=(
  default_100_percent
  default_200_percent
  default_300_percent
)
sizes=(
  24
  48
  72
)

validate_inputs() {
  if ! command -v rsvg-convert >/dev/null; then
    printf 'Error: librsvg is required. Install it with: brew install librsvg\n' >&2
    exit 1
  fi

  if (($# == 0)); then
    printf 'Error: No SVG files found in %s\n' "$source_dir" >&2
    exit 1
  fi

  if [[ ! -f "$grd_source" ]]; then
    printf 'Error: GRD file not found: %s\n' "$grd_source" >&2
    exit 1
  fi
}

generate_definitions() {
  local definitions_dir="$output_dir/definitions"
  local manifest="$definitions_dir/search_engine_scaled_resources.grdp"
  local assets_manifest="$output_dir/search_engine_assets.gni"
  local grd_output="$output_dir/${grd_source##*/}"
  local source filename name resource_name scale

  mkdir -p "$definitions_dir"

  cp "$grd_source" "$grd_output"
  printf 'Copied: %s\n' "$grd_output"

  {
    printf '%s\n' \
      '<?xml version="1.0" encoding="UTF-8"?>' \
      '<!--' \
      'Copyright 2026 The Helium Authors' \
      'You can use, redistribute, and/or modify this source code under' \
      'the terms of the GPL-3.0 license that can be found in the LICENSE file.' \
      '-->' \
      '<grit-part>'

    for source in "$@"; do
      filename="${source##*/}"
      name="${filename%.svg}"
      resource_name="$(printf '%s' "$name" | tr '[:lower:]-' '[:upper:]_')"

      printf '  <structure type="chrome_scaled_image" name="IDR_SEARCH_ENGINE_%s_IMAGE" file="search_engines/%s.png"/>\n' \
        "$resource_name" "$name"
    done

    printf '%s\n' '</grit-part>'
  } > "$manifest"

  printf 'Generated: %s\n' "$manifest"

  {
    echo '# Copyright 2026 The Helium Authors'
    echo '# You can use, redistribute, and/or modify this source code under'
    echo '# the terms of the GPL-3.0 license that can be found in the LICENSE file.'
    echo
    echo 'search_engine_scaled_resource_files = ['

    for scale in "${scales[@]}"; do
      for source in "$@"; do
        filename="${source##*/}"
        echo "  \"$scale/search_engines/${filename%.svg}.png\","
      done
    done

    echo ']'
  } > "$assets_manifest"

  echo "Generated: $assets_manifest"
}

generate_scaled_images() {
  local i scale size target_dir source filename output

  for i in "${!scales[@]}"; do
    scale="${scales[i]}"
    size="${sizes[i]}"
    target_dir="$output_dir/$scale/search_engines"
    mkdir -p "$target_dir"

    for source in "$@"; do
      filename="${source##*/}"
      output="$target_dir/${filename%.svg}.png"

      rsvg-convert \
        --width "$size" \
        --height "$size" \
        --keep-aspect-ratio \
        --background-color transparent \
        --output "$output" \
        "$source"

      printf 'Generated: %s\n' "$output"
    done
  done
}

main() {
  shopt -s nullglob
  local svg_files=("$source_dir"/*.svg)

  validate_inputs "${svg_files[@]}"
  generate_definitions "${svg_files[@]}"
  generate_scaled_images "${svg_files[@]}"
}

main
