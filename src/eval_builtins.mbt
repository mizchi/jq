///|
/// Dispatch a function call to user-defined functions, filter args, or builtins.
fn eval_func_call(
  name : String,
  args : Array[Filter],
  input : Json,
  env : Scope,
  yield_ : (Json) -> Unit raise JqError,
) -> Unit raise JqError {
  // Check variable reference
  if name.has_prefix("$") {
    match env.get_var(name) {
      Some(v) => {
        yield_(v)
        return
      }
      None => raise JqError("undefined variable: " + name)
    }
  }
  // Check filter argument reference (def parameters are filter closures)
  match env.get_filter_arg(name) {
    Some(filter) => {
      eval(filter, input, env, yield_)
      return
    }
    None => ()
  }
  // Check user-defined function
  match env.get_func(name) {
    Some((params, body)) => {
      let mut new_env = env
      // Bind each param to its corresponding arg filter as a filter closure
      for i = 0; i < params.length() && i < args.length(); i = i + 1 {
        new_env = new_env.bind_filter_arg(params[i], args[i])
      }
      eval(body, input, new_env, yield_)
      return
    }
    None => ()
  }
  // Builtins
  eval_builtin(name, args, input, env, yield_)
}

///|
/// Evaluate a built-in jq function.
fn eval_builtin(
  name : String,
  args : Array[Filter],
  input : Json,
  env : Scope,
  yield_ : (Json) -> Unit raise JqError,
) -> Unit raise JqError {
  match name {
    "length" =>
      match input {
        String(s) => yield_(Json::number(s.iter().count().to_double()))
        Array(arr) => yield_(Json::number(arr.length().to_double()))
        Object(map) => yield_(Json::number(map.length().to_double()))
        Null => yield_(Json::number(0.0))
        _ => raise JqError("cannot get length of " + json_type(input))
      }
    "keys" =>
      match input {
        Object(map) => {
          let ks : Array[String] = []
          map.each((k, _v) => ks.push(k))
          ks.sort()
          let result : Array[Json] = []
          for i = 0; i < ks.length(); i = i + 1 {
            result.push(Json::string(ks[i]))
          }
          yield_(Json::array(result))
        }
        Array(arr) => {
          let ks : Array[Json] = []
          for i = 0; i < arr.length(); i = i + 1 {
            ks.push(Json::number(i.to_double()))
          }
          yield_(Json::array(ks))
        }
        _ => raise JqError("cannot get keys of " + json_type(input))
      }
    "keys_unsorted" =>
      match input {
        Object(map) => {
          let ks : Array[Json] = []
          map.each((k, _v) => ks.push(Json::string(k)))
          yield_(Json::array(ks))
        }
        Array(arr) => {
          let ks : Array[Json] = []
          for i = 0; i < arr.length(); i = i + 1 {
            ks.push(Json::number(i.to_double()))
          }
          yield_(Json::array(ks))
        }
        _ => raise JqError("cannot get keys of " + json_type(input))
      }
    "values" =>
      match input {
        Null => ()
        _ => yield_(input)
      }
    "type" => yield_(Json::string(json_type(input)))
    "empty" => ()
    "add" =>
      match input {
        Array(arr) => {
          let mut acc : Json = Json::null()
          for i = 0; i < arr.length(); i = i + 1 {
            acc = arith_op(ArithOp::Add, acc, arr[i])
          }
          yield_(acc)
        }
        _ => raise JqError("add requires array input")
      }
    "not" => yield_(Json::boolean(not(is_truthy(input))))
    "reverse" =>
      match input {
        Array(arr) => {
          let result : Array[Json] = []
          for i = arr.length() - 1; i >= 0; i = i - 1 {
            result.push(arr[i])
          }
          yield_(Json::array(result))
        }
        String(s) => {
          let chars = Array::from_iter(s.iter())
          let buf = StringBuilder::new()
          for i = chars.length() - 1; i >= 0; i = i - 1 {
            buf.write_char(chars[i])
          }
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("cannot reverse " + json_type(input))
      }
    "sort" =>
      match input {
        Array(arr) => {
          let sorted = arr.copy()
          sorted.sort_by((a, b) => compare_json(a, b))
          yield_(Json::array(sorted))
        }
        _ => raise JqError("sort requires array input")
      }
    "flatten" =>
      match input {
        Array(arr) => {
          let depth = if args.length() == 1 {
            let mut d = 1
            eval(args[0], input, env, v => {
              match v {
                Number(n, ..) => {
                  if n < 0.0 {
                    raise JqError("flatten depth must not be negative")
                  }
                  d = n.to_int()
                }
                _ => raise JqError("flatten depth must be a number")
              }
            })
            d
          } else {
            999999999
          }
          let result : Array[Json] = []
          flatten_impl(arr, depth, result)
          yield_(Json::array(result))
        }
        _ => raise JqError("flatten requires array input")
      }
    "unique" =>
      match input {
        Array(arr) => {
          let sorted = arr.copy()
          sorted.sort_by((a, b) => compare_json(a, b))
          let result : Array[Json] = []
          for i = 0; i < sorted.length(); i = i + 1 {
            if i == 0 || sorted[i] != sorted[i - 1] {
              result.push(sorted[i])
            }
          }
          yield_(Json::array(result))
        }
        _ => raise JqError("unique requires array input")
      }
    "min" =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            yield_(Json::null())
          } else {
            let mut m = arr[0]
            for i = 1; i < arr.length(); i = i + 1 {
              if compare_json(arr[i], m) < 0 {
                m = arr[i]
              }
            }
            yield_(m)
          }
        _ => raise JqError("min requires array input")
      }
    "max" =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            yield_(Json::null())
          } else {
            let mut m = arr[0]
            for i = 1; i < arr.length(); i = i + 1 {
              if compare_json(arr[i], m) > 0 {
                m = arr[i]
              }
            }
            yield_(m)
          }
        _ => raise JqError("max requires array input")
      }
    "tostring" =>
      match input {
        String(_) => yield_(input)
        _ => yield_(Json::string(input.stringify()))
      }
    "tonumber" =>
      match input {
        Number(_) => yield_(input)
        String(s) => {
          let n = parse_number_str(s)
          yield_(Json::number(n))
        }
        _ => raise JqError("cannot convert " + json_type(input) + " to number")
      }
    "tojson" => yield_(Json::string(input.stringify()))
    "fromjson" =>
      match input {
        String(s) => {
          let trimmed = s.trim(chars=" \t\n\r").to_string()
          if trimmed == "nan" || trimmed == "NaN" {
            yield_(Json::number(0.0 / 0.0))
          } else if trimmed == "infinity" || trimmed == "Infinity" {
            yield_(Json::number(1.0 / 0.0))
          } else if trimmed == "-infinity" || trimmed == "-Infinity" {
            yield_(Json::number(-1.0 / 0.0))
          } else {
            let json = @json.parse(s) catch {
              _ => raise JqError("invalid JSON string")
            }
            yield_(json)
          }
        }
        _ => raise JqError("fromjson requires string input")
      }
    "ascii_downcase" =>
      match input {
        String(s) => {
          let buf = StringBuilder::new()
          s.iter().each(c => buf.write_char(c.to_ascii_lowercase()))
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("ascii_downcase requires string input")
      }
    "ascii_upcase" =>
      match input {
        String(s) => {
          let buf = StringBuilder::new()
          s.iter().each(c => buf.write_char(c.to_ascii_uppercase()))
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("ascii_upcase requires string input")
      }
    "to_entries" =>
      match input {
        Object(map) => {
          let result : Array[Json] = []
          map.each((k, v) => {
            let entry : Map[String, Json] = Map::new()
            entry["key"] = Json::string(k)
            entry["value"] = v
            result.push(Json::object(entry))
          })
          yield_(Json::array(result))
        }
        _ => raise JqError("to_entries requires object input")
      }
    "from_entries" =>
      match input {
        Array(arr) => {
          let result : Map[String, Json] = Map::new()
          for i = 0; i < arr.length(); i = i + 1 {
            match arr[i] {
              Object(entry) => {
                let key = match entry.get("key") {
                  Some(String(k)) => k
                  Some(Number(n, ..)) => n.to_string()
                  _ =>
                    match entry.get("Key") {
                      Some(String(k)) => k
                      Some(Number(n, ..)) => n.to_string()
                      _ =>
                        match entry.get("name") {
                          Some(String(k)) => k
                          _ =>
                            match entry.get("Name") {
                              Some(String(k)) => k
                              _ => raise JqError("from_entries: invalid entry")
                            }
                        }
                    }
                }
                let value = match entry.get("value") {
                  Some(v) => v
                  None =>
                    match entry.get("Value") {
                      Some(v) => v
                      None => Json::null()
                    }
                }
                result[key] = value
              }
              _ => raise JqError("from_entries: expected object entries")
            }
          }
          yield_(Json::object(result))
        }
        _ => raise JqError("from_entries requires array input")
      }
    "with_entries" => {
      guard args.length() == 1 else {
        raise JqError("with_entries takes 1 argument")
      }
      let f = args[0]
      match input {
        Object(map) => {
          let result : Map[String, Json] = Map::new()
          map.each((k, v) => {
            let entry : Map[String, Json] = Map::new()
            entry["key"] = Json::string(k)
            entry["value"] = v
            let entry_json = Json::object(entry)
            eval(f, entry_json, env, new_entry => {
              match new_entry {
                Object(ne) =>
                  match ne.get("key") {
                    Some(String(nk)) => {
                      let nv = match ne.get("value") {
                        Some(v) => v
                        None => Json::null()
                      }
                      result[nk] = nv
                    }
                    _ => raise JqError("with_entries: key must be string")
                  }
                _ => raise JqError("with_entries: expected object result")
              }
            })
          })
          yield_(Json::object(result))
        }
        _ => raise JqError("with_entries requires object input")
      }
    }
    "recurse" => recurse_impl(input, yield_)
    "debug" => {
      println(input.stringify())
      yield_(input)
    }
    "map" => {
      guard args.length() == 1 else { raise JqError("map takes 1 argument") }
      let f = args[0]
      match input {
        Array(arr) => {
          let result : Array[Json] = []
          for i = 0; i < arr.length(); i = i + 1 {
            eval(f, arr[i], env, v => result.push(v))
          }
          yield_(Json::array(result))
        }
        _ => raise JqError("map requires array input")
      }
    }
    "map_values" => {
      guard args.length() == 1 else {
        raise JqError("map_values takes 1 argument")
      }
      let f = args[0]
      match input {
        Object(map) => {
          let result : Map[String, Json] = Map::new()
          map.each((k, v) => eval(f, v, env, nv => result[k] = nv))
          yield_(Json::object(result))
        }
        Array(arr) => {
          let result : Array[Json] = []
          for i = 0; i < arr.length(); i = i + 1 {
            eval(f, arr[i], env, v => result.push(v))
          }
          yield_(Json::array(result))
        }
        _ => raise JqError("map_values requires array or object input")
      }
    }
    "select" => {
      guard args.length() == 1 else { raise JqError("select takes 1 argument") }
      let f = args[0]
      eval(f, input, env, v => if is_truthy(v) { yield_(input) })
    }
    "has" => {
      guard args.length() == 1 else { raise JqError("has takes 1 argument") }
      eval(args[0], input, env, key => {
        match (input, key) {
          (Object(map), String(k)) => yield_(Json::boolean(map.contains(k)))
          (Array(arr), Number(n, ..)) =>
            yield_(Json::boolean(n.to_int() >= 0 && n.to_int() < arr.length()))
          _ => raise JqError("has: invalid arguments")
        }
      })
    }
    "any" =>
      if args.is_empty() {
        match input {
          Array(arr) => {
            let mut found = false
            for i = 0; i < arr.length(); i = i + 1 {
              if is_truthy(arr[i]) {
                found = true
                break
              }
            }
            yield_(Json::boolean(found))
          }
          _ => raise JqError("any requires array input")
        }
      } else if args.length() == 1 {
        let f = args[0]
        match input {
          Array(arr) => {
            let mut found = false
            for i = 0; i < arr.length(); i = i + 1 {
              eval(f, arr[i], env, v => if is_truthy(v) { found = true })
              if found {
                break
              }
            }
            yield_(Json::boolean(found))
          }
          _ => raise JqError("any requires array input")
        }
      } else if args.length() == 2 {
        let gen = args[0]
        let cond = args[1]
        let mut found = false
        eval(gen, input, env, v => {
          if not(found) {
            eval(cond, v, env, cv => if is_truthy(cv) { found = true })
          }
        })
        yield_(Json::boolean(found))
      } else {
        raise JqError("any takes 0, 1, or 2 arguments")
      }
    "all" =>
      if args.is_empty() {
        match input {
          Array(arr) => {
            let mut ok = true
            for i = 0; i < arr.length(); i = i + 1 {
              if not(is_truthy(arr[i])) {
                ok = false
                break
              }
            }
            yield_(Json::boolean(ok))
          }
          _ => raise JqError("all requires array input")
        }
      } else if args.length() == 1 {
        let f = args[0]
        match input {
          Array(arr) => {
            let mut ok = true
            for i = 0; i < arr.length(); i = i + 1 {
              eval(f, arr[i], env, v => if not(is_truthy(v)) { ok = false })
              if not(ok) {
                break
              }
            }
            yield_(Json::boolean(ok))
          }
          _ => raise JqError("all requires array input")
        }
      } else if args.length() == 2 {
        let gen = args[0]
        let cond = args[1]
        let mut ok = true
        eval(gen, input, env, v => {
          if ok {
            eval(cond, v, env, cv => if not(is_truthy(cv)) { ok = false })
          }
        })
        yield_(Json::boolean(ok))
      } else {
        raise JqError("all takes 0, 1, or 2 arguments")
      }
    "sort_by" => {
      guard args.length() == 1 else {
        raise JqError("sort_by takes 1 argument")
      }
      let f = args[0]
      match input {
        Array(arr) => {
          let keyed : Array[(Json, Json)] = []
          for i = 0; i < arr.length(); i = i + 1 {
            let keys : Array[Json] = []
            eval(f, arr[i], env, v => keys.push(v))
            let key = if keys.length() == 1 {
              keys[0]
            } else {
              Json::array(keys)
            }
            keyed.push((key, arr[i]))
          }
          keyed.sort_by((a, b) => compare_json(a.0, b.0))
          let result : Array[Json] = []
          for i = 0; i < keyed.length(); i = i + 1 {
            result.push(keyed[i].1)
          }
          yield_(Json::array(result))
        }
        _ => raise JqError("sort_by requires array input")
      }
    }
    "group_by" => {
      guard args.length() == 1 else {
        raise JqError("group_by takes 1 argument")
      }
      let f = args[0]
      match input {
        Array(arr) => {
          let keyed : Array[(Json, Json)] = []
          for i = 0; i < arr.length(); i = i + 1 {
            let mut key = Json::null()
            eval(f, arr[i], env, v => key = v)
            keyed.push((key, arr[i]))
          }
          keyed.sort_by((a, b) => compare_json(a.0, b.0))
          let groups : Array[Json] = []
          let mut current_group : Array[Json] = []
          let mut current_key = Json::null()
          for i = 0; i < keyed.length(); i = i + 1 {
            if i == 0 || keyed[i].0 != current_key {
              if not(current_group.is_empty()) {
                groups.push(Json::array(current_group))
              }
              current_group = []
              current_key = keyed[i].0
            }
            current_group.push(keyed[i].1)
          }
          if not(current_group.is_empty()) {
            groups.push(Json::array(current_group))
          }
          yield_(Json::array(groups))
        }
        _ => raise JqError("group_by requires array input")
      }
    }
    "unique_by" => {
      guard args.length() == 1 else {
        raise JqError("unique_by takes 1 argument")
      }
      let f = args[0]
      match input {
        Array(arr) => {
          let keyed : Array[(Json, Json)] = []
          for i = 0; i < arr.length(); i = i + 1 {
            let mut key = Json::null()
            eval(f, arr[i], env, v => key = v)
            keyed.push((key, arr[i]))
          }
          keyed.sort_by((a, b) => compare_json(a.0, b.0))
          let result : Array[Json] = []
          for i = 0; i < keyed.length(); i = i + 1 {
            if i == 0 || keyed[i].0 != keyed[i - 1].0 {
              result.push(keyed[i].1)
            }
          }
          yield_(Json::array(result))
        }
        _ => raise JqError("unique_by requires array input")
      }
    }
    "min_by" => {
      guard args.length() == 1 else { raise JqError("min_by takes 1 argument") }
      let f = args[0]
      match input {
        Array(arr) =>
          if arr.is_empty() {
            yield_(Json::null())
          } else {
            let mut min_key = Json::null()
            let mut min_val = arr[0]
            eval(f, arr[0], env, v => min_key = v)
            for i = 1; i < arr.length(); i = i + 1 {
              let mut key = Json::null()
              eval(f, arr[i], env, v => key = v)
              if compare_json(key, min_key) < 0 {
                min_key = key
                min_val = arr[i]
              }
            }
            yield_(min_val)
          }
        _ => raise JqError("min_by requires array input")
      }
    }
    "max_by" => {
      guard args.length() == 1 else { raise JqError("max_by takes 1 argument") }
      let f = args[0]
      match input {
        Array(arr) =>
          if arr.is_empty() {
            yield_(Json::null())
          } else {
            let mut max_key = Json::null()
            let mut max_val = arr[0]
            eval(f, arr[0], env, v => max_key = v)
            for i = 1; i < arr.length(); i = i + 1 {
              let mut key = Json::null()
              eval(f, arr[i], env, v => key = v)
              if compare_json(key, max_key) > 0 {
                max_key = key
                max_val = arr[i]
              }
            }
            yield_(max_val)
          }
        _ => raise JqError("max_by requires array input")
      }
    }
    "contains" => {
      guard args.length() == 1 else {
        raise JqError("contains takes 1 argument")
      }
      eval(args[0], input, env, other => {
        yield_(Json::boolean(json_contains(input, other)))
      })
    }
    "startswith" => {
      guard args.length() == 1 else {
        raise JqError("startswith takes 1 argument")
      }
      eval(args[0], input, env, suffix => {
        match (input, suffix) {
          (String(s), String(p)) => yield_(Json::boolean(s.has_prefix(p)))
          _ => raise JqError("startswith requires string arguments")
        }
      })
    }
    "endswith" => {
      guard args.length() == 1 else {
        raise JqError("endswith takes 1 argument")
      }
      eval(args[0], input, env, suffix => {
        match (input, suffix) {
          (String(s), String(p)) => yield_(Json::boolean(s.has_suffix(p)))
          _ => raise JqError("endswith requires string arguments")
        }
      })
    }
    "ltrimstr" => {
      guard args.length() == 1 else {
        raise JqError("ltrimstr takes 1 argument")
      }
      eval(args[0], input, env, prefix => {
        match (input, prefix) {
          (String(s), String(p)) =>
            match s.strip_prefix(p) {
              Some(rest) => yield_(Json::string(rest.to_string()))
              None => yield_(input)
            }
          _ => yield_(input)
        }
      })
    }
    "rtrimstr" => {
      guard args.length() == 1 else {
        raise JqError("rtrimstr takes 1 argument")
      }
      eval(args[0], input, env, suffix => {
        match (input, suffix) {
          (String(s), String(p)) =>
            match s.strip_suffix(p) {
              Some(rest) => yield_(Json::string(rest.to_string()))
              None => yield_(input)
            }
          _ => yield_(input)
        }
      })
    }
    "trim" =>
      match input {
        String(s) => {
          let chars = Array::from_iter(s.iter())
          let len = chars.length()
          let mut start = 0
          while start < len && chars[start].is_whitespace() {
            start = start + 1
          }
          let mut end = len - 1
          while end >= start && chars[end].is_whitespace() {
            end = end - 1
          }
          let buf = StringBuilder::new()
          for i = start; i <= end; i = i + 1 {
            buf.write_char(chars[i])
          }
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("trim input must be a string")
      }
    "ltrim" =>
      match input {
        String(s) => {
          let chars = Array::from_iter(s.iter())
          let len = chars.length()
          let mut start = 0
          while start < len && chars[start].is_whitespace() {
            start = start + 1
          }
          let buf = StringBuilder::new()
          for i = start; i < len; i = i + 1 {
            buf.write_char(chars[i])
          }
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("trim input must be a string")
      }
    "rtrim" =>
      match input {
        String(s) => {
          let chars = Array::from_iter(s.iter())
          let len = chars.length()
          let mut end = len - 1
          while end >= 0 && chars[end].is_whitespace() {
            end = end - 1
          }
          let buf = StringBuilder::new()
          for i = 0; i <= end; i = i + 1 {
            buf.write_char(chars[i])
          }
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("trim input must be a string")
      }
    "trimstr" => {
      guard args.length() == 1 else {
        raise JqError("trimstr takes 1 argument")
      }
      eval(args[0], input, env, affix => {
        match (input, affix) {
          (String(s), String(p)) => {
            let mut result = s
            match result.strip_prefix(p) {
              Some(rest) => result = rest.to_string()
              None => ()
            }
            match result.strip_suffix(p) {
              Some(rest) => result = rest.to_string()
              None => ()
            }
            yield_(Json::string(result))
          }
          _ => yield_(input)
        }
      })
    }
    "split" => {
      guard args.length() == 1 else { raise JqError("split takes 1 argument") }
      eval(args[0], input, env, sep => {
        match (input, sep) {
          (String(s), String(d)) => {
            let parts : Array[Json] = []
            s.split(d).each(part => parts.push(Json::string(part.to_string())))
            yield_(Json::array(parts))
          }
          _ => raise JqError("split requires string arguments")
        }
      })
    }
    "join" => {
      guard args.length() == 1 else { raise JqError("join takes 1 argument") }
      eval(args[0], input, env, sep => {
        match (input, sep) {
          (Array(arr), String(d)) => {
            let buf = StringBuilder::new()
            for i = 0; i < arr.length(); i = i + 1 {
              if i > 0 {
                buf.write_string(d)
              }
              match arr[i] {
                String(s) => buf.write_string(s)
                Null => ()
                Number(n, ..) => buf.write_string(n.to_string())
                True => buf.write_string("true")
                False => buf.write_string("false")
                other =>
                  raise JqError(
                    "string (\"" +
                    buf.to_string() +
                    "\") and " +
                    json_type(other) +
                    " (" +
                    other.stringify() +
                    ") cannot be added",
                  )
              }
            }
            yield_(Json::string(buf.to_string()))
          }
          _ => raise JqError("join requires array input and string separator")
        }
      })
    }
    "limit" => {
      guard args.length() == 2 else { raise JqError("limit takes 2 arguments") }
      eval(args[0], input, env, nv => {
        match nv {
          Number(n, ..) => {
            let max = n.to_int()
            if max < 0 {
              raise JqError("limit doesn't support negative count")
            }
            let mut count = 0
            eval(args[1], input, env, v => {
              if count < max {
                yield_(v)
                count += 1
              }
              if count >= max {
                raise JqError("__break__")
              }
            }) catch {
              JqError("__break__") => ()
              e => raise e
            }
          }
          _ => raise JqError("limit: first argument must be a number")
        }
      })
    }
    "first" =>
      if args.length() == 1 {
        let mut found = false
        eval(args[0], input, env, v => {
          if not(found) {
            found = true
            yield_(v)
            raise JqError("__break__")
          }
        }) catch {
          JqError("__break__") => ()
          e => raise e
        }
      } else {
        // first without args = .[0]
        match input {
          Array(arr) =>
            if arr.is_empty() {
              yield_(Json::null())
            } else {
              yield_(arr[0])
            }
          _ => raise JqError("first requires array input")
        }
      }
    "last" =>
      if args.length() == 1 {
        let mut last_val : Json? = None
        eval(args[0], input, env, v => last_val = Some(v))
        match last_val {
          Some(v) => yield_(v)
          None => ()
        }
      } else {
        match input {
          Array(arr) =>
            if arr.is_empty() {
              yield_(Json::null())
            } else {
              yield_(arr[arr.length() - 1])
            }
          _ => raise JqError("last requires array input")
        }
      }
    "range" =>
      if args.length() == 1 {
        eval(args[0], input, env, nv => {
          match nv {
            Number(n, ..) => {
              let max = n.to_int()
              for i = 0; i < max; i = i + 1 {
                yield_(Json::number(i.to_double()))
              }
            }
            _ => raise JqError("range: argument must be a number")
          }
        })
      } else if args.length() == 2 {
        eval(args[0], input, env, from_v => {
          eval(args[1], input, env, to_v => {
            match (from_v, to_v) {
              (Number(f, ..), Number(t, ..)) => {
                let start = f.to_int()
                let end = t.to_int()
                for i = start; i < end; i = i + 1 {
                  yield_(Json::number(i.to_double()))
                }
              }
              _ => raise JqError("range: arguments must be numbers")
            }
          })
        })
      } else if args.length() == 3 {
        eval(args[0], input, env, from_v => {
          eval(args[1], input, env, to_v => {
            eval(args[2], input, env, step_v => {
              match (from_v, to_v, step_v) {
                (Number(f, ..), Number(t, ..), Number(s, ..)) =>
                  if s > 0.0 {
                    let mut i = f
                    while i < t {
                      yield_(Json::number(i))
                      i = i + s
                    }
                  } else if s < 0.0 {
                    let mut i = f
                    while i > t {
                      yield_(Json::number(i))
                      i = i + s
                    }
                  } else {
                    raise JqError("range: step cannot be zero")
                  }
                _ => raise JqError("range: arguments must be numbers")
              }
            })
          })
        })
      } else {
        raise JqError("range takes 1, 2, or 3 arguments")
      }
    "input" => raise JqError("input not supported")
    "inputs" => raise JqError("inputs not supported")
    "path" => raise JqError("path not yet implemented")
    "paths" =>
      if args.length() == 1 {
        // paths(f) - return paths where f is truthy
        let f = args[0]
        fn collect_paths_filter(
          v : Json,
          prefix : Array[Json],
          f : Filter,
          env : Scope,
          yield_ : (Json) -> Unit raise JqError,
        ) -> Unit raise JqError {
          match v {
            Array(arr) =>
              for i = 0; i < arr.length(); i = i + 1 {
                let p = prefix.copy()
                p.push(Json::number(i.to_double()))
                let mut is_truthy_result = false
                eval(f, arr[i], env, fv => {
                  if is_truthy(fv) {
                    is_truthy_result = true
                  }
                })
                if is_truthy_result {
                  yield_(Json::array(p))
                }
                collect_paths_filter(arr[i], p, f, env, yield_)
              }
            Object(map) =>
              map.each((k, val) => {
                let p = prefix.copy()
                p.push(Json::string(k))
                let mut is_truthy_result = false
                eval(f, val, env, fv => {
                  if is_truthy(fv) {
                    is_truthy_result = true
                  }
                })
                if is_truthy_result {
                  yield_(Json::array(p))
                }
                collect_paths_filter(val, p, f, env, yield_)
              })
            _ => ()
          }
        }

        collect_paths_filter(input, [], f, env, yield_)
      } else {
        fn collect_paths(
          v : Json,
          prefix : Array[Json],
          yield_ : (Json) -> Unit raise JqError,
        ) -> Unit raise JqError {
          match v {
            Array(arr) =>
              for i = 0; i < arr.length(); i = i + 1 {
                let p = prefix.copy()
                p.push(Json::number(i.to_double()))
                yield_(Json::array(p))
                collect_paths(arr[i], p, yield_)
              }
            Object(map) =>
              map.each((k, val) => {
                let p = prefix.copy()
                p.push(Json::string(k))
                yield_(Json::array(p))
                collect_paths(val, p, yield_)
              })
            _ => ()
          }
        }

        collect_paths(input, [], yield_)
      }
    "getpath" => {
      guard args.length() == 1 else {
        raise JqError("getpath takes 1 argument")
      }
      eval(args[0], input, env, path => {
        match path {
          Array(parts) => {
            let mut current = input
            for i = 0; i < parts.length(); i = i + 1 {
              match (current, parts[i]) {
                (Object(map), String(k)) =>
                  current = match map.get(k) {
                    Some(v) => v
                    None => Json::null()
                  }
                (Array(arr), Number(n, ..)) => {
                  let idx = n.to_int()
                  current = if idx >= 0 && idx < arr.length() {
                    arr[idx]
                  } else {
                    Json::null()
                  }
                }
                _ => {
                  current = Json::null()
                  break
                }
              }
            }
            yield_(current)
          }
          _ => raise JqError("getpath: argument must be an array")
        }
      })
    }
    "null" => yield_(Json::null())
    "true" => yield_(Json::boolean(true))
    "false" => yield_(Json::boolean(false))
    "infinite" => yield_(Json::number(1.0 / 0.0))
    "nan" => yield_(Json::number(0.0 / 0.0))
    "isinfinite" =>
      match input {
        Number(n, ..) =>
          yield_(Json::boolean(n == 1.0 / 0.0 || n == -1.0 / 0.0))
        _ => yield_(Json::boolean(false))
      }
    "isnan" =>
      match input {
        Number(n, ..) => yield_(Json::boolean(n != n))
        _ => yield_(Json::boolean(false))
      }
    "isnormal" =>
      match input {
        Number(n, ..) =>
          yield_(
            Json::boolean(
              n == n && n != 0.0 && n != 1.0 / 0.0 && n != -1.0 / 0.0,
            ),
          )
        _ => yield_(Json::boolean(false))
      }
    "isfinite" =>
      match input {
        Number(n, ..) =>
          yield_(Json::boolean(n == n && n != 1.0 / 0.0 && n != -1.0 / 0.0))
        _ => yield_(Json::boolean(false))
      }
    "abs" | "fabs" =>
      match input {
        Number(n, ..) => yield_(Json::number(if n < 0.0 { -n } else { n }))
        _ => yield_(input)
      }
    "floor" =>
      match input {
        Number(n, ..) => {
          let i = if n < 0.0 && n != n.to_int().to_double() {
            n.to_int() - 1
          } else {
            n.to_int()
          }
          yield_(Json::number(i.to_double()))
        }
        _ => raise JqError("floor requires number input")
      }
    "ceil" =>
      match input {
        Number(n, ..) => {
          let i = n.to_int()
          let result = if i.to_double() < n { i + 1 } else { i }
          yield_(Json::number(result.to_double()))
        }
        _ => raise JqError("ceil requires number input")
      }
    "round" =>
      match input {
        Number(n, ..) => yield_(Json::number((n + 0.5).to_int().to_double()))
        _ => raise JqError("round requires number input")
      }
    "ascii" =>
      match input {
        Number(n, ..) =>
          yield_(Json::string(n.to_int().unsafe_to_char().to_string()))
        _ => raise JqError("ascii requires number input")
      }
    "explode" =>
      match input {
        String(s) => {
          let result : Array[Json] = []
          s.iter().each(c => result.push(Json::number(c.to_int().to_double())))
          yield_(Json::array(result))
        }
        _ => raise JqError("explode requires string input")
      }
    "implode" =>
      match input {
        Array(arr) => {
          let buf = StringBuilder::new()
          for i = 0; i < arr.length(); i = i + 1 {
            match arr[i] {
              Number(n, ..) => {
                let cp = n.to_int()
                if cp >= 0 && cp <= 1114111 {
                  buf.write_char(cp.unsafe_to_char())
                }
              }
              _ => raise JqError("implode: array must contain numbers")
            }
          }
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("implode requires array input")
      }
    "indices" | "index" => {
      guard args.length() == 1 else {
        raise JqError(name + " takes 1 argument")
      }
      eval(args[0], input, env, target => {
        match (input, target) {
          (String(s), String(t)) =>
            if name == "index" {
              match s.find(t) {
                Some(idx) => yield_(Json::number(idx.to_double()))
                None => yield_(Json::null())
              }
            } else {
              let result : Array[Json] = []
              let chars_s = Array::from_iter(s.iter())
              let chars_t = Array::from_iter(t.iter())
              if chars_t.length() > 0 {
                for i = 0; i <= chars_s.length() - chars_t.length(); i = i + 1 {
                  let mut found = true
                  for j = 0; j < chars_t.length(); j = j + 1 {
                    if chars_s[i + j] != chars_t[j] {
                      found = false
                      break
                    }
                  }
                  if found {
                    result.push(Json::number(i.to_double()))
                  }
                }
              }
              yield_(Json::array(result))
            }
          (Array(arr), Array(sub)) =>
            if name == "index" {
              let mut idx : Json = Json::null()
              if sub.length() > 0 {
                for i = 0; i <= arr.length() - sub.length(); i = i + 1 {
                  let mut found = true
                  for j = 0; j < sub.length(); j = j + 1 {
                    if arr[i + j] != sub[j] {
                      found = false
                      break
                    }
                  }
                  if found {
                    idx = Json::number(i.to_double())
                    break
                  }
                }
              }
              yield_(idx)
            } else {
              let result : Array[Json] = []
              if sub.length() > 0 {
                for i = 0; i <= arr.length() - sub.length(); i = i + 1 {
                  let mut found = true
                  for j = 0; j < sub.length(); j = j + 1 {
                    if arr[i + j] != sub[j] {
                      found = false
                      break
                    }
                  }
                  if found {
                    result.push(Json::number(i.to_double()))
                  }
                }
              }
              yield_(Json::array(result))
            }
          (Array(arr), _) =>
            if name == "index" {
              let mut idx : Json = Json::null()
              for i = 0; i < arr.length(); i = i + 1 {
                if arr[i] == target {
                  idx = Json::number(i.to_double())
                  break
                }
              }
              yield_(idx)
            } else {
              let result : Array[Json] = []
              for i = 0; i < arr.length(); i = i + 1 {
                if arr[i] == target {
                  result.push(Json::number(i.to_double()))
                }
              }
              yield_(Json::array(result))
            }
          _ => raise JqError(name + ": requires string or array input")
        }
      })
    }
    "rindex" => {
      guard args.length() == 1 else { raise JqError("rindex takes 1 argument") }
      eval(args[0], input, env, target => {
        match (input, target) {
          (String(s), String(t)) => {
            let chars_s = Array::from_iter(s.iter())
            let chars_t = Array::from_iter(t.iter())
            let mut idx : Json = Json::null()
            if chars_t.length() > 0 {
              for i = chars_s.length() - chars_t.length(); i >= 0; i = i - 1 {
                let mut found = true
                for j = 0; j < chars_t.length(); j = j + 1 {
                  if chars_s[i + j] != chars_t[j] {
                    found = false
                    break
                  }
                }
                if found {
                  idx = Json::number(i.to_double())
                  break
                }
              }
            }
            yield_(idx)
          }
          (Array(arr), _) => {
            let mut idx : Json = Json::null()
            for i = arr.length() - 1; i >= 0; i = i - 1 {
              if arr[i] == target {
                idx = Json::number(i.to_double())
                break
              }
            }
            yield_(idx)
          }
          _ => raise JqError("rindex: requires string or array input")
        }
      })
    }
    "inside" => {
      guard args.length() == 1 else { raise JqError("inside takes 1 argument") }
      eval(args[0], input, env, other => {
        yield_(Json::boolean(json_contains(other, input)))
      })
    }
    "test" => {
      guard args.length() == 1 else { raise JqError("test takes 1 argument") }
      eval(args[0], input, env, pattern => {
        match (input, pattern) {
          (String(s), String(p)) => yield_(Json::boolean(s.contains(p)))
          _ => raise JqError("test requires string arguments")
        }
      })
    }
    "walk" => {
      guard args.length() == 1 else { raise JqError("walk takes 1 argument") }
      let f = args[0]
      walk_impl(input, f, env, yield_)
    }
    "transpose" =>
      match input {
        Array(arr) => {
          let mut max_len = 0
          for i = 0; i < arr.length(); i = i + 1 {
            match arr[i] {
              Array(sub) => if sub.length() > max_len { max_len = sub.length() }
              _ => ()
            }
          }
          let result : Array[Json] = []
          for j = 0; j < max_len; j = j + 1 {
            let col : Array[Json] = []
            for i = 0; i < arr.length(); i = i + 1 {
              match arr[i] {
                Array(sub) =>
                  if j < sub.length() {
                    col.push(sub[j])
                  } else {
                    col.push(Json::null())
                  }
                _ => col.push(Json::null())
              }
            }
            result.push(Json::array(col))
          }
          yield_(Json::array(result))
        }
        _ => raise JqError("transpose requires array input")
      }
    "numbers" =>
      match input {
        Number(_) => yield_(input)
        _ => ()
      }
    "strings" =>
      match input {
        String(_) => yield_(input)
        _ => ()
      }
    "booleans" =>
      match input {
        True | False => yield_(input)
        _ => ()
      }
    "nulls" =>
      match input {
        Null => yield_(input)
        _ => ()
      }
    "arrays" =>
      match input {
        Array(_) => yield_(input)
        _ => ()
      }
    "objects" =>
      match input {
        Object(_) => yield_(input)
        _ => ()
      }
    "iterables" =>
      match input {
        Array(_) | Object(_) => yield_(input)
        _ => ()
      }
    "scalars" =>
      match input {
        Null | True | False | Number(_) | String(_) => yield_(input)
        _ => ()
      }
    "bsearch" => {
      guard args.length() == 1 else {
        raise JqError("bsearch takes 1 argument")
      }
      eval(args[0], input, env, target => {
        match input {
          Array(arr) => {
            let mut lo = 0
            let mut hi = arr.length() - 1
            let mut found = false
            let mut result = 0
            while lo <= hi {
              let mid = (lo + hi) / 2
              let cmp = compare_json(arr[mid], target)
              if cmp == 0 {
                result = mid
                found = true
                break
              } else if cmp < 0 {
                lo = mid + 1
              } else {
                hi = mid - 1
              }
            }
            if found {
              yield_(Json::number(result.to_double()))
            } else {
              yield_(Json::number((-lo - 1).to_double()))
            }
          }
          _ =>
            raise JqError(
              json_type(input) +
              " (" +
              input.stringify() +
              ") cannot be searched from",
            )
        }
      })
    }
    "env" => yield_(Json::null())
    "sqrt" =>
      match input {
        Number(n, ..) => yield_(Json::number(n.sqrt()))
        _ => raise JqError("sqrt requires number input")
      }
    "sin" =>
      match input {
        Number(n, ..) => yield_(Json::number(@math.sin(n)))
        _ => raise JqError("sin requires number input")
      }
    "cos" =>
      match input {
        Number(n, ..) => yield_(Json::number(@math.cos(n)))
        _ => raise JqError("cos requires number input")
      }
    "atan" =>
      match input {
        Number(n, ..) => yield_(Json::number(@math.atan(n)))
        _ => raise JqError("atan requires number input")
      }
    "atan2" => {
      guard args.length() == 1 else { raise JqError("atan2 takes 1 argument") }
      eval(args[0], input, env, yv => {
        match (input, yv) {
          (Number(a, ..), Number(b, ..)) =>
            yield_(Json::number(@math.atan2(a, b)))
          _ => raise JqError("atan2 requires number arguments")
        }
      })
    }
    "log" =>
      match input {
        Number(n, ..) => yield_(Json::number(@math.ln(n)))
        _ => raise JqError("log requires number input")
      }
    "log2" =>
      match input {
        Number(n, ..) => yield_(Json::number(@math.log2(n)))
        _ => raise JqError("log2 requires number input")
      }
    "exp" =>
      match input {
        Number(n, ..) => yield_(Json::number(@math.exp(n)))
        _ => raise JqError("exp requires number input")
      }
    "exp2" =>
      match input {
        Number(n, ..) => yield_(Json::number(@math.pow(2.0, n)))
        _ => raise JqError("exp2 requires number input")
      }
    "pow" => {
      guard args.length() == 2 else { raise JqError("pow takes 2 arguments") }
      eval(args[0], input, env, base_v => {
        eval(args[1], input, env, exp_v => {
          match (base_v, exp_v) {
            (Number(b, ..), Number(e, ..)) =>
              yield_(Json::number(@math.pow(b, e)))
            _ => raise JqError("pow requires number arguments")
          }
        })
      })
    }
    "builtins" => {
      let names : Array[String] = [
        "length/0", "keys/0", "values/0", "type/0", "empty/0", "add/0", "not/0",
        "map/1", "select/1", "sort/0", "sort_by/1", "group_by/1", "unique/0", "unique_by/1",
        "reverse/0", "flatten/0", "flatten/1", "min/0", "max/0", "min_by/1", "max_by/1",
        "contains/1", "has/1", "any/0", "any/1", "all/0", "all/1", "range/1", "range/2",
        "range/3", "first/0", "first/1", "last/0", "last/1", "limit/2", "nth/1",
        "nth/2", "skip/2", "tostring/0", "tonumber/0", "toboolean/0", "tojson/0",
        "fromjson/0", "ascii_downcase/0", "ascii_upcase/0", "split/1", "join/1",
        "test/1", "startswith/1", "endswith/1", "ltrimstr/1", "rtrimstr/1", "trim/0",
        "ltrim/0", "rtrim/0", "trimstr/1", "to_entries/0", "from_entries/0", "with_entries/1",
        "keys_unsorted/0", "recurse/0", "recurse/1", "walk/1", "transpose/0", "explode/0",
        "implode/0", "abs/0", "fabs/0", "floor/0", "ceil/0", "round/0", "bsearch/1",
        "indices/1", "index/1", "rindex/1", "inside/1", "isnan/0", "isinfinite/0",
        "isfinite/0", "isnormal/0", "infinite/0", "nan/0", "error/0", "error/1",
        "debug/0", "paths/0", "paths/1", "getpath/1", "map_values/1", "IN/1", "IN/2",
        "while/2", "until/2", "isempty/1", "ascii/0", "null/0", "true/0", "false/0",
        "numbers/0", "strings/0", "booleans/0", "nulls/0", "arrays/0", "objects/0",
        "iterables/0", "scalars/0", "sqrt/0", "sin/0", "cos/0", "atan/0", "atan2/1",
        "log/0", "log2/0", "exp/0", "exp2/0", "pow/2", "@base64/0", "@base64d/0",
        "@json/0", "@text/0", "@html/0", "@uri/0",
      ]
      let arr = names.map(fn(s) { Json::string(s) })
      arr.sort_by(fn(a, b) { compare_json(a, b) })
      yield_(Json::array(arr))
    }
    "@base64" =>
      match input {
        String(s) => {
          let bytes = string_to_utf8(s)
          let encoded = @base64.encode(bytes[:])
          yield_(Json::string(encoded))
        }
        _ => raise JqError("@base64 requires string input")
      }
    "@base64d" =>
      match input {
        String(s) => {
          let bytes = @base64.decode(s) catch {
            _ => raise JqError("@base64d: invalid base64 input")
          }
          let buf = StringBuilder::new()
          utf8_to_string(bytes, buf)
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("@base64d requires string input")
      }
    "@json" => yield_(Json::string(input.stringify()))
    "@text" =>
      match input {
        String(_) => yield_(input)
        _ => yield_(Json::string(input.stringify()))
      }
    "@html" =>
      match input {
        String(s) => {
          let buf = StringBuilder::new()
          s
          .iter()
          .each(c => {
            match c {
              '<' => buf.write_string("&lt;")
              '>' => buf.write_string("&gt;")
              '&' => buf.write_string("&amp;")
              '\'' => buf.write_string("&apos;")
              '"' => buf.write_string("&quot;")
              _ => buf.write_char(c)
            }
          })
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("@html requires string input")
      }
    "@uri" =>
      match input {
        String(s) => {
          let bytes = string_to_utf8(s)
          let buf = StringBuilder::new()
          for i = 0; i < bytes.length(); i = i + 1 {
            let b = bytes[i].to_int()
            if (b >= 'A'.to_int() && b <= 'Z'.to_int()) ||
              (b >= 'a'.to_int() && b <= 'z'.to_int()) ||
              (b >= '0'.to_int() && b <= '9'.to_int()) ||
              b == '-'.to_int() ||
              b == '_'.to_int() ||
              b == '.'.to_int() ||
              b == '~'.to_int() {
              buf.write_char(b.unsafe_to_char())
            } else {
              let hex = "0123456789ABCDEF"
              buf.write_char('%')
              buf.write_char(hex.iter().to_array()[(b >> 4) & 0xf])
              buf.write_char(hex.iter().to_array()[b & 0xf])
            }
          }
          yield_(Json::string(buf.to_string()))
        }
        _ => raise JqError("@uri requires string input")
      }
    "IN" =>
      if args.length() == 1 {
        // IN(expr): check if input equals any output of expr
        let mut found = false
        eval(args[0], input, env, v => {
          if v == input {
            found = true
            raise JqError("__break__")
          }
        }) catch {
          JqError("__break__") => ()
          e => raise e
        }
        yield_(Json::boolean(found))
      } else if args.length() == 2 {
        // IN(gen; expr): yield single boolean — true if ANY gen output matches any expr output
        let mut found = false
        eval(args[0], input, env, gv => {
          eval(args[1], input, env, ev => {
            if ev == gv {
              found = true
              raise JqError("__break__")
            }
          }) catch {
            JqError("__break__") => ()
            e => raise e
          }
          if found {
            raise JqError("__break__")
          }
        }) catch {
          JqError("__break__") => ()
          e => raise e
        }
        yield_(Json::boolean(found))
      }
    "error" =>
      if args.length() == 0 {
        raise JqError(jq_error_encode(input))
      } else {
        eval(args[0], input, env, v => raise JqError(jq_error_encode(v)))
      }
    "isempty" => {
      guard args.length() == 1 else {
        raise JqError("isempty takes 1 argument")
      }
      let mut found = false
      eval(args[0], input, env, _ => {
        found = true
        raise JqError("__break__")
      }) catch {
        JqError("__break__") => ()
        e => raise e
      }
      yield_(Json::boolean(not(found)))
    }
    "nth" =>
      if args.length() == 2 {
        eval(args[0], input, env, nv => {
          match nv {
            Number(n, ..) => {
              let target = n.to_int()
              if target < 0 {
                raise JqError("nth doesn't support negative indices")
              }
              let mut count = 0
              eval(args[1], input, env, v => {
                if count == target {
                  yield_(v)
                  raise JqError("__break__")
                }
                count += 1
              }) catch {
                JqError("__break__") => ()
                e => raise e
              }
            }
            _ => raise JqError("nth: index must be a number")
          }
        })
      } else if args.length() == 1 {
        // nth(n) = first(.[n:] | .[0]) — but simpler: get nth output of .[]
        eval(args[0], input, env, nv => {
          match nv {
            Number(n, ..) => {
              let target = n.to_int()
              match input {
                Array(arr) =>
                  if target >= 0 && target < arr.length() {
                    yield_(arr[target])
                  } else {
                    yield_(Json::null())
                  }
                _ => raise JqError("nth requires array input")
              }
            }
            _ => raise JqError("nth: index must be a number")
          }
        })
      } else {
        raise JqError("nth takes 1 or 2 arguments")
      }
    "skip" => {
      guard args.length() == 2 else { raise JqError("skip takes 2 arguments") }
      eval(args[0], input, env, nv => {
        match nv {
          Number(n, ..) => {
            let target = n.to_int()
            if target < 0 {
              raise JqError("skip doesn't support negative count")
            }
            let mut count = 0
            eval(args[1], input, env, v => {
              if count >= target {
                yield_(v)
              }
              count += 1
            })
          }
          _ => raise JqError("skip: first argument must be a number")
        }
      })
    }
    "toboolean" =>
      match input {
        True | False => yield_(input)
        String(s) =>
          match s {
            "true" => yield_(Json::boolean(true))
            "false" => yield_(Json::boolean(false))
            _ =>
              raise JqError(
                "string (" +
                input.stringify() +
                ") cannot be parsed as a boolean",
              )
          }
        _ =>
          raise JqError(
            json_type(input) +
            " (" +
            input.stringify() +
            ") cannot be parsed as a boolean",
          )
      }
    "while" => {
      guard args.length() == 2 else { raise JqError("while takes 2 arguments") }
      let cond = args[0]
      let update = args[1]
      let mut current = input
      while true {
        if not(is_truthy(eval_single(cond, current, env))) {
          break
        }
        yield_(current)
        current = eval_single(update, current, env)
      }
    }
    "until" => {
      guard args.length() == 2 else { raise JqError("until takes 2 arguments") }
      let cond = args[0]
      let update = args[1]
      let mut current = input
      while true {
        if is_truthy(eval_single(cond, current, env)) {
          break
        }
        current = eval_single(update, current, env)
      }
      yield_(current)
    }
    _ => raise JqError("unknown function: " + name)
  }
}
