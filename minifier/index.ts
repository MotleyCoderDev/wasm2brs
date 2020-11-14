import fs from "fs";
import seedrandom from "seedrandom";

const files = [
  "/home/trevor/wasm2brs/project/source/test.wasm.brs",
  "/home/trevor/wasm2brs/project/source/test.cases.brs",
  "/home/trevor/wasm2brs/project/source/runtime.brs",
  "/home/trevor/wasm2brs/project/source/helpers.brs",
  "/home/trevor/wasm2brs/project/source/wasi_snapshot_preview1.brs",
  "/home/trevor/wasm2brs/project/source/spectest.brs"
];

const text = files.map((file) => fs.readFileSync(file, "utf8")).join("\n");

const uniqueIdentifiers: Record<string, true> = {};

const builtinLiterals = {
  false: true,
  invalid: true,
  m: true,
  true: true
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
  endfor: true,
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
  type: true,
  while: true
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
const textWithoutCommentsOrWhitespace = text.
  replace(/('|REM).*/ug, "").
  replace(/^\s+/ugm, "").
  replace(/\s+$/ugm, "").
  replace(/  +/ugm, " ").
  replace(/ ([^a-zA-Z0-9]{1,3}) /ugm, "$1").
  replace(/, /ugm, ",").
  replace(/End /ug, "End");

const textWithoutFalseIdentifiers = textWithoutCommentsOrWhitespace.replace(/("[^"\n]*")|(&[hH][a-fA-F0-9]+)/ug, "");
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

let newIdentifierText = textWithoutCommentsOrWhitespace;
for (let i = 0; i < oldIdentifiers.length; ++i) {
  const identifierRegex = new RegExp(`\\b${oldIdentifiers[i]}\\b`, "gui");
  newIdentifierText = newIdentifierText.replace(identifierRegex, newIdentifiers[i]);
}

// Lowercase all reserved words
for (const reservedWord of Object.keys(reservedWords)) {
  const reservedRegex = new RegExp(`\\b${reservedWord}\\b`, "gui");
  newIdentifierText = newIdentifierText.replace(reservedRegex, reservedWord.toLowerCase());
}

const functionRegex = /^function.*?endfunction$/ugms;
const functions: string[] = [];
for (;;) {
  const match = functionRegex.exec(newIdentifierText);
  if (match) {
    functions.push(match[0]);
  } else {
    break;
  }
}

shuffleArray(functions);
const finalText = functions.join("\n");

fs.writeFileSync("/home/trevor/wasm2brs/testproject/source/test.min.brs", newIdentifierText, "utf8");
