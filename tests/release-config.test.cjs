const assert = require("node:assert/strict");
const fs = require("node:fs");

function readRepositoryFile(path) {
  return fs.existsSync(path) ? fs.readFileSync(path, "utf8") : "";
}

const manifest = readRepositoryFile("BetterNamePlates.toc");

assert.ok(
  manifest.includes("## X-Curse-Project-ID: 1664307"),
  "manifest must identify CurseForge project 1664307",
);

const packageMetadata = readRepositoryFile(".pkgmeta");

assert.ok(
  packageMetadata.includes("package-as: BetterNamePlates"),
  "package metadata must preserve the addon folder name",
);
assert.ok(
  packageMetadata.includes("  - tests"),
  "release packages must exclude tests",
);
assert.ok(
  packageMetadata.includes("  - profile.txt"),
  "release packages must exclude the source profile",
);
assert.ok(
  packageMetadata.includes("  - package.json"),
  "release packages must exclude Node metadata",
);

const workflow = readRepositoryFile(".github/workflows/release.yml");

assert.ok(
  workflow.includes('- "v*"'),
  "release workflow must trigger on version tags",
);
assert.ok(
  workflow.includes("run: npm test"),
  "release workflow must run tests before publishing",
);
assert.ok(
  workflow.includes("uses: BigWigsMods/packager@v2"),
  "release workflow must use the WoW addon packager",
);
assert.ok(
  workflow.includes("CF_API_KEY: ${{ secrets.CF_API_TOKEN }}"),
  "release workflow must map the configured CurseForge secret",
);

console.log("PASS validates tag-driven CurseForge release configuration");
