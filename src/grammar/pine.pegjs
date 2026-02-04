{{
  // =========================================================
  // Pine Script v6 Grammar (Final Fix: Type Casting Support)
  // =========================================================

  function extractList(list, index) {
    return list.map(function(element) { return element[index]; });
  }

  function extractOptional(optional, index) {
    return optional ? optional[index] : null;
  }

  function buildBinary(head, tail) {
    return tail.reduce(function(result, element) {
      return {
        type: "BinaryExpression",
        operator: element[1],
        left: result,
        right: element[3]
      };
    }, head);
  }
  
  function buildLogical(head, tail) {
    return tail.reduce(function(result, element) {
      return {
        type: "LogicalExpression",
        operator: element[1],
        left: result,
        right: element[3]
      };
    }, head);
  }
}}

// ==========================================
// 1. 程序结构
// ==========================================

Start
  = __ version:VersionDirective? __ 
    imports:ImportStatement* __ 
    decl:ScriptDeclaration? __ 
    body:StatementList 
    __ 
    {
      return {
        type: "Program",
        version: version,
        imports: imports,
        scriptType: decl,
        body: body
      };
    }

VersionDirective
  = "//@version=" v:$([0-9]+) (LineTerminator / EOF) { return parseInt(v, 10); }

ImportStatement
  = "import" _ path:ImportPath _ alias:("as" _ Identifier)? EOS
    { return { type: "ImportDeclaration", source: path, alias: alias ? alias[2] : null }; }

ImportPath
  = user:Identifier "/" lib:Identifier "/" v:$([0-9]+) 
    { return user + "/" + lib + "/" + v; }

ScriptDeclaration
  = type:("indicator" / "strategy" / "library") _ "(" __ args:ArgumentList? __ ")" EOS
    { return { type: "ScriptDeclaration", scriptType: type, args: args || [] }; }

// ==========================================
// 2. 语句 (Statements)
// ==========================================

StatementList
  = head:Statement tail:(__ Statement)* { return [head].concat(extractList(tail, 1)); }

Statement
  = CommentStatement    
  / BlockStatement      
  / ExportStatement     
  / BreakStatement      
  / ContinueStatement   
  / TypeDeclaration     
  / EnumDeclaration     
  / MethodDeclaration   
  / FunctionDeclaration 
  / VariableDeclaration 
  / AssignmentStatement 
  / TupleDeclaration    
  / ControlStructure    
  / ExpressionStatement 

// --- 循环控制语句 ---
BreakStatement
  = "break" EOS { return { type: "BreakStatement" }; }

ContinueStatement
  = "continue" EOS { return { type: "ContinueStatement" }; }

// --- 注释语句 ---
CommentStatement
  = c:Comment EOS
    { return { type: "CommentStatement", value: c }; }

// --- 2.1 变量声明与赋值 ---

VariableDeclaration
  = VariableDeclaration_Mode_Typed    // 1. const float x = ...
  / VariableDeclaration_Mode_Untyped  // 2. var x = ...
  / VariableDeclaration_Typed         // 3. float x = ...
  / VariableDeclaration_Simple        // 4. x = ...

// Case 1: Mode + Type + ID
VariableDeclaration_Mode_Typed
  = mode:DeclarationMode __ type:TypeAnnotation __ id:Identifier _ "=" _ init:Expression EOS
    { return { type: "VariableDeclaration", mode: mode, valueType: type, id: id, init: init }; }

// Case 2: Mode + ID
VariableDeclaration_Mode_Untyped
  = mode:DeclarationMode __ id:Identifier _ "=" _ init:Expression EOS
    { return { type: "VariableDeclaration", mode: mode, valueType: null, id: id, init: init }; }

// Case 3: Type + ID
VariableDeclaration_Typed
  = type:TypeAnnotation __ id:Identifier _ "=" _ init:Expression EOS
    { return { type: "VariableDeclaration", mode: null, valueType: type, id: id, init: init }; }

// Case 4: ID only
VariableDeclaration_Simple
  = id:Identifier _ "=" _ init:Expression EOS
    { return { type: "VariableDeclaration", mode: null, valueType: null, id: id, init: init }; }

DeclarationMode
  = ("varip" / "var" / "const") !IdentifierPart { return text(); }

AssignmentStatement
  = id:Identifier _ op:AssignmentOperator _ val:Expression EOS
    { return { type: "AssignmentExpression", operator: op, left: id, right: val }; }

AssignmentOperator
  = ":=" / "+=" / "-=" / "*=" / "/=" / "%="

TupleDeclaration
  = "[" __ elements:TupleElementList __ "]" _ "=" _ init:Expression EOS
    { return { type: "TupleDeclaration", elements: elements, init: init }; }

TupleElementList
  = head:(Identifier / "_") tail:(__ "," __ (Identifier / "_"))* { return [head].concat(extractList(tail, 3)); }

// --- 2.2 结构定义 ---

TypeDeclaration
  = "type" _ id:Identifier EOL fields:TypeFields
    { return { type: "TypeDeclaration", id: id, fields: fields }; }

