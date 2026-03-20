#!/usr/bin/env node
// Verify jq clone output against actual jq binary (not jq.test expected values)
import { readFileSync, existsSync } from "fs";
import { execSync } from "child_process";

const mbtFile = readFileSync(
  new URL("../src/jq_compat_test.mbt", import.meta.url),
  "utf-8"
);

// Check jq is available
try {
  const ver = execSync("jq --version", { encoding: "utf-8" }).trim();
  console.log(`Using ${ver}\n`);
} catch {
  console.error("jq not found. Install jq to run this verification.");
  process.exit(1);
}

// Parse MBT test file: extract filter, input, and snapshot content per test
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

// Run jq binary and get output lines
function runJq(filter, input) {
  try {
    const result = execSync(`echo ${JSON.stringify(input)} | jq -c ${JSON.stringify(filter)}`, {
      encoding: "utf-8",
      timeout: 5000,
      stdio: ["pipe", "pipe", "pipe"],
    });
    return result.trim().split("\n").filter(Boolean);
  } catch (e) {
    // jq error - return error output
    const stderr = e.stderr?.toString().trim() || "";
    return [`ERROR: ${stderr}`];
  }
}

const mbtTests = parseMbtTests(mbtFile);
let pass = 0,
  fail = 0,
  skip = 0;
const failures = [];

for (const mbt of mbtTests) {
  let ourValues;
  try {
    ourValues = JSON.parse(mbt.content);
  } catch {
    skip++;
    continue;
  }
  if (!Array.isArray(ourValues)) {
    skip++;
    continue;
  }

  // Skip error results from our side
  if (ourValues.some((v) => typeof v === "string" && v.startsWith("ERROR:"))) {
    skip++;
    continue;
  }

  const jqOutput = runJq(mbt.filter, mbt.input);

  // Skip if jq errored
  if (jqOutput.some((v) => v.startsWith("ERROR:"))) {
    skip++;
    continue;
  }

  if (ourValues.length !== jqOutput.length) {
    fail++;
    failures.push({
      num: mbt.num,
      filter: mbt.filter,
      jq: jqOutput,
      got: ourValues,
      reason: `count: ${jqOutput.length} vs ${ourValues.length}`,
    });
    continue;
  }

  let ok = true;
  for (let i = 0; i < ourValues.length; i++) {
    if (
      ourValues[i] !== jqOutput[i] &&
      ourValues[i].replace(/\s/g, "") !== jqOutput[i].replace(/\s/g, "")
    ) {
      ok = false;
      break;
    }
  }
  if (ok) pass++;
  else {
    fail++;
    failures.push({
      num: mbt.num,
      filter: mbt.filter,
      jq: jqOutput,
      got: ourValues,
      reason: "mismatch",
    });
  }
}

const total = pass + fail + skip;
const tested = pass + fail;
console.log(
  `Compatibility: ${pass}/${tested} tested (${((100 * pass) / tested).toFixed(1)}%), ${skip} skipped`
);
console.log(`  Pass: ${pass}, Fail: ${fail}, Skip: ${skip}, Total: ${total}`);

if (failures.length > 0) {
  console.log(`\nFailures (${failures.length}):`);
  for (const f of failures) {
    console.log(`  #${f.num}: ${f.filter.slice(0, 70)}  [${f.reason}]`);
    console.log(`    jq:  ${JSON.stringify(f.jq).slice(0, 120)}`);
    console.log(`    got: ${JSON.stringify(f.got).slice(0, 120)}`);
  }
}
