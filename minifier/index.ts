import fs from "fs";
import seedrandom from "seedrandom";

export const minifyFiles = (filesContents: string[]): string => {
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
    replace(/([^a-zA-Z0-9]) ([a-zA-Z_0-9])/ugm, "$1$2").
    replace(/([a-zA-Z_0-9]) ([^a-zA-Z0-9&])/ugm, "$1$2").
    replace(/End /ug, "End");

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
    const usedBrsFunctions = brsFunctions.filter((brsFunc) =>
      usedIdentifiers[brsFunc.name] > 1 || usedIdentifiers[brsFunc.name] === undefined);
    const numRemoved = brsFunctions.length - usedBrsFunctions.length;
    if (numRemoved === 0) {
      break;
    }
    unusedFunctionPass = usedBrsFunctions.map((brsFunc) => brsFunc.text).join("\n");
  }

  const functions = collectFunctions(unusedFunctionPass).map((brsFunc) => brsFunc.text);
  shuffleArray(functions);
  const finalText = functions.join("\n");

  return finalText;
};

if (process.env.INPUT && process.env.OUTPUT) {
  const filesContents = process.env.INPUT.split(",").map((file) => fs.readFileSync(file, "utf8"));
  const result = minifyFiles(filesContents);
  fs.writeFileSync(process.env.OUTPUT, result, "utf8");
}
