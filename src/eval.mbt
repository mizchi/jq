///|
priv enum Scope {
  Empty
  Var(String, Json, Scope)
  Func(String, Array[String], Filter, Scope)
  FilterArg(String, Filter, Scope)
}

///|
let empty_scope : Scope = Scope::Empty

///|
fn Scope::bind_var(self : Scope, name : String, value : Json) -> Scope {
  Var(name, value, self)
}

///|
fn Scope::get_var(self : Scope, name : String) -> Json? {
  match self {
    Empty => None
    Var(n, v, parent) => if n == name { Some(v) } else { parent.get_var(name) }
    Func(_, _, _, parent) => parent.get_var(name)
    FilterArg(_, _, parent) => parent.get_var(name)
  }
}

///|
fn Scope::bind_func(
  self : Scope,
  name : String,
  params : Array[String],
  body : Filter,
) -> Scope {
  Func(name, params, body, self)
}

///|
fn Scope::get_func(self : Scope, name : String) -> (Array[String], Filter)? {
  match self {
    Empty => None
    Var(_, _, parent) => parent.get_func(name)
    Func(n, params, body, parent) =>
      if n == name {
        Some((params, body))
      } else {
        parent.get_func(name)
      }
    FilterArg(_, _, parent) => parent.get_func(name)
  }
}

///|
fn Scope::bind_filter_arg(
  self : Scope,
  name : String,
  filter : Filter,
) -> Scope {
  FilterArg(name, filter, self)
}

///|
fn Scope::get_filter_arg(self : Scope, name : String) -> Filter? {
  match self {
    Empty => None
    Var(_, _, parent) => parent.get_filter_arg(name)
    Func(_, _, _, parent) => parent.get_filter_arg(name)
    FilterArg(n, f, parent) =>
      if n == name {
        Some(f)
      } else {
        parent.get_filter_arg(name)
      }
  }
}

///|
/// Fast path for single-output filters. Returns the value directly
/// without callback overhead. Falls back to eval() for multi-output filters.
fn eval_single(
  filter : Filter,
  input : Json,
  env : Scope,
) -> Json raise JqError {
  match filter {
    Identity => input
    Field(name) =>
      match input {
        Object(map) =>
          match map.get(name) {
            Some(v) => v
            None => Json::null()
          }
        Null => Json::null()
        _ => raise JqError("cannot index " + json_type(input) + " with string")
      }
    Index(i) =>
      match input {
        Array(arr) => {
          let idx = if i < 0 { arr.length() + i } else { i }
          if idx >= 0 && idx < arr.length() {
            arr[idx]
          } else {
            Json::null()
          }
        }
        _ => raise JqError("cannot index " + json_type(input) + " with number")
      }
    Literal(v) => v
    Pipe(left, right) => eval_single(right, eval_single(left, input, env), env)
    Arith(op, left, right) =>
      arith_op(
        op,
        eval_single(left, input, env),
        eval_single(right, input, env),
      )
    Compare(op, left, right) =>
      Json::boolean(
        compare_op(
          op,
          eval_single(left, input, env),
          eval_single(right, input, env),
        ),
      )
    Neg(expr) => {
      let v = eval_single(expr, input, env)
      match v {
        Number(n, ..) => Json::number(-n)
        _ => {
          let desc = match v {
            String(s) =>
              if s.iter().count() > 10 {
                let buf = StringBuilder::new()
                let mut count = 0
                s
                .iter()
                .each(c => {
                  if count < 10 {
                    buf.write_char(c)
                    count += 1
                  }
                })
                "\"" + buf.to_string() + "..."
              } else {
                "\"" + s + "\""
              }
            _ => v.stringify()
          }
          raise JqError(json_type(v) + " (" + desc + ") cannot be negated")
        }
      }
    }
    FuncCall(name, _args) =>
      if name.has_prefix("$") {
        if name == "$__loc__" {
          let m : Map[String, Json] = Map::new()
          m["file"] = Json::string("<top-level>")
          m["line"] = Json::number(1.0)
          Json::object(m)
        } else {
          match env.get_var(name) {
            Some(v) => v
            None => raise JqError("undefined variable: " + name)
          }
        }
      } else {
        // Fall back to callback eval for builtins
        let mut result = Json::null()
        eval(filter, input, env, v => result = v)
        result
      }
    _ => {
      // Fall back to callback eval
      let mut result = Json::null()
      eval(filter, input, env, v => result = v)
      result
    }
  }
}

