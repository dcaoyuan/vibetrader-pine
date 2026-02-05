{{
  // =========================================================
  // Pine Script v6 Grammar (Fixed: Exported Constants)
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
  = ComplexStatement
  / StatementLine

ComplexStatement
  = CommentStatement    
  / BlockStatement      
  / ImportStatement    
  / ExportStatement     
  / BreakStatement      
  / ContinueStatement   
  / TypeDeclaration     
  / EnumDeclaration     
  / MethodDeclaration   
  / FunctionDeclaration 
  / ControlStructure    
  / VariableDeclaration_Struct  
  / AssignmentStatement_Struct  
  / TupleDeclaration_Struct     

StatementLine
  = head:SimpleStatement tail:(_ "," _ SimpleStatement)* EOS
    {
      if (tail.length === 0) return head;
      var tailStmts = tail.map(function(t) { return t[3]; });
      return { type: "Block", body: [head].concat(tailStmts) };
    }

SimpleStatement
  = VariableDeclaration_Expr    
  / AssignmentStatement_Expr    
  / TupleDeclaration_Expr       
  / ExpressionStatement         

// --- 基础语句类型 ---

BreakStatement
  = "break" EOS { return { type: "BreakStatement" }; }

ContinueStatement
  = "continue" EOS { return { type: "ContinueStatement" }; }

CommentStatement
  = c:Comment EOS
    { return { type: "CommentStatement", value: c }; }

// --- 2.1 变量声明 ---

VariableDeclaration_Expr
  = mods:StorageModifiers? __ type:TypeAnnotation? __ id:Identifier _ "=" __ init:Expression_Safe
    { 
      return { 
        type: "VariableDeclaration", 
        modifiers: mods ? mods[0] : null, 
        valueType: type ? type[0] : null, 
        id: id, 
        init: init 
      }; 
    }
  / mods:StorageModifiers __ id:Identifier _ "=" __ init:Expression_Safe
    { return { type: "VariableDeclaration", modifiers: mods, valueType: null, id: id, init: init }; }
  / id:Identifier _ "=" __ init:Expression_Safe
    { return { type: "VariableDeclaration", modifiers: null, valueType: null, id: id, init: init }; }

VariableDeclaration_Struct
  = mods:StorageModifiers? __ type:TypeAnnotation? __ id:Identifier _ "=" __ init:ControlStructure
    { 
      return { 
        type: "VariableDeclaration", 
        modifiers: mods ? mods[0] : null, 
        valueType: type ? type[0] : null, 
        id: id, 
        init: init 
      }; 
    }
  / mods:StorageModifiers __ id:Identifier _ "=" __ init:ControlStructure
    { return { type: "VariableDeclaration", modifiers: mods, valueType: null, id: id, init: init }; }
  / id:Identifier _ "=" __ init:ControlStructure
    { return { type: "VariableDeclaration", modifiers: null, valueType: null, id: id, init: init }; }

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

// --- 赋值语句 ---

AssignmentStatement_Expr
  = left:PrimaryExpression _ op:AssignmentOperator __ val:Expression_Safe
    { return { type: "AssignmentExpression", operator: op, left: left, right: val }; }

AssignmentStatement_Struct
  = left:PrimaryExpression _ op:AssignmentOperator __ val:ControlStructure
    { return { type: "AssignmentExpression", operator: op, left: left, right: val }; }

AssignmentOperator
  = ":=" / "+=" / "-=" / "*=" / "/=" / "%="

// --- 元组声明 ---

TupleDeclaration_Expr
  = pattern:TuplePattern _ "=" __ init:Expression_Safe
    { return { type: "TupleDeclaration", elements: pattern.elements, init: init }; }

TupleDeclaration_Struct
  = pattern:TuplePattern _ "=" __ init:ControlStructure
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
  = INDENT type:TypeAnnotation _ id:Identifier _ def:("=" __ Expression)?
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

// [FIXED] Added VariableDeclaration_Expr to the possible exported statements
ExportStatement
  = "export" _ stmt:(MethodDeclaration / FunctionDeclaration / TypeDeclaration / EnumDeclaration / VariableDeclaration_Expr)
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
  = type:TypeAnnotation __ &Identifier id:Identifier _ def:("=" __ Expression)?
    { return { type: type, id: id, default: def ? def[2] : null }; }
  / id:Identifier _ def:("=" __ Expression)?
    { return { type: null, id: id, default: def ? def[2] : null }; }

FunctionBody
  = ScopeBlock  
  / _ body:InlineSeries EOS { return { type: "Block", body: body }; }

InlineSeries
  = head:SimpleStatement tail:(_ "," _ SimpleStatement)*
    { return [head].concat(extractList(tail, 3)); }

// --- 2.3 控制流 ---

ControlStructure
  = IfStatement
  / SwitchStatement
  / ForStatement
  / WhileStatement

IfStatement
  = "if" _ test:Expression_Safe _ body:BlockOrLine
    elseIfs:(__ "else" _ "if" _ Expression_Safe _ BlockOrLine)*
    elseBody:(__ "else" _ BlockOrLine)?
    { return { type: "IfStatement", test: test, consequent: body, alternates: elseIfs, fallback: elseBody }; }

SwitchStatement
  = "switch" _ discriminant:Expression_Safe? _ EOL
    cases:SwitchCaseList
    { return { type: "SwitchStatement", discriminant: discriminant, cases: cases }; }

SwitchCaseList
  = intro:CaseSeparator head:SwitchCase tail:(CaseSeparator SwitchCase)*
    { return [head].concat(extractList(tail, 1)); }

CaseSeparator
  = (SAMELINE_WS Comment? LineTerminatorSequence)*

SwitchCase
  = INDENT ExtraIndents tests:ExpressionList_Safe _ "=>" _ body:BlockOrLine
    { return { type: "SwitchCase", tests: tests, consequent: body }; }
  / INDENT ExtraIndents "=>" _ body:BlockOrLine 
    { return { type: "SwitchCase", default: true, consequent: body }; }

ExpressionList_Safe
  = head:Expression_Safe tail:(_ "," _ Expression_Safe)*
    { return [head].concat(extractList(tail, 3)); }

ForStatement
  = "for" _ counter:Identifier _ "=" _ start:Expression_Safe _ "to" _ end:Expression_Safe _ step:("by" _ Expression_Safe)? _ body:BlockOrLine
    { return { type: "ForNumeric", counter: counter, start: start, end: end, step: step, body: body }; }
  / "for" _ item:(TuplePattern / Identifier) _ "in" _ collection:Expression_Safe _ body:BlockOrLine
    { return { type: "ForIn", item: item, collection: collection, body: body }; }

WhileStatement
  = "while" _ test:Expression_Safe _ body:BlockOrLine
    { return { type: "WhileStatement", test: test, body: body }; }

BlockOrLine
  = ScopeBlock
  / _ "=>" _ ScopeBlock
  / _ stmt:StatementLine 
    { 
      if (stmt.type === "Block") return stmt;
      return { type: "Block", body: [stmt] };
    }

ScopeBlock
  = EOL BlockSeparator statements:StatementListDedent 
    { return { type: "Block", body: statements }; }

StatementListDedent
  = head:(_ Statement) tail:(BlockSeparator _ Statement)* { 
       var tailList = tail.map(function(e) { return e[2]; });
       return [head[1]].concat(tailList); 
    }

BlockStatement
  = ScopeBlock

ExpressionStatement
  = expr:Expression_Safe
    { return { type: "ExpressionStatement", expression: expr }; }

// ==========================================
// 3. 表达式 (Expressions)
// ==========================================

ExprSep "valid continuation"
  = (
      [ \t]+
    / Comment
    / LineTerminatorSequence indent:[ \t]+ &{ return indent.join("").length % 4 !== 0; }
    )*

Expression
  = ConditionalExpression

ConditionalExpression
  = test:LogicalOrExpression __ "?" __ consequent:Expression __ ":" __ alternate:Expression
    { return { type: "ConditionalExpression", test: test, consequent: consequent, alternate: alternate }; }
  / LogicalOrExpression

LogicalOrExpression
  = head:LogicalAndExpression tail:(__ "or" !IdentifierPart __ LogicalAndExpression)* { return buildLogical(head, tail); }

LogicalAndExpression
  = head:EqualityExpression tail:(__ "and" !IdentifierPart __ EqualityExpression)* { return buildLogical(head, tail); }

EqualityExpression
  = head:RelationalExpression tail:(__ ("==" / "!=") __ RelationalExpression)* { return buildBinary(head, tail); }

RelationalExpression
  = head:AdditiveExpression tail:(__ (">=" / "<=" / ">" / "<") __ AdditiveExpression)* { return buildBinary(head, tail); }

AdditiveExpression
  = head:MultiplicativeExpression tail:(__ ("+" / "-") __ MultiplicativeExpression)* { return buildBinary(head, tail); }

MultiplicativeExpression
  = head:UnaryExpression tail:(__ ("*" / "/" / "%") __ UnaryExpression)* { return buildBinary(head, tail); }

UnaryExpression
  = operator:("not" !IdentifierPart / "+" / "-") __ argument:UnaryExpression
    { return { type: "UnaryExpression", operator: operator[0], argument: argument }; }
  / PrimaryExpression

Expression_Safe
  = ConditionalExpression_Safe

ConditionalExpression_Safe
  = test:LogicalOrExpression_Safe ExprSep "?" ExprSep consequent:Expression_Safe ExprSep ":" ExprSep alternate:Expression_Safe
    { return { type: "ConditionalExpression", test: test, consequent: consequent, alternate: alternate }; }
  / LogicalOrExpression_Safe

LogicalOrExpression_Safe
  = head:LogicalAndExpression_Safe tail:(ExprSep "or" !IdentifierPart ExprSep LogicalAndExpression_Safe)* { return buildLogical(head, tail); }

LogicalAndExpression_Safe
  = head:EqualityExpression_Safe tail:(ExprSep "and" !IdentifierPart ExprSep EqualityExpression_Safe)* { return buildLogical(head, tail); }

EqualityExpression_Safe
  = head:RelationalExpression_Safe tail:(ExprSep ("==" / "!=") ExprSep RelationalExpression_Safe)* { return buildBinary(head, tail); }

RelationalExpression_Safe
  = head:AdditiveExpression_Safe tail:(ExprSep (">=" / "<=" / ">" / "<") ExprSep AdditiveExpression_Safe)* { return buildBinary(head, tail); }

AdditiveExpression_Safe
  = head:MultiplicativeExpression_Safe tail:(ExprSep ("+" / "-") ExprSep MultiplicativeExpression_Safe)* { return buildBinary(head, tail); }

MultiplicativeExpression_Safe
  = head:UnaryExpression_Safe tail:(ExprSep ("*" / "/" / "%") ExprSep UnaryExpression_Safe)* { return buildBinary(head, tail); }

UnaryExpression_Safe
  = operator:("not" !IdentifierPart / "+" / "-") ExprSep argument:UnaryExpression_Safe
    { return { type: "UnaryExpression", operator: operator[0], argument: argument }; }
  / PrimaryExpression

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
  / "(" __ expression:Expression __ ")" { return expression; }

BracketExpression
  = "[" __ elements:ArrayElements? __ "]"
    { return { type: "ArrayLiteral", elements: elements || [] }; }

ArrayElements
  = head:Expression tail:(__ "," __ Expression)* { return [head].concat(extractList(tail, 3)); }

ArgumentList
  = head:Argument tail:(__ "," __ Argument)* { return [head].concat(extractList(tail, 3)); }

Argument
  = name:(IdentifierName __ "=" !"=")? __ value:Expression 
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

FloatLiteral
  = chars:(
      ( [0-9]+ "." [0-9]* ([eE] [-+]? [0-9]+)? )
    / ( "." [0-9]+ ([eE] [-+]? [0-9]+)? )
    / ( [0-9]+ [eE] [-+]? [0-9]+ )
    ) { return { type: "Literal", value: parseFloat(text()) }; }

IntLiteral    = chars:([0-9]+) { return { type: "Literal", value: parseInt(text(), 10) }; }
BoolLiteral   = ("true" / "false") { return { type: "Literal", value: text() === "true" }; }

NaLiteral     = "na" !IdentifierPart { return { type: "Literal", value: null }; }

ColorLiteral  = "#" [0-9a-fA-F]+ { return { type: "Literal", kind: "color", value: text() }; }

// ------------------------------------------
// 缩进与空白
// ------------------------------------------

INDENT = "    " / "\t"
ExtraIndents = INDENT*

SAMELINE_WS = [ \t]*
_  = [ \t]*
__ = (WhiteSpace / LineTerminatorSequence / Comment)*
WhiteSpace = [ \t]
LineTerminator = [\n\r]
LineTerminatorSequence = "\n" / "\r\n" / "\r"

EOL = SAMELINE_WS Comment? LineTerminatorSequence

EOS 
  = _ (";" / (Comment? LineTerminatorSequence) / (Comment? EOF))

BlockSeparator 
  = (SAMELINE_WS LineTerminatorSequence)* INDENT ExtraIndents

Comment
  = "//" text:(!LineTerminator .)* { return text.map(t => t[1]).join(""); }

ReservedWord
  = Keyword
  / LiteralKeyword

Keyword
  = ("if" / "else" / "for" / "while" / "switch" / "return" / "break" / "continue" / 
     "var" / "varip" / "import" / "export" / "method" / "type" / "enum" / "const") !IdentifierPart

LiteralKeyword
  = ("true" / "false" / "na" / "and" / "or" / "not") !IdentifierPart

EOF = !.