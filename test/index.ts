import fs from "fs";
import path from "path";
import execa from "execa";

(async () => {
  const root = path.join(__filename, "../..");
  await execa("third_party/wabt/bin/wast2json", ["third_party/wabt/third_party/testsuite/address.wast"], {cwd: root});

  const tests = JSON.parse(fs.readFileSync("/home/trevor/wabt/address.json", "utf8"));
  console.log(tests.commands);
})();
