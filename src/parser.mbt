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
  let mut left = self.parse_comma()
  while self.peek() == Pipe {
    ignore(self.advance())
    let right = self.parse_comma()
    left = Pipe(left, right)
  }
  left
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
fn Parser::parse_binding(self : Parser) -> Filter raise JqError {
  let expr = self.parse_or()
  if self.peek() == KwAs {
    ignore(self.advance())
    let var_tok = self.advance()
    let var_name = match var_tok {
      Variable(name) => name
      _ => raise JqError("expected variable after 'as'")
    }
    self.expect(Pipe)
    let body = self.parse_pipe()
    Binding("$" + var_name, expr, body)
  } else {
    expr
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
    KwDef => {
      ignore(self.advance())
      self.parse_def()
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
fn Parser::parse_object_field(self : Parser) -> (ObjKey, Filter) raise JqError {
  match self.peek() {
    Ident(name) => {
      ignore(self.advance())
      if self.peek() == Colon {
        ignore(self.advance())
        let value = self.parse_binding()
        (StrKey(name), value)
      } else {
        (StrKey(name), Field(name))
      }
    }
    Str(s) => {
      ignore(self.advance())
      self.expect(Colon)
      let value = self.parse_binding()
      (StrKey(s), value)
    }
    LParen => {
      ignore(self.advance())
      let key_expr = self.parse_pipe()
      self.expect(RParen)
      self.expect(Colon)
      let value = self.parse_binding()
      (ExprKey(key_expr), value)
    }
    Variable(name) => {
      ignore(self.advance())
      if self.peek() == Colon {
        ignore(self.advance())
        let value = self.parse_binding()
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
  let var_tok = self.advance()
  let var_name = match var_tok {
    Variable(name) => name
    _ => raise JqError("expected variable after 'as' in reduce")
  }
  self.expect(LParen)
  let init = self.parse_pipe()
  self.expect(Semicolon)
  let update = self.parse_pipe()
  self.expect(RParen)
  Reduce(iter_expr, "$" + var_name, init, update)
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
