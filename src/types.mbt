///|
/// Error type for jq compilation and evaluation failures.
pub(all) suberror JqError {
  JqError(String)
} derive(Show)

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
  Binding(String, Filter, Filter)
  Reduce(Filter, String, Filter, Filter)
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
  Foreach(Filter, String, Filter, Filter, Filter?)
} derive(Show)
