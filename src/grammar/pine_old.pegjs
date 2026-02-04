// [1] https://www.tradingview.com/pine-script-docs/welcome/
// [2] https://www.tradingview.com/pine-script-reference/v6/
// [3] https://docs.bulltrading.io/bulltrading-designer/pinescript/pine-script-tm-v5-user-manual
// [4] https://github.com/pegjs/pegjs/blob/master/examples/javascript.pegjs
// [5] https://peggyjs.org/online.html

{{
  // Helper to simplify the AST structure
  function extractList(list, index) {
    return list.map(element => element[index]);
  }
}}

start 
  = _ Version _ DeclarationStatement _ Code


Version
  = "//@version=" digits:$([0-9]+)

DeclarationStatement 
  = Indicator
  / Strategy
  / Library


Indicator 
  = "indicator(" FunctionCallParams ")"

Strategy
  = "strategy(" FunctionCallParams ")"

Library
  = "library(" FunctionCallParams ")"

Code
  = StatementList

// ----- A.1 Lexical Grammar -----

SourceCharacter
  = .

WhiteSpace "whitespace"
  = "\t"
  / " "

LineTerminator
  = [\n\r]

LineTerminatorSequence "end of line"
  = "\n"
  / "\r\n"
  / "\r"

Comment "comment"
  = SingleLineComment

SingleLineComment
  = "//" (!LineTerminator SourceCharacter)*

Identifier
  = !ReservedWord name:IdentifierName { return name; }

IdentifierName "identifier"
  = head:IdentifierStart tail:IdentifierPart* {
      return {
        type: "Identifier",
        name: head + tail.join("")
      };
    }

IdentifierStart
  = [a-zA-Z_]

IdentifierPart
  = [a-zA-Z0-9_]

ReservedWord
  = Keyword

Keyword
  = AndToken
  / BreakToken
  / ContinueToken
  / ElseToken
  / EnumToken
  / ExportToken
  / ForToken
  / InToken
  / IfToken
  / ImportToken
  / MethodToken
  / NotToken
  / SwitchToken
  / ToToken
  / TypeToken
  / VarToken
  / VaripToken
  / WhileToken

Literal
  = NaLiteral
  / BooleanLiteral
  / NumericLiteral
  / ColorLiteral
  / StringLiteral

NaLiteral
  = NaToken { return { type: "Literal", value: undefined }; }

BooleanLiteral
  = TrueToken  { return { type: "Literal", value: true  }; }
  / FalseToken { return { type: "Literal", value: false }; }

// The "!(IdentifierStart / DecimalDigit)" predicate is not part of the official
// grammar, it comes from text in section 7.8.3.
NumericLiteral "number"
  = literal:FloatLiteral !(IdentifierStart / DecimalDigit) {
      return literal;
    }
  / literal:IntegerLiteral !(IdentifierStart / DecimalDigit) {
      return literal;
    }

FloatLiteral
  = IntegerPart "." DecimalDigit* ExponentPart? {
      return { type: "Literal", value: parseFloat(text()) };
    }
  / "." DecimalDigit+ ExponentPart? {
      return { type: "Literal", value: parseFloat(text()) };
    }

IntegerLiteral
  = IntegerPart ExponentPart? {
      return { type: "Literal", value: parseInt(text()) };
    }

IntegerPart
  = "0"
  / NonZeroDigit DecimalDigit*

DecimalDigit
  = [0-9]

NonZeroDigit
  = [1-9]

ExponentPart
  = ExponentIndicator SignedInteger

ExponentIndicator
  = "e"i

SignedInteger
  = [+-]? DecimalDigit+

HexIntegerLiteral
  = "0x"i digits:$HexDigit+ {
      return { type: "Literal", value: parseInt(digits, 16) };
     }

HexDigit
  = [0-9a-f]i

ColorLiteral "color"
  = "#" digits:(HexDigit HexDigit HexDigit HexDigit HexDigit HexDigit HexDigit?) {
      return {type: "Literal", value: digits} 
    }

StringLiteral "string"
  = '"' chars:DoubleStringCharacter* '"' {
      return { type: "Literal", value: chars.join("") };
    }
  / "'" chars:SingleStringCharacter* "'" {
      return { type: "Literal", value: chars.join("") };
    }

DoubleStringCharacter
  = !('"' / "\\" / LineTerminator) SourceCharacter { return text(); }
  / "\\" sequence:EscapeSequence { return sequence; }
  / LineContinuation

