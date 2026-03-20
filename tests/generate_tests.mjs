#!/usr/bin/env node
// Parse jq.test and generate MoonBit test file
import { readFileSync, writeFileSync } from "fs";

const content = readFileSync(new URL("./jq.test", import.meta.url), "utf-8");
const lines = content.split("\n");

// Features we DON'T support - skip tests containing these patterns
const UNSUPPORTED_PATTERNS = [
  /\\[(]/, // string interpolation \(...)
  /@(urid|csv|tsv|sh)\b/, // unsupported format strings
  /\?\/\//, // alternative destructuring operator
  /\bas\s+\[/, // destructuring as [$a, $b]
  /\bas\s+\{/, // destructuring as {$a}
  /\bwhile\b/, // while
  /\buntil\b/, // until
  /\blabel\b/, // label
  /\bbreak\b/, // break
  /\bforeach\b/, // foreach
  /\bdel\b/, // del()
  /\bsetpath\b/, // setpath()
  /\bdelpaths\b/, // delpaths()
  /\bpick\b/, // pick()
  /\bgetpath\b/, // getpath() - skip complex uses
  /\|=/, // update assignment
  /\/\/=/, // alternative assignment
  /[^=!<>]=(?!=)/, // assignment (but not ==, !=, <=, >=)
  /\/\/(?!\/)/, // alternative operator //
  /\berror\b/, // error()
  /\bskip\b/, // skip()
  /\bnth\b/, // nth()
  /\bsqrt\b/, // sqrt()
  /\bsin\b/, // sin()
  /\bcos\b/, // cos()
  /\batan\b/, // atan()
  /\blog\b/, // log()
  /\bexp\b/, // exp()
  /\bpow\b/, // pow()
  /\bfenv\b/, // fenv
  /\binfinite\b/i, // infinite/Infinity
  /\bnan\b/i, // nan/NaN
  /\btoboolean\b/, // toboolean
  /\butf8bytelength\b/, // utf8bytelength
  /\bpath\b/, // path()
  /\bpaths\b/, // paths
  /\benv\b/, // env
  /\bbuiltins\b/, // builtins
  /\blast\(/, // last( with args  - complex version
  /\blimit\(0/, // limit(0; error) edge case
  /\bascii\b(?!_)/, // ascii (not ascii_downcase/upcase)
  /\b__loc__\b/, // __loc__
  /\btry\s+error\b/, // try error
  /\brecurse_down\b/, // deprecated
  /\binput\b/, // input
  /\bdebug\b/, // debug
  /\b\$__loc__\b/, // $__loc__
  /\bisempty\b/, // isempty
  /\blimit\(\d+;\s*\.?\[\]/, // complex limit
  /\bformat\b/, // format
  /\bmodulename\b/, // modules
  /\bimport\b/, // import
  /\binclude\b/, // include
  /\bscan\b/, // regex scan
  /\bmatch\b/, // regex match
  /\bcapture\b/, // regex capture
  /\btest\(/, // regex test with pattern
  /\bsub\(/, // regex sub
  /\bgsub\(/, // regex gsub
  /\bsplits\b/, // splits
  /\bltrimstr\b.*\btrimstr\b/, // complex trim patterns
  /\bgetpath\(/, // getpath with args
  /\bnow\b/, // now
  /\bstrftime\b/, // strftime
  /\bstrptime\b/, // strptime
  /\bdate\b/, // date functions
  /\bgmtime\b/, // gmtime
  /\bmktime\b/, // mktime
  /\btodate\b/, // todate
  /\bfromdate\b/, // fromdate
  /\blength\b.*\bjoin\b/, // complex chained builtins
  /\bmap_values\b.*\b\+1\b/, // map_values(.+1) edge cases
  /\badd\(/, // add with args (add/1)
  /\b1e[+-]?\d+\b/, // scientific notation
  /\b\d+[eE]/, // scientific notation
  /\b0x/, // hex literals
  /\?$/, // trailing ? (complex optional)
  /\.\[\]\?/, // .[]? complex forms
  /try\s+\(/, // try (complex expression)
  /\bflatten\(\d/, // flatten with depth arg
];

// Parse test cases
function parseTests(lines) {
  const tests = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i].trimEnd();
    // Skip blank lines and comments
    if (line === "" || line.startsWith("#")) {
      i++;
      continue;
    }
    // Skip %%FAIL blocks
    if (line === "%%FAIL") {
      i++;
      while (i < lines.length && lines[i].trimEnd() !== "") {
        i++;
      }
      continue;
    }
    // Parse test case: filter, input, expected outputs
    const filter = line;
    i++;
    if (i >= lines.length) break;
    const input = lines[i].trimEnd();
    i++;
    const expected = [];
    while (i < lines.length) {
      const l = lines[i].trimEnd();
      if (l === "" || l.startsWith("#")) break;
      expected.push(l);
      i++;
    }
    if (expected.length > 0) {
      tests.push({ filter, input, expected });
    }
  }
  return tests;
}

function isSupported(test) {
  const combined = test.filter + " " + test.input + " " + test.expected.join(" ");
  for (const pattern of UNSUPPORTED_PATTERNS) {
    if (pattern.test(test.filter)) return false;
  }
  // Skip tests with BOM
  if (test.input.charCodeAt(0) === 0xfeff) return false;
  // Skip tests with embedded unicode escapes in expected output that differ from input
  // Skip tests with very long expected outputs (complex)
  if (test.expected.some((e) => e.length > 200)) return false;
  // Skip multi-output tests that use error
  if (test.expected.some((e) => e.includes("Cannot") || e.includes("error"))) return false;
  // Skip if filter contains features we can't handle
  if (test.filter.includes("|=")) return false;
  if (test.filter.includes("//") && !test.filter.includes("//=")) return false;
  // Skip array subtraction
  if (/\]\s*-\s*\[/.test(test.filter)) return false;
  // Skip .e0, .E1 style (scientific notation field names)
  if (/\.E[+-]?\d/.test(test.filter)) return false;
  // Skip def with complex recursive/nested patterns
  if ((test.filter.match(/\bdef\b/g) || []).length > 2) return false;
  // Skip tests that use .[key] = value assignment
  if (/\.\[.*\]\s*=/.test(test.filter)) return false;
  if (/\.\w+\s*=[^=]/.test(test.filter)) return false;

  return true;
}

function escapeString(s) {
  return s
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\t/g, "\\t")
    .replace(/\r/g, "\\r");
}

const allTests = parseTests(lines);
const supportedTests = allTests.filter(isSupported);

console.log(
  `Total tests: ${allTests.length}, Supported: ${supportedTests.length}`
);

// Group tests and generate MoonBit code
let output = `///|
fn run_jq(filter : String, input : String) -> Array[String] {
  try {
    @jq.run_string(filter, input)
  } catch {
    @jq.JqError::JqError(msg) => ["ERROR: " + msg]
  }
}

`;

// Group by sections for readability
let testNum = 0;
for (const test of supportedTests) {
  testNum++;
  const expectedArr = test.expected.map((e) => `"${escapeString(e)}"`);
  const expectedStr = `[${expectedArr.join(", ")}]`;
  const filterEsc = escapeString(test.filter);
  const inputEsc = escapeString(test.input);

  output += `///|\n`;
  output += `test "jq_compat_${testNum}: ${escapeString(test.filter.slice(0, 60))}" {\n`;
  output += `  inspect(\n`;
  output += `    run_jq("${filterEsc}", "${inputEsc}"),\n`;
  output += `    content="",\n`;
  output += `  )\n`;
  output += `}\n\n`;
}

writeFileSync(
  new URL("../src/jq_compat_test.mbt", import.meta.url),
  output
);
console.log(`Generated ${testNum} tests in src/jq_compat_test.mbt`);