TypeFields
  = head:TypeField tail:(EOL TypeField)* { return [head].concat(extractList(tail, 1)); }

TypeField
  = INDENT type:TypeAnnotation _ id:Identifier _ def:("=" _ Expression)?
    { return { name: id, type: type, default: def ? def[2] : null }; }

EnumDeclaration
  = "enum" _ id:Identifier EOL fields:EnumFields
    { return { type: "EnumDeclaration", id: id, fields: fields }; }

EnumFields
  = head:EnumField tail:(EOL EnumField)* { return [head].concat(extractList(tail, 1)); }

EnumField
  = INDENT id:Identifier _ title:("=" _ StringLiteral)?
    { return { key: id, title: title ? title[2] : null }; }

FunctionDeclaration
  = id:Identifier _ "(" __ params:ParameterList? __ ")" _ "=>" _ body:FunctionBody
    { return { type: "FunctionDeclaration", id: id, params: params || [], body: body }; }

MethodDeclaration
  = "method" _ id:Identifier _ "(" __ params:ParameterList? __ ")" _ "=>" _ body:FunctionBody
    { return { type: "MethodDeclaration", id: id, params: params || [], body: body }; }

ExportStatement
  = "export" _ stmt:(MethodDeclaration / FunctionDeclaration / TypeDeclaration / EnumDeclaration)
    { stmt.exported = true; return stmt; }

ParameterList
  = head:Parameter tail:(__ "," __ Parameter)* { return [head].concat(extractList(tail, 3)); }

Parameter
  = type:(TypeAnnotation _)? id:Identifier _ def:("=" _ Expression)?
    { return { id: id, type: type ? type[0] : null, default: def ? def[2] : null }; }

FunctionBody
  = ScopeBlock  
  / _ expr:Expression EOS { return { type: "Block", body: [expr] }; }

// --- 2.3 控制流 ---

ControlStructure
  = IfStatement
  / SwitchStatement
  / ForStatement
  / WhileStatement

IfStatement
  = "if" _ test:Expression _ body:BlockOrLine
    elseIfs:(_ "else" _ "if" _ Expression _ BlockOrLine)*
    elseBody:(_ "else" _ BlockOrLine)?
    { return { type: "IfStatement", test: test, consequent: body, alternates: elseIfs, fallback: elseBody }; }

SwitchStatement
  = "switch" _ discriminant:Expression? _ EOL
    cases:SwitchCaseList
    { return { type: "SwitchStatement", discriminant: discriminant, cases: cases }; }

SwitchCaseList
  = head:SwitchCase tail:(EOL SwitchCase)*
    { return [head].concat(extractList(tail, 1)); }

SwitchCase
  = INDENT tests:ExpressionList _ "=>" _ body:BlockOrLine
    { return { type: "SwitchCase", tests: tests, consequent: body }; }
  / INDENT "=>" _ body:BlockOrLine 
    { return { type: "SwitchCase", default: true, consequent: body }; }

ExpressionList
  = head:Expression tail:(_ "," _ Expression)*
    { return [head].concat(extractList(tail, 3)); }

ForStatement
  = "for" _ counter:Identifier _ "=" _ start:Expression _ "to" _ end:Expression _ step:("by" _ Expression)? _ body:BlockOrLine
    { return { type: "ForNumeric", counter: counter, start: start, end: end, step: step, body: body }; }
  / "for" _ item:(Identifier / TupleDeclaration) _ "in" _ collection:Expression _ body:BlockOrLine
    { return { type: "ForIn", item: item, collection: collection, body: body }; }

WhileStatement
  = "while" _ test:Expression _ body:BlockOrLine
    { return { type: "WhileStatement", test: test, body: body }; }

BlockOrLine
  = ScopeBlock
  / _ "=>" _ ScopeBlock
  / _ expr:Expression EOS { return { type: "Block", body: [expr] }; }

ScopeBlock
  = EOL INDENT statements:StatementListDedent 
    { return { type: "Block", body: statements }; }

StatementListDedent
  = head:(_ Statement) tail:(BlockSeparator _ Statement)* { 
       var tailList = tail.map(function(e) { return e[2]; });
       return [head[1]].concat(tailList); 
    }

BlockStatement
  = ScopeBlock

ExpressionStatement
  = expr:Expression EOS 
    { return { type: "ExpressionStatement", expression: expr }; }

// ==========================================
// 3. 表达式 (Expressions)
// ==========================================

Expression
  = ConditionalExpression

ConditionalExpression
  = test:LogicalOrExpression _ "?" _ consequent:Expression _ ":" _ alternate:Expression
    { return { type: "ConditionalExpression", test: test, consequent: consequent, alternate: alternate }; }
  / LogicalOrExpression

LogicalOrExpression
  = head:LogicalAndExpression tail:(_ "or" _ LogicalAndExpression)* { return buildLogical(head, tail); }

LogicalAndExpression
  = head:EqualityExpression tail:(_ "and" _ EqualityExpression)* { return buildLogical(head, tail); }

EqualityExpression
  = head:RelationalExpression tail:(_ ("==" / "!=") _ RelationalExpression)* { return buildBinary(head, tail); }

