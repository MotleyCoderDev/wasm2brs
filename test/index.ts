import fs from "fs";
import path from "path";
import execa from "execa";
import mkdirp from "mkdirp";
import * as rokuDeploy from "roku-deploy";
import net from "net";
import * as uuid from "uuid";
import ADLER32 from "adler-32";

interface WastModule {
  type: "module";
  filename: string;
}

interface WastArg {
  type: "i32" | "i64" | "f32" | "f64";
  value: string;
}

interface WastAssertReturnInvoke {
  type: "invoke";
  field: string;
  args: WastArg[]
}

interface WastAssertReturnGet {
  type: "get";
}

interface WastAssertReturn {
  type: "assert_return";
  filename: string;
  action: WastAssertReturnInvoke | WastAssertReturnGet,
  expected: WastArg[];
  line: number;
  jsonLine: number;
}

interface WastUnhandledCommand {
  type: "assert_malformed" | "assert_invalid" | "assert_trap" | "assert_exhaustion";
}

interface WastJson {
  commands: (WastModule | WastAssertReturn | WastUnhandledCommand)[];
}

interface WastTest {
  moduleFilename: string;
  commands: WastAssertReturn[];
}

const root = path.join(__dirname, "../..");
const testOut = path.join(root, "test/out");
const project = path.join(root, "project");
const projectSource = path.join(project, "source");
const testCasesBrs = path.join(projectSource, "test.cases.brs");
const testWasmBrs = path.join(projectSource, "test.wasm.brs");

const outputWastTests = async (wastFile: string, guid: string): Promise<true | string> => {
  const testWast = path.resolve(wastFile);
  const testWastFilename = path.basename(wastFile);

  const fromRootOptions: execa.Options = {cwd: root, stdio: "inherit"};
  await mkdirp(testOut);

  const outJsonFilename = "current.json";
  const outJson = path.join(testOut, outJsonFilename);
  await execa("third_party/wabt/bin/wast2json",
    [
      testWast,
      "-o", outJson
    ],
    fromRootOptions);

  const wastJson = JSON.parse(fs.readFileSync(outJson, "utf8")) as WastJson;

  // Group all the commands under the module they belong to.
  let currentTest: WastTest = null;
  // The commands start at this line in the json output by wast2json.
  let currentJsonLine = 3;
  const unfilteredTests: WastTest[] = [];
  for (const command of wastJson.commands) {
    if (command.type === "module") {
      currentTest = {
        moduleFilename: command.filename,
        commands: []
      };
      unfilteredTests.push(currentTest);
    } else if (command.type === "assert_return" && command.action.type === "invoke") {
      command.jsonLine = currentJsonLine;
      currentTest.commands.push(command);
    }
    ++currentJsonLine;
  }

  // Ignore tests that have no asserts that we currently handle.
  const tests = unfilteredTests.filter((test) => test.commands.length !== 0);

  const floatNanBrs = "FloatNan()";
  const floatInfBrs = "FloatInf()";
  const floatNegativeZeroBrs = "FloatNegativeZero()";
  const doubleNanBrs = "DoubleNan()";
  const doubleInfBrs = "DoubleInf()";
  const doubleNegativeZeroBrs = "DoubleNegativeZero()";
  const toArgValue = (arg: WastArg) => {
    if (arg.type === "i32" || arg.type === "i64") {
      return arg.value + (arg.type === "i32" ? "%" : "&");
    }

    // TODO(trevor): Differentiate between nan:canonical and nan:arithmetic (find a way in Brightscript)
    if (arg.value === "nan:canonical" || arg.value === "nan:arithmetic") {
      return arg.type === "f32" ? floatNanBrs : doubleNanBrs;
    }

    const buffer = new ArrayBuffer(8);
    const view = new DataView(buffer);
    const value = (() => {
      if (arg.type === "f32") {
        view.setUint32(0, parseInt(arg.value, 10), true);
        return view.getFloat32(0, true);
      }
      view.setBigUint64(0, BigInt(arg.value), true);
      return view.getFloat64(0, true);
    })();

    const isNegativeZero = value === 0 && 1 / value === -Infinity;
    if (isNegativeZero) {
      return arg.type === "f32" ? floatNegativeZeroBrs : doubleNegativeZeroBrs;
    }
    const str = value.toString();
    if (str === "Infinity") {
      return arg.type === "f32" ? floatInfBrs : doubleInfBrs;
    }
    if (str === "-Infinity") {
      return arg.type === "f32" ? `-${floatInfBrs}` : `-${doubleInfBrs}`;
    }
    if (str === "NaN") {
      const signByte = arg.type === "f32" ? view.getUint8(3) : view.getUint8(7);
      const isSignBitSet = signByte >= 128;
      return `${isSignBitSet ? "-" : ""}${arg.type === "f32" ? floatNanBrs : doubleNanBrs}`;
    }
    return str + (arg.type === "f32" ? "!" : "#");
  };

  // Should match LegalizeName
  const legalizeName = (name: string) => `${name.replace(/[^a-zA-Z0-9]/gu, "_")}_${ADLER32.str(name)}`;

  let testCasesFile = "";
  let testWasmFile = "";

  let runTestsFunction = "Function RunTests()\n";

  console.log("Number of modules to test:", tests.length);
  for (const [textIndex, test] of tests.entries()) {
    const testPrefix = `Test${textIndex}`;
    console.log("Testing module", test.moduleFilename);
    const wasm2BrsResult = await execa("build/wasm2brs",
      [
        "--name-prefix", testPrefix,
        path.join(testOut, test.moduleFilename)
      ],
      {...fromRootOptions, stdio: "pipe", reject: false});

    if (wasm2BrsResult.exitCode !== 0) {
      return wasm2BrsResult.stderr;
    }
    testWasmFile += `${wasm2BrsResult.stdout}\n`;

    let testFunction =
      `Function ${testPrefix}()\n` +
      `  ${testPrefix}Init__()\n`;

    for (const command of test.commands) {
      switch (command.type) {
        case "assert_return": {
          if (command.action.type === "invoke") {
            const args = command.action.args.map((arg) => toArgValue(arg)).join(",");
            testFunction += `  result = ${testPrefix}${legalizeName(command.action.field)}(${args}) ` +
            `' ${testWastFilename}(${command.line}) ${outJsonFilename}(${command.jsonLine})\n`;

            for (const [index, arg] of command.expected.entries()) {
              const expected = toArgValue(arg);
              testFunction += `  AssertEquals(${command.expected.length === 1
                ? "result"
                : `result[${index}]`
              }, ${expected})\n`;
            }
          }
          break;
        }
      }
    }
    testFunction += "End Function\n";
    runTestsFunction += `  ${testPrefix}()\n`;
    testCasesFile += testFunction;
  }
  runTestsFunction += "End Function\n";
  testCasesFile += runTestsFunction;
  fs.writeFileSync(testCasesBrs, testCasesFile);
  fs.writeFileSync(testWasmBrs, testWasmFile);

  fs.writeFileSync(path.join(project, "manifest"), `title=${guid}`);
  return true;
};

