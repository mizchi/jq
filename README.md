# mizchi/jq

A jq clone implemented in MoonBit.

## Install CLI

```bash
moon install mizchi/jq/cmd/moonjq
```

This installs `moonjq` to `~/.moon/bin/moonjq`.

```bash
echo '{"name":"alice","age":30}' | moonjq '.name'
# "alice"

echo '[1,2,3,4,5]' | moonjq 'map(. * 2) | add'
# 30

echo '[{"a":1},{"a":2},{"a":3}]' | moonjq '[.[] | select(.a > 1)]'
# [{"a":2},{"a":3}]
```

## Use as Library

```bash
moon add mizchi/jq
```

```moonbit
let results = @jq.run(".foo", @json.parse("{\"foo\":42}"))
// results = [Number(42)]

// Pre-compile for repeated use
let filter = @jq.compile("map(. + 1)")
let r1 = @jq.run_compiled(filter, @json.parse("[1,2,3]"))
// r1 = [Array([Number(2), Number(3), Number(4)])]
```

See [README.mbt.md](src/README.mbt.md) for full doc-tested API examples.

## Features

- Lexer, recursive descent parser, callback-based evaluator
- 87.3% compatibility with jq's official test suite (151/173 verified tests)
- 50+ builtin functions
- Native CLI + JS library target

### Supported Syntax

| Category | Features |
|---|---|
| Basic | `.` (identity), `.foo`, `.[n]`, `.[]`, `..` (recursive descent) |
| Operators | `\|`, `,`, `+ - * / %`, `== != < > <= >=`, `and or not` |
| Construction | `[expr]`, `{k: v}`, `{foo}` (shorthand), `(expr)` |
| Control | `if-then-elif-else-end`, `try-catch`, `.foo?`, `try expr` |
| Binding | `as $x`, `reduce`, `def f: body;`, `def f(a;b): body;` |
| Builtins | `length`, `keys`, `values`, `type`, `select`, `map`, `map_values`, `empty`, `add`, `sort`, `sort_by`, `group_by`, `unique`, `unique_by`, `reverse`, `flatten`, `min`, `max`, `min_by`, `max_by`, `first`, `last`, `limit`, `range`, `has`, `contains`, `inside`, `any`, `all`, `tostring`, `tonumber`, `tojson`, `fromjson`, `ascii_downcase`, `ascii_upcase`, `split`, `join`, `startswith`, `endswith`, `ltrimstr`, `rtrimstr`, `trim`, `ltrim`, `rtrim`, `trimstr`, `abs`, `fabs`, `floor`, `ceil`, `round`, `explode`, `implode`, `to_entries`, `from_entries`, `with_entries`, `walk`, `transpose`, `bsearch`, `indices`, `index`, `rindex`, `not`, `recurse`, `debug`, `getpath`, `IN` |
| Formats | `@base64`, `@base64d`, `@json`, `@text`, `@html`, `@uri` |
| Types | `numbers`, `strings`, `booleans`, `nulls`, `arrays`, `objects`, `iterables`, `scalars` |

## Known Incompatibilities with jq

### Parser Limitations

- `{x:-.}` (unary minus as object value without parens) is not supported. Use `{x:(-.)}`.
- `try -.?` does not propagate to catch correctly.
- String interpolation `\(expr)` is not supported.

### Numeric Precision

- Numbers use IEEE 754 double precision. Integers larger than 2^53 overflow to `Infinity` instead of being represented exactly.
- jq outputs `2.0` for some integer-valued float results (e.g., `1+1` with string input gives `2.0` in jq, `2` here).
- Scientific notation in output (e.g., `1e-1`, `9E+999999999`) may differ.

### Unicode / String Handling

- Control characters (`\b`, `\f`) are output as literal characters instead of `\u00XX` escape sequences.
- Unicode escapes like `\u03bc` may be output as the actual character (`μ`) instead of the escape form.
- `contains` with NUL bytes (`\u0000`) may not match correctly due to JavaScript string handling.

### Slice Indexing

- Float slice indices like `.[1.2:3.5]` use truncation (`.[1:3]`) instead of jq's rounding behavior (`.[1:4]`).

### Unsupported Features

- Assignment operators: `=`, `|=`, `+=`, `-=`, `*=`, `/=`, `%=`, `//=`
- Alternative operator: `//`
- Destructuring bind: `as [$a, $b]`, `as {$a}`
- Alternative destructuring: `?//`
- String interpolation: `\(expr)`
- Control flow: `while`, `until`, `label`, `break`, `foreach`
- Path operations: `path`, `paths`, `setpath`, `delpaths`, `del`, `pick`
- Format strings: `@csv`, `@tsv`, `@sh`, `@urid`
- Module system: `import`, `include`, `modulemeta`
- I/O: `input`, `inputs`, `input_line_number`
- Regex: `test` (pattern), `match`, `capture`, `scan`, `sub`, `gsub`, `splits`
- Other: `env`, `builtins`, `$__loc__`, `$ENV`, `nth`, `skip`, `toboolean`, `utf8bytelength`, `halt`, `stderr`, `debug(msg)`, `sqrt`, `sin`, `cos`, `atan`, `log`, `exp`, `pow`, `strftime`, `strptime`, `now`, `date`, `JOIN`, `REGEX`

### walk Behavior

- `walk(f)` where `f` produces multiple outputs generates a combinatorial explosion instead of jq's first-output behavior.

## Benchmark (js target, pre-compiled eval)

| Benchmark | Ops/sec | vs Naive | Description |
|---|---|---|---|
| identity | 4,910,610 | 10.8x | `.` |
| field_access | 3,805,345 | 10.5x | `.a` |
| nested_field | 539,358 | 2.9x | `.a.b.c.d` |
| sort | 325,085 | 2.3x | `sort` (10 elements) |
| keys_length | 468,123 | 4.3x | `keys \| length` |
| object_construct | 397,703 | 4.0x | `{x: .a, y: .b}` |
| parse_complex | 321,200 | 25.1x | `if .a > 0 then ... end` |
| reduce | 297,406 | 26.6x | `reduce .[] as $x (0; . + $x)` |
| group_by_map | 2,516,187 | 95.9x | `group_by(.k) \| map(...)` |
| split_join | 250,297 | 6.1x | `split(",") \| join("-")` |
| map | 111,305 | 3.1x | `map(. + 1)` (10 elements) |
| recursive_descent | 99,485 | 4.0x | `[.. \| numbers]` |
| array_iterate | 83,673 | 2.8x | `[.[] \| . * 2]` (10 elements) |
| select_filter | 48,006 | 6.2x | `[.[] \| select(. > 5)]` (10 elements) |
| pipe_chain | 36,160 | 4.7x | `.[] \| . * 2 \| . + 1 \| tostring \| length` |

*Measured on js target with `@bench`. "vs Naive" compares pre-compiled eval against naive parse+eval per call.*

### Optimizations Applied

- **compile/run_compiled separation**: Parse the filter once, evaluate many times
- **Persistent scope chain**: Linked-list env makes `bind_var` O(1) (no array copy)
- **eval_single fast path**: Single-output filters (Identity, Field, Literal, Pipe chains, variable refs) bypass callback/closure overhead
- **AST optimization pass**: Eliminates `Pipe(Identity, x)` → `x`, strips Paren wrappers at compile time
- **Pre-baked `$` prefix**: Variable names include `$` at parse time, avoiding runtime string concatenation

## Quick Commands

```bash
just           # check + test
just fmt       # format code
just check     # type check
just test      # run tests
just run       # run main
```

## License

Apache-2.0
