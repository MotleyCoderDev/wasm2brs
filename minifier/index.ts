import fs from "fs";

const files = [
  "/home/trevor/wasm2brs/project/source/test.wasm.brs",
  "/home/trevor/wasm2brs/project/source/test.cases.brs",
  "/home/trevor/wasm2brs/project/source/runtime.brs",
  "/home/trevor/wasm2brs/project/source/helpers.brs",
  "/home/trevor/wasm2brs/project/source/wasi_snapshot_preview1.brs"
];

const text = files.map((file) => fs.readFileSync(file, "utf8")).join("\n");

const uniqueNames: Record<string, true> = {};

const reservedWords = {
  and: true,
  as: true,
  asc: true,
  boolean: true,
  box: true,
  count: true,
  createobject: true,
  dim: true,
  double: true,
  each: true,
  else: true,
  elseif: true,
  end: true,
  endfunction: true,
  endif: true,
  endsub: true,
  endwhile: true,
  eval: true,
  exit: true,
  exitwhile: true,
  false: true,
  float: true,
  for: true,
  fromhexstring: true,
  function: true,
  getglobalaa: true,
  getlastruncompileerror: true,
  getlastrunruntimeerror: true,
  getsignedbyte: true,
  goto: true,
  if: true,
  in: true,
  integer: true,
  interface: true,
  invalid: true,
  len: true,
  let: true,
  // eslint-disable-next-line camelcase
  line_num: true,
  log: true,
  longinteger: true,
  m: true,
  next: true,
  not: true,
  object: true,
  objfun: true,
  or: true,
  pos: true,
  print: true,
  rem: true,
  return: true,
  run: true,
  step: true,
  stop: true,
  string: true,
  sub: true,
  tab: true,
  then: true,
  to: true,
  tostr: true,
  true: true,
  type: true,
  void: true,
  while: true
};

const regex = /\b[a-zA-Z_][a-zA-Z0-9_]*\b/ug;
const textWithoutComments = text.replace(/('|REM).*/ug, "");
const textWithoutFalseIdentifiers = textWithoutComments.replace(/("[^"]")|(&[hH][a-fA-F0-9]+)/ug, "");
for (;;) {
  const match = regex.exec(textWithoutFalseIdentifiers);
  if (match) {
    const lower = match[0].toLowerCase();
    if (!reservedWords[lower]) {
      uniqueNames[lower] = true;
    }
  } else {
    break;
  }
}

console.log(Object.keys(uniqueNames).join("\n"));
