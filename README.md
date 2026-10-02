# utmelab-assets

Public static origin for UTME Lab, served by GitHub Pages from the
`gh-pages` branch at `https://ultimatekristency.github.io/utmelab-assets/`.
`assets.utmelab.com` is a CNAME to that site.

The serving branch is `gh-pages` - a push to `main` does NOT go live. The
UTME-Lab `publish-downloads` job pushes the shelf to `gh-pages` on every
version tag, then verifies every URL answers 200 before the job passes.

## Layout

- `images/` — question-diagram images keyed by the bare filename the
  question bank stores in each question's `image` field. Filenames are
  stable content hashes: overwrite in place, never rename.
- `materials/` — study-material zips served to buyers.
- `downloads/` — native release binaries + `latest.json`, written by CI
  on every version tag (UTME-Lab repo, `release.yml` → `publish-downloads`).
  Hand-edit only to roll back (see below).

## downloads/ contract (clients depend on this shape)

- `latest.json` — the update manifest. Schema is `AppVersionResponse`
  (UTME-Lab `crates/api/src/dtos.rs`): `{version, update: {version,
  android_apk_url, linux_appimage_url, windows_setup_url,
  windows_portable_url, download_page_url}, min_compatible_version}`.
  Apps fetch it directly (CDN-cached, no auth); the app server is never
  in the update path.
- `utmelab-release.apk` — stable pointer, always the newest Android build.
- `utmelab-<version>-x86_64.AppImage[.zsync]`, `UTME-Lab-<version>-setup.exe`,
  `UTME-Lab-<version>-portable.zip` — version-pinned desktop builds.
- Keep the newest 4 releases (`prune` runs in the publish step). History
  retains the rest; at ~35 MB/release this is years of runway, not a crisis.

## Rollback

Bad release out? Revert the publish commit (`git revert`, push): files
restore from history, the platform rebuilds, clients see the older
`latest.json` and stay silent (they never downgrade — correct: a working
build keeps working). No server involvement, no rush.

## Update flow

Add/overwrite files, then push to `gh-pages` to publish:

```sh
git add .
git commit -m "Describe the content change"
git push
```
