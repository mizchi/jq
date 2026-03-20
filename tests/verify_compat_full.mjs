#!/usr/bin/env node
// Show all skipped tests (our errors) and check if jq handles them
import { readFileSync } from "fs";
import { execSync } from "child_process";

const mbtFile = readFileSync(
  new URL("../src/jq_compat_test.mbt", import.meta.url),
  "utf-8"
);

function parseMbtTests(content) {
  const results = [];
  const re =
    /test "jq_compat_(\d+): [^"]*" \{[\s\S]*?run_jq\("((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\)[\s\S]*?content=(\([^)]*\)|"[^"]*"),?\s*\)\s*\}/g;
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
    return execSync(
      `echo ${JSON.stringify(input)} | jq -c ${JSON.stringify(filter)}`,
      { encoding: "utf-8", timeout: 5000, stdio: ["pipe", "pipe", "pipe"] }
    ).trim().split("\n").filter(Boolean);
  } catch (e) {
    return [`JQ_ERROR: ${(e.stderr || "").toString().trim()}`];
  }
}

const mbtTests = parseMbtTests(mbtFile);
console.log("=== Skipped tests (our ERROR outputs) ===\n");

let fixable = 0;
for (const mbt of mbtTests) {
  let ourValues;
  try { ourValues = JSON.parse(mbt.content); } catch { continue; }
  if (!Array.isArray(ourValues)) continue;

  const hasError = ourValues.some(v => typeof v === "string" && v.startsWith("ERROR:"));
  if (!hasError) continue;

  const jqOutput = runJq(mbt.filter, mbt.input);
  const jqErrors = jqOutput.some(v => v.startsWith("JQ_ERROR:"));

  if (jqErrors) {
    // Both error - probably fine
    continue;
  }

  fixable++;
  console.log(`#${mbt.num}: ${mbt.filter.slice(0, 70)}`);
  console.log(`  input: ${mbt.input.slice(0, 60)}`);
  console.log(`  ours:  ${JSON.stringify(ourValues).slice(0, 100)}`);
  console.log(`  jq:    ${JSON.stringify(jqOutput).slice(0, 100)}`);
  console.log();
}
console.log(`Fixable: ${fixable} tests where we error but jq succeeds`);
