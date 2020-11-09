import fs from "fs";
import seedrandom from "seedrandom";

const files = [
  "/home/trevor/wasm2brs/project/sourcex/test.wasm.brs",
  "/home/trevor/wasm2brs/project/sourcex/test.cases.brs",
  "/home/trevor/wasm2brs/project/sourcex/runtime.brs",
  "/home/trevor/wasm2brs/project/sourcex/helpers.brs",
  "/home/trevor/wasm2brs/project/sourcex/wasi_snapshot_preview1.brs",
  "/home/trevor/wasm2brs/project/sourcex/spectest.brs"
];

const text = files.map((file) => fs.readFileSync(file, "utf8")).join("\n");

const uniqueIdentifiers: Record<string, true> = {};

const builtinLiterals = {
  false: true,
  invalid: true,
  m: true,
  true: true,
  while: true
};

const builtinKeywords = {
  and: true,
  as: true,
  box: true,
  dim: true,
  each: true,
  else: true,
  elseif: true,
  end: true,
  endfunction: true,
  endif: true,
  endsub: true,
  endwhile: true,
  exit: true,
  exitwhile: true,
  for: true,
  function: true,
  goto: true,
  if: true,
  in: true,
  interface: true,
  let: true,
  mod: true,
  next: true,
  not: true,
  objfun: true,
  or: true,
  pos: true,
  print: true,
  rem: true,
  return: true,
  run: true,
  step: true,
  stop: true,
  sub: true,
  tab: true,
  then: true,
  to: true,
  type: true
};

const builtinTypes = {
  boolean: true,
  double: true,
  dynamic: true,
  float: true,
  integer: true,
  longinteger: true,
  object: true,
  string: true,
  void: true
};

const builtinGlobals = {
  asc: true,
  createobject: true,
  eval: true,
  getglobalaa: true,
  getinterface: true,
  getlastruncompileerror: true,
  getlastrunruntimeerror: true,
  // eslint-disable-next-line camelcase
  line_num: true,
  log: true,
  instr: true,
  left: true,
  mid: true,
  chr: true
};

const builtinMembers = {
  count: true,
  doesexist: true,
  fromhexstring: true,
  getsignedbyte: true,
  len: true,
  push: true,
  tostr: true,
  unshift: true,
  fromasciistring: true,
  toasciistring: true
};

const reservedWords = {
  ...builtinLiterals,
  ...builtinKeywords,
  ...builtinTypes,
  ...builtinGlobals,
  ...builtinMembers
};

if (process.env.KEEP) {
  for (const identifier of process.env.KEEP.split(",")) {
    reservedWords[identifier.toLowerCase()] = true;
  }
}

const regex = /\b[a-zA-Z_][a-zA-Z0-9_]*\b/ug;
const textWithoutComments = text.replace(/('|REM).*/ug, "");
const textWithoutFalseIdentifiers = textWithoutComments.replace(/("[^"\n]*")|(&[hH][a-fA-F0-9]+)/ug, "");
for (;;) {
  const match = regex.exec(textWithoutFalseIdentifiers);
  if (match) {
    const lower = match[0].toLowerCase();
    if (!reservedWords[lower]) {
      uniqueIdentifiers[lower] = true;
    }
  } else {
    break;
  }
}

const rand = seedrandom("seed");
const shuffleArray = (array: any[]) => {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
};

const oldIdentifiers = Object.keys(uniqueIdentifiers);

const newIdentifiers: string[] = [];
for (let i = 0; i < oldIdentifiers.length; ++i) {
  newIdentifiers.push(`a${i}`);
}

shuffleArray(newIdentifiers);

let finalText = textWithoutComments;
for (let i = 0; i < oldIdentifiers.length; ++i) {
  const identifierRegex = new RegExp(`\\b${oldIdentifiers[i]}\\b`, "gui");
  finalText = finalText.replace(identifierRegex, newIdentifiers[i]);
}

fs.writeFileSync("/home/trevor/wasm2brs/project/source/test.min.brs", finalText, "utf8");
