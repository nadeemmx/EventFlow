import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

/**
 * Regression guard for P0-1: the "New X" create-flow routing collision.
 *
 * `app/(dashboard)/<entity>/[id]/page.tsx` used to export
 *   generateStaticParams() { return [{ id: "new" }]; }
 * which prerendered the *detail* component at `/xxx/new`, colliding with the
 * real create page. Next.js then served the detail component for the create
 * route, so every "New X" page rendered "not found".
 *
 * This test fails if that static-param pattern is reintroduced, and also
 * asserts every [id] page still has a default export (i.e. the removal of
 * generateStaticParams did not break the route).
 */

const APP_DIR = join(import.meta.dirname, "..", "app");
const ANTI_PATTERN = /generateStaticParams[\s\S]{0,80}id:\s*["']new["']/;

function findIdPages(dir, acc = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) findIdPages(full, acc);
    else if (entry.name === "page.tsx") acc.push(full);
  }
  return acc;
}

const idPages = findIdPages(APP_DIR).filter((p) => p.includes("[id]"));

test("there is at least one [id] route to guard", () => {
  assert.ok(idPages.length >= 13, `expected >=13 [id] pages, found ${idPages.length}`);
});

test('no [id] route prerenders the "new" static param (P0-1 regression)', () => {
  const offenders = idPages.filter((p) =>
    ANTI_PATTERN.test(readFileSync(p, "utf8")),
  );
  assert.deepEqual(
    offenders,
    [],
    `generateStaticParams must not return { id: "new" } in:\n  ${offenders.join("\n  ")}`,
  );
});

test("every [id] page still exports a default component", () => {
  const broken = idPages.filter(
    (p) => !/export\s+default\s+(function|const)/.test(readFileSync(p, "utf8")),
  );
  assert.deepEqual(broken, [], `missing default export in:\n  ${broken.join("\n  ")}`);
});

test("entities that define a /new create page are not claimed by [id]", () => {
  // The collision is only observable when a real create page exists next door.
  // (Some entities — inventory, packages, staff, tasks, vendors — have no
  // /new page; creating them happens via a modal. They are not asserted here.)
  const withCreatePage = idPages.filter((p) =>
    existsSync(p.replace(`/${"[id]"}/page.tsx`, "/new/page.tsx")),
  );
  assert.ok(withCreatePage.length >= 8, `expected >=8 entities with a /new page`);
});
