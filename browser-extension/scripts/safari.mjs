import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import path from "node:path";
const project = path.resolve(
  "safari/Phralio Browser/Phralio Browser.xcodeproj",
);
if (existsSync(project))
  console.log(
    `Safari project already exists: ${project}\nIts resources reference dist/safari, which was refreshed. Build the existing project; signing settings are preserved.`,
  );
else {
  const result = spawnSync(
    "xcrun",
    [
      "safari-web-extension-converter",
      path.resolve("dist/safari"),
      "--project-location",
      path.resolve("safari"),
      "--app-name",
      "Phralio Browser",
      "--bundle-identifier",
      "app.phralio.browser",
      "--swift",
      "--no-open",
      "--no-prompt",
    ],
    { stdio: "inherit" },
  );
  process.exitCode = result.status ?? 1;
}
