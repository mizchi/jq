///|
/// Check if a JSON value is truthy (not false and not null).
fn is_truthy(v : Json) -> Bool {
  match v {
    False | Null => false
    _ => true
  }
}

///|
/// Return the jq type name of a JSON value.
fn json_type(v : Json) -> String {
  match v {
    Null => "null"
    True | False => "boolean"
    Number(_) => "number"
    String(_) => "string"
    Array(_) => "array"
    Object(_) => "object"
  }
}

///|
/// Perform arithmetic on two JSON values.
fn arith_op(op : ArithOp, left : Json, right : Json) -> Json raise JqError {
  match (op, left, right) {
    (Add, Number(a, ..), Number(b, ..)) => Json::number(a + b)
    (Sub, Number(a, ..), Number(b, ..)) => Json::number(a - b)
    (Mul, Number(a, ..), Number(b, ..)) => Json::number(a * b)
    (Div, Number(_, ..), Number(b, ..)) => {
      if b == 0.0 {
        raise JqError("division by zero")
      }
      Json::number(
        match (left, right) {
          (Number(a, ..), Number(b, ..)) => a / b
          _ => raise JqError("unreachable")
        },
      )
    }
    (Mod, Number(a, ..), Number(b, ..)) =>
      if a != a || b != b {
        Json::number(0.0 / 0.0)
      } else {
        Json::number((a.to_int() % b.to_int()).to_double())
      }
    (Mul, String(_), Number(n, ..)) =>
      if n != n || n < 0.0 {
        Json::null()
      } else if n < 1.0 {
        Json::string("")
      } else {
        let s = match left {
          String(s) => s
          _ => ""
        }
        let count = n.to_int()
        let buf = StringBuilder::new()
        for i = 0; i < count; i = i + 1 {
          buf.write_string(s)
        }
        Json::string(buf.to_string())
      }
    (Mul, Number(n, ..), String(_)) =>
      if n != n || n < 0.0 {
        Json::null()
      } else if n < 1.0 {
        Json::string("")
      } else {
        let s = match right {
          String(s) => s
          _ => ""
        }
        let count = n.to_int()
        let buf = StringBuilder::new()
        for i = 0; i < count; i = i + 1 {
          buf.write_string(s)
        }
        Json::string(buf.to_string())
      }
    (Mul, Object(a), Object(b)) => {
      let result = a.copy()
      b.each((k, vb) => {
        match (result.get(k), vb) {
          (Some(Object(va_map)), Object(vb_map)) =>
            result[k] = arith_op(
              Mul,
              Json::object(va_map),
              Json::object(vb_map),
            )
          _ => result[k] = vb
        }
      })
      Json::object(result)
    }
    (Div, String(s), String(d)) => {
      let parts : Array[Json] = []
      s.split(d).each(part => parts.push(Json::string(part.to_string())))
      Json::array(parts)
    }
    (Sub, Array(a), Array(b)) => {
      let result : Array[Json] = []
      for i = 0; i < a.length(); i = i + 1 {
        let mut found = false
        for j = 0; j < b.length(); j = j + 1 {
          if a[i] == b[j] {
            found = true
            break
          }
        }
        if not(found) {
          result.push(a[i])
        }
      }
      Json::array(result)
    }
    (Add, String(a), String(b)) => Json::string(a + b)
    (Add, Array(a), Array(b)) => {
      let result = a.copy()
      for i = 0; i < b.length(); i = i + 1 {
        result.push(b[i])
      }
      Json::array(result)
    }
    (Add, Object(a), Object(b)) => {
      let result = a.copy()
      b.each((k, v) => result[k] = v)
      Json::object(result)
    }
    (Add, Null, x) => x
    (Add, x, Null) => x
    _ =>
      raise JqError(
        "cannot apply " +
        op.to_string() +
        " to " +
        json_type(left) +
        " and " +
        json_type(right),
      )
  }
}

