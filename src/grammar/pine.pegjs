{{
  // =========================================================
  // Pine Script v6 Grammar (Final Fix: Inline Function Decls)
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
  / TupleDeclaration
  / VariableDeclaration 
  / AssignmentStatement 
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

// --- 2.1 变量声明 ---

VariableDeclaration
  = VarDecl_Full      
  / VarDecl_ModOnly   
  / VarDecl_TypeOnly  
  / VarDecl_Simple    

// 1. Modifiers + Type + ID
VarDecl_Full
  = mods:StorageModifiers __ type:TypeAnnotation __ id:Identifier _ "=" _ init:Initializer
    { return { type: "VariableDeclaration", modifiers: mods, valueType: type, id: id, init: init }; }

// 2. Modifiers + ID
VarDecl_ModOnly
  = mods:StorageModifiers __ id:Identifier _ "=" _ init:Initializer
    { return { type: "VariableDeclaration", modifiers: mods, valueType: null, id: id, init: init }; }

// 3. Type + ID
VarDecl_TypeOnly
  = type:TypeAnnotation __ id:Identifier _ "=" _ init:Initializer
    { return { type: "VariableDeclaration", modifiers: null, valueType: type, id: id, init: init }; }

// 4. Simple ID
VarDecl_Simple
  = id:Identifier _ "=" _ init:Initializer
    { return { type: "VariableDeclaration", modifiers: null, valueType: null, id: id, init: init }; }

Initializer
  = c:ControlStructure { return c; }
  / e:Expression EOS { return e; }

StorageModifiers
  = p:PersistenceMode __ q:TypeQualifier 
    { return { persistence: p, qualifier: q }; }
  / p:PersistenceMode 
    { return { persistence: p, qualifier: null }; }
  / q:TypeQualifier
    { return { persistence: null, qualifier: q }; }

PersistenceMode
  = ("varip" / "var") !IdentifierPart { return text(); }

TypeQualifier
  = ("const" / "simple" / "series") !IdentifierPart { return text(); }

AssignmentStatement
  = left:PrimaryExpression _ op:AssignmentOperator _ val:Initializer
    { return { type: "AssignmentExpression", operator: op, left: left, right: val }; }

AssignmentOperator
  = ":=" / "+=" / "-=" / "*=" / "/=" / "%="

TupleDeclaration
  = pattern:TuplePattern _ "=" _ init:Initializer
    { return { type: "TupleDeclaration", elements: pattern.elements, init: init }; }

TuplePattern
  = "[" __ elements:TupleElementList __ "]"
    { return { type: "TuplePattern", elements: elements }; }

TupleElementList
  = head:(Identifier / "_") tail:(__ "," __ (Identifier / "_"))* { return [head].concat(extractList(tail, 3)); }

// --- 2.2 结构定义 ---

TypeDeclaration
  = "type" _ id:Identifier EOL fields:TypeFields
    { return { type: "TypeDeclaration", id: id, fields: fields }; }

TypeFields
  = head:TypeField tail:(EOL TypeField)* { return [head].concat(extractList(tail, 1)); }

TypeField
  = INDENT type:TypeAnnotation _ id:Identifier _ def:("=" _ Initializer)?
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
  = qual:(TypeQualifier __)? core:ParameterCore
    { 
      return { 
        id: core.id, 
        qualifier: qual ? qual[0] : null, 
        type: core.type, 
        default: core.default 
      }; 
    }

ParameterCore
  = type:TypeAnnotation __ &Identifier id:Identifier _ def:("=" _ Expression)?
    { return { type: type, id: id, default: def ? def[2] : null }; }
  / id:Identifier _ def:("=" _ Expression)?
    { return { type: null, id: id, default: def ? def[2] : null }; }

// [修复] FunctionBody: 支持单行函数中的逗号分隔序列 (InlineSeries)
FunctionBody
  = ScopeBlock  
  / _ body:InlineSeries EOS { return { type: "Block", body: body }; }

// [新增] 逗号分隔的单行语句序列
InlineSeries
  = head:InlineItem tail:(_ "," _ InlineItem)*
    { return [head].concat(extractList(tail, 3)); }

// [新增] 单行元素：声明、赋值或表达式
InlineItem
  = InlineVarDecl
  / InlineAssignment
  / Expression

// [新增] 单行变量声明 (不带 EOS)
InlineVarDecl
  // Case 1: 显式类型 (int x = 1)
  = type:TypeAnnotation __ id:Identifier _ "=" _ init:Expression
    { return { type: "VariableDeclaration", valueType: type, id: id, init: init }; }
  // Case 2: 推断类型 (x = 1)
  / id:Identifier _ "=" _ init:Expression
    { return { type: "VariableDeclaration", valueType: null, id: id, init: init }; }

// [新增] 单行赋值 (x := 1)
InlineAssignment
  = left:PrimaryExpression _ op:AssignmentOperator _ val:Expression
    { return { type: "AssignmentExpression", operator: op, left: left, right: val }; }

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
  = intro:CaseSeparator head:SwitchCase tail:(CaseSeparator SwitchCase)*
    { return [head].concat(extractList(tail, 1)); }

CaseSeparator
  = (SAMELINE_WS Comment? LineTerminatorSequence)*

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
  / "for" _ item:(TuplePattern / Identifier) _ "in" _ collection:Expression _ body:BlockOrLine
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
  = test:LogicalOrExpression __ "?" __ consequent:Expression __ ":" __ alternate:Expression
    { return { type: "ConditionalExpression", test: test, consequent: consequent, alternate: alternate }; }
  / LogicalOrExpression

LogicalOrExpression
  = head:LogicalAndExpression tail:(__ "or" __ LogicalAndExpression)* { return buildLogical(head, tail); }

LogicalAndExpression
  = head:EqualityExpression tail:(__ "and" __ EqualityExpression)* { return buildLogical(head, tail); }

EqualityExpression
  = head:RelationalExpression tail:(__ ("==" / "!=") __ RelationalExpression)* { return buildBinary(head, tail); }

RelationalExpression
  = head:AdditiveExpression tail:(__ (">=" / "<=" / ">" / "<") __ AdditiveExpression)* { return buildBinary(head, tail); }

AdditiveExpression
  = head:MultiplicativeExpression tail:(__ ("+" / "-") __ MultiplicativeExpression)* { return buildBinary(head, tail); }

MultiplicativeExpression
  = head:UnaryExpression tail:(__ ("*" / "/" / "%") __ UnaryExpression)* { return buildBinary(head, tail); }

UnaryExpression
  = operator:("not" / "+" / "-") __ argument:UnaryExpression
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
      / _ typeArgs:TypeTemplate? _ "(" __ args:ArgumentList? __ ")" { 
            return { type: "CallPart", args: args || [], typeArgs: typeArgs }; 
        }
    )*
    {
      return tail.reduce(function(result, part) {
        if (part.type === "MemberPart") {
          return { type: "MemberExpression", object: result, property: part.id };
        } else if (part.type === "IndexPart") {
          // 禁止连续 []
          if (result.type === "ArrayAccess") {
            error("The [] operator can only be used once on the same value.");
          }
          return { type: "ArrayAccess", object: result, index: part.index };
        } else if (part.type === "CallPart") {
          return { type: "CallExpression", callee: result, args: part.args, typeArgs: part.typeArgs };
        }
        return result;
      }, head);
    }

TypeTemplate
  = "<" _ head:TypeAnnotation tail:(_ "," _ TypeAnnotation)* _ ">" 
    { return [head].concat(extractList(tail, 3)); }

Atom
  = Literal
  / BracketExpression
  / PrimitiveType { return { type: "Identifier", name: text() }; }
  / Identifier
  / "(" _ expression:Expression _ ")" { return expression; }

BracketExpression
  = "[" __ elements:ArrayElements? __ "]"
    { return { type: "ArrayLiteral", elements: elements || [] }; }

ArrayElements
  = head:Expression tail:(__ "," __ Expression)* { return [head].concat(extractList(tail, 3)); }

ArgumentList
  = head:Argument tail:(__ "," __ Argument)* { return [head].concat(extractList(tail, 3)); }

Argument
  = name:(IdentifierName __ "=")? __ value:Expression
    { return { name: name ? name[0] : null, value: value }; }

// ==========================================
// 4. 词法规则 (Lexical Rules)
// ==========================================

TypeAnnotation
  = (GenericType / SimpleType) ("[" "]")*

SimpleType
  = PrimitiveType
  / NamespacedIdentifier

NamespacedIdentifier
  = head:Identifier tail:("." Identifier)* { 
       if (tail.length === 0) return head;
       return head + tail.map(function(e) { return "." + e[1]; }).join(""); 
    }

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

StringLiteral
  = '"' chars:DoubleStringChar* '"' { return { type: "Literal", value: chars.join("") }; }
  / "'" chars:SingleStringChar* "'" { return { type: "Literal", value: chars.join("") }; }

DoubleStringChar
  = !('"' / "\\" / LineTerminator) c:. { return c; }
  / "\\" esc:EscapeSequence { return esc; }

SingleStringChar
  = !("'" / "\\" / LineTerminator) c:. { return c; }
  / "\\" esc:EscapeSequence { return esc; }

EscapeSequence
  = "'"
  / '"'
  / "\\"
  / "n"  { return "\n"; }
  / "r"  { return "\r"; }
  / "t"  { return "\t"; }
  / c:.  { return c; }

FloatLiteral  = chars:([0-9]* "." [0-9]+ ([eE] [-+]? [0-9]+)?) { return { type: "Literal", value: parseFloat(text()) }; }
IntLiteral    = chars:([0-9]+) { return { type: "Literal", value: parseInt(text(), 10) }; }
BoolLiteral   = ("true" / "false") { return { type: "Literal", value: text() === "true" }; }
NaLiteral     = "na" { return { type: "Literal", value: null }; }
ColorLiteral  = "#" [0-9a-fA-F]+ { return { type: "Literal", kind: "color", value: text() }; }

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

// EOS: 允许语句末尾出现注释
EOS 
  = _ (";" / (Comment? LineTerminatorSequence) / (Comment? EOF))

BlockSeparator 
  = (SAMELINE_WS LineTerminatorSequence)* INDENT

Comment
  = "//" text:(!LineTerminator .)* { return text.map(t => t[1]).join(""); }

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
