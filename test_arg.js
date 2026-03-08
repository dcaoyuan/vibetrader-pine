import fs from "fs";
let code = fs.readFileSync("src/parser.js", "utf8");
code = code.replace(/function peg\$f82\(name, value\) \{/, "function peg$f82(name, value) { console.log('peg$f82 called with:', name, value);");
fs.writeFileSync("src/parser_patched.js", code);
