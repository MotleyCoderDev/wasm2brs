import fs from "fs";
import path from "path";
import execa from "execa";
import mkdirp from "mkdirp";
import {ProgramBuilder} from "brighterscript";

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
  expected: [WastArg];
  line: number;
}

interface WastJson {
  commands: (WastModule | WastAssertReturn)[];
}

interface WastTest {
  moduleFilename: string;
  commands: WastAssertReturn[];
}

(async () => {
  const root = path.join(__dirname, "../..");
  const rokuOut = path.join(root, "out/out.zip");
  const testOut = path.join(root, "test/out");
  const project = path.join(root, "project");
  const projectSource = path.join(project, "source");
  const fromRootOptions: execa.Options = {cwd: root, stdio: "inherit"};
  await mkdirp(testOut);

  const testWast = "third_party/wabt/third_party/testsuite/f32.wast";
  const testWastFilename = path.basename(testWast);

  const outJson = path.join(testOut, "current.json");
  await execa("third_party/wabt/bin/wast2json",
    [
      testWast,
      "-o", outJson
    ],
    fromRootOptions);

  const wastJson = JSON.parse(fs.readFileSync(outJson, "utf8")) as WastJson;

  // Group all the commands under the module they belong to.
  let currentTest: WastTest = null;
  const tests: WastTest[] = [];
  for (const command of wastJson.commands) {
    if (command.type === "module") {
      currentTest = {
        moduleFilename: command.filename,
        commands: []
      };
      tests.push(currentTest);
    } else {
      currentTest.commands.push(command);
    }
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

    if (arg.type === "f64") {
      throw new Error("Unhandled f64 type");
    }

    // TODO(trevor): Differentiate between nan:canonical and nan:arithmetic (find a way in Brightscript)
    if (arg.value === "nan:canonical" || arg.value === "nan:arithmetic") {
      return arg.type === "f32" ? floatNanBrs : doubleNanBrs;
    }

    const buffer = new ArrayBuffer(4);
    const view = new DataView(buffer);
    view.setUint32(0, parseInt(arg.value, 10), true);

    const f32 = view.getFloat32(0, true);
    const isNegativeZero = 1 / f32 === -Infinity;
    if (isNegativeZero) {
      return arg.type === "f32" ? floatNegativeZeroBrs : doubleNegativeZeroBrs;
    }
    const str = f32.toString();
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
          const actual = `w2b_${command.action.field}(${args})`;
          const expected = toArgValue(command.expected[0]);
          const ending = ` ' ${testWastFilename}(${command.line})\n`;
          if (expected === floatNanBrs) {
            testFunction += `AssertEqualsFloatNan(${actual})${ending}`;
          } else if (expected === doubleNanBrs) {
            testFunction += `AssertEqualsDoubleNan(${actual})${ending}`;
          } else {
            testFunction += `AssertEquals(${actual}, ${expected})${ending}`;
          }
          break;
        }
      }
    }
    testFunction += "End Function\n";
    fs.writeFileSync(path.join(projectSource, "test.cases.brs"), testFunction);

    await new ProgramBuilder().run({
      cwd: project,
      outFile: rokuOut,
      host: process.env.HOST,
      password: process.env.PASSWORD,
      deploy: process.env.HOST !== undefined && process.env.PASSWORD !== undefined,
      ignoreErrorCodes: [1065, 1061, 1075, 1082]
    });
  };

  console.log("Number of tests:", tests.length);
  outputTest(tests[0]);
})();
