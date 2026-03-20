///|
fn optimize(filter : Filter) -> Filter {
  match filter {
    Pipe(left, right) => {
      let l = optimize(left)
      let r = optimize(right)
      match (l, r) {
        (Identity, r) => r
        (l, Identity) => l
        _ => Pipe(l, r)
      }
    }
    Comma(left, right) => Comma(optimize(left), optimize(right))
    Paren(inner) => optimize(inner)
    ArrayConstruct(Some(inner)) => ArrayConstruct(Some(optimize(inner)))
    ObjectConstruct(fields) => {
      let opt_fields : Array[(ObjKey, Filter)] = []
      for i = 0; i < fields.length(); i = i + 1 {
        let (key, value) = fields[i]
        let opt_key = match key {
          ExprKey(expr) => ExprKey(optimize(expr))
          _ => key
        }
        opt_fields.push((opt_key, optimize(value)))
      }
      ObjectConstruct(opt_fields)
    }
    Try(inner) => Try(optimize(inner))
    TryCatch(inner, handler) => TryCatch(optimize(inner), optimize(handler))
    IfThenElse(cond, then_b, else_b) =>
      IfThenElse(optimize(cond), optimize(then_b), optimize(else_b))
    Binding(name, expr, body) => Binding(name, optimize(expr), optimize(body))
    Reduce(iter, name, init, update) =>
      Reduce(optimize(iter), name, optimize(init), optimize(update))
    FuncDef(name, params, body, rest) =>
      FuncDef(name, params, optimize(body), optimize(rest))
    FuncCall(name, args) => {
      let opt_args : Array[Filter] = []
      for i = 0; i < args.length(); i = i + 1 {
        opt_args.push(optimize(args[i]))
      }
      FuncCall(name, opt_args)
    }
    Neg(inner) => Neg(optimize(inner))
    Arith(op, left, right) => Arith(op, optimize(left), optimize(right))
    Compare(op, left, right) => Compare(op, optimize(left), optimize(right))
    LogicAnd(left, right) => LogicAnd(optimize(left), optimize(right))
    LogicOr(left, right) => LogicOr(optimize(left), optimize(right))
    DynIndex(expr) => DynIndex(optimize(expr))
    PostfixDynIndex(base, idx) => PostfixDynIndex(optimize(base), optimize(idx))
    DynSlice(base, start, end) =>
      DynSlice(optimize(base), start.map(optimize), end.map(optimize))
    _ => filter
  }
}
