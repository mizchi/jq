///|
fn keyword_or_ident(name : String) -> Token {
  match name {
    "and" => KwAnd
    "or" => KwOr
    "not" => KwNot
    "if" => KwIf
    "then" => KwThen
    "elif" => KwElif
    "else" => KwElse
    "end" => KwEnd
    "as" => KwAs
    "def" => KwDef
    "try" => KwTry
    "catch" => KwCatch
    "reduce" => KwReduce
    "foreach" => KwForeach
    "true" => KwTrue
    "false" => KwFalse
    "null" => KwNull
    _ => Ident(name)
  }
}

///|
fn tokenize(input : String) -> Array[Token] raise JqError {
  let chars = Array::from_iter(input.iter())
  let tokens : Array[Token] = []
  let len = chars.length()
  let mut pos = 0
  while pos < len {
    let c = chars[pos]
    if c.is_ascii_whitespace() {
      pos += 1
      continue
    }
    if c == '#' {
      // line comment
      while pos < len && chars[pos] != '\n' {
        pos += 1
      }
      continue
    }
    match c {
      '.' =>
        if pos + 1 < len && chars[pos + 1] == '.' {
          tokens.push(DotDot)
          pos += 2
        } else {
          tokens.push(Dot)
          pos += 1
        }
      '[' => {
        tokens.push(LBracket)
        pos += 1
      }
      ']' => {
        tokens.push(RBracket)
        pos += 1
      }
      '{' => {
        tokens.push(LBrace)
        pos += 1
      }
      '}' => {
        tokens.push(RBrace)
        pos += 1
      }
      '(' => {
        tokens.push(LParen)
        pos += 1
      }
      ')' => {
        tokens.push(RParen)
        pos += 1
      }
      '|' => {
        tokens.push(Pipe)
        pos += 1
      }
      ',' => {
        tokens.push(Comma)
        pos += 1
      }
      ':' => {
        tokens.push(Colon)
        pos += 1
      }
      ';' => {
        tokens.push(Semicolon)
        pos += 1
      }
      '?' => {
        tokens.push(Question)
        pos += 1
      }
      '+' => {
        tokens.push(Plus)
        pos += 1
      }
      '-' => {
        tokens.push(Minus)
        pos += 1
      }
      '*' => {
        tokens.push(Star)
        pos += 1
      }
      '/' =>
        if pos + 1 < len && chars[pos + 1] == '/' {
          tokens.push(SlashSlash)
          pos += 2
        } else {
          tokens.push(Slash)
          pos += 1
        }
      '%' => {
        tokens.push(Percent)
        pos += 1
      }
      '=' =>
        if pos + 1 < len && chars[pos + 1] == '=' {
          tokens.push(EqEq)
          pos += 2
        } else {
          raise JqError("unexpected '='")
        }
      '!' =>
        if pos + 1 < len && chars[pos + 1] == '=' {
          tokens.push(Ne)
          pos += 2
        } else {
          raise JqError("unexpected '!'")
        }
      '<' =>
        if pos + 1 < len && chars[pos + 1] == '=' {
          tokens.push(Le)
          pos += 2
        } else {
          tokens.push(Lt)
          pos += 1
        }
      '>' =>
        if pos + 1 < len && chars[pos + 1] == '=' {
          tokens.push(Ge)
          pos += 2
        } else {
          tokens.push(Gt)
          pos += 1
        }
      '"' => {
        pos += 1
        let buf = StringBuilder::new()
        while pos < len && chars[pos] != '"' {
          if chars[pos] == '\\' {
            pos += 1
            if pos >= len {
              raise JqError("unterminated string")
            }
            match chars[pos] {
              'n' => buf.write_char('\n')
              't' => buf.write_char('\t')
              'r' => buf.write_char('\r')
              '\\' => buf.write_char('\\')
              '"' => buf.write_char('"')
              '/' => buf.write_char('/')
              _ => {
                buf.write_char('\\')
                buf.write_char(chars[pos])
              }
            }
          } else {
            buf.write_char(chars[pos])
          }
          pos += 1
        }
        if pos >= len {
          raise JqError("unterminated string")
        }
        pos += 1
        tokens.push(Str(buf.to_string()))
      }
      '$' => {
        pos += 1
        let buf = StringBuilder::new()
        while pos < len &&
              (
                chars[pos].is_ascii_alphabetic() ||
                chars[pos].is_ascii_digit() ||
                chars[pos] == '_'
              ) {
          buf.write_char(chars[pos])
          pos += 1
        }
        let name = buf.to_string()
        if name.is_empty() {
          raise JqError("expected variable name after $")
        }
        tokens.push(Variable(name))
      }
      _ =>
        if c.is_ascii_digit() {
          let buf = StringBuilder::new()
          while pos < len && chars[pos].is_ascii_digit() {
            buf.write_char(chars[pos])
            pos += 1
          }
          if pos < len &&
            chars[pos] == '.' &&
            (pos + 1 >= len || chars[pos + 1] != '.') {
            buf.write_char('.')
            pos += 1
            while pos < len && chars[pos].is_ascii_digit() {
              buf.write_char(chars[pos])
              pos += 1
            }
          }
          let s = buf.to_string()
          let n = parse_number_str(s)
          tokens.push(Num(n))
        } else if c.is_ascii_alphabetic() || c == '_' {
          let buf = StringBuilder::new()
          while pos < len &&
                (
                  chars[pos].is_ascii_alphabetic() ||
                  chars[pos].is_ascii_digit() ||
                  chars[pos] == '_'
                ) {
            buf.write_char(chars[pos])
            pos += 1
          }
          tokens.push(keyword_or_ident(buf.to_string()))
        } else if c == '@' {
          pos += 1
          let buf = StringBuilder::new()
          while pos < len &&
                (
                  chars[pos].is_ascii_alphabetic() ||
                  chars[pos].is_ascii_digit() ||
                  chars[pos] == '_'
                ) {
            buf.write_char(chars[pos])
            pos += 1
          }
          tokens.push(Format(buf.to_string()))
        } else {
          raise JqError("unexpected character: " + c.to_string())
        }
    }
  }
  tokens.push(Eof)
  tokens
}

///|
fn parse_number_str(s : String) -> Double {
  let chars = Array::from_iter(s.iter())
  let mut result = 0.0
  let mut i = 0
  while i < chars.length() && chars[i] != '.' {
    let d = chars[i].to_int() - '0'.to_int()
    result = result * 10.0 + d.to_double()
    i += 1
  }
  if i < chars.length() && chars[i] == '.' {
    i += 1
    let mut frac_div = 10.0
    while i < chars.length() {
      let d = chars[i].to_int() - '0'.to_int()
      result = result + d.to_double() / frac_div
      frac_div = frac_div * 10.0
      i += 1
    }
  }
  result
}
