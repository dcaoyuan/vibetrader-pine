{
  function makeToken(type, value, loc) {
    return {
      type: type,
      value: value,
      start: loc.start.offset,
      end: loc.end.offset
    };
  }
}

// The Start rule returns a flat array of all tokens found
Tokens
  = tokens:(Token / Unknown)* {
      // Filter out nulls if any, though Token/Unknown covers all space
      return tokens.filter(t => t !== null);
    }

Token
  = Comment
  / Annotation
  / String
  / Directive
  / Keyword
  / Type
  / Literal
  / Identifier
  / Operator
  / Punctuation
  / Whitespace

// --- 1. Comments & Annotations ---
Comment
  = "//" (!LineTerminator .)* { 
      return makeToken("comment", text(), location()); 
    }

Annotation
  = "@" key:AnnotationKeys { 
      return makeToken("annotation", text(), location()); 
    }

AnnotationKeys
  = "description" / "enum" / "field" / "function" / "param" / 
    "returns" / "strategy_alert_message" / "type" / "variable" / "version="

// --- 2. Keywords & Modifiers ---
Keyword
  = ( "if" / "else" / "for" / "while" / "switch" / "return" / "break" / "continue" 
    / "varip" / "var" / "import" / "export" / "method" / "type" / "enum" 
    / "const" / "simple" / "series" / "as" / "to" / "by" / "in"
    ) !IdentifierPart { 
      return makeToken("keyword", text(), location()); 
    }

// --- 3. Types ---
Type
  = ( "int" / "float" / "bool" / "color" / "string" / "line" / "label" 
    / "box" / "table" / "array" / "matrix" / "map"
    ) !IdentifierPart { 
      return makeToken("type", text(), location()); 
    }

// --- 4. Literals ---
Literal
  = (FloatLiteral / IntLiteral / BoolLiteral / NaLiteral / ColorLiteral) {
      return makeToken("literal", text(), location());
    }

FloatLiteral
  = [0-9]+ "." [0-9]* ([eE] [-+]? [0-9]+)?
  / "." [0-9]+ ([eE] [-+]? [0-9]+)?
  / [0-9]+ [eE] [-+]? [0-9]+

IntLiteral    = [0-9]+
BoolLiteral   = ("true" / "false") !IdentifierPart
NaLiteral     = "na" !IdentifierPart
ColorLiteral  = "#" [0-9a-fA-F]+

String
  = ( '\"' (!'\"' .)* '\"' / '\'' (!'\'' .)* '\'' ) {
      return makeToken("string", text(), location());
    }

// --- 5. Logic & Identifiers ---
Directive
  = "//@version=" [0-9]+ { 
      return makeToken("directive", text(), location()); 
    }

Identifier
  = [a-zA-Z_] [a-zA-Z0-9_]* { 
      return makeToken("identifier", text(), location()); 
    }

IdentifierPart = [a-zA-Z0-9_]

// --- 6. Operators & Symbols ---
Operator
  = ( "==" / "!=" / "<=" / ">=" / "=>" / ":=" / "+=" / "-=" / "*=" / "/=" / "%=" 
    / "+" / "-" / "*" / "/" / "%" / ">" / "<" / "=" / "?" / ":" / "!"
    / "and" / "or" / "not"
    ) { 
      return makeToken("operator", text(), location()); 
    }

Punctuation
  = [()\[\],.] { 
      return makeToken("punctuation", text(), location()); 
    }

Whitespace
  = [ \t\n\r]+ { 
      return makeToken("whitespace", text(), location()); 
    }

// Fallback for any character not matched (prevents parser from stopping)
Unknown
  = . { return makeToken("unknown", text(), location()); }

LineTerminator = [\n\r]