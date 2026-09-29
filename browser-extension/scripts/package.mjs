import { spawnSync } from "node:child_process";
import { mkdir, rm } from "node:fs/promises";
import path from "node:path";
await mkdir("artifacts/packages", { recursive: true });
for (const browser of ["chrome", "firefox", "safari"]) {
  const file = path.resolve(`artifacts/packages/phralio-${browser}-1.0.0.zip`);
  await rm(file, { force: true });
  const result = spawnSync("zip", ["-qr", file, "."], {
    cwd: `dist/${browser}`,
    stdio: "inherit",
  });
  if (result.status !== 0) throw Error(`Could not package ${browser}`);
  console.log(file);
}
