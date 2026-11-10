// Adds the Ask AI script tag to every built page through static-llms-txt's inject().
// Started by run.sh with `npx --package static-llms-txt@0.1.1`, which puts the package's
// bin folder on PATH; the package itself sits next to that folder.
"use strict";
const fs = require("node:fs");
const path = require("node:path");

function loadCore() {
  for (const dir of (process.env.PATH || "").split(path.delimiter)) {
    const file = path.join(dir, "..", "static-llms-txt", "index.cjs");
    if (dir && fs.existsSync(file)) return require(file);
  }
  throw new Error("static-llms-txt was not found on PATH. Run this through run.sh.");
}

const DEMO_KEY = "ot_demo000000000000000000000";
const SIGNUP = "curl -X POST https://onetagai.com/api/signup -H \"Content-Type: application/json\" -d '{\"email\":\"you@example.com\"}'";
const env = (name) => String(process.env[name] || "").trim();

const dir = env("INPUT_PATH");
const key = env("INPUT_KEY") || env("ONETAG_KEY");
const exclude = env("INPUT_EXCLUDE").split(/[\n,]/).map((s) => s.trim()).filter(Boolean);

const changed = loadCore().inject(dir, {
  key: key || DEMO_KEY,
  ref: "onetag-action",
  label: env("INPUT_LABEL") || undefined,
  position: env("INPUT_POSITION") || undefined,
  color: env("INPUT_COLOR").replace(/^#/, "") || undefined,
  lang: env("INPUT_LANG") || undefined,
  exclude,
});

console.log("added the Ask AI script to " + changed.length + " pages");
if (process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT, "pages=" + changed.length + "\n");
if (!key) {
  console.log("::warning title=OneTag AI::No key, so the Ask AI box uses the demo key and answers on localhost only. Get a free key, then set the key input: " + SIGNUP);
}
