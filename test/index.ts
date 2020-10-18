import fs from "fs";
import path from "path";
import execa from "execa";
import mkdirp from "mkdirp";

(async () => {
  const root = path.join(__dirname, "../..");
  const out = path.join(root, "test/out");
  await mkdirp(out);
  await execa("third_party/wabt/bin/wast2json",
    [
      "third_party/wabt/third_party/testsuite/address.wast",
      "-o", path.join(out, "best.json")
    ],
    {cwd: root});

  const tests = JSON.parse(fs.readFileSync("/home/trevor/wabt/address.json", "utf8"));
  console.log(tests.commands);
})();