///|
/// Return a sort-order index for JSON type ordering.
fn type_order(v : Json) -> Int {
  match v {
    Null => 0
    False => 1
    True => 2
    Number(_) => 3
    String(_) => 4
    Array(_) => 5
    Object(_) => 6
  }
}

///|
/// Compare two JSON values, returning -1, 0, or 1.
fn compare_json(a : Json, b : Json) -> Int {
  let ta = type_order(a)
  let tb = type_order(b)
  if ta != tb {
    return if ta < tb { -1 } else { 1 }
  }
  match (a, b) {
    (Null, Null) => 0
    (False, False) => 0
    (True, True) => 0
    (False, True) => -1
    (True, False) => 1
    (Number(x, ..), Number(y, ..)) =>
      if x < y {
        -1
      } else if x > y {
        1
      } else {
        0
      }
    (String(x), String(y)) => if x < y { -1 } else if x > y { 1 } else { 0 }
    (Array(xs), Array(ys)) => {
      let len = if xs.length() < ys.length() {
        xs.length()
      } else {
        ys.length()
      }
      for i = 0; i < len; i = i + 1 {
        let c = compare_json(xs[i], ys[i])
        if c != 0 {
          return c
        }
      }
      if xs.length() < ys.length() {
        -1
      } else if xs.length() > ys.length() {
        1
      } else {
        0
      }
    }
    (Object(ma), Object(mb)) => {
      let ka : Array[String] = []
      ma.each((k, _) => ka.push(k))
      ka.sort()
      let kb : Array[String] = []
      mb.each((k, _) => kb.push(k))
      kb.sort()
      let klen = if ka.length() < kb.length() {
        ka.length()
      } else {
        kb.length()
      }
      for i = 0; i < klen; i = i + 1 {
        if ka[i] < kb[i] {
          return -1
        } else if ka[i] > kb[i] {
          return 1
        }
      }
      if ka.length() != kb.length() {
        return if ka.length() < kb.length() { -1 } else { 1 }
      }
      for i = 0; i < ka.length(); i = i + 1 {
        let va = match ma.get(ka[i]) {
          Some(v) => v
          None => Json::null()
        }
        let vb = match mb.get(ka[i]) {
          Some(v) => v
          None => Json::null()
        }
        let c = compare_json(va, vb)
        if c != 0 {
          return c
        }
      }
      0
    }
    _ => 0
  }
}

///|
/// Apply a comparison operator to two JSON values.
fn compare_op(op : CmpOp, left : Json, right : Json) -> Bool {
  let cmp = compare_json(left, right)
  match op {
    Eq => left == right
    Ne => left != right
    Lt => cmp < 0
    Gt => cmp > 0
    Le => cmp <= 0
    Ge => cmp >= 0
  }
}

///|
/// Recursively yield a value and all its descendants.
fn recurse_impl(
  input : Json,
  yield_ : (Json) -> Unit raise JqError,
) -> Unit raise JqError {
  yield_(input)
  match input {
    Array(arr) =>
      for i = 0; i < arr.length(); i = i + 1 {
        recurse_impl(arr[i], yield_)
      }
    Object(map) => map.each((_k, v) => recurse_impl(v, yield_))
    _ => ()
  }
}

///|
/// Flatten nested arrays up to a given depth.
fn flatten_impl(arr : Array[Json], depth : Int, result : Array[Json]) -> Unit {
  for i = 0; i < arr.length(); i = i + 1 {
    match arr[i] {
      Array(sub) =>
        if depth > 0 {
          flatten_impl(sub, depth - 1, result)
        } else {
          result.push(arr[i])
        }
      _ => result.push(arr[i])
    }
  }
}

