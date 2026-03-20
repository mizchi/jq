///|
priv struct Parser {
  tokens : Array[Token]
  mut pos : Int
}

///|
fn Parser::new(tokens : Array[Token]) -> Parser {
  { tokens, pos: 0 }
}

///|
fn Parser::peek(self : Parser) -> Token {
  if self.pos < self.tokens.length() {
    self.tokens[self.pos]
  } else {
    Eof
  }
}

///|
fn Parser::advance(self : Parser) -> Token {
  let tok = self.peek()
  self.pos += 1
  tok
}

///|
fn Parser::expect(self : Parser, expected : Token) -> Unit raise JqError {
  let tok = self.advance()
  if tok != expected {
    raise JqError(
      "expected " + expected.to_string() + " but got " + tok.to_string(),
    )
  }
}

///|
fn parse(tokens : Array[Token]) -> Filter raise JqError {
  let parser = Parser::new(tokens)
  let filter = parser.parse_pipe()
  let tok = parser.peek()
  if tok != Eof {
    raise JqError("unexpected token: " + tok.to_string())
  }
  filter
}

///|
fn Parser::parse_pipe(self : Parser) -> Filter raise JqError {
  let left = self.parse_comma()
  match self.peek() {
    Pipe => {
      ignore(self.advance())
      let right = self.parse_pipe()
      Pipe(left, right)
    }
    Eq => {
      ignore(self.advance())
      let right = self.parse_pipe()
      Assign(left, right)
    }
    PipeEq => {
      ignore(self.advance())
      let right = self.parse_pipe()
      Update(left, right)
    }
    PlusEq => {
      ignore(self.advance())
      let right = self.parse_pipe()
      Update(left, Arith(ArithOp::Add, Identity, right))
    }
    MinusEq => {
      ignore(self.advance())
      let right = self.parse_pipe()
      Update(left, Arith(ArithOp::Sub, Identity, right))
    }
    StarEq => {
      ignore(self.advance())
      let right = self.parse_pipe()
      Update(left, Arith(ArithOp::Mul, Identity, right))
    }
    SlashEq => {
      ignore(self.advance())
      let right = self.parse_pipe()
      Update(left, Arith(ArithOp::Div, Identity, right))
    }
    PercentEq => {
      ignore(self.advance())
      let right = self.parse_pipe()
      Update(left, Arith(ArithOp::Mod, Identity, right))
    }
    SlashSlashEq => {
      ignore(self.advance())
      let right = self.parse_pipe()
      UpdateAlt(left, right)
    }
    _ => left
  }
}

///|
fn Parser::parse_comma(self : Parser) -> Filter raise JqError {
  let mut left = self.parse_binding()
  while self.peek() == Comma {
    ignore(self.advance())
    let right = self.parse_binding()
    left = Comma(left, right)
  }
  left
}

///|
/// Evaluate a constant string expression at parse time (for pattern keys).
fn eval_const_string(filter : Filter) -> String raise JqError {
  match filter {
    Literal(String(s)) => s
    Arith(ArithOp::Add, left, right) =>
      eval_const_string(left) + eval_const_string(right)
    _ =>
      raise JqError("pattern object key must be a constant string expression")
  }
}

///|
fn Parser::parse_pattern(self : Parser) -> Pattern raise JqError {
  match self.peek() {
    Variable(name) => {
      ignore(self.advance())
      PatVar("$" + name)
    }
    LBracket => {
      ignore(self.advance())
      let pats : Array[Pattern] = []
      if self.peek() != RBracket {
        pats.push(self.parse_pattern())
        while self.peek() == Comma {
          ignore(self.advance())
          pats.push(self.parse_pattern())
        }
      }
      self.expect(RBracket)
      PatArray(pats)
    }
    LBrace => {
      ignore(self.advance())
      let fields : Array[(String, Pattern)] = []
      if self.peek() != RBrace {
        fields.push(self.parse_pattern_field())
        while self.peek() == Comma {
          ignore(self.advance())
          fields.push(self.parse_pattern_field())
        }
      }
      self.expect(RBrace)
      PatObject(fields)
    }
    _ => raise JqError("expected pattern (variable, [ ], or { })")
  }
}

