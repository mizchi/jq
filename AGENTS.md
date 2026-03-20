# MoonBit jq Clone

This is a [MoonBit](https://docs.moonbitlang.com) project implementing a jq clone.

## Quick Commands

```bash
just           # check + test
just fmt       # format code
just check     # type check
just test      # run tests
just test-update  # update snapshot tests
just run       # run main
```

## Project Structure

- `src/` - Library (lexer, parser, evaluator)
- `src/main/` - CLI entry point
- `moon.mod.json` - Module definition
- `moon.pkg.json` - Package dependencies (per directory)

## Coding Convention

- Each block is separated by `///|`
- MoonBit code uses snake_case for variables/functions
- UpperCamelCase for types, enums, and enum variants
- Type parameter comes after `fn`: `fn[T] foo(x: T) -> T`
- Use `moon doc '<Type>'` to explore APIs before implementing

## Tooling

- `moon fmt` - format code
- `moon info` - update generated package interfaces
- `moon test` - run tests. Use `moon test --update` to update snapshots.
- `moon check --deny-warn` - type check with warnings as errors
- `moon doc '<query>'` - discover APIs

## Before Commit

```bash
just release-check  # fmt + info + check + test
```
