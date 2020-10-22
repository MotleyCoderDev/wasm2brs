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

  const outJson = path.join(testOut, "current.json");
  await execa("third_party/wabt/bin/wast2json",
    [
      "third_party/wabt/third_party/testsuite/i32.wast",
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

  const toArgValue = (arg: WastArg) => {
    if (arg.type === "i32" || arg.type === "i64") {
      return parseInt(arg.value, 10);
    }

    const buffer = new ArrayBuffer(4);
    const view = new DataView(buffer);
    view.setUint32(0, parseInt(arg.value, 10), true);
    return view.getFloat32(0, true);
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

    let i = 0;
    for (const command of test.commands) {
      switch (command.type) {
        case "assert_return": {
          const args = command.action.args.map((arg) => toArgValue(arg)).join(",");
          testFunction += `x${i} = w2b_${command.action.field}(${args})\n`;
          const value = toArgValue(command.expected[0]);
          if (isNaN(value)) {
            testFunction += `If Not IsFloatNan(x${i}) Then Stop\n`;
          } else {
            testFunction += `If x${i} <> ${value} Then Stop\n`;
          }
          break;
        }
      }
      ++i;
    }
    testFunction += "End Function\n";
    fs.writeFileSync(path.join(projectSource, "test.cases.brs"), testFunction);

    await new ProgramBuilder().run({
      cwd: project,
      outFile: rokuOut,
      host: process.env.HOST,
      password: process.env.PASSWORD,
      deploy: process.env.HOST !== undefined && process.env.PASSWORD !== undefined,
      ignoreErrorCodes: [1065, 1061]
    });
  };

  console.log("Number of tests: ", tests.length);
  outputTest(tests[0]);
})();
