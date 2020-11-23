/* eslint-disable camelcase */
import fs from "fs";
import path from "path";
import seedrandom from "seedrandom";

export const minifyFiles = (debug: boolean, filesContents: string[], keepIdentifiers?: string[]): string[] => {
  const text = filesContents.join("\n");

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
    catch: true,
    dim: true,
    each: true,
    else: true,
    elseif: true,
    end: true,
    endfor: true,
    endfunction: true,
    endif: true,
    endsub: true,
    endtry: true,
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
    throw: true,
    to: true,
    try: true,
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
    line_num: true,
    log: true,
    instr: true,
    left: true,
    mid: true,
    chr: true,
    sqr: true,
    abs: true,
    lcase: true
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
    toasciistring: true,
    append: true,
    mark: true,
    asseconds: true,
    getmilliseconds: true
  };

  const ourGlobals = {
    external_append_stdin: true
  };

  const ourMembers = {
    external_print_line: true,
    external_output: true,
    external_wait_for_stdin: true
  };

  const standardExports = {
    start: true,
    getsettings: true,
    graphical: true,
    custominit: true,
    restartonfailure: true
  };

  const reservedWords = {
    ...builtinLiterals,
    ...builtinKeywords,
    ...builtinTypes,
    ...builtinGlobals,
    ...builtinMembers,
    ...ourGlobals,
    ...ourMembers,
    ...standardExports
  };

  if (keepIdentifiers) {
    for (const identifier of keepIdentifiers) {
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
    replace(/([^a-zA-Z0-9_]) ([a-zA-Z_0-9])/ugm, "$1$2").
    replace(/([a-zA-Z_0-9]) ([^a-zA-Z0-9_&])/ugm, "$1$2").
    replace(/End /ug, "End");

  console.log("Removed Whitespace");

  const gatherIdentifierUsage = (str: string) => {
    const textWithoutFalseIdentifiers = str.replace(/("[^"\n]*")|(&[hH][a-fA-F0-9]+)/ug, "");
    const usage: Record<string, number> = {};
    for (;;) {
      const match = regex.exec(textWithoutFalseIdentifiers);
      if (match) {
        const lower = match[0].toLowerCase();
        if (!reservedWords[lower]) {
          usage[lower] = (usage[lower] || 0) + 1;
        }
      } else {
        break;
      }
    }
    return usage;
  };

  const rand = seedrandom("seed");
  const shuffleArray = (array: any[]) => {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(rand() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
  };

  const identifierUsage = gatherIdentifierUsage(textWithoutCommentsOrWhitespace);
  const oldIdentifiers = Object.keys(identifierUsage);

  const newIdentifiers: string[] = [];
  for (let i = 0; i < oldIdentifiers.length; ++i) {
    newIdentifiers.push(`a${i}${debug ? `_${oldIdentifiers[i]}` : ""}`);
  }

  if (!debug) {
    shuffleArray(newIdentifiers);
  }

  console.log("Remapped Identifiers");

  let newIdentifierText = textWithoutCommentsOrWhitespace;
  for (let i = 0; i < oldIdentifiers.length; ++i) {
    const identifierRegex = new RegExp(`\\b${oldIdentifiers[i]}\\b`, "gui");
    newIdentifierText = newIdentifierText.replace(identifierRegex, newIdentifiers[i]);
  }

  console.log("Replaced Identifiers");

  // Lowercase all reserved words
  for (const reservedWord of Object.keys(reservedWords)) {
    const reservedRegex = new RegExp(`\\b${reservedWord}\\b`, "gui");
    newIdentifierText = newIdentifierText.replace(reservedRegex, reservedWord.toLowerCase());
  }

  console.log("Lowercased Reserved Words");

  interface BrsFunction {
    text: string;
    name: string;
  }
  const collectFunctions = (str: string) => {
    const functionRegex = /^function ([a-zA-Z_][a-zA-Z0-9_]*).*?endfunction$/ugms;
    const functions: BrsFunction[] = [];
    for (;;) {
      const match = functionRegex.exec(str);
      if (match) {
        functions.push({text: match[0], name: match[1]});
      } else {
        break;
      }
    }
    return functions;
  };

  let unusedFunctionPass = newIdentifierText;
  for (;;) {
    const brsFunctions = collectFunctions(unusedFunctionPass);
    const usedIdentifiers = gatherIdentifierUsage(unusedFunctionPass);
    const usedBrsFunctions: BrsFunction[] = [];
    for (const brsFunc of brsFunctions) {
      if (usedIdentifiers[brsFunc.name] > 1 || usedIdentifiers[brsFunc.name] === undefined) {
        usedBrsFunctions.push(brsFunc);
      } else if (debug) {
        console.log("Unused function:", brsFunc.name);
      }
    }
    const numRemoved = brsFunctions.length - usedBrsFunctions.length;
    if (numRemoved === 0) {
      break;
    }
    unusedFunctionPass = usedBrsFunctions.map((brsFunc) => brsFunc.text).join("\n");
  }

  console.log("Removed All Unused Functions");

  const functions = collectFunctions(unusedFunctionPass).map((brsFunc) => brsFunc.text);
  shuffleArray(functions);

  console.log("Splittng Into 2MB Chunks (Max 65535 lines)");
  const brightScriptSizeLimit = 1024 * 1024 * 2;
  const brightScriptLineLimit = 65535;
  const joinedFunctions: string[] = [];
  let joinedFunction = "";
  let joinedByteSize = 0;
  let joinedLines = 0;
  for (const func of functions) {
    const funcWithNewline = `${func}\n`;
    const byteSize = Buffer.from(funcWithNewline).length;
    const lines = funcWithNewline.split("\n").length;
    if (joinedByteSize + byteSize > brightScriptSizeLimit || joinedLines + lines > brightScriptLineLimit) {
      joinedFunctions.push(joinedFunction.trim());
      joinedFunction = "";
      joinedByteSize = 0;
      joinedLines = 0;
    }
    joinedFunction += `${func}\n`;
    joinedByteSize += byteSize;
    joinedLines += lines;
  }
  if (joinedFunction !== "") {
    joinedFunctions.push(joinedFunction.trim());
  }
  return joinedFunctions;
};

if (process.env.INPUT && process.env.OUTPUT) {
  const filesContents = process.env.INPUT.split(",").map((file) => fs.readFileSync(file, "utf8"));
  const results = minifyFiles(Boolean(process.env.DEBUG), filesContents, (process.env.KEEP || "").split(","));
  if (results.length === 1) {
    fs.writeFileSync(process.env.OUTPUT, results[0], "utf8");
  } else {
    for (const [index, result] of results.entries()) {
      const parsed = path.parse(process.env.OUTPUT);
      const outPath = path.join(parsed.dir, `${parsed.name}.${index}${parsed.ext}`);
      fs.writeFileSync(outPath, result, "utf8");
    }
  }
}