///|
fn Parser::parse_pattern_field(
  self : Parser,
) -> (String, Pattern) raise JqError {
  match self.peek() {
    Variable(name) => {
      ignore(self.advance())
      (name, PatVar("$" + name))
    }
    Ident(name) => {
      ignore(self.advance())
      if self.peek() == Colon {
        ignore(self.advance())
        let pat = self.parse_pattern()
        (name, pat)
      } else {
        (name, PatVar("$" + name))
      }
    }
    Str(s) => {
      ignore(self.advance())
      self.expect(Colon)
      let pat = self.parse_pattern()
      (s, pat)
    }
    LParen => {
      // Dynamic key pattern: ("expr"): $var
      // We evaluate the key expression at bind time
      // For now, parse the expression but store it as a special marker
      // Actually jq evaluates the key at bind time, which requires
      // storing the expression. We'll use a special pattern variant.
      // For simplicity, eval the expr during parse if it's a literal concatenation
      // Actually, we need to handle this at eval time.
      // Store the expression source in a special way.
      ignore(self.advance())
      let key_expr = self.parse_pipe()
      self.expect(RParen)
      self.expect(Colon)
      let pat = self.parse_pattern()
      // We encode dynamic key patterns by storing a sentinel key
      // and the expression in PatObject. But Pattern doesn't support this.
      // Alternative: evaluate literal expressions at parse time.
      // For now, try to evaluate constant string concatenations:
      let key = eval_const_string(key_expr)
      (key, pat)
    }
    _ => {
      // Handle keywords used as field names (e.g., "as", "if", "then", etc.)
      let tok = self.peek()
      let name = match tok {
        KwAs => "as"
        KwAnd => "and"
        KwOr => "or"
        KwNot => "not"
        KwIf => "if"
        KwThen => "then"
        KwElif => "elif"
        KwElse => "else"
        KwEnd => "end"
        KwDef => "def"
        KwTry => "try"
        KwCatch => "catch"
        KwReduce => "reduce"
        KwForeach => "foreach"
        KwTrue => "true"
        KwFalse => "false"
        KwNull => "null"
        KwLabel => "label"
        KwBreak => "break"
        _ => raise JqError("expected pattern field")
      }
      ignore(self.advance())
      if self.peek() == Colon {
        ignore(self.advance())
        let pat = self.parse_pattern()
        (name, pat)
      } else {
        (name, PatVar("$" + name))
      }
    }
  }
}

///|
fn Parser::parse_binding(self : Parser) -> Filter raise JqError {
  let expr = self.parse_alternative()
  if self.peek() == KwAs {
    ignore(self.advance())
    let pat = self.parse_pattern()
    // Check for ?// alternative destructuring
    let patterns : Array[Pattern] = [pat]
    while self.peek() == Question {
      let saved = self.pos
      ignore(self.advance())
      if self.peek() == SlashSlash {
        ignore(self.advance())
        patterns.push(self.parse_pattern())
      } else {
        self.pos = saved
        break
      }
    }
    self.expect(Pipe)
    let body = self.parse_pipe()
    if patterns.length() == 1 {
      Binding(pat, expr, body)
    } else {
      BindingAlt(patterns, expr, body)
    }
  } else {
    expr
  }
}

///|
fn Parser::parse_alternative(self : Parser) -> Filter raise JqError {
  let left = self.parse_or()
  if self.peek() == SlashSlash {
    ignore(self.advance())
    let right = self.parse_alternative()
    Alternative(left, right)
  } else {
    left
  }
}

///|
fn Parser::parse_or(self : Parser) -> Filter raise JqError {
  let mut left = self.parse_and()
  while self.peek() == KwOr {
    ignore(self.advance())
    let right = self.parse_and()
    left = LogicOr(left, right)
  }
  left
}

///|
fn Parser::parse_and(self : Parser) -> Filter raise JqError {
  let mut left = self.parse_not()
  while self.peek() == KwAnd {
    ignore(self.advance())
    let right = self.parse_not()
    left = LogicAnd(left, right)
  }
  left
}

///|
fn Parser::parse_not(self : Parser) -> Filter raise JqError {
  self.parse_compare()
}