///|
/// Core eval: evaluate a filter against input, yielding results via callback.
fn eval(
  filter : Filter,
  input : Json,
  env : Scope,
  yield_ : (Json) -> Unit raise JqError,
) -> Unit raise JqError {
  match filter {
    Identity => yield_(input)
    RecurseOp => recurse_impl(input, yield_)
    Field(name) =>
      match input {
        Object(map) =>
          match map.get(name) {
            Some(v) => yield_(v)
            None => yield_(Json::null())
          }
        Null => yield_(Json::null())
        _ => raise JqError("cannot index " + json_type(input) + " with string")
      }
    Index(i) =>
      match input {
        Array(arr) => {
          let idx = if i < 0 { arr.length() + i } else { i }
          if idx >= 0 && idx < arr.length() {
            yield_(arr[idx])
          } else {
            yield_(Json::null())
          }
        }
        _ => raise JqError("cannot index " + json_type(input) + " with number")
      }
    Slice(start, end) =>
      match input {
        Array(arr) => {
          let len = arr.length()
          let s = match start {
            Some(v) => if v < 0 { len + v } else { v }
            None => 0
          }
          let e = match end {
            Some(v) => if v < 0 { len + v } else { v }
            None => len
          }
          let result : Array[Json] = []
          for i = s; i < e && i < len; i = i + 1 {
            if i >= 0 {
              result.push(arr[i])
            }
          }
          yield_(Json::array(result))
        }
        String(str) => {
          let chars = Array::from_iter(str.iter())
          let len = chars.length()
          let s = match start {
            Some(v) => if v < 0 { len + v } else { v }
            None => 0
          }
          let e = match end {
            Some(v) => if v < 0 { len + v } else { v }
            None => len
          }
          let buf = StringBuilder::new()
          for i = s; i < e && i < len; i = i + 1 {
            if i >= 0 {
              buf.write_char(chars[i])
            }
          }
          yield_(Json::string(buf.to_string()))
        }
        Null => yield_(Json::null())
        _ => raise JqError("cannot slice " + json_type(input))
      }
    Iterate =>
      match input {
        Array(arr) =>
          for i = 0; i < arr.length(); i = i + 1 {
            yield_(arr[i])
          }
        Object(map) => map.each((_k, v) => yield_(v))
        _ => raise JqError("cannot iterate over " + json_type(input))
      }
    Pipe(left, right) =>
      eval(left, input, env, mid => eval(right, mid, env, yield_))
    Comma(left, right) => {
      eval(left, input, env, yield_)
      eval(right, input, env, yield_)
    }
    Literal(v) => yield_(v)
    ArrayConstruct(None) => yield_(Json::array([]))
    ArrayConstruct(Some(expr)) => {
      let result : Array[Json] = []
      eval(expr, input, env, v => result.push(v))
      yield_(Json::array(result))
    }
    ObjectConstruct(fields) =>
      eval_object_construct(fields, 0, Map::new(), input, env, yield_)
    Paren(expr) => eval(expr, input, env, yield_)
    Try(expr) => {
      let results : Array[Json] = []
      eval(expr, input, env, v => results.push(v)) catch {
        JqError(_) => ()
      }
      for r in results {
        yield_(r)
      }
    }
    TryCatch(expr, handler) => {
      let results : Array[Json] = []
      let mut caught_msg : String? = None
      eval(expr, input, env, v => results.push(v)) catch {
        JqError(msg) => caught_msg = Some(msg)
      }
      for r in results {
        yield_(r)
      }
      match caught_msg {
        Some(msg) => eval(handler, jq_error_decode(msg), env, yield_)
        None => ()
      }
    }
    IfThenElse(cond, then_branch, else_branch) =>
      eval(cond, input, env, cv => {
        if is_truthy(cv) {
          eval(then_branch, input, env, yield_)
        } else {
          eval(else_branch, input, env, yield_)
        }
      })
    Binding(pat, expr, body) =>
      eval(expr, input, env, v => {
        let new_env = bind_pattern(env, pat, v)
        eval(body, input, new_env, yield_)
      })
    Reduce(iter_expr, pat, init, update) => {
      let mut acc = eval_single(init, input, env)
      eval(iter_expr, input, env, v => {
        let new_env = bind_pattern(env, pat, v)
        acc = eval_single(update, acc, new_env)
      })
      yield_(acc)
    }
    FuncDef(name, params, body, rest) => {
      let new_env = env.bind_func(name, params, body)
      eval(rest, input, new_env, yield_)
    }
    FuncCall(name, args) => eval_func_call(name, args, input, env, yield_)
    DynIndex(expr) =>
      eval(expr, input, env, idx => dyn_index_impl(input, idx, yield_))
    PostfixDynIndex(base, idx_expr) =>
      eval(base, input, env, base_val => {
        eval(idx_expr, input, env, idx => dyn_index_impl(base_val, idx, yield_))
      })
    DynSlice(base, start_expr, end_expr) =>
      eval(base, input, env, base_val => {
        let mut s : Int? = None
        let mut e : Int? = None
        match start_expr {
          Some(se) =>
            eval(se, input, env, sv => {
              match sv {
                Number(n, ..) => if not(n != n) { s = Some(n.floor().to_int()) }
                _ => raise JqError("slice index must be a number")
              }
            })
          None => ()
        }
        match end_expr {
          Some(ee) =>
            eval(ee, input, env, ev => {
              match ev {
                Number(n, ..) =>
                  if not(n != n) {
                    let floored = n.floor()
                    // jq uses ceil for end index on non-integer floats
                    let idx = if floored < n {
                      floored.to_int() + 1
                    } else {
                      floored.to_int()
                    }
                    e = Some(idx)
                  }
                _ => raise JqError("slice index must be a number")
              }
            })
          None => ()
        }
        match base_val {
          Array(arr) => {
            let len = arr.length()
            let start = match s {
              Some(v) => if v < 0 { len + v } else { v }
              None => 0
            }
            let end = match e {
              Some(v) => if v < 0 { len + v } else { v }
              None => len
            }
            let result : Array[Json] = []
            for i = start; i < end && i < len; i = i + 1 {
              if i >= 0 {
                result.push(arr[i])
              }
            }
            yield_(Json::array(result))
          }
          String(str) => {
            let chars = Array::from_iter(str.iter())
            let len = chars.length()
            let start = match s {
              Some(v) => if v < 0 { len + v } else { v }
              None => 0
            }
            let end = match e {
              Some(v) => if v < 0 { len + v } else { v }
              None => len
            }
            let buf = StringBuilder::new()
            for i = start; i < end && i < len; i = i + 1 {
              if i >= 0 {
                buf.write_char(chars[i])
              }
            }
            yield_(Json::string(buf.to_string()))
          }
          Null => yield_(Json::null())
          _ => raise JqError("cannot slice " + json_type(base_val))
        }
      })
    Neg(expr) =>
      eval(expr, input, env, v => {
        match v {
          Number(n, ..) => yield_(Json::number(-n))
          _ => {
            let desc = match v {
              String(s) =>
                if s.iter().count() > 10 {
                  let buf = StringBuilder::new()
                  let mut count = 0
                  s
                  .iter()
                  .each(c => {
                    if count < 10 {
                      buf.write_char(c)
                      count += 1
                    }
                  })
                  "\"" + buf.to_string() + "..."
                } else {
                  "\"" + s + "\""
                }
              _ => v.stringify()
            }
            raise JqError(json_type(v) + " (" + desc + ") cannot be negated")
          }
        }
      })
    Arith(op, left, right) =>
      eval(left, input, env, lv => {
        eval(right, input, env, rv => yield_(arith_op(op, lv, rv)))
      })
    Compare(op, left, right) =>
      eval(left, input, env, lv => {
        eval(right, input, env, rv => {
          yield_(Json::boolean(compare_op(op, lv, rv)))
        })
      })
    LogicAnd(left, right) =>
      eval(left, input, env, lv => {
        if is_truthy(lv) {
          eval(right, input, env, rv => yield_(Json::boolean(is_truthy(rv))))
        } else {
          yield_(Json::boolean(false))
        }
      })
    LogicOr(left, right) =>
      eval(left, input, env, lv => {
        if is_truthy(lv) {
          yield_(Json::boolean(true))
        } else {
          eval(right, input, env, rv => yield_(Json::boolean(is_truthy(rv))))
        }
      })
    Alternative(left, right) => {
      let mut has_result = false
      eval(left, input, env, v => {
        if is_truthy(v) {
          has_result = true
          yield_(v)
        }
      })
      if not(has_result) {
        eval(right, input, env, yield_)
      }
    }
    Foreach(iter_expr, pat, init, update, extract) => {
      let mut acc = eval_single(init, input, env)
      eval(iter_expr, input, env, v => {
        let new_env = bind_pattern(env, pat, v)
        acc = eval_single(update, acc, new_env)
        match extract {
          Some(ext) => {
            let new_env2 = bind_pattern(env, pat, v)
            eval(ext, acc, new_env2, yield_)
          }
          None => yield_(acc)
        }
      })
    }
    StringInterp(parts) => {
      let buf = StringBuilder::new()
      for part in parts {
        let (lit, filter_opt) = part
        if not(lit.is_empty()) {
          buf.write_string(lit)
        }
        match filter_opt {
          Some(f) => {
            let v = eval_single(f, input, env)
            buf.write_string(json_to_interp_string(v))
          }
          None => ()
        }
      }
      yield_(Json::string(buf.to_string()))
    }
    Assign(path_expr, value_expr) =>
      eval(value_expr, input, env, value => {
        let mut result = input
        eval_path(path_expr, input, env, path => {
          result = setpath_impl(result, path, value)
        })
        yield_(result)
      })
    Update(path_expr, update_filter) => {
      let mut result = input
      let paths : Array[Array[Json]] = []
      eval_path(path_expr, input, env, p => paths.push(p))
      let del_paths : Array[Array[Json]] = []
      for p in paths {
        let current = getpath_impl(result, p)
        let vals : Array[Json] = []
        eval(update_filter, current, env, v => vals.push(v))
        if vals.is_empty() {
          del_paths.push(p)
        } else {
          result = setpath_impl(result, p, vals[0])
        }
      }
      if not(del_paths.is_empty()) {
        result = delpaths_impl(result, del_paths)
      }
      yield_(result)
    }
    Label(name, body) => {
      let tag = "__label_" + name
      eval(body, input, env, yield_) catch {
        JqError(msg) => if msg == tag { () } else { raise JqError(msg) }
      }
    }
    Break(name) => raise JqError("__label_" + name)
    BindingAlt(patterns, expr, body) =>
      eval(expr, input, env, v => {
        // Collect all variable names from all patterns
        let all_vars : Array[String] = []
        for pat in patterns {
          collect_pattern_vars(pat, all_vars)
        }
        // Pre-bind all variables as null
        let mut base_env = env
        for var_name in all_vars {
          base_env = base_env.bind_var(var_name, Json::null())
        }
        let mut succeeded = false
        for i = 0; i < patterns.length(); i = i + 1 {
          if not(succeeded) {
            let results : Array[Json] = []
            let mut had_error = false
            (fn() -> Unit raise JqError {
              let new_env = bind_pattern_strict(base_env, patterns[i], v)
              eval(body, input, new_env, r => results.push(r))
            })() catch {
              JqError(_) => had_error = true
            }
            if not(had_error) {
              succeeded = true
              for r in results {
                yield_(r)
              }
            }
          }
        }
      })
    UpdateAlt(path_expr, value_expr) => {
      let mut result = input
      let paths : Array[Array[Json]] = []
      eval_path(path_expr, input, env, p => paths.push(p))
      for p in paths {
        let current = getpath_impl(result, p)
        if not(is_truthy(current)) {
          let new_val = eval_single(value_expr, current, env)
          result = setpath_impl(result, p, new_val)
        }
      }
      yield_(result)
    }
  }
}

