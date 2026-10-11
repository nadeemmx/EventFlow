import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { join } from "node:path";

/**
 * Regression guard for P0-3 (frontend vulnerability backlog).
 *
 * Baseline before the fix: 25 advisories — 1 critical (next), 18 high,
 * 6 moderate. Production runtime was affected by `next` (critical, incl.
 * unauthenticated RCE in the Image Optimizer and RSC deserialization DoS)
 * and its nested `postcss` (high).
 *
 * The bar that matters is what ships: `--omit=dev` must stay at zero.
 * Dev-only build tooling (tailwindcss and its chokidar/braces/micromatch
 * chain, and the `serve` static server used only by the broken `npm run
 * export` path) is tracked separately and asserted to never carry a
 * critical.
 */

function audit(args) {
  // `npm audit` exits non-zero whenever it finds ANY advisory, which is the
  // expected case for the dev-only tree. Capture stdout from the thrown error
  // rather than letting execFileSync propagate the failure.
  let raw = "";
  try {
    raw = execFileSync("npm", ["audit", "--json", ...args], {
      cwd: join(import.meta.dirname, ".."),
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
  } catch (err) {
    if (typeof err.stdout === "string" && err.stdout.trim().startsWith("{")) {
      raw = err.stdout;
    } else {
      throw err;
    }
  }
  return JSON.parse(raw).metadata?.vulnerabilities ?? {};
}

test("production dependency tree has zero known vulnerabilities", () => {
  const v = audit(["--omit=dev"]);
  assert.equal(
    v.total ?? 0,
    0,
    `production tree must be clean, found ${JSON.stringify(v)}`,
  );
});

test("no critical advisories anywhere, including devDependencies", () => {
  const v = audit([]);
  assert.equal(
    v.critical ?? 0,
    0,
    `critical advisories present: ${JSON.stringify(v)}`,
  );
});

test("remaining dev-only advisories stay within the documented budget", () => {
  // Documented residual: tailwindcss v3 build chain + serve. Both are
  // build/serve-time tooling that never processes untrusted user input.
  // Tailwind v3 -> v4 is a visual-regression-prone migration and is
  // deliberately not taken for build-tool-only advisories.
  const v = audit([]);
  const total = v.total ?? 0;
  assert.ok(
    total <= 9,
    `dev-only advisory budget is 9, found ${total}: ${JSON.stringify(v)}`,
  );
});