///|
fn Parser::parse_compare(self : Parser) -> Filter raise JqError {
  let left = self.parse_add()
  match self.peek() {
    EqEq => {
      ignore(self.advance())
      let right = self.parse_add()
      Compare(CmpOp::Eq, left, right)
    }
    Ne => {
      ignore(self.advance())
      let right = self.parse_add()
      Compare(CmpOp::Ne, left, right)
    }
    Lt => {
      ignore(self.advance())
      let right = self.parse_add()
      Compare(CmpOp::Lt, left, right)
    }
    Gt => {
      ignore(self.advance())
      let right = self.parse_add()
      Compare(CmpOp::Gt, left, right)
    }
    Le => {
      ignore(self.advance())
      let right = self.parse_add()
      Compare(CmpOp::Le, left, right)
    }
    Ge => {
      ignore(self.advance())
      let right = self.parse_add()
      Compare(CmpOp::Ge, left, right)
    }
    _ => left
  }
}

///|
fn Parser::parse_add(self : Parser) -> Filter raise JqError {
  let mut left = self.parse_mul()
  while (match self.peek() {
          Plus | Minus => true
          _ => false
        }) {
    let op = self.advance()
    let right = self.parse_mul()
    left = match op {
      Plus => Arith(ArithOp::Add, left, right)
      _ => Arith(ArithOp::Sub, left, right)
    }
  }
  left
}

///|
fn Parser::parse_mul(self : Parser) -> Filter raise JqError {
  let mut left = self.parse_unary()
  while (match self.peek() {
          Star | Slash | Percent => true
          _ => false
        }) {
    let op = self.advance()
    let right = self.parse_unary()
    left = match op {
      Star => Arith(ArithOp::Mul, left, right)
      Slash => Arith(ArithOp::Div, left, right)
      _ => Arith(ArithOp::Mod, left, right)
    }
  }
  left
}

///|
fn Parser::parse_unary(self : Parser) -> Filter raise JqError {
  if self.peek() == Minus {
    ignore(self.advance())
    let expr = self.parse_postfix()
    Neg(expr)
  } else {
    self.parse_postfix()
  }
}

///|
fn Parser::parse_postfix(self : Parser) -> Filter raise JqError {
  let mut expr = self.parse_primary()
  while (match self.peek() {
          Dot | LBracket | Question => true
          _ => false
        }) {
    match self.peek() {
      Dot => {
        ignore(self.advance())
        match self.peek() {
          Ident(name) => {
            ignore(self.advance())
            expr = Pipe(expr, Field(name))
          }
          Str(name) => {
            ignore(self.advance())
            expr = Pipe(expr, Field(name))
          }
          _ => raise JqError("expected field name after '.'")
        }
      }
      LBracket => {
        ignore(self.advance())
        let suffix = self.parse_bracket_suffix()
        match suffix {
          DynIndex(idx_expr) => expr = PostfixDynIndex(expr, idx_expr)
          DynSlice(_, start_expr, end_expr) =>
            expr = DynSlice(expr, start_expr, end_expr)
          _ => expr = Pipe(expr, suffix)
        }
      }
      Question => {
        ignore(self.advance())
        expr = Try(expr)
      }
      _ => break
    }
  }
  expr
}

///|
fn Parser::parse_signed_int(self : Parser) -> Int raise JqError {
  if self.peek() == Minus {
    ignore(self.advance())
    match self.peek() {
      Num(n) => {
        ignore(self.advance())
        -n.to_int()
      }
      _ => raise JqError("expected number after '-'")
    }
  } else {
    match self.peek() {
      Num(n) => {
        ignore(self.advance())
        n.to_int()
      }
      _ => raise JqError("expected number")
    }
  }
}

///|
/// Parse a signed number as a Double, preserving float precision.
fn Parser::parse_signed_num(self : Parser) -> Double raise JqError {
  if self.peek() == Minus {
    ignore(self.advance())
    match self.peek() {
      Num(n) => {
        ignore(self.advance())
        -n
      }
      _ => raise JqError("expected number after '-'")
    }
  } else {
    match self.peek() {
      Num(n) => {
        ignore(self.advance())
        n
      }
      _ => raise JqError("expected number")
    }
  }
}