const deploy = async (guid: string) => {
  console.log("Deploying...");
  try {
    await rokuDeploy.deploy({
      host: process.env.DEPLOY,
      password: process.env.PASSWORD || "rokudev",
      rootDir: project,
      failOnCompileError: true
    });
  } catch {
    console.error("Failed to deploy. Connecting to see the error...");
  }

  console.log("Connecting...");
  let str = "";
  let writeOutput = false;
  const socket = net.connect(8085, process.env.DEPLOY);
  socket.on("data", async (buffer) => {
    const text = buffer.toString();
    str += text;
    if (writeOutput) {
      process.stdout.write(text);
    } else {
      const index = str.indexOf(`------ Compiling dev '${guid}' ------`);
      if (index !== -1) {
        str = str.substr(index);
        process.stdout.write(str);
        writeOutput = true;
      }
      if (str.indexOf("Console connection is already in use.") !== -1) {
        throw new Error("Telnet connection already in use, please stop debugger to see result");
      }
    }

    if (writeOutput && (/ERROR compiling|Syntax Error|------ Completed ------|Brightscript Debugger>/ug).test(str)) {
      process.stdout.write("\n");
      socket.destroy();
      const match = (/file\/line: pkg:\/source\/test.cases.brs\(([0-9]+)\)/ug).exec(str);
      if (match) {
        await execa("code", ["-g", `${testCasesBrs}:${match[1]}`]);
      }
    }
  });
};

const outputAndMaybeDeploy = async (wastFile: string) => {
  const guid = uuid.v4();
  const result = await outputWastTests(wastFile, guid);
  if (result === true && process.env.DEPLOY) {
    await deploy(guid);
  }
  return result;
};

(async () => {
  if (process.env.WAST === undefined) {
    console.error("Expected WAST to be set to a .wast file");
    return;
  }
  const result = await outputAndMaybeDeploy(process.env.WAST);
  if (result !== true) {
    console.error(result);
  }
})();
