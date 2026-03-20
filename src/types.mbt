///|
/// Error type for jq compilation and evaluation failures.
pub(all) suberror JqError {
  JqError(String)
} derive(Show)

///|
/// A part of a string interpolation token.
priv enum StringInterpPart {
  Lit(String)
  ExprSource(String)
} derive(Show, Eq)

///|
priv enum Token {
  Dot
  DotDot
  LBracket
  RBracket
  LBrace
  RBrace
  LParen
  RParen
  Pipe
  Comma
  Colon
  Semicolon
  Question
  Ident(String)
  Str(String)
  StrInterp(Array[StringInterpPart])
  Num(Double)
  Variable(String)
  Format(String)
  EqEq
  Ne
  Lt
  Gt
  Le
  Ge
  Plus
  Minus
  Star
  Slash
  SlashSlash
  Percent
  Eq
  PipeEq
  PlusEq
  MinusEq
  StarEq
  SlashEq
  PercentEq
  SlashSlashEq
  KwAnd
  KwOr
  KwNot
  KwIf
  KwThen
  KwElif
  KwElse
  KwEnd
  KwAs
  KwDef
  KwTry
  KwCatch
  KwReduce
  KwForeach
  KwTrue
  KwFalse
  KwNull
  KwLabel
  KwBreak
  Eof
} derive(Show, Eq)

///|
/// Arithmetic operation type used in filter expressions.
pub enum ArithOp {
  Add
  Sub
  Mul
  Div
  Mod
} derive(Show)

///|
/// Comparison operation type used in filter expressions.
pub enum CmpOp {
  Eq
  Ne
  Lt
  Gt
  Le
  Ge
} derive(Show)

///|
/// Object key type: either a static string or a dynamic expression.
pub enum ObjKey {
  StrKey(String)
  ExprKey(Filter)
} derive(Show)

///|
/// Pattern for destructuring bind in 'as' expressions.
pub enum Pattern {
  PatVar(String)
  PatArray(Array[Pattern])
  PatObject(Array[(String, Pattern)])
} derive(Show)

///|
/// A compiled jq filter AST node.
pub enum Filter {
  Identity
  RecurseOp
  Field(String)
  Index(Int)
  Slice(Int?, Int?)
  Iterate
  Pipe(Filter, Filter)
  Comma(Filter, Filter)
  Literal(Json)
  ArrayConstruct(Filter?)
  ObjectConstruct(Array[(ObjKey, Filter)])
  Paren(Filter)
  Try(Filter)
  TryCatch(Filter, Filter)
  IfThenElse(Filter, Filter, Filter)
  Binding(Pattern, Filter, Filter)
  Reduce(Filter, Pattern, Filter, Filter)
  FuncDef(String, Array[String], Filter, Filter)
  FuncCall(String, Array[Filter])
  DynIndex(Filter)
  PostfixDynIndex(Filter, Filter)
  DynSlice(Filter, Filter?, Filter?)
  Neg(Filter)
  Arith(ArithOp, Filter, Filter)
  Compare(CmpOp, Filter, Filter)
  LogicAnd(Filter, Filter)
  LogicOr(Filter, Filter)
  Alternative(Filter, Filter)
  Foreach(Filter, Pattern, Filter, Filter, Filter?)
  StringInterp(Array[(String, Filter?)])
  Assign(Filter, Filter)
  Update(Filter, Filter)
  UpdateAlt(Filter, Filter)
  Label(String, Filter)
  Break(String)
  BindingAlt(Array[Pattern], Filter, Filter)
} derive(Show)