SingleStringCharacter
  = !("'" / "\\" / LineTerminator) SourceCharacter { return text(); }
  / "\\" sequence:EscapeSequence { return sequence; }
  / LineContinuation

LineContinuation
  = "\\" LineTerminatorSequence { return ""; }

EscapeSequence
  = CharacterEscapeSequence
  / "0" !DecimalDigit { return "\0"; }
  / HexEscapeSequence

CharacterEscapeSequence
  = SingleEscapeCharacter
  / NonEscapeCharacter

SingleEscapeCharacter
  = "'"
  / '"'
  / "\\"
  / "b"  { return "\b"; }
  / "f"  { return "\f"; }
  / "n"  { return "\n"; }
  / "r"  { return "\r"; }
  / "t"  { return "\t"; }
  / "v"  { return "\v"; }

NonEscapeCharacter
  = !(EscapeCharacter / LineTerminator) SourceCharacter { return text(); }

EscapeCharacter
  = SingleEscapeCharacter
  / DecimalDigit
  / "x"
  / "u"

HexEscapeSequence
  = "x" digits:$(HexDigit HexDigit) {
      return String.fromCharCode(parseInt(digits, 16));
    }

// Tokens

AndToken        = "and"      !IdentifierPart
BoolToken       = "bool"    !IdentifierPart
BreakToken      = "break"    !IdentifierPart
ByToken         = "by"       !IdentifierPart
ContinueToken   = "continue" !IdentifierPart
ElseToken       = "else"     !IdentifierPart
EnumToken       = "enum"     !IdentifierPart
ExportToken     = "export"   !IdentifierPart
FalseToken      = "false"    !IdentifierPart
ForToken        = "for"      !IdentifierPart
InToken         = "in"       !IdentifierPart
IfToken         = "if"       !IdentifierPart
ImportToken     = "import"   !IdentifierPart
MethodToken     = "method"   !IdentifierPart
NaToken         = "na"       !IdentifierPart
NotToken        = "not"      !IdentifierPart
SwitchToken     = "switch"   !IdentifierPart
ToToken         = "to"       !IdentifierPart
TrueToken       = "true"       !IdentifierPart
TypeToken       = "type"     !IdentifierPart
VarToken        = "var"      !IdentifierPart
VaripToken      = "varip"    !IdentifierPart
WhileToken      = "while"    !IdentifierPart

// Skipped

__
  = (WhiteSpace / LineTerminatorSequence / Comment)*

_
  = (WhiteSpace)*

// Automatic Semicolon Insertion

EOS
  = __ ";"
  / _ SingleLineComment? LineTerminatorSequence
  / _ &"}"
  / __ EOF

EOF
  = !.

// inline whitespace (no \n)
_ = [ \t]*

// newline 
EOL = "\r"? "\n"

// Pine Script indentation：1 tab or 4 spaces
INDENT = ("\t" / "    ")

// ----- A.3 Expressions -----

PrimaryExpression
  = Identifier
  / Literal
  / ArrayLiteral
  / ObjectLiteral
  / "(" __ expression:Expression __ ")" { return expression; }

ArrayLiteral
  = "[" __ elements:ElementList __ "]" {
      return {
        type: "ArrayExpression",
        elements: elements
      };
    }

ElementList
  = head:(
      element:AssignmentExpression {
        return optionalList(extractOptional(elision, 0)).concat(element);
      }
    )
    tail:(
      __ "," element:AssignmentExpression {
        return optionalList(extractOptional(elision, 0)).concat(element);
      }
    )*
    { return Array.prototype.concat.apply(head, tail); }

ObjectLiteral
  = TypeToken __ name:Identifier __ EOL {
       return { type: "ObjectExpression" };
     }
  / TypeToken __ name:Identifier __ EOL (INDENT properties:PropertyNameAndValueList __ EOL)* {
       return { type: "ObjectExpression", properties: properties };
     }

PropertyNameAndValueList
  = head:PropertyAssignment tail:(__ "," __ PropertyAssignment)* {
      return buildList(head, tail, 3);
    }

PropertyAssignment
  = type:Type __ name:PropertyName __ (value:AssignmentExpression)* {
      return { type: "Property", propertyType: type, name: name, value: value };
    }

PropertyName
  = IdentifierName
  / StringLiteral
  / NumericLiteral