///|
fn eval_object_construct(
  fields : Array[(ObjKey, Filter)],
  idx : Int,
  acc : Map[String, Json],
  input : Json,
  env : Scope,
  yield_ : (Json) -> Unit raise JqError,
) -> Unit raise JqError {
  if idx >= fields.length() {
    yield_(Json::object(acc))
    return
  }
  let (key, value_filter) = fields[idx]
  match key {
    StrKey(name) =>
      eval(value_filter, input, env, v => {
        let new_acc = acc.copy()
        new_acc[name] = v
        eval_object_construct(fields, idx + 1, new_acc, input, env, yield_)
      })
    ExprKey(key_expr) =>
      eval(key_expr, input, env, k => {
        match k {
          String(name) =>
            eval(value_filter, input, env, v => {
              let new_acc = acc.copy()
              new_acc[name] = v
              eval_object_construct(
                fields,
                idx + 1,
                new_acc,
                input,
                env,
                yield_,
              )
            })
          _ => raise JqError("object key must be a string")
        }
      })
  }
}

///|
fn dyn_index_impl(
  base : Json,
  idx : Json,
  yield_ : (Json) -> Unit raise JqError,
) -> Unit raise JqError {
  match (base, idx) {
    (Array(arr), Number(n, ..)) =>
      if n != n {
        yield_(Json::null())
      } else {
        let i = n.to_int()
        let actual = if i < 0 { arr.length() + i } else { i }
        if actual >= 0 && actual < arr.length() {
          yield_(arr[actual])
        } else {
          yield_(Json::null())
        }
      }
    (Object(map), String(k)) =>
      match map.get(k) {
        Some(v) => yield_(v)
        None => yield_(Json::null())
      }
    (Null, _) => yield_(Json::null())
    _ =>
      raise JqError(
        "cannot index " + json_type(base) + " with " + json_type(idx),
      )
  }
}