RelationalExpression
  = head:AdditiveExpression tail:(_ (">=" / "<=" / ">" / "<") _ AdditiveExpression)* { return buildBinary(head, tail); }

AdditiveExpression
  = head:MultiplicativeExpression tail:(_ ("+" / "-") _ MultiplicativeExpression)* { return buildBinary(head, tail); }

MultiplicativeExpression
  = head:UnaryExpression tail:(_ ("*" / "/" / "%") _ UnaryExpression)* { return buildBinary(head, tail); }

UnaryExpression
  = operator:("not" / "+" / "-") _ argument:UnaryExpression
    { return { type: "UnaryExpression", operator: operator, argument: argument }; }
  / PrimaryExpression

// --- 链式调用与多行支持 ---

PrimaryExpression
  = head:Atom
    tail:(
        _ "." _ id:IdentifierName { 
            return { type: "MemberPart", id: id }; 
        }
      / _ "[" __ idx:Expression __ "]" { 
            return { type: "IndexPart", index: idx }; 
        }
      / _ "(" __ args:ArgumentList? __ ")" { 
            return { type: "CallPart", args: args || [] }; 
        }
    )*
    {
      return tail.reduce(function(result, part) {
        if (part.type === "MemberPart") {
          return { type: "MemberExpression", object: result, property: part.id };
        } else if (part.type === "IndexPart") {
          return { type: "ArrayAccess", object: result, index: part.index };
        } else if (part.type === "CallPart") {
          return { type: "CallExpression", callee: result, args: part.args };
        }
        return result;
      }, head);
    }

Atom
  = Literal
  // [修复] 允许 PrimitiveType 作为表达式原子 (用于 float(), int() 等类型转换调用)
  / PrimitiveType { return { type: "Identifier", name: text() }; }
  / Identifier
  / "(" _ expression:Expression _ ")" { return expression; }

ArgumentList
  = head:Argument tail:(__ "," __ Argument)* { return [head].concat(extractList(tail, 3)); }

Argument
  = name:(IdentifierName __ "=")? __ value:Expression
    { return { name: name ? name[0] : null, value: value }; }

// ==========================================
// 4. 词法规则 (Lexical Rules)
// ==========================================

TypeAnnotation
  = (SimpleType / GenericType) ("[" "]")*

SimpleType
  // SimpleType 可以匹配 PrimitiveType 或 Identifier (用户自定义类型)
  = PrimitiveType
  / Identifier

PrimitiveType
  = ("int" / "float" / "bool" / "color" / "string" / "line" / "label" / "box" / "table") !IdentifierPart { return text(); }

GenericType
  = ("array" / "matrix" / "map") "<" _ TypeAnnotation _ ("," _ TypeAnnotation)? ">"

Identifier
  = !ReservedWord name:IdentifierName { return name; }

IdentifierName
  = start:[a-zA-Z_] part:IdentifierPart* { return start + part.join(""); }

IdentifierPart
  = [a-zA-Z0-9_]

Literal
  = FloatLiteral
  / IntLiteral
  / BoolLiteral
  / StringLiteral
  / ColorLiteral
  / NaLiteral

FloatLiteral  = chars:([0-9]* "." [0-9]+ ([eE] [-+]? [0-9]+)?) { return { type: "Literal", value: parseFloat(text()) }; }
IntLiteral    = chars:([0-9]+) { return { type: "Literal", value: parseInt(text(), 10) }; }
BoolLiteral   = ("true" / "false") { return { type: "Literal", value: text() === "true" }; }
NaLiteral     = "na" { return { type: "Literal", value: null }; }
ColorLiteral  = "#" [0-9a-fA-F]+ { return { type: "Literal", kind: "color", value: text() }; }
StringLiteral = ('"' [^"\n\r]* '"' / "'" [^'\n\r]* "'") { return { type: "Literal", value: text().slice(1, -1) }; }

// ------------------------------------------
// 缩进与空白
// ------------------------------------------

INDENT = "    " / "\t"
SAMELINE_WS = [ \t]*
_  = [ \t]*
__ = (WhiteSpace / LineTerminatorSequence / Comment)*
WhiteSpace = [ \t]
LineTerminator = [\n\r]
LineTerminatorSequence = "\n" / "\r\n" / "\r"
EOL = SAMELINE_WS LineTerminatorSequence
EOS = _ (";" / LineTerminatorSequence / EOF)

BlockSeparator 
  = (SAMELINE_WS LineTerminatorSequence)* INDENT

Comment
  = "//" text:(!LineTerminator .)* { return text.map(t => t[1]).join(""); }

// [重构] ReservedWord 拆分
ReservedWord
  = Keyword
  / PrimitiveType
  / LiteralKeyword

Keyword
  = ("if" / "else" / "for" / "while" / "switch" / "return" / "break" / "continue" / 
     "var" / "varip" / "const" / "simple" / "series" / 
     "import" / "export" / "method" / "type" / "enum") !IdentifierPart

LiteralKeyword
  = ("true" / "false" / "na" / "and" / "or" / "not") !IdentifierPart

EOF = !.
