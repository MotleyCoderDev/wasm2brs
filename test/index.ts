import fs from "fs";
import path from "path";
import execa from "execa";
import mkdirp from "mkdirp";

interface WastModule {
  type: "module";
  filename: string;
}

interface WastAssertReturn {
  type: "assert_return";
  filename: string;
  action: {
    type: "invoke";
    field: string;
    args: {
      type: "i32" | "i64";
      value: string;
    }[]
  };
}

interface WastJson {
  commands: (WastModule | WastAssertReturn)[];
}

(async () => {
  const root = path.join(__dirname, "../..");
  const out = path.join(root, "test/out");
  const fromRootOptions: execa.Options = {cwd: root, stdio: "inherit"};
  await mkdirp(out);

  const outJson = path.join(out, "address.json");
  await execa("third_party/wabt/bin/wast2json",
    [
      "third_party/wabt/third_party/testsuite/address.wast",
      "-o", outJson
    ],
    fromRootOptions);

  const wastJson = JSON.parse(fs.readFileSync(outJson, "utf8")) as WastJson;

  for (const command of wastJson.commands) {
    switch (command.type) {
      case "module":
        console.log("Module", command.filename);
        await execa("build/wasm2brs",
          [
            "-o", "project/source/wasm.brs",
            path.join(out, command.filename)
          ],
          fromRootOptions);

        break;
      case "assert_return":
        break;
    }
  }
})();
