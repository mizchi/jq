///|
fn run_bench(filter : String, input : Json) -> Array[Json] {
  run(filter, input) catch {
    _ => []
  }
}

///|
fn run_compiled_bench(filter : Filter, input : Json) -> Array[Json] {
  run_compiled(filter, input) catch {
    _ => []
  }
}

///|
fn compile_bench(filter : String) -> Filter {
  compile(filter) catch {
    _ => Identity
  }
}

///|
test "bench" {
  let b = @bench.Bench::new()
  let obj3 = @json.parse("{\"a\":1,\"b\":2,\"c\":3}") catch {
    _ => Json::null()
  }
  let nested = @json.parse("{\"a\":{\"b\":{\"c\":{\"d\":42}}}}") catch {
    _ => Json::null()
  }
  let arr10 = @json.parse("[1,2,3,4,5,6,7,8,9,10]") catch { _ => Json::null() }
  let unsorted = @json.parse("[9,3,7,1,5,8,2,6,4,10]") catch {
    _ => Json::null()
  }
  let obj5 = @json.parse("{\"a\":1,\"b\":2,\"c\":3,\"d\":4,\"e\":5}") catch {
    _ => Json::null()
  }
  let records = @json.parse(
    "[{\"k\":\"a\",\"v\":1},{\"k\":\"b\",\"v\":2},{\"k\":\"a\",\"v\":3},{\"k\":\"b\",\"v\":4},{\"k\":\"c\",\"v\":5}]",
  ) catch {
    _ => Json::null()
  }
  let deep = @json.parse(
    "{\"a\":{\"b\":{\"c\":1,\"d\":[2,3]},\"e\":4},\"f\":5}",
  ) catch {
    _ => Json::null()
  }
  let str_input = @json.parse("\"hello,world,foo,bar,baz\"") catch {
    _ => Json::null()
  }
  let arr5 = @json.parse("[1,2,3,4,5]") catch { _ => Json::null() }
  let if_input = @json.parse("{\"a\":5,\"b\":3}") catch { _ => Json::null() }
  // Pre-compile all filters
  let f_identity = compile_bench(".")
  let f_field = compile_bench(".a")
  let f_nested = compile_bench(".a.b.c.d")
  let f_iterate = compile_bench("[.[] | . * 2]")
  let f_select = compile_bench("[.[] | select(. > 5)]")
  let f_map = compile_bench("map(. + 1)")
  let f_sort = compile_bench("sort")
  let f_obj = compile_bench("{x: .a, y: .b}")
  let f_reduce = compile_bench("reduce .[] as $x (0; . + $x)")
  let f_keys = compile_bench("keys | length")
  let f_group = compile_bench(
    "group_by(.k) | map({key: .[0].k, sum: map(.v) | add})",
  )
  let f_recurse = compile_bench("[.. | numbers]")
  let f_split = compile_bench("split(\",\") | join(\"-\")")
  let f_pipe = compile_bench(".[] | . * 2 | . + 1 | tostring | length")
  let f_complex = compile_bench(
    "if .a > 0 then {r: (.a + .b)} else {r: (.a - .b)} end",
  )
  // Eval-only benchmarks (pre-compiled)
  b.bench(name="identity", fn() { b.keep(run_compiled_bench(f_identity, obj3)) })
  b.bench(name="field_access", fn() {
    b.keep(run_compiled_bench(f_field, obj3))
  })
  b.bench(name="nested_field", fn() {
    b.keep(run_compiled_bench(f_nested, nested))
  })
  b.bench(name="array_iterate", fn() {
    b.keep(run_compiled_bench(f_iterate, arr10))
  })
  b.bench(name="select_filter", fn() {
    b.keep(run_compiled_bench(f_select, arr10))
  })
  b.bench(name="map", fn() { b.keep(run_compiled_bench(f_map, arr10)) })
  b.bench(name="sort", fn() { b.keep(run_compiled_bench(f_sort, unsorted)) })
  b.bench(name="object_construct", fn() {
    b.keep(run_compiled_bench(f_obj, obj3))
  })
  b.bench(name="reduce", fn() { b.keep(run_compiled_bench(f_reduce, arr10)) })
  b.bench(name="keys_length", fn() { b.keep(run_compiled_bench(f_keys, obj5)) })
  b.bench(name="group_by_map", fn() {
    b.keep(run_compiled_bench(f_group, records))
  })
  b.bench(name="recursive_descent", fn() {
    b.keep(run_compiled_bench(f_recurse, deep))
  })
  b.bench(name="split_join", fn() {
    b.keep(run_compiled_bench(f_split, str_input))
  })
  b.bench(name="pipe_chain", fn() { b.keep(run_compiled_bench(f_pipe, arr5)) })
  b.bench(name="parse_complex", fn() {
    b.keep(run_compiled_bench(f_complex, if_input))
  })
  // Parse-only benchmark
  b.bench(name="parse_only", fn() {
    b.keep(
      compile_bench("group_by(.k) | map({key: .[0].k, sum: map(.v) | add})"),
    )
  })
  // Full pipeline (parse + eval) for comparison
  b.bench(name="full_identity", fn() { b.keep(run_bench(".", obj3)) })
  b.bench(name="full_reduce", fn() {
    b.keep(run_bench("reduce .[] as $x (0; . + $x)", arr10))
  })
  println(b.dump_summaries())
}