MemberExpression
  = head:(
        PrimaryExpression
      / FunctionExpression
      / NewToken __ callee:MemberExpression __ args:Arguments {
          return { type: "NewExpression", callee: callee, arguments: args };
        }
    )
    tail:(
        __ "[" __ property:Expression __ "]" {
          return { property: property, computed: true };
        }
      / __ "." __ property:IdentifierName {
          return { property: property, computed: false };
        }
    )*
    {
      return tail.reduce(function(result, element) {
        return {
          type: "MemberExpression",
          object: result,
          property: element.property,
          computed: element.computed
        };
      }, head);
    }

CallExpression
  = head:(
      callee:MemberExpression __ args:Arguments {
        return { type: "CallExpression", callee: callee, arguments: args };
      }
    )
    tail:(
        __ args:Arguments {
          return { type: "CallExpression", arguments: args };
        }
      / __ "[" __ property:Expression __ "]" {
          return {
            type: "MemberExpression",
            property: property,
            computed: true
          };
        }
      / __ "." __ property:IdentifierName {
          return {
            type: "MemberExpression",
            property: property,
            computed: false
          };
        }
    )*
    {
      return tail.reduce(function(result, element) {
        element[TYPES_TO_PROPERTY_NAMES[element.type]] = result;

        return element;
      }, head);
    }

Arguments
  = "(" __ args:(ArgumentList __)? ")" {
      return optionalList(extractOptional(args, 0));
    }

ArgumentList
  = head:AssignmentExpression tail:(__ "," __ AssignmentExpression)* {
      return buildList(head, tail, 3);
    }

LeftHandSideExpression
  = CallExpression
  / NewExpression

PostfixExpression
  = argument:LeftHandSideExpression _ operator:PostfixOperator {
      return {
        type: "UpdateExpression",
        operator: operator,
        argument: argument,
        prefix: false
      };
    }
  / LeftHandSideExpression

PostfixOperator
  = "++"
  / "--"

UnaryExpression
  = PostfixExpression
  / operator:UnaryOperator __ argument:UnaryExpression {
      var type = (operator === "++" || operator === "--")
        ? "UpdateExpression"
        : "UnaryExpression";

      return {
        type: type,
        operator: operator,
        argument: argument,
        prefix: true
      };
    }

UnaryOperator
  = $DeleteToken
  / $VoidToken
  / $TypeofToken
  / "++"
  / "--"
  / $("+" !"=")
  / $("-" !"=")
  / "~"
  / "!"

MultiplicativeExpression
  = head:UnaryExpression
    tail:(__ MultiplicativeOperator __ UnaryExpression)*
    { return buildBinaryExpression(head, tail); }

MultiplicativeOperator
  = $("*" !"=")
  / $("/" !"=")
  / $("%" !"=")

AdditiveExpression
  = head:MultiplicativeExpression
    tail:(__ AdditiveOperator __ MultiplicativeExpression)*
    { return buildBinaryExpression(head, tail); }

AdditiveOperator
  = $("+" ![+=])
  / $("-" ![-=])

ShiftExpression
  = head:AdditiveExpression
    tail:(__ ShiftOperator __ AdditiveExpression)*
    { return buildBinaryExpression(head, tail); }

ShiftOperator
  = $("<<"  !"=")
  / $(">>>" !"=")
  / $(">>"  !"=")

RelationalExpression
  = head:ShiftExpression
    tail:(__ RelationalOperator __ ShiftExpression)*
    { return buildBinaryExpression(head, tail); }

RelationalOperator
  = "<="
  / ">="
  / $("<" !"<")
  / $(">" !">")
  / $InstanceofToken
  / $InToken

RelationalExpressionNoIn
  = head:ShiftExpression
    tail:(__ RelationalOperatorNoIn __ ShiftExpression)*
    { return buildBinaryExpression(head, tail); }

RelationalOperatorNoIn
  = "<="
  / ">="
  / $("<" !"<")
  / $(">" !">")
  / $InstanceofToken

EqualityExpression
  = head:RelationalExpression
    tail:(__ EqualityOperator __ RelationalExpression)*
    { return buildBinaryExpression(head, tail); }

EqualityExpressionNoIn
  = head:RelationalExpressionNoIn
    tail:(__ EqualityOperator __ RelationalExpressionNoIn)*
    { return buildBinaryExpression(head, tail); }

EqualityOperator
  = "==="
  / "!=="
  / "=="
  / "!="

