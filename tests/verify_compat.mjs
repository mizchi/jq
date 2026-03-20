#!/usr/bin/env node
import { readFileSync } from "fs";

const testFile = readFileSync(new URL("./jq.test", import.meta.url), "utf-8");
const mbtFile = readFileSync(new URL("../src/jq_compat_test.mbt", import.meta.url), "utf-8");

// Parse jq.test → Map<"filter\0input", expected[]>
function parseJqTests(content) {
  const lines = content.split("\n");
  const tests = new Map();
  let i = 0;
  while (i < lines.length) {
    const line = lines[i].trimEnd();
    if (line === "" || line.startsWith("#")) { i++; continue; }
    if (line === "%%FAIL") { i++; while (i < lines.length && lines[i].trimEnd() !== "") i++; continue; }
    const filter = line; i++;
    if (i >= lines.length) break;
    const input = lines[i].trimEnd(); i++;
    const expected = [];
    while (i < lines.length) {
      const l = lines[i].trimEnd();
      if (l === "" || l.startsWith("#")) break;
      expected.push(l); i++;
    }
    if (expected.length > 0) tests.set(filter + "\0" + input, expected);
  }
  return tests;
}

// Parse MBT test file
function parseMbtTests(content) {
  const results = [];
  const re = /test "jq_compat_(\d+): [^"]*" \{[\s\S]*?run_jq\("((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\)[\s\S]*?content=(\([^)]*\)|"[^"]*"),?\s*\)\s*\}/g;
  let m;
  while ((m = re.exec(content)) !== null) {
    const num = parseInt(m[1]);
    const filter = m[2].replace(/\\"/g, '"').replace(/\\\\/g, "\\");
    const input = m[3].replace(/\\"/g, '"').replace(/\\\\/g, "\\");
    let contentVal = m[4];
    if (contentVal.startsWith("(")) {
      // Extract #| lines
      const lines = contentVal.match(/#\|.*/g);
      contentVal = lines ? lines.map(l => l.slice(2)).join("\n") : "";
    } else {
      contentVal = contentVal.replace(/^"|"$/g, "");
    }
    results.push({ num, filter, input, content: contentVal });
  }
  return results;
}

const jqTests = parseJqTests(testFile);
const mbtTests = parseMbtTests(mbtFile);

let pass = 0, fail = 0, skip = 0;
const failures = [];

for (const mbt of mbtTests) {
  const key = mbt.filter + "\0" + mbt.input;
  const jqExpected = jqTests.get(key);
  if (!jqExpected) { skip++; continue; }

  let ourValues;
  try { ourValues = JSON.parse(mbt.content); } catch { skip++; continue; }
  if (!Array.isArray(ourValues)) { skip++; continue; }

  if (ourValues.length !== jqExpected.length) {
    fail++; failures.push({ num: mbt.num, filter: mbt.filter, expected: jqExpected, got: ourValues, reason: `count: ${jqExpected.length} vs ${ourValues.length}` });
    continue;
  }

  let ok = true;
  for (let i = 0; i < ourValues.length; i++) {
    if (ourValues[i] !== jqExpected[i] && ourValues[i].replace(/\s/g, "") !== jqExpected[i].replace(/\s/g, "")) {
      ok = false; break;
    }
  }
  if (ok) pass++; else {
    fail++; failures.push({ num: mbt.num, filter: mbt.filter, expected: jqExpected, got: ourValues, reason: "mismatch" });
  }
}

console.log(`Compatibility: ${pass}/${pass+fail+skip} (${(100*pass/(pass+fail+skip)).toFixed(1)}%)`);
console.log(`  Pass: ${pass}, Fail: ${fail}, Skip: ${skip}`);
if (failures.length > 0) {
  console.log(`\nFailures (${failures.length}):`);
  for (const f of failures) {
    console.log(`  #${f.num}: ${f.filter.slice(0,70)}  [${f.reason}]`);
    console.log(`    want: ${JSON.stringify(f.expected).slice(0,120)}`);
    console.log(`    got:  ${JSON.stringify(f.got).slice(0,120)}`);
  }
}
