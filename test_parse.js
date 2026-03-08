const { parse } = require('./src/parser.js');
console.log(JSON.stringify(parse('my_sma = my_sma(close)'), null, 2));
