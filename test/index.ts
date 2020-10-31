import fs from "fs";
import path from "path";
import execa from "execa";
import mkdirp from "mkdirp";
import * as rokuDeploy from "roku-deploy";
import net from "net";
import * as uuid from "uuid";

interface WastModule {
  type: "module";
  filename: string;
}

interface WastArg {
  type: "i32" | "i64" | "f32" | "f64";
  value: string;
}


interface WastAssertReturn {
  type: "assert_return";
  filename: string;
  action: {
    type: "invoke";
    field: string;
    args: WastArg[]
  },
  expected: WastArg[];
  line: number;
  jsonLine: number;
}

interface WastJson {
  commands: (WastModule | WastAssertReturn)[];
}

interface WastTest {
  moduleFilename: string;
  commands: WastAssertReturn[];
}

(async () => {
  if (process.env.WAST === undefined) {
    console.error("Expected WAST to be set to a .wast file");
    return;
  }
  if (process.env.INDEX === undefined) {
    console.error("Expected INDEX to be set to a test index within the .wast file");
    return;
  }

  const testWast = path.resolve(process.env.WAST);
  const testIndex = parseInt(process.env.INDEX, 10);
  const testWastFilename = path.basename(testWast);

  const root = path.join(__dirname, "../..");
  const testOut = path.join(root, "test/out");
  const project = path.join(root, "project");
  const projectSource = path.join(project, "source");
  const testCasesBrs = path.join(projectSource, "test.cases.brs");
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
  const tests: WastTest[] = [];
  for (const command of wastJson.commands) {
    if (command.type === "module") {
      currentTest = {
        moduleFilename: command.filename,
        commands: []
      };
      tests.push(currentTest);
    } else {
      command.jsonLine = currentJsonLine;
      currentTest.commands.push(command);
    }
    ++currentJsonLine;
  }

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
      return arg.type === "f32" ? floatNanBrs : doubleNanBrs;
    }
    return str + (arg.type === "f32" ? "!" : "#");
  };

  const outputTest = async (test: WastTest) => {
    console.log("Testing module", test.moduleFilename);
    await execa("build/wasm2brs",
      [
        "-o", path.join(projectSource, "test.wasm.brs"),
        path.join(testOut, test.moduleFilename)
      ],
      fromRootOptions);

    let testFunction = "Function RunTests()\n";

    for (const command of test.commands) {
      switch (command.type) {
        case "assert_return": {
          const args = command.action.args.map((arg) => toArgValue(arg)).join(",");
          testFunction += `result = w2b_${command.action.field.replace(/[^a-zA-Z0-9]/gu, "_")}(${args}) ` +
            `' ${testWastFilename}(${command.line}) ${outJsonFilename}(${command.jsonLine})\n`;

          for (const [index, arg] of command.expected.entries()) {
            const expected = toArgValue(arg);
            testFunction += `AssertEquals(${command.expected.length === 1
              ? "result"
              : `result[${index}]`
            }, ${expected})\n`;
          }
          break;
        }
      }
    }
    testFunction += "End Function\n";
    fs.writeFileSync(testCasesBrs, testFunction);
  };

  console.log("Number of tests:", tests.length);
  if (testIndex > tests.length) {
    console.error("Invalid test", testIndex);
    return;
  }
  await outputTest(tests[testIndex]);
  const id = uuid.v4();
  fs.writeFileSync(path.join(project, "manifest"), `title=${id}`);
  if (process.env.DEPLOY) {
    try {
      await rokuDeploy.deploy({
        host: process.env.DEPLOY,
        password: process.env.PASSWORD || "rokudev",
        rootDir: project,
        failOnCompileError: true
      });
    } catch {
      console.error("Failed to deploy");
    }

    let str = "";
    let writeOutput = false;
    const socket = net.connect(8085, process.env.DEPLOY);
    socket.on("data", async (buffer) => {
      const text = buffer.toString();
      str += text;
      if (writeOutput) {
        process.stdout.write(text);
        if ((/Syntax Error.|------ Completed ------|Brightscript Debugger>/u).test(str)) {
          process.stdout.write("\n");
          socket.destroy();
          const match = (/file\/line: pkg:\/source\/test.cases.brs\(([0-9]+)\)/ug).exec(str);
          if (match) {
            await execa("code", ["-g", `${testCasesBrs}:${match[1]}`]);
          }
        }
      } else {
        const index = str.indexOf(`------ Compiling dev '${id}' ------`);
        if (index !== -1) {
          str = str.substr(index);
          process.stdout.write(str);
          writeOutput = true;
        }
        if (str.indexOf("Console connection is already in use.") !== -1) {
          throw new Error("Telnet connection already in use, please stop debugger to see result");
        }
      }
    });
  }
})();