///|
fn Parser::parse_bracket_suffix(self : Parser) -> Filter raise JqError {
  match self.peek() {
    RBracket => {
      ignore(self.advance())
      Iterate
    }
    Str(s) => {
      ignore(self.advance())
      self.expect(RBracket)
      Field(s)
    }
    Variable(_) => {
      let expr = self.parse_pipe()
      self.expect(RBracket)
      DynIndex(expr)
    }
    Colon => {
      // .[:-2] or .[:expr]
      ignore(self.advance())
      match self.peek() {
        Num(_) | Minus => {
          let saved = self.pos
          let num = self.parse_signed_num()
          let end_is_float = num != num.floor()
          if self.peek() == RBracket {
            self.expect(RBracket)
            if end_is_float {
              DynSlice(Identity, None, Some(Literal(Json::number(num))))
            } else {
              Slice(None, Some(num.to_int()))
            }
          } else {
            // Not a simple number, reparse as expression
            self.pos = saved
            let end_expr = self.parse_pipe()
            self.expect(RBracket)
            DynSlice(Identity, None, Some(end_expr))
          }
        }
        _ => {
          let end_expr = self.parse_pipe()
          self.expect(RBracket)
          DynSlice(Identity, None, Some(end_expr))
        }
      }
    }
    Num(_) | Minus => {
      let saved = self.pos
      let num = self.parse_signed_num()
      let is_float = num != num.floor()
      match self.peek() {
        Colon => {
          // .[n:end] or .[n:] or .[n:expr]
          ignore(self.advance())
          match self.peek() {
            RBracket => {
              ignore(self.advance())
              if is_float {
                DynSlice(Identity, Some(Literal(Json::number(num))), None)
              } else {
                Slice(Some(num.to_int()), None)
              }
            }
            Num(_) | Minus => {
              let saved2 = self.pos
              let end_num = self.parse_signed_num()
              let end_is_float = end_num != end_num.floor()
              if self.peek() == RBracket {
                self.expect(RBracket)
                if is_float || end_is_float {
                  DynSlice(
                    Identity,
                    Some(Literal(Json::number(num))),
                    Some(Literal(Json::number(end_num))),
                  )
                } else {
                  Slice(Some(num.to_int()), Some(end_num.to_int()))
                }
              } else {
                self.pos = saved2
                let end_expr = self.parse_pipe()
                self.expect(RBracket)
                DynSlice(
                  Identity,
                  Some(Literal(Json::number(num))),
                  Some(end_expr),
                )
              }
            }
            _ => {
              let end_expr = self.parse_pipe()
              self.expect(RBracket)
              DynSlice(
                Identity,
                Some(Literal(Json::number(num))),
                Some(end_expr),
              )
            }
          }
        }
        Comma =>
          if is_float {
            // Float index — fall through to expression parsing
            self.pos = saved
            let expr = self.parse_pipe()
            self.expect(RBracket)
            DynIndex(expr)
          } else {
            // .[n,m,...] multi-index
            let n = num.to_int()
            let indices : Array[Int] = [n]
            while self.peek() == Comma {
              ignore(self.advance())
              indices.push(self.parse_signed_int())
            }
            self.expect(RBracket)
            let mut result : Filter = Index(indices[0])
            for i = 1; i < indices.length(); i = i + 1 {
              result = Comma(result, Index(indices[i]))
            }
            result
          }
        _ => {
          // .[n]
          self.expect(RBracket)
          if is_float {
            DynIndex(Literal(Json::number(num)))
          } else {
            Index(num.to_int())
          }
        }
      }
    }
    _ => {
      let expr = self.parse_pipe()
      self.expect(RBracket)
      DynIndex(expr)
    }
  }
}

