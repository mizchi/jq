///|
fn run(filter : String, input : String) -> Array[String] {
  @jq.run_string(filter, input) catch {
    @jq.JqError::JqError(msg) => ["ERROR: " + msg]
  }
}

///|
test "identity" {
  inspect(run(".", "42"), content="[\"42\"]")
  inspect(run(".", "\"hello\""), content="[\"\\\"hello\\\"\"]")
  inspect(
    run(".", "{\"a\":1}"),
    content=(
      #|["{\"a\":1}"]
    ),
  )
}

///|
test "field access" {
  inspect(
    run(".foo", "{\"foo\":42}"),
    content=(
      #|["42"]
    ),
  )
  inspect(
    run(".foo.bar", "{\"foo\":{\"bar\":1}}"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "array index" {
  inspect(
    run(".[0]", "[10,20,30]"),
    content=(
      #|["10"]
    ),
  )
  inspect(
    run(".[-1]", "[10,20,30]"),
    content=(
      #|["30"]
    ),
  )
}

///|
test "iterate" {
  inspect(
    run(".[]", "[1,2,3]"),
    content=(
      #|["1", "2", "3"]
    ),
  )
}

///|
test "pipe" {
  inspect(
    run(".foo | .bar", "{\"foo\":{\"bar\":99}}"),
    content=(
      #|["99"]
    ),
  )
}

///|
test "comma" {
  inspect(
    run(".foo, .bar", "{\"foo\":1,\"bar\":2}"),
    content=(
      #|["1", "2"]
    ),
  )
}

///|
test "literals" {
  inspect(
    run("null", "0"),
    content=(
      #|["null"]
    ),
  )
  inspect(
    run("true", "0"),
    content=(
      #|["true"]
    ),
  )
  inspect(
    run("42", "0"),
    content=(
      #|["42"]
    ),
  )
  inspect(
    run("\"hello\"", "0"),
    content=(
      #|["\"hello\""]
    ),
  )
}

///|
test "array construct" {
  inspect(
    run("[.foo, .bar]", "{\"foo\":1,\"bar\":2}"),
    content=(
      #|["[1,2]"]
    ),
  )
}

///|
test "object construct" {
  inspect(
    run("{a: .foo}", "{\"foo\":42}"),
    content=(
      #|["{\"a\":42}"]
    ),
  )
}

///|
test "arithmetic" {
  inspect(
    run(". + 1", "2"),
    content=(
      #|["3"]
    ),
  )
  inspect(
    run(". * 2", "3"),
    content=(
      #|["6"]
    ),
  )
  inspect(
    run(". - 1", "5"),
    content=(
      #|["4"]
    ),
  )
  inspect(
    run("10 / 2", "0"),
    content=(
      #|["5"]
    ),
  )
}

///|
test "comparison" {
  inspect(
    run(". == 1", "1"),
    content=(
      #|["true"]
    ),
  )
  inspect(
    run(". > 1", "2"),
    content=(
      #|["true"]
    ),
  )
  inspect(
    run(". < 1", "0"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "if-then-else" {
  inspect(
    run("if . > 0 then \"pos\" else \"neg\" end", "1"),
    content=(
      #|["\"pos\""]
    ),
  )
  inspect(
    run("if . > 0 then \"pos\" else \"neg\" end", "-1"),
    content=(
      #|["\"neg\""]
    ),
  )
}

///|
test "length" {
  inspect(
    run("length", "[1,2,3]"),
    content=(
      #|["3"]
    ),
  )
  inspect(
    run("length", "\"hello\""),
    content=(
      #|["5"]
    ),
  )
  inspect(
    run("length", "{\"a\":1,\"b\":2}"),
    content=(
      #|["2"]
    ),
  )
}

///|
test "keys and values" {
  inspect(
    run("keys", "{\"a\":1,\"b\":2}"),
    content=(
      #|["[\"a\",\"b\"]"]
    ),
  )
  inspect(
    run("values", "{\"a\":1,\"b\":2}"),
    content=(
      #|["{\"a\":1,\"b\":2}"]
    ),
  )
}

///|
test "type" {
  inspect(
    run("type", "42"),
    content=(
      #|["\"number\""]
    ),
  )
  inspect(
    run("type", "\"s\""),
    content=(
      #|["\"string\""]
    ),
  )
  inspect(
    run("type", "null"),
    content=(
      #|["\"null\""]
    ),
  )
}

///|
test "select" {
  inspect(
    run("[.[] | select(. > 2)]", "[1,2,3,4,5]"),
    content=(
      #|["[3,4,5]"]
    ),
  )
}

///|
test "map" {
  inspect(
    run("map(. * 2)", "[1,2,3]"),
    content=(
      #|["[2,4,6]"]
    ),
  )
}

///|
test "add" {
  inspect(
    run("add", "[1,2,3]"),
    content=(
      #|["6"]
    ),
  )
}

///|
test "sort" {
  inspect(
    run("sort", "[3,1,2]"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "reverse" {
  inspect(
    run("reverse", "[1,2,3]"),
    content=(
      #|["[3,2,1]"]
    ),
  )
}

///|
test "unique" {
  inspect(
    run("unique", "[1,2,1,3,2]"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "flatten" {
  inspect(
    run("flatten", "[[1,2],[3,[4]]]"),
    content=(
      #|["[1,2,3,4]"]
    ),
  )
}

///|
test "range" {
  inspect(
    run("[range(3)]", "null"),
    content=(
      #|["[0,1,2]"]
    ),
  )
  inspect(
    run("[range(1;4)]", "null"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "reduce" {
  inspect(
    run("reduce .[] as $x (0; . + $x)", "[1,2,3,4]"),
    content=(
      #|["10"]
    ),
  )
}

///|
test "variable binding" {
  inspect(
    run(".foo as $x | .bar + $x", "{\"foo\":10,\"bar\":20}"),
    content=(
      #|["30"]
    ),
  )
}

///|
test "def" {
  inspect(
    run("def double: . * 2; [.[] | double]", "[1,2,3]"),
    content=(
      #|["[2,4,6]"]
    ),
  )
}

///|
test "try" {
  inspect(
    run("[.[] | try .foo]", "[{\"foo\":1},{},2]"),
    content=(
      #|["[1,null]"]
    ),
  )
}

///|
test "recursive descent" {
  inspect(
    run("[.. | numbers]", "{\"a\":{\"b\":1},\"c\":2}"),
    content=(
      #|["[1,2]"]
    ),
  )
}

///|
test "string operations" {
  inspect(
    run("split(\",\")", "\"a,b,c\""),
    content=(
      #|["[\"a\",\"b\",\"c\"]"]
    ),
  )
  inspect(
    run("join(\"-\")", "[\"a\",\"b\",\"c\"]"),
    content=(
      #|["\"a-b-c\""]
    ),
  )
  inspect(
    run("ascii_upcase", "\"hello\""),
    content=(
      #|["\"HELLO\""]
    ),
  )
  inspect(
    run("ascii_downcase", "\"HELLO\""),
    content=(
      #|["\"hello\""]
    ),
  )
}

///|
test "to_entries and from_entries" {
  inspect(
    run("[to_entries[] | .key]", "{\"a\":1,\"b\":2}"),
    content=(
      #|["[\"a\",\"b\"]"]
    ),
  )
}

///|
test "has" {
  inspect(
    run("has(\"foo\")", "{\"foo\":1}"),
    content=(
      #|["true"]
    ),
  )
  inspect(
    run("has(\"bar\")", "{\"foo\":1}"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "contains" {
  inspect(
    run("contains([2,3])", "[1,2,3,4]"),
    content=(
      #|["true"]
    ),
  )
  inspect(
    run("contains([5])", "[1,2,3]"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "startswith and endswith" {
  inspect(
    run("startswith(\"he\")", "\"hello\""),
    content=(
      #|["true"]
    ),
  )
  inspect(
    run("endswith(\"lo\")", "\"hello\""),
    content=(
      #|["true"]
    ),
  )
}

///|
test "any and all" {
  inspect(
    run("any(. > 3)", "[1,2,3,4]"),
    content=(
      #|["true"]
    ),
  )
  inspect(
    run("all(. > 0)", "[1,2,3]"),
    content=(
      #|["true"]
    ),
  )
  inspect(
    run("all(. > 1)", "[1,2,3]"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "min and max" {
  inspect(
    run("min", "[3,1,2]"),
    content=(
      #|["1"]
    ),
  )
  inspect(
    run("max", "[3,1,2]"),
    content=(
      #|["3"]
    ),
  )
}

///|
test "tostring and tonumber" {
  inspect(
    run("tostring", "42"),
    content=(
      #|["\"42\""]
    ),
  )
  inspect(
    run("tonumber", "\"42\""),
    content=(
      #|["42"]
    ),
  )
}

///|
test "not" {
  inspect(
    run("not", "true"),
    content=(
      #|["false"]
    ),
  )
  inspect(
    run("not", "false"),
    content=(
      #|["true"]
    ),
  )
  inspect(
    run("not", "null"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "object shorthand" {
  inspect(
    run("{foo}", "{\"foo\":42}"),
    content=(
      #|["{\"foo\":42}"]
    ),
  )
}

///|
test "sort_by" {
  inspect(
    run(
      "sort_by(.age)", "[{\"name\":\"b\",\"age\":2},{\"name\":\"a\",\"age\":1}]",
    ),
    content=(
      #|["[{\"name\":\"a\",\"age\":1},{\"name\":\"b\",\"age\":2}]"]
    ),
  )
}

///|
test "group_by" {
  inspect(
    run("group_by(.a)", "[{\"a\":1},{\"a\":2},{\"a\":1}]"),
    content=(
      #|["[[{\"a\":1},{\"a\":1}],[{\"a\":2}]]"]
    ),
  )
}

///|
test "empty" {
  inspect(
    run("[1, empty, 2]", "null"),
    content=(
      #|["[1,2]"]
    ),
  )
}

///|
test "limit" {
  inspect(
    run("[limit(2; .[])]", "[1,2,3,4,5]"),
    content=(
      #|["[1,2]"]
    ),
  )
}

///|
test "first and last" {
  inspect(
    run("first(.[])", "[1,2,3]"),
    content=(
      #|["1"]
    ),
  )
  inspect(
    run("last(.[])", "[1,2,3]"),
    content=(
      #|["3"]
    ),
  )
}

///|
test "and or" {
  inspect(
    run("true and false", "null"),
    content=(
      #|["false"]
    ),
  )
  inspect(
    run("true or false", "null"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "tojson and fromjson" {
  inspect(
    run("tojson", "[1,2]"),
    content=(
      #|["\"[1,2]\""]
    ),
  )
  inspect(
    run("fromjson", "\"[1,2]\""),
    content=(
      #|["[1,2]"]
    ),
  )
}

///|
test "abs floor ceil round" {
  inspect(
    run("abs", "-5"),
    content=(
      #|["5"]
    ),
  )
  inspect(
    run("floor", "3.7"),
    content=(
      #|["3"]
    ),
  )
  inspect(
    run("ceil", "3.2"),
    content=(
      #|["4"]
    ),
  )
  inspect(
    run("round", "3.5"),
    content=(
      #|["4"]
    ),
  )
}

///|
test "ltrimstr and rtrimstr" {
  inspect(
    run("ltrimstr(\"he\")", "\"hello\""),
    content=(
      #|["\"llo\""]
    ),
  )
  inspect(
    run("rtrimstr(\"lo\")", "\"hello\""),
    content=(
      #|["\"hel\""]
    ),
  )
}

///|
test "string addition" {
  inspect(
    run(". + \" world\"", "\"hello\""),
    content=(
      #|["\"hello world\""]
    ),
  )
}

///|
test "array addition" {
  inspect(
    run(". + [4,5]", "[1,2,3]"),
    content=(
      #|["[1,2,3,4,5]"]
    ),
  )
}

///|
test "object addition" {
  inspect(
    run(". + {\"b\":2}", "{\"a\":1}"),
    content=(
      #|["{\"a\":1,\"b\":2}"]
    ),
  )
}

///|
test "null propagation" {
  inspect(
    run(".foo", "null"),
    content=(
      #|["null"]
    ),
  )
  inspect(
    run(".foo.bar", "{\"foo\":null}"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "optional field" {
  inspect(
    run(".foo?", "42"),
    content=(
      #|[]
    ),
  )
  inspect(
    run("[.[]?]", "42"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "nested array construct" {
  inspect(
    run("[.[] | . * 2]", "[1,2,3]"),
    content=(
      #|["[2,4,6]"]
    ),
  )
}

///|
test "numbers" {
  inspect(
    run("[.. | numbers]", "{\"a\":{\"b\":1,\"c\":[2,3]},\"d\":4}"),
    content=(
      #|["[1,2,3,4]"]
    ),
  )
}
