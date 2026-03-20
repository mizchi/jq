///|
/// Evaluate a filter in "path mode", yielding paths (arrays of Json keys/indices).
fn eval_path(
  filter : Filter,
  input : Json,
  env : Scope,
  yield_ : (Array[Json]) -> Unit raise JqError,
) -> Unit raise JqError {
  match filter {
    Identity => yield_([])
    Field(name) => yield_([Json::string(name)])
    Index(i) => {
      let actual = if i < 0 {
        match input {
          Array(arr) => arr.length() + i
          _ => i
        }
      } else {
        i
      }
      yield_([Json::number(actual.to_double())])
    }
    Iterate =>
      match input {
        Array(arr) =>
          for i in 0..<arr.length() {
            yield_([Json::number(i.to_double())])
          }
        Object(map) => map.each((k, _) => yield_([Json::string(k)]))
        _ => raise JqError("cannot iterate over " + json_type(input))
      }
    RecurseOp => recurse_paths(input, [], yield_)
    Pipe(left, right) =>
      eval_path(left, input, env, lpath => {
        let mid = getpath_impl(input, lpath)
        eval_path(right, mid, env, rpath => {
          let full = lpath.copy()
          for r in rpath {
            full.push(r)
          }
          yield_(full)
        })
      })
    Comma(left, right) => {
      eval_path(left, input, env, yield_)
      eval_path(right, input, env, yield_)
    }
    DynIndex(expr) =>
      eval(expr, input, env, idx => {
        match idx {
          Number(n, ..) => yield_([Json::number(n)])
          String(s) => yield_([Json::string(s)])
          _ => raise JqError("invalid path index")
        }
      })
    PostfixDynIndex(base, idx_expr) =>
      eval_path(base, input, env, lpath => {
        eval(idx_expr, input, env, idx => {
          let full = lpath.copy()
          match idx {
            Number(n, ..) => full.push(Json::number(n))
            String(s) => full.push(Json::string(s))
            _ => raise JqError("invalid path index")
          }
          yield_(full)
        })
      })
    Paren(inner) => eval_path(inner, input, env, yield_)
    FuncCall(name, args) =>
      if name == "recurse" {
        recurse_paths(input, [], yield_)
      } else if name.has_prefix("$") {
        match env.get_var(name) {
          Some(v) =>
            match v {
              Number(n, ..) => yield_([Json::number(n)])
              String(s) => yield_([Json::string(s)])
              _ => raise JqError("invalid path")
            }
          None => raise JqError("undefined variable: " + name)
        }
      } else if name == "select" && args.length() == 1 {
        eval(args[0], input, env, v => if is_truthy(v) { yield_([]) })
      } else {
        raise JqError("Invalid path expression")
      }
    _ =>
      raise JqError(
        "Invalid path expression with result " +
        eval_single(filter, input, env).stringify(),
      )
  }
}

///|
fn recurse_paths(
  input : Json,
  prefix : Array[Json],
  yield_ : (Array[Json]) -> Unit raise JqError,
) -> Unit raise JqError {
  yield_(prefix)
  match input {
    Array(arr) =>
      for i in 0..<arr.length() {
        let p = prefix.copy()
        p.push(Json::number(i.to_double()))
        recurse_paths(arr[i], p, yield_)
      }
    Object(map) =>
      map.each((k, v) => {
        let p = prefix.copy()
        p.push(Json::string(k))
        recurse_paths(v, p, yield_)
      })
    _ => ()
  }
}

///|
/// Get the value at a given path in a JSON value.
fn getpath_impl(input : Json, path : Array[Json]) -> Json {
  let mut current = input
  for p in path {
    match (current, p) {
      (Object(map), String(k)) =>
        current = match map.get(k) {
          Some(v) => v
          None => Json::null()
        }
      (Array(arr), Number(n, ..)) => {
        let i = n.to_int()
        current = if i >= 0 && i < arr.length() { arr[i] } else { Json::null() }
      }
      _ => {
        current = Json::null()
        break
      }
    }
  }
  current
}

///|
/// Set the value at a given path in a JSON value, creating intermediate
/// objects/arrays as needed.
fn setpath_impl(input : Json, path : Array[Json], value : Json) -> Json {
  if path.is_empty() {
    return value
  }
  let key = path[0]
  let rest : Array[Json] = []
  for i = 1; i < path.length(); i = i + 1 {
    rest.push(path[i])
  }
  match key {
    String(k) => {
      let map = match input {
        Object(m) => m.copy()
        _ => Map::new()
      }
      let child = match map.get(k) {
        Some(v) => v
        None => Json::null()
      }
      map[k] = setpath_impl(child, rest, value)
      Json::object(map)
    }
    Number(n, ..) => {
      let raw_i = n.to_int()
      let arr = match input {
        Array(a) => a.copy()
        _ => []
      }
      let i = if raw_i < 0 { arr.length() + raw_i } else { raw_i }
      if i < 0 {
        return input
      }
      while arr.length() <= i {
        arr.push(Json::null())
      }
      arr[i] = setpath_impl(arr[i], rest, value)
      Json::array(arr)
    }
    _ => input
  }
}

///|
/// Delete multiple paths from a JSON value.
/// Paths are sorted in reverse order to avoid index shifting issues.
fn delpaths_impl(input : Json, paths : Array[Array[Json]]) -> Json {
  // Sort paths by reverse order (deeper/later first)
  let sorted = paths.copy()
  sorted.sort_by((a, b) => {
    let len = if a.length() < b.length() { a.length() } else { b.length() }
    for i = 0; i < len; i = i + 1 {
      let cmp = compare_json(a[i], b[i])
      if cmp != 0 {
        return cmp
      }
    }
    if a.length() < b.length() {
      -1
    } else if a.length() > b.length() {
      1
    } else {
      0
    }
  })
  // Delete in reverse order
  let mut result = input
  for i = sorted.length() - 1; i >= 0; i = i - 1 {
    result = delpath_single(result, sorted[i])
  }
  result
}

///|
/// Delete a single path from a JSON value.
fn delpath_single(input : Json, path : Array[Json]) -> Json {
  if path.is_empty() {
    return Json::null()
  }
  if path.length() == 1 {
    let key = path[0]
    match (input, key) {
      (Object(map), String(k)) => {
        let new_map = Map::new()
        map.each((mk, mv) => if mk != k { new_map[mk] = mv })
        Json::object(new_map)
      }
      (Array(arr), Number(n, ..)) => {
        let idx = n.to_int()
        let actual = if idx < 0 { arr.length() + idx } else { idx }
        if actual >= 0 && actual < arr.length() {
          let new_arr : Array[Json] = []
          for j = 0; j < arr.length(); j = j + 1 {
            if j != actual {
              new_arr.push(arr[j])
            }
          }
          Json::array(new_arr)
        } else {
          input
        }
      }
      _ => input
    }
  } else {
    let key = path[0]
    let rest : Array[Json] = []
    for i = 1; i < path.length(); i = i + 1 {
      rest.push(path[i])
    }
    match (input, key) {
      (Object(map), String(k)) =>
        match map.get(k) {
          Some(child) => {
            let new_map = map.copy()
            new_map[k] = delpath_single(child, rest)
            Json::object(new_map)
          }
          None => input
        }
      (Array(arr), Number(n, ..)) => {
        let idx = n.to_int()
        let actual = if idx < 0 { arr.length() + idx } else { idx }
        if actual >= 0 && actual < arr.length() {
          let new_arr = arr.copy()
          new_arr[actual] = delpath_single(arr[actual], rest)
          Json::array(new_arr)
        } else {
          input
        }
      }
      _ => input
    }
  }
}
