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

## Compatibility

94.7% compatible with jq 1.8.1 (178/188 verified tests from `tests/jq.test`).

334 of 514 tests ported. 129 tests excluded due to unimplemented features. 401 MoonBit tests total.

### Supported Features

| Category | Features |
|---|---|
| Basic | `.`, `.foo`, `.[n]`, `.[]`, `..`, `.[m:n]` |
| Operators | `\|`, `,`, `+ - * / %`, `== != < > <= >=`, `and or not`, `//` |
| Construction | `[expr]`, `{k: v}`, `{foo}` (shorthand), `(expr)` |
| Control | `if-then-elif-else-end`, `try-catch`, `.foo?`, `foreach`, `while`, `until` |
| Binding | `as $x`, `reduce`, `def f: body;`, `def f(a;b): body;` |
| Builtins | `length`, `keys`, `values`, `type`, `select`, `map`, `map_values`, `empty`, `add`, `sort`, `sort_by`, `group_by`, `unique`, `unique_by`, `reverse`, `flatten`, `min`, `max`, `min_by`, `max_by`, `first`, `last`, `limit`, `range`, `has`, `contains`, `inside`, `any`, `all`, `tostring`, `tonumber`, `toboolean`, `tojson`, `fromjson`, `ascii_downcase`, `ascii_upcase`, `split`, `join`, `startswith`, `endswith`, `ltrimstr`, `rtrimstr`, `trim`, `ltrim`, `rtrim`, `trimstr`, `abs`, `fabs`, `floor`, `ceil`, `round`, `explode`, `implode`, `to_entries`, `from_entries`, `with_entries`, `walk`, `transpose`, `bsearch`, `indices`, `index`, `rindex`, `not`, `recurse`, `debug`, `getpath`, `IN`, `error`, `paths`, `isempty`, `nth`, `skip`, `builtins` |
| Math | `sqrt`, `sin`, `cos`, `atan`, `atan2`, `log`, `log2`, `exp`, `exp2`, `pow`, `infinite`, `nan`, `isnan`, `isinfinite`, `isfinite`, `isnormal` |
| Formats | `@base64`, `@base64d`, `@json`, `@text`, `@html`, `@uri` |
| Types | `numbers`, `strings`, `booleans`, `nulls`, `arrays`, `objects`, `iterables`, `scalars` |

### Excluded Tests (129 of 514)

| Feature | Tests | Notes |
|---|---|---|
| `=` assignment | 26 | Requires path expression tracking |
| `?//` alternative destructuring | 17 | Parser extension needed |
| `\|=` update assignment | 14 | Requires path expression tracking |
| `\(expr)` string interpolation | 10 | Lexer rework needed |
| `as [$a,$b]` destructuring bind | 9 | Pattern matching extension |
| `import/include` | 9 | Module system |
| `path()` expression | 8 | Path tracking |
| `label/break` | 6 | Non-local control flow |
| `setpath` | 6 | Path mutation |
| `del()` | 5 | Path mutation |
| `as {$a}` destructuring bind | 4 | Pattern matching extension |
| `pick()` | 4 | Path tracking |
| `delpaths()` | 3 | Path mutation |
| Other | 8 | `@csv`, `@tsv`, `@sh`, `utf8bytelength`, `$__loc__`, `input` |

See [TODO.md](TODO.md) for details.

### Known Precision Limits

- Integers > 2^53 overflow to `Infinity` (IEEE 754 double)
- `-0` outputs as `0`
- `contains` with NUL bytes may be inaccurate (JS string handling)
- `fromjson` error messages differ from jq

## Quick Commands

```bash
just           # check + test
just fmt       # format code
just check     # type check
just test      # run tests
just moonjq FILTER  # run CLI
```

## License

Apache-2.0
