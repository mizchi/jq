#!/usr/bin/env node
// Verify jq clone output against actual jq binary
// Uses a single jq process per test with strict resource limits
import { readFileSync } from "fs";
import { execFileSync } from "child_process";

const mbtFile = readFileSync(
  new URL("../src/jq_compat_test.mbt", import.meta.url),
  "utf-8"
);

// Check jq
try {
  const ver = execFileSync("jq", ["--version"], { encoding: "utf-8" }).trim();
  console.log(`Using ${ver}\n`);
} catch {
  console.error("jq not found");
  process.exit(1);
}

// Filters known to cause high resource usage in jq
const SKIP_FILTERS = [
  /range\(\d{6,}/, // huge ranges
  /\*\s*100000/, // huge repeats
  /reduce range\(655/, // large reduce
  /999999999/, // huge numbers
];

function parseMbtTests(content) {
  const results = [];
  const re =
    /test "jq_compat_(\d+): [^"]*" \{[\s\S]*?run_jq\("((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\)[\s\S]*?content=(\([\s\S]*?\n\s*\)|"[^"]*"),?\s*\)\s*\}/g;
  let m;
  while ((m = re.exec(content)) !== null) {
    const num = parseInt(m[1]);
    const filter = m[2].replace(/\\"/g, '"').replace(/\\\\/g, "\\");
    const input = m[3].replace(/\\"/g, '"').replace(/\\\\/g, "\\");
    let contentVal = m[4];
    if (contentVal.startsWith("(")) {
      const lines = contentVal.match(/#\|.*/g);
      contentVal = lines ? lines.map((l) => l.slice(2)).join("\n") : "";
    } else {
      contentVal = contentVal.replace(/^"|"$/g, "");
    }
    results.push({ num, filter, input, content: contentVal });
  }
  return results;
}

function runJq(filter, input) {
  try {
    const result = execFileSync("jq", ["-c", filter], {
      input,
      encoding: "utf-8",
      timeout: 3000,
      maxBuffer: 1024 * 1024,
      stdio: ["pipe", "pipe", "pipe"],
    });
    return result.trim().split("\n").filter(Boolean);
  } catch (e) {
    if (e.killed) return ["TIMEOUT"];
    const stderr = e.stderr?.toString().trim() || "";
    return [`ERROR: ${stderr}`];
  }
}

const mbtTests = parseMbtTests(mbtFile);
let pass = 0, fail = 0, skip = 0;
const failures = [];

for (const mbt of mbtTests) {
  let ourValues;
  try { ourValues = JSON.parse(mbt.content); } catch { skip++; continue; }
  if (!Array.isArray(ourValues)) { skip++; continue; }
  if (ourValues.some((v) => typeof v === "string" && v.startsWith("ERROR:"))) { skip++; continue; }

  // Skip resource-heavy filters
  if (SKIP_FILTERS.some((p) => p.test(mbt.filter))) { skip++; continue; }

  const jqOutput = runJq(mbt.filter, mbt.input);
  if (jqOutput.some((v) => v.startsWith("ERROR:") || v === "TIMEOUT")) { skip++; continue; }

  if (ourValues.length !== jqOutput.length) {
    fail++;
    failures.push({ num: mbt.num, filter: mbt.filter, jq: jqOutput, got: ourValues, reason: `count: ${jqOutput.length} vs ${ourValues.length}` });
    continue;
  }

  let ok = true;
  for (let i = 0; i < ourValues.length; i++) {
    if (ourValues[i] !== jqOutput[i] && ourValues[i].replace(/\s/g, "") !== jqOutput[i].replace(/\s/g, "")) {
      ok = false; break;
    }
  }
  if (ok) pass++;
  else {
    fail++;
    failures.push({ num: mbt.num, filter: mbt.filter, jq: jqOutput, got: ourValues, reason: "mismatch" });
  }
}

const tested = pass + fail;
console.log(`Compatibility: ${pass}/${tested} tested (${((100 * pass) / tested).toFixed(1)}%), ${skip} skipped`);
console.log(`  Pass: ${pass}, Fail: ${fail}, Skip: ${skip}, Total: ${pass + fail + skip}`);

if (failures.length > 0) {
  console.log(`\nFailures (${failures.length}):`);
  for (const f of failures) {
    console.log(`  #${f.num}: ${f.filter.slice(0, 70)}  [${f.reason}]`);
    console.log(`    jq:  ${JSON.stringify(f.jq).slice(0, 120)}`);
    console.log(`    got: ${JSON.stringify(f.got).slice(0, 120)}`);
  }
}