BitwiseANDExpression
  = head:EqualityExpression
    tail:(__ BitwiseANDOperator __ EqualityExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseANDExpressionNoIn
  = head:EqualityExpressionNoIn
    tail:(__ BitwiseANDOperator __ EqualityExpressionNoIn)*
    { return buildBinaryExpression(head, tail); }

BitwiseANDOperator
  = $("&" ![&=])

BitwiseXORExpression
  = head:BitwiseANDExpression
    tail:(__ BitwiseXOROperator __ BitwiseANDExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseXORExpressionNoIn
  = head:BitwiseANDExpressionNoIn
    tail:(__ BitwiseXOROperator __ BitwiseANDExpressionNoIn)*
    { return buildBinaryExpression(head, tail); }

BitwiseXOROperator
  = $("^" !"=")

BitwiseORExpression
  = head:BitwiseXORExpression
    tail:(__ BitwiseOROperator __ BitwiseXORExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseORExpressionNoIn
  = head:BitwiseXORExpressionNoIn
    tail:(__ BitwiseOROperator __ BitwiseXORExpressionNoIn)*
    { return buildBinaryExpression(head, tail); }

BitwiseOROperator
  = $("|" ![|=])

LogicalANDExpression
  = head:BitwiseORExpression
    tail:(__ LogicalANDOperator __ BitwiseORExpression)*
    { return buildLogicalExpression(head, tail); }

LogicalANDExpressionNoIn
  = head:BitwiseORExpressionNoIn
    tail:(__ LogicalANDOperator __ BitwiseORExpressionNoIn)*
    { return buildLogicalExpression(head, tail); }

LogicalANDOperator
  = "&&"

LogicalORExpression
  = head:LogicalANDExpression
    tail:(__ LogicalOROperator __ LogicalANDExpression)*
    { return buildLogicalExpression(head, tail); }

LogicalORExpressionNoIn
  = head:LogicalANDExpressionNoIn
    tail:(__ LogicalOROperator __ LogicalANDExpressionNoIn)*
    { return buildLogicalExpression(head, tail); }

LogicalOROperator
  = "||"

ConditionalExpression
  = test:LogicalORExpression __
    "?" __ consequent:AssignmentExpression __
    ":" __ alternate:AssignmentExpression
    {
      return {
        type: "ConditionalExpression",
        test: test,
        consequent: consequent,
        alternate: alternate
      };
    }
  / LogicalORExpression

ConditionalExpressionNoIn
  = test:LogicalORExpressionNoIn __
    "?" __ consequent:AssignmentExpression __
    ":" __ alternate:AssignmentExpressionNoIn
    {
      return {
        type: "ConditionalExpression",
        test: test,
        consequent: consequent,
        alternate: alternate
      };
    }
  / LogicalORExpressionNoIn

AssignmentExpression
  = left:LeftHandSideExpression __
    "=" !"=" __
    right:AssignmentExpression
    {
      return {
        type: "AssignmentExpression",
        operator: "=",
        left: left,
        right: right
      };
    }
  / left:LeftHandSideExpression __
    operator:AssignmentOperator __
    right:AssignmentExpression
    {
      return {
        type: "AssignmentExpression",
        operator: operator,
        left: left,
        right: right
      };
    }
  / ConditionalExpression

AssignmentExpressionNoIn
  = left:LeftHandSideExpression __
    "=" !"=" __
    right:AssignmentExpressionNoIn
    {
      return {
        type: "AssignmentExpression",
        operator: "=",
        left: left,
        right: right
      };
    }
  / left:LeftHandSideExpression __
    operator:AssignmentOperator __
    right:AssignmentExpressionNoIn
    {
      return {
        type: "AssignmentExpression",
        operator: operator,
        left: left,
        right: right
      };
    }
  / ConditionalExpressionNoIn

AssignmentOperator
  = "*="
  / "/="
  / "%="
  / "+="
  / "-="
  / "<<="
  / ">>="
  / ">>>="
  / "&="
  / "^="
  / "|="

Expression
  = head:AssignmentExpression tail:(__ "," __ AssignmentExpression)* {
      return tail.length > 0
        ? { type: "SequenceExpression", expressions: buildList(head, tail, 3) }
        : head;
  }


// <structure> can be an if, for, while or switch structure.
structure
  = IfStatement
  / SwitchStatement
  / LoopStatement 

function_call
  = namespace:Identifier _ "." _ functionName:Identifier _ "(" FunctionCallParams ")"

FunctionCallParams
  = _ (paramName:Identifier _ "=")? _ objectName:Identifier _ "," _ (Params)* _


Type
  = "int" 
  / "float" 
  / "bool" 
  / "color" 
  / "string" 
  / "line" 
  / "linefill" 
  / "label" 
  / "box" 
  / "table" 
  / "polyline" 
  / "chart.point" 
  / "array" _ "<" _ elemType:Type _ ">"
  / "matrix" _ "<" _ elemType:Type _ ">" 
  / "map"_ "<" _ keyType:Type _ "," _ valueType:Type ">"
  / UDT 
  / Enum

Enum 
  = ExportToken? _ EnumToken _ Identifier (Identifier (_ "=" _ Identifier))+
//    <field_1>[ = <title_1>]
//    <field_2>[ = <title_2>]
//    ...
//    <field_N>[ = <title_N>]

UDT
  = ExportToken? _ MethodToken _ functionName:Identifier _ "(" _ paramType:Type paramName:Identifier (_ "=" defaultValue:value)? _ ","  (_ paramType:Type paramName:Identifier (_ "=" defaultValue:value)?)*  _ ")" _ "=>" _
    functionBlock

// ----- A.4 Statements -----

Statement
  = Block
  / VariableStatement
  / EmptyStatement
  / ExpressionStatement
  / IfStatement
  / IterationStatement
  / ContinueStatement
  / BreakStatement
  / ReturnStatement
  / WithStatement
  / LabelledStatement
  / SwitchStatement

StatementList
  = head:Statement tail:(__ Statement)* { return buildList(head, tail, 1); }

VariableStatement
  = DeclarationMode __ declarations:VariableDeclarationList EOS {
      return {
        type: "VariableDeclaration",
        declarations: declarations,
        kind: "var"
      };
    }

VariableDeclarationList
  = head:VariableDeclaration tail:(__ "," __ VariableDeclaration)* {
      return buildList(head, tail, 3);
    }

VariableDeclarationListNoIn
  = head:VariableDeclarationNoIn tail:(__ "," __ VariableDeclarationNoIn)* {
      return buildList(head, tail, 3);
    }

VariableDeclaration
  = id:Identifier init:(__ Initialiser)? {
      return {
        type: "VariableDeclarator",
        id: id,
        init: extractOptional(init, 1)
      };
    }

VariableDeclarationNoIn
  = id:Identifier init:(__ InitialiserNoIn)? {
      return {
        type: "VariableDeclarator",
        id: id,
        init: extractOptional(init, 1)
      };
    }

Initialiser
  = "=" !"=" __ expression:AssignmentExpression { return expression; }

InitialiserNoIn
  = "=" !"=" __ expression:AssignmentExpressionNoIn { return expression; }

EmptyStatement
  = ";" { return { type: "EmptyStatement" }; }

ExpressionStatement
  = !("{" / FunctionToken) expression:Expression EOS {
      return {
        type: "ExpressionStatement",
        expression: expression
      };
    }


variable_declaration
  = DeclarationMode? (_ Type)? _ Identifier _ "=" (expression / structure)
  / tuple_declaration "=" (function_call / structure)

tuple_declaration 
  = function_call 
  / structure

DeclarationMode
  = VarToken 
  / VaripToken 


IfStatement
  = (DeclarationMode? _ Type? _ Identifier "=" )? 
    IfToken _ condition:expression EOL
      LocalBlock
    (ElseToken _ IfToken expression 
      LocalBlock)*
    (ElseToken
      LocalBlock)?
    {
      return { type: "IfStatement", condition, body };
    }

SwitchStatement
  = (DeclarationMode? _ Type? _ Identifier "=" )? SwitchToken _ expression?
    (expression _ "=>" _ LocalBlock)*
    "=>" _ LocalBlock

LoopStatement
  = (variables ("=" / ":="))? LoopHeader
    (statements / ContinueToken / BreakToken)
    ReturnExpression

LoopHeader
  = ForLoopHeader
  / ForInLoopHeader
  / WhileLoopHeader

ForLoopHeader 
  = Foroken counter:Identifier "=" from_num:variables ToToken to_num:variables (ByToken step_num:variables)?

ForInLoopHeader
  = ForToken item:VariableDeclaration InToken collection_id:variables
  / ForToken "[" index:Int "," item:variables "]" InToken collection_id:variables

WhileLoopHeader
  =  WhileToken _ condition:expression EOL

LocalBlock
  = INDENT stmt:statement EOL { return stmt; }