///|
fn Parser::parse_primary(self : Parser) -> Filter raise JqError {
  match self.peek() {
    Dot => {
      ignore(self.advance())
      match self.peek() {
        Ident(name) => {
          ignore(self.advance())
          Field(name)
        }
        Str(name) => {
          ignore(self.advance())
          Field(name)
        }
        LBracket => {
          ignore(self.advance())
          self.parse_bracket_suffix()
        }
        _ => Identity
      }
    }
    DotDot => {
      ignore(self.advance())
      RecurseOp
    }
    Num(n) => {
      ignore(self.advance())
      Literal(Json::number(n))
    }
    Str(s) => {
      ignore(self.advance())
      Literal(Json::string(s))
    }
    StrInterp(parts) => {
      ignore(self.advance())
      let interp_parts : Array[(String, Filter?)] = []
      for part in parts {
        match part {
          Lit(s) => interp_parts.push((s, None))
          ExprSource(src) => {
            let expr_tokens = tokenize(src)
            let expr_filter = parse(expr_tokens)
            interp_parts.push(("", Some(expr_filter)))
          }
        }
      }
      StringInterp(interp_parts)
    }
    KwTrue => {
      ignore(self.advance())
      Literal(Json::boolean(true))
    }
    KwFalse => {
      ignore(self.advance())
      Literal(Json::boolean(false))
    }
    KwNull => {
      ignore(self.advance())
      Literal(Json::null())
    }
    Variable(name) => {
      ignore(self.advance())
      FuncCall("$" + name, [])
    }
    LParen => {
      ignore(self.advance())
      let expr = self.parse_pipe()
      self.expect(RParen)
      Paren(expr)
    }
    LBracket => {
      ignore(self.advance())
      if self.peek() == RBracket {
        ignore(self.advance())
        ArrayConstruct(None)
      } else {
        let expr = self.parse_pipe()
        self.expect(RBracket)
        ArrayConstruct(Some(expr))
      }
    }
    LBrace => {
      ignore(self.advance())
      self.parse_object_construct()
    }
    KwIf => {
      ignore(self.advance())
      self.parse_if()
    }
    KwTry => {
      ignore(self.advance())
      let expr = self.parse_postfix()
      if self.peek() == KwCatch {
        ignore(self.advance())
        let handler = self.parse_postfix()
        TryCatch(expr, handler)
      } else {
        Try(expr)
      }
    }
    KwReduce => {
      ignore(self.advance())
      self.parse_reduce()
    }
    KwForeach => {
      ignore(self.advance())
      self.parse_foreach()
    }
    KwDef => {
      ignore(self.advance())
      self.parse_def()
    }
    KwLabel => {
      ignore(self.advance())
      let var_tok = self.advance()
      let var_name = match var_tok {
        Variable(n) => n
        _ => raise JqError("expected variable after 'label'")
      }
      self.expect(Pipe)
      let body = self.parse_pipe()
      Label("$" + var_name, body)
    }
    KwBreak => {
      ignore(self.advance())
      let var_tok = self.advance()
      let var_name = match var_tok {
        Variable(n) => n
        _ => raise JqError("expected variable after 'break'")
      }
      Break("$" + var_name)
    }
    KwNot => {
      ignore(self.advance())
      FuncCall("not", [])
    }
    Ident(name) => {
      ignore(self.advance())
      if self.peek() == LParen {
        ignore(self.advance())
        let args = self.parse_func_args()
        FuncCall(name, args)
      } else {
        FuncCall(name, [])
      }
    }
    Format(name) => {
      ignore(self.advance())
      FuncCall("@" + name, [])
    }
    Minus => {
      ignore(self.advance())
      let expr = self.parse_postfix()
      Neg(expr)
    }
    _ => {
      let tok = self.peek()
      raise JqError("unexpected token: " + tok.to_string())
    }
  }
}

///|
fn Parser::parse_func_args(self : Parser) -> Array[Filter] raise JqError {
  let args : Array[Filter] = []
  if self.peek() == RParen {
    ignore(self.advance())
    return args
  }
  args.push(self.parse_pipe())
  while self.peek() == Semicolon {
    ignore(self.advance())
    args.push(self.parse_pipe())
  }
  self.expect(RParen)
  args
}

///|
fn Parser::parse_object_construct(self : Parser) -> Filter raise JqError {
  let fields : Array[(ObjKey, Filter)] = []
  if self.peek() == RBrace {
    ignore(self.advance())
    return ObjectConstruct(fields)
  }
  while true {
    let (key, value) = self.parse_object_field()
    fields.push((key, value))
    match self.peek() {
      Comma => ignore(self.advance())
      RBrace => {
        ignore(self.advance())
        break
      }
      _ => raise JqError("expected ',' or '}' in object")
    }
  }
  ObjectConstruct(fields)
}

///|
/// Parse pipe-separated bindings without consuming commas.
/// Used for object values where `{x: a | b}` means `{x: (a | b)}`.
fn Parser::parse_object_value(self : Parser) -> Filter raise JqError {
  let mut left = self.parse_binding()
  while self.peek() == Pipe {
    ignore(self.advance())
    let right = self.parse_binding()
    left = Pipe(left, right)
  }
  left
}

