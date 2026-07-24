# Non-free assets for Helium

This repository is the source of truth for all non-free assets used in Helium
for identification purposes, under fair use. This includes search engine logos,
browser icons, and password manager logos.

See [COPYRIGHT](nonfree/COPYRIGHT) for legal and fair use information.

## Included assets

- `nonfree/search` contains vector icons for Helium's default search engines.
- `nonfree/password-managers` contains raster icons for password managers
  suggested during onboarding.

Most of these icons were recreated by hand due to lack of up-to-date official
brand assets. All icons were optimized.

## Build scripts

The scripts target the latest macOS and generate packages ready for use in
Helium.

#### `search-engines-data.sh`

Builds search engine assets from the source SVGs. Requires `librsvg`.

#### `extract-browser-icons.sh`

Downloads the configured browsers and extracts their application icons. Uses
`render-browser-icon.swift` and requires Xcode, Swift, and enough disk space.

#### `onboarding-assets.sh`

Combines the browser, search engine, and password manager icons into the
onboarding package. Requires `libavif`.

#### `package-generated.sh`

Packages the generated search engine and onboarding assets as `.tar.gz`
archives.

### Build and package everything

```sh
./scripts/search-engines-data.sh
./scripts/extract-browser-icons.sh
./scripts/onboarding-assets.sh
./scripts/package-generated.sh
```

## License

All content outside `nonfree/` is licensed under GPL-3.0.
See [LICENSE](LICENSE).
