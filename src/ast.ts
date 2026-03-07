export type Node =
  | Program
  | ImportDeclaration
  | ScriptDeclaration
  | Statement
  | Expression
  | SwitchCase
  | TuplePattern
  | Comment;

export interface Program {
  type: 'Program';
  version: number | null;
  imports: ImportDeclaration[];
  scriptType: ScriptDeclaration | null;
  body: Statement[];
}

export interface ImportDeclaration {
  type: 'ImportDeclaration';
  source: string;
  alias: string | null;
}

export interface ScriptDeclaration {
  type: 'ScriptDeclaration';
  scriptType: 'indicator' | 'strategy' | 'library';
  args: Argument[];
}

export interface Argument {
  name: string | null;
  value: Expression;
}

// --- Statements ---

export type Statement =
  | CommentStatement
  | Block
  | BreakStatement
  | ContinueStatement
  | VariableDeclaration
  | AssignmentExpression // Note: The grammar parses assignment as a statement or expression
  | TupleDeclaration
  | TypeDeclaration
  | EnumDeclaration
  | FunctionDeclaration
  | MethodDeclaration
  | IfStatement
  | SwitchStatement
  | ForNumeric
  | ForIn
  | WhileStatement
  | ExpressionStatement;

export interface CommentStatement {
  type: 'CommentStatement';
  value: Comment;
}

export interface Block {
  type: 'Block';
  body: Statement[];
}

export interface BreakStatement {
  type: 'BreakStatement';
}

export interface ContinueStatement {
  type: 'ContinueStatement';
}

export interface VariableDeclaration {
  type: 'VariableDeclaration';
  modifiers: { persistence: string | null; qualifier: string | null } | null;
  valueType: string | null;
  id: string;
  init: Expression | Statement;
  exported?: boolean;
}

export interface AssignmentExpression {
  type: 'AssignmentExpression';
  operator: string;
  left: Expression;
  right: Expression | Statement;
}

export interface TupleDeclaration {
  type: 'TupleDeclaration';
  elements: string[];
  init: Expression | Statement;
}

export interface TuplePattern {
  type: 'TuplePattern';
  elements: string[];
}

export interface TypeDeclaration {
  type: 'TypeDeclaration';
  id: string;
  fields: { name: string; type: string; default: Expression | null }[];
  exported?: boolean;
}

export interface EnumDeclaration {
  type: 'EnumDeclaration';
  id: string;
  fields: { key: string; title: string | null }[];
  exported?: boolean;
}

export interface FunctionDeclaration {
  type: 'FunctionDeclaration';
  id: string;
  params: Parameter[];
  body: Block;
  exported?: boolean;
}

export interface MethodDeclaration {
  type: 'MethodDeclaration';
  id: string;
  params: Parameter[];
  body: Block;
  exported?: boolean;
}

export interface Parameter {
  id: string;
  qualifier: string | null;
  type: string | null;
  default: Expression | null;
}

export interface IfStatement {
  type: 'IfStatement';
  test: Expression;
  consequent: Block;
  alternates: { type: 'IfStatement'; test: Expression; consequent: Block }[]; // Actually arrays from pegjs: [__ "else" _ "if" _ Expression_Safe _ BlockOrLine] -> need to map this carefully or type it loosely based on pegjs output
  fallback: Block | null;
}

export interface SwitchStatement {
  type: 'SwitchStatement';
  discriminant: Expression | null;
  cases: SwitchCase[];
}

export interface SwitchCase {
  type: 'SwitchCase';
  tests?: Expression[];
  default?: boolean;
  consequent: Block;
}

export interface ForNumeric {
  type: 'ForNumeric';
  counter: string;
  start: Expression;
  end: Expression;
  step: Expression | null;
  body: Block;
}

export interface ForIn {
  type: 'ForIn';
  item: TuplePattern | string;
  collection: Expression;
  body: Block;
}

export interface WhileStatement {
  type: 'WhileStatement';
  test: Expression;
  body: Block;
}

export interface ExpressionStatement {
  type: 'ExpressionStatement';
  expression: Expression;
}

// --- Expressions ---

export type Expression =
  | ConditionalExpression
  | LogicalExpression
  | BinaryExpression
  | UnaryExpression
  | MemberExpression
  | ArrayAccess
  | CallExpression
  | Identifier
  | ArrayLiteral
  | Literal;

export interface ConditionalExpression {
  type: 'ConditionalExpression';
  test: Expression;
  consequent: Expression;
  alternate: Expression;
}

export interface LogicalExpression {
  type: 'LogicalExpression';
  operator: 'and' | 'or';
  left: Expression;
  right: Expression;
}

export interface BinaryExpression {
  type: 'BinaryExpression';
  operator: string;
  left: Expression;
  right: Expression;
}

export interface UnaryExpression {
  type: 'UnaryExpression';
  operator: 'not' | '+' | '-';
  argument: Expression;
}

export interface MemberExpression {
  type: 'MemberExpression';
  object: Expression;
  property: string;
}

export interface ArrayAccess {
  type: 'ArrayAccess';
  object: Expression;
  index: Expression;
}

export interface CallExpression {
  type: 'CallExpression';
  callee: Expression;
  args: Argument[];
  typeArgs: string[] | null;
}

export interface Identifier {
  type: 'Identifier';
  name: string;
}

export interface ArrayLiteral {
  type: 'ArrayLiteral';
  elements: Expression[];
}

export interface Literal {
  type: 'Literal';
  value: string | number | boolean | null;
  kind?: 'color';
}

export interface Comment {
  type: 'Comment';
  content: string;
}

export interface Annotation {
  type: 'Annotation';
  key: string;
}