///|
fn Parser::parse_object_field(self : Parser) -> (ObjKey, Filter) raise JqError {
  match self.peek() {
    Ident(name) => {
      ignore(self.advance())
      if self.peek() == Colon {
        ignore(self.advance())
        let value = self.parse_object_value()
        (StrKey(name), value)
      } else {
        (StrKey(name), Field(name))
      }
    }
    Str(s) => {
      ignore(self.advance())
      if self.peek() == Colon {
        ignore(self.advance())
        let value = self.parse_object_value()
        (StrKey(s), value)
      } else {
        // Shorthand: {"key"} means {"key": .["key"]}
        (StrKey(s), DynIndex(Literal(Json::string(s))))
      }
    }
    StrInterp(parts) => {
      ignore(self.advance())
      // Build the StringInterp filter for the key
      let interp_parts : Array[(String, Filter?)] = []
      for part in parts {
        match part {
          Lit(s) => interp_parts.push((s, None))
          ExprSource(src) => {
            let expr_tokens = tokenize(src)
            let expr_filter = parse(expr_tokens)
            interp_parts.push(("", Some(expr_filter)))
          }
        }
      }
      let key_filter = StringInterp(interp_parts)
      if self.peek() == Colon {
        ignore(self.advance())
        let value = self.parse_object_value()
        (ExprKey(key_filter), value)
      } else {
        // Shorthand: {"interp_key"} means {"interp_key": .["interp_key"]}
        (ExprKey(key_filter), DynIndex(key_filter))
      }
    }
    LParen => {
      ignore(self.advance())
      let key_expr = self.parse_pipe()
      self.expect(RParen)
      self.expect(Colon)
      let value = self.parse_object_value()
      (ExprKey(key_expr), value)
    }
    Variable(name) => {
      ignore(self.advance())
      if self.peek() == Colon {
        ignore(self.advance())
        let value = self.parse_object_value()
        (StrKey(name), value)
      } else {
        (StrKey(name), FuncCall("$" + name, []))
      }
    }
    _ => raise JqError("expected object key")
  }
}

///|
fn Parser::parse_if(self : Parser) -> Filter raise JqError {
  let cond = self.parse_pipe()
  self.expect(KwThen)
  let then_branch = self.parse_pipe()
  let else_branch = match self.peek() {
    KwElif => {
      ignore(self.advance())
      self.parse_if()
    }
    KwElse => {
      ignore(self.advance())
      let e = self.parse_pipe()
      self.expect(KwEnd)
      e
    }
    KwEnd => {
      ignore(self.advance())
      Identity
    }
    _ => raise JqError("expected 'elif', 'else', or 'end' in if expression")
  }
  IfThenElse(cond, then_branch, else_branch)
}

///|
fn Parser::parse_reduce(self : Parser) -> Filter raise JqError {
  let iter_expr = self.parse_or()
  self.expect(KwAs)
  let pat = self.parse_pattern()
  self.expect(LParen)
  let init = self.parse_pipe()
  self.expect(Semicolon)
  let update = self.parse_pipe()
  self.expect(RParen)
  Reduce(iter_expr, pat, init, update)
}

///|
fn Parser::parse_foreach(self : Parser) -> Filter raise JqError {
  let iter_expr = self.parse_postfix()
  self.expect(KwAs)
  let pat = self.parse_pattern()
  self.expect(LParen)
  let init = self.parse_pipe()
  self.expect(Semicolon)
  let update = self.parse_pipe()
  let extract : Filter? = if self.peek() == Semicolon {
    ignore(self.advance())
    Some(self.parse_pipe())
  } else {
    None
  }
  self.expect(RParen)
  Foreach(iter_expr, pat, init, update, extract)
}

///|
fn Parser::parse_def(self : Parser) -> Filter raise JqError {
  let name_tok = self.advance()
  let name = match name_tok {
    Ident(n) => n
    _ => raise JqError("expected function name after 'def'")
  }
  let params : Array[String] = []
  if self.peek() == LParen {
    ignore(self.advance())
    if self.peek() != RParen {
      while true {
        let p = self.advance()
        match p {
          Ident(pname) => params.push(pname)
          _ => raise JqError("expected parameter name")
        }
        match self.peek() {
          Semicolon => ignore(self.advance())
          RParen => break
          _ => raise JqError("expected ';' or ')' in def params")
        }
      }
    }
    self.expect(RParen)
  }
  self.expect(Colon)
  let body = self.parse_pipe()
  self.expect(Semicolon)
  let rest = self.parse_pipe()
  FuncDef(name, params, body, rest)
}
