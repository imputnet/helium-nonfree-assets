#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
config_file="$repo_root/resources/browser-downloads.ini"
downloads_dir="$repo_root/downloads/browsers"
output_dir="$repo_root/generated/browsers"
renderer_path="$script_dir/render-browser-icon.swift"

for tool in curl hdiutil ditto unzip sips swift; do
  if ! command -v "$tool" >/dev/null; then
    printf 'Error: Required command not found: %s\n' "$tool" >&2
    exit 1
  fi
done

if [[ ! -f "$config_file" ]]; then
  printf 'Error: Download configuration not found: %s\n' "$config_file" >&2
  exit 1
fi

mkdir -p "$downloads_dir" "$output_dir"

work_dir=""
mounted=0

cleanup() {
  if ((mounted)); then
    hdiutil detach "$work_dir" -quiet
    mounted=0
  fi

  if [[ -d "$work_dir" ]]; then
    rm -rf -- "$work_dir"
  fi

  work_dir=""
}

trap cleanup EXIT

render_icon() {
  local name="$1"
  local app_path="$2"
  local output="$output_dir/$name.png"

  "$renderer_path" "$app_path" "$output" "$name"
  sips --resampleHeightWidth 256 256 "$output" >/dev/null
  printf 'Extracted: %s\n' "$output"
}

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" == \#* ]] && continue

  if [[ "$line" != *=* ]]; then
    printf 'Error: Invalid configuration line: %s\n' "$line" >&2
    exit 1
  fi

  name="${line%%=*}"
  url="${line#*=}"
  url="${url#\"}"
  url="${url%\"}"

  if [[ ! "$name" =~ ^[a-z0-9_]+$ || -z "$url" ]]; then
    printf 'Error: Invalid browser entry: %s\n' "$line" >&2
    exit 1
  fi

  dmg="$downloads_dir/$name.dmg"
  zip="$downloads_dir/$name.zip"

  if [[ -f "$dmg" ]]; then
    hdiutil imageinfo "$dmg" >/dev/null
    archive="$dmg"
    printf 'Using cached: %s\n' "$archive"
  elif [[ -f "$zip" ]]; then
    unzip -tqq "$zip"
    archive="$zip"
    printf 'Using cached: %s\n' "$archive"
  else
    download="$downloads_dir/$name.download"
    printf 'Downloading: %s\n' "$url"
    curl --fail --location --retry 3 --output "$download" "$url"

    if hdiutil imageinfo "$download" >/dev/null 2>&1; then
      archive="$dmg"
    elif unzip -tqq "$download" >/dev/null 2>&1; then
      archive="$zip"
    else
      printf 'Error: Download is not a valid DMG or ZIP: %s\n' "$url" >&2
      exit 1
    fi

    mv "$download" "$archive"
    printf 'Downloaded: %s\n' "$archive"
  fi

  work_dir="$(mktemp -d /private/tmp/browser-icon.XXXXXX)"

  if [[ "$archive" == *.dmg ]]; then
    hdiutil attach "$archive" \
      -nobrowse \
      -readonly \
      -mountpoint "$work_dir" \
      >/dev/null
    mounted=1
  else
    ditto -x -k "$archive" "$work_dir"
  fi

  app_path="$(find "$work_dir" -mindepth 1 -maxdepth 2 -type d -name '*.app' -print -quit)"

  if [[ -z "$app_path" ]]; then
    printf 'Error: No .app found in %s\n' "$archive" >&2
    exit 1
  fi

  render_icon "$name" "$app_path"
  cleanup
done < "$config_file"

safari="/Applications/Safari.app"
if [[ -d "$safari" ]]; then
  render_icon safari "$safari"
else
  printf 'Not found: %s\n' "$safari" >&2
fi
