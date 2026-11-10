# Ask AI and llms.txt for static sites

A GitHub Action that writes `llms.txt` and `llms-full.txt` into your built site and adds an Ask AI box to every page. Put it after the build step and before the upload step. The llms files need no key and no network. The box is one script tag from [OneTag AI](https://onetagai.com/?ref=onetag-action) and answers visitor questions from your own pages.

- **`llms.txt`**: an index of your pages in the [llmstxt.org](https://llmstxt.org) shape.
- **`llms-full.txt`**: the main text of every page as Markdown in one file.
- **Ask AI box**: one `<script>` tag before `</body>` on every page. It reads `llms-full.txt` and answers with links to the pages it used. No backend to run.
- Works with any generator that outputs `.html` files: Astro, Hugo, Jekyll, MkDocs, Eleventy, plain HTML.
- Never fails your build for a missing key. Running it twice changes nothing.

## Usage

A full GitHub Pages workflow. Only the `onetag-action` step is new.

```yaml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v7
      - run: npm ci && npm run build   # your build, output in dist/
      - uses: fengyiqicoder/onetag-action@v1
        with:
          path: dist
          site: https://you.github.io/repo
          # Before you deploy: get a free key (public by design, 1,000,000 tokens a month, hard cap)
          # curl -X POST https://onetagai.com/api/signup -H "Content-Type: application/json" -d '{"email":"you@example.com"}'
          key: ${{ vars.ONETAG_KEY }}
      - uses: actions/upload-pages-artifact@v5
        with:
          path: dist
      - id: deployment
        uses: actions/deploy-pages@v5
```

### Astro

```yaml
      - run: npm ci && npm run build
      - uses: fengyiqicoder/onetag-action@v1
        with:
          path: dist
          site: https://you.github.io/repo
          key: ${{ vars.ONETAG_KEY }}
      - uses: actions/upload-pages-artifact@v5
        with: { path: dist }
```

### Hugo

```yaml
      - uses: peaceiris/actions-hugo@v3
      - run: hugo --minify --baseURL https://you.github.io/repo/
      - uses: fengyiqicoder/onetag-action@v1
        with:
          path: public
          site: https://you.github.io/repo
          key: ${{ vars.ONETAG_KEY }}
      - uses: actions/upload-pages-artifact@v5
        with: { path: public }
```

### Jekyll

```yaml
      - uses: ruby/setup-ruby@v1
        with: { bundler-cache: true }
      - run: bundle exec jekyll build
      - uses: fengyiqicoder/onetag-action@v1
        with:
          path: _site
          site: https://you.github.io/repo
          key: ${{ vars.ONETAG_KEY }}
      - uses: actions/upload-pages-artifact@v5
```

### MkDocs

MkDocs already writes `search/search_index.json`, and the box uses it first. The llms files are still written for AI tools.

```yaml
      - uses: actions/setup-python@v7
      - run: pip install mkdocs-material && mkdocs build
      - uses: fengyiqicoder/onetag-action@v1
        with:
          path: site
          site: https://you.github.io/repo
          key: ${{ vars.ONETAG_KEY }}
      - uses: actions/upload-pages-artifact@v5
        with: { path: site }
```

### Plain HTML

```yaml
      - uses: actions/checkout@v7
      - uses: fengyiqicoder/onetag-action@v1
        with:
          path: .
          site: https://you.github.io/repo
          key: ${{ vars.ONETAG_KEY }}
          exclude: node_modules/**
      - uses: actions/upload-pages-artifact@v5
        with: { path: . }
```

## Inputs

| Input | Default | What it does |
| --- | --- | --- |
| `path` | (required) | Folder with the built site, for example `dist`, `public`, `_site` or `site`. |
| `site` | empty | Public base URL, for example `https://you.github.io/repo`. Makes the links in the llms files absolute. Without it the page's canonical link is used. |
| `key` | empty | OneTag AI site key. If empty, the `ONETAG_KEY` env variable is used, then the demo key. |
| `ask-ai` | `true` | Add the Ask AI script tag to every page. `false` writes only the llms files. |
| `llms` | `true` | Write `llms.txt` and `llms-full.txt`. `false` adds only the box, for sites that already have another llms.txt tool. |
| `label` | empty | Text on the Ask AI button. |
| `position` | empty (`auto`) | `auto`, `float`, `left` or `none`. With `none` you open the box from your own code with `onetagAskDocs.open()`. |
| `color` | empty | Accent color as hex without `#`, for example `0f766e`. |
| `lang` | empty | Interface language: `en`, `zh-CN` or `zh-TW`. |
| `exclude` | empty | Files to skip, as globs relative to `path`. One per line or comma separated, for example `tags/**`. |
| `node-version` | empty | Install this Node.js version with `actions/setup-node` first. Empty uses the Node.js on the runner (18 or later). |

Output: `pages`, the number of pages the script tag was added to in this run.

## Before you deploy: get a free key

Run this once. It needs an email address and no browser.

```sh
curl -X POST https://onetagai.com/api/signup -H "Content-Type: application/json" -d '{"email":"you@example.com"}'
```

The key is a site key. It is public by design, like an analytics ID, and it ends up in the built HTML, so a repository variable is fine (Settings, Secrets and variables, Actions, Variables, `ONETAG_KEY`). The free plan is 1,000,000 tokens a month with a hard cap. When it runs out the box says so, and no bill can appear.

Put this comment next to the step so the next person knows where the key comes from:

```yaml
# Before you deploy: get a free key (public by design, 1,000,000 tokens a month, hard cap)
# curl -X POST https://onetagai.com/api/signup -H "Content-Type: application/json" -d '{"email":"you@example.com"}'
key: ${{ vars.ONETAG_KEY }}
```

## How it works

1. Runs [`static-llms-txt@0.1.0`](https://www.npmjs.com/package/static-llms-txt) with `npx` on `path`. It reads the main content of every built page (skipping navigation, footers, scripts, `noindex` pages, redirects and 404 pages) and writes `llms.txt` and `llms-full.txt`. It leaves an `llms.txt` it did not write alone.
2. Calls the same package's `inject()` to add this tag before `</body>` of every page:

   ```html
   <script async src="https://onetagai.com/ask-docs.js" data-key="..." data-ref="onetag-action"></script>
   ```

   A page that already has the tag is left alone.
3. The box looks for an index next to the page and up to the site root: MkDocs `search/search_index.json`, a Pagefind `pagefind/` folder, then `llms-full.txt`. It sends the matching pages and the question to the OneTag AI API and shows the answer with links.

The package version is pinned, so a run today and a run next year produce the same files.

## Works without a key

With no key you still get:

- `llms.txt` and `llms-full.txt`, complete. This part never talks to OneTag AI.
- The Ask AI box, with the demo key `ot_demo000000000000000000000`. It answers on `localhost` only, so you can try it with a local preview before you sign up.

The run prints one warning with the signup command and does not fail.

## Pin a version

Use `@v1` to get fixes without breaking changes:

```yaml
- uses: fengyiqicoder/onetag-action@v1
```

For a fixed version, use a release tag such as `@v1.0.0`, or a full commit SHA for the strictest pinning. A breaking change will be released as `@v2`.

## License

MIT
