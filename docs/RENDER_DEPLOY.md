# Deploy Ocean Match on Render

Ocean Match is a Flutter Web single-page app. On Render, deploy it as a Static Site.

## What is already configured

- `render.yaml` creates a Render Static Site named `ocean-match-mvp`.
- `scripts/render_build.sh` installs Flutter on Render and runs `flutter build web --release`.
- Render serves `build/web`.
- SPA fallback rewrites all routes to `/index.html`.
- Basic security/cache headers are included.

## Deploy steps

1. Push this project to GitHub, GitLab, or Bitbucket.
2. Open Render Dashboard.
3. Choose **New +** then **Blueprint**.
4. Select the repository.
5. Render will read `render.yaml`.
6. Click **Apply**.
7. After the deploy finishes, share the generated `.onrender.com` URL with the client.

## Manual Static Site settings

If you do not use Blueprint:

- Runtime: Static Site
- Build command: `bash scripts/render_build.sh`
- Publish directory: `build/web`
- Rewrite rule: `/*` -> `/index.html`

## Important

The current local URL `http://127.0.0.1:8765` only works on this computer.
Render gives you a public URL that your client can open anywhere.
