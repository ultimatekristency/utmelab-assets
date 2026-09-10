# utmelab-assets

Public diagram images for UTME-Lab, served as static assets via GitHub Pages.

## Layout
- 2,928 question-diagram images at the repo root, keyed by the same bare
  filename the question bank stores in each question's `image` field.
- The app resolves `image` → `https://shedrackgodstime.github.io/utmelab-assets/<filename>`
  in `src/components/features/exam/content.rs::image_src`.

## Update flow
Add/overwrite files then push to `main`; GitHub Pages redeploys automatically:

```sh
git add .
git commit -m "Add N updated diagrams"
git push
```

Filenames are the hunt UUIDs and are stable — `image_src()` passes absolute
URLs through unchanged, so a future migration to a real CDN (Cloudflare/R2)
is a one-line change in the app and needs no filename or data change here.