///|
/// Check if JSON value `a` contains value `b` recursively.
fn json_contains(a : Json, b : Json) -> Bool {
  match (a, b) {
    (_, _) if a == b => true
    (String(s), String(sub)) => s.contains(sub)
    (Array(arr_a), Array(arr_b)) => {
      let mut ok = true
      for i = 0; i < arr_b.length(); i = i + 1 {
        let mut found = false
        for j = 0; j < arr_a.length(); j = j + 1 {
          if json_contains(arr_a[j], arr_b[i]) {
            found = true
            break
          }
        }
        if not(found) {
          ok = false
          break
        }
      }
      ok
    }
    (Object(map_a), Object(map_b)) => {
      let mut ok = true
      map_b.each((k, vb) => {
        match map_a.get(k) {
          Some(va) => if not(json_contains(va, vb)) { ok = false }
          None => ok = false
        }
      })
      ok
    }
    _ => false
  }
}

///|
/// Recursively apply a filter to all sub-values (walk builtin).
/// Matches jq semantics:
/// - Arrays: [.[] | walk(f)] — collect all walk outputs per element, then apply f
/// - Objects: reduce pattern — use first walk output per value, then apply f
/// - Scalars: apply f directly
fn walk_impl(
  input : Json,
  f : Filter,
  env : Scope,
  yield_ : (Json) -> Unit raise JqError,
) -> Unit raise JqError {
  match input {
    Array(arr) => {
      // jq: [.[] | walk(f)] — collect ALL walk outputs into one array
      let collected : Array[Json] = []
      for i = 0; i < arr.length(); i = i + 1 {
        walk_impl(arr[i], f, env, walked => collected.push(walked))
      }
      let transformed = Json::array(collected)
      eval(f, transformed, env, yield_)
    }
    Object(map) => {
      // jq: reduce keys_unsorted[] as $key ({}; . + {($key): ($in[$key] | walk(f))})
      // reduce uses first output per key; if no output, key is skipped
      let result : Map[String, Json] = Map::new()
      map.each((k, v) => {
        let mut found = false
        walk_impl(v, f, env, walked => {
          if not(found) {
            found = true
            result[k] = walked
            raise JqError("__walk_break__")
          }
        }) catch {
          JqError("__walk_break__") => ()
          e => raise e
          // If walk produced no output, the key is skipped (reduce semantics)
        }
      })
      let transformed = Json::object(result)
      eval(f, transformed, env, yield_)
    }
    _ => eval(f, input, env, yield_)
  }
}

///|
/// Bind variables from a destructuring pattern against a JSON value.
fn bind_pattern(env : Scope, pattern : Pattern, value : Json) -> Scope {
  match pattern {
    PatVar(name) => env.bind_var(name, value)
    PatArray(pats) => {
      let arr = match value {
        Array(a) => a
        _ => []
      }
      let mut new_env = env
      for i = 0; i < pats.length(); i = i + 1 {
        let v = if i < arr.length() { arr[i] } else { Json::null() }
        new_env = bind_pattern(new_env, pats[i], v)
      }
      new_env
    }
    PatObject(fields) => {
      let map : Map[String, Json] = match value {
        Object(m) => m
        _ => Map::new()
      }
      let mut new_env = env
      for field in fields {
        let (key, pat) = field
        let v = match map.get(key) {
          Some(v) => v
          None => Json::null()
        }
        new_env = bind_pattern(new_env, pat, v)
      }
      new_env
    }
  }
}

///|
/// Convert a JSON value to its string representation for string interpolation.
fn json_to_interp_string(v : Json) -> String {
  match v {
    String(s) => s
    Null => "null"
    True => "true"
    False => "false"
    Number(n, ..) => {
      let i = n.to_int()
      if i.to_double() == n {
        i.to_string()
      } else {
        n.to_string()
      }
    }
    _ => v.stringify()
  }
}

///|
let jq_error_prefix : String = "\u0000json:"

///|
fn jq_error_encode(v : Json) -> String {
  match v {
    String(s) => s
    _ => jq_error_prefix + v.stringify()
  }
}

///|
fn jq_error_decode(msg : String) -> Json {
  if msg.has_prefix(jq_error_prefix) {
    let json_str = msg.view(start_offset=jq_error_prefix.length())
    @json.parse(json_str) catch {
      _ => Json::string(msg)
    }
  } else {
    Json::string(msg)
  }
}
