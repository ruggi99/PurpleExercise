import fs from "node:fs/promises";
import util from "node:util";
import {execSync} from "node:child_process";

const response = execSync("npx vite build");
console.log(response.toString())
await fs.rename("dist/src/index.html", "../server/templates/index.html");
await fs.rename("dist/src/red_team.html", "../server/templates/red_team.html");
await fs.rm("../server/static/", { recursive: true, force: true });
await fs.rename("dist/static/", "../server/static/");
