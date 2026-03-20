///|
/// Compile a jq filter string into a reusable Filter AST.
pub fn compile(filter_str : String) -> Filter raise JqError {
  let tokens = tokenize(filter_str)
  let filter = parse(tokens)
  optimize(filter)
}

///|
/// Execute a pre-compiled filter against JSON input.
pub fn run_compiled(filter : Filter, input : Json) -> Array[Json] raise JqError {
  let results : Array[Json] = []
  let env = empty_scope
  eval(filter, input, env, fn(v) { results.push(v) })
  results
}

///|
/// Compile and execute a jq filter string against JSON input.
pub fn run(filter_str : String, input : Json) -> Array[Json] raise JqError {
  run_compiled(compile(filter_str), input)
}

///|
/// Compile and execute a jq filter, with JSON string input/output.
pub fn run_string(
  filter_str : String,
  input_str : String,
) -> Array[String] raise JqError {
  let input = @json.parse(input_str) catch {
    _ => raise JqError("invalid JSON input")
  }
  let results = run(filter_str, input)
  results.map(fn(v) { v.stringify() })
}
