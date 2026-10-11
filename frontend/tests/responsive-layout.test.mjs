// Regression test for QA-TEST-REPORT.md P1-1 (horizontal overflow).
//
// Both authed layouts put their content column inside a row-direction flex
// parent. A flex item's default `min-width: auto` stops it shrinking below
// its content's intrinsic width, so a wide data table (the bookings table is
// ~744px) dragged the whole page past the viewport:
//   375px viewport -> scrollWidth 778, 768px -> scrollWidth 1050.
// Adding `min-w-0` lets the column shrink, which in turn lets the table's own
// `overflow-x-auto` (components/common/DataTable.tsx) scroll inside its box.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync, readdirSync, statSync } from "node:fs"
import { join } from "node:path"

const ROOT = new URL("..", import.meta.url).pathname

const LAYOUTS = [
  "app/(dashboard)/layout.tsx",
  "app/(admin)/layout.tsx",
]

const read = (rel) => readFileSync(join(ROOT, rel), "utf8")

test("both authed layouts exist", () => {
  for (const rel of LAYOUTS) {
    assert.ok(statSync(join(ROOT, rel)).isFile(), `missing layout: ${rel}`)
  }
})

test("the content column declares min-w-0 so it can shrink", () => {
  for (const rel of LAYOUTS) {
    const src = read(rel)
    // The flex column that wraps TopNav + main must opt out of min-width:auto.
    assert.match(
      src,
      /flex[^"']*min-w-0[^"']*flex-1\s+flex-col/,
      `${rel}: expected "flex ... min-w-0 ... flex-1 flex-col" on the content column`,
    )
  }
})

test("no other authed layout still has the overflowing pattern", () => {
  // Scan every layout under app/ so a future one cannot reintroduce it.
  const layouts = []
  const walk = (dir) => {
    for (const name of readdirSync(dir)) {
      const p = join(dir, name)
      if (statSync(p).isDirectory()) walk(p)
      else if (name === "layout.tsx") layouts.push(p)
    }
  }
  walk(join(ROOT, "app"))

  const offenders = layouts
    .map((p) => ({ p, src: readFileSync(p, "utf8") }))
    // only authed shells use this exact content-column class combination
    .filter(({ src }) => src.includes("flex-1 flex-col md:pl-64"))
    .filter(({ src }) => !src.includes("min-w-0"))
    .map(({ p }) => p.slice(ROOT.length))

  assert.deepEqual(
    offenders,
    [],
    `layouts still missing min-w-0: ${offenders.join(", ")}`,
  )
})
