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
assert.ok(
  manifest.includes("## SavedVariables: BetterNamePlatesDB"),
  "manifest must persist nameplate dimensions",
);
assert.ok(
  manifest.includes("PlateDimensions.lua"),
  "manifest must load dimension handling before the runtime",
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
  packageMetadata.includes("  - icon-readme.png"),
  "release packages must exclude the full-size README icon",
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

const runtime = readRepositoryFile("Runtime.lua");
const interrupts = readRepositoryFile("Interrupts.lua");
const kickTracker = readRepositoryFile("KickTracker.lua");
const config = readRepositoryFile("Config.lua");
const auraDisplay = readRepositoryFile("AuraDisplay.lua");
const readme = readRepositoryFile("README.md");

assert.ok(
  fs.existsSync("icon-readme.png"),
  "the repository must retain a full-size README icon",
);
assert.ok(
  readme.includes("![BetterNamePlates icon](icon-readme.png)"),
  "the README must display the full-size repository icon",
);
const healthFontUses = runtime.match(/Config\.healthFont(?!Size)/g) ?? [];

assert.equal(
  healthFontUses.length,
  2,
  "HP and HP percentage must use healthFont without duplicate layers",
);

const castFontUses = runtime.match(/Config\.castFont(?!Size)/g) ?? [];
const expresswayOutlineUses =
  runtime.match(/Config\.expresswayFontFlags/g) ?? [];

assert.equal(
  castFontUses.length,
  3,
  "cast spell names, targets, and timers must use castFont",
);
assert.equal(
  expresswayOutlineUses.length,
  5,
  "health and cast text must use the shared Expressway outline flag",
);
assert.match(
  runtime,
  /createSelectionBorder\(\s*view\.healthForeground,\s*Config\.hoverBorderThickness\s*\)/,
  "hover borders must use their independent thickness",
);
assert.match(
  runtime,
  /HandleKickCastEvent|ShowKickIndicator/,
  "Runtime must render secret-safe kick indicators",
);
assert.match(
  runtime,
  /castTarget:SetPoint\(\s*"RIGHT",\s*view\.castTime,\s*"LEFT",\s*-Config\.castTargetTimerGap,\s*0\s*\)/,
  "spell target names must end immediately before the cast timer",
);
assert.match(
  runtime,
  /castTarget:SetJustifyH\("RIGHT"\)/,
  "spell target names must be right aligned",
);
assert.match(
  runtime,
  /castTarget:SetWidth\(\s*Config\.castFontSize\s*\*\s*Config\.castTargetMaxCharacters\s*\*\s*0\.6\s*\)/,
  "spell target names must be clipped to approximately ten characters",
);
assert.match(
  runtime,
  /event\s*==\s*"UNIT_THREAT_LIST_UPDATE"[\s\S]*?self:UpdateHealth\(unit,\s*true,\s*false\)/,
  "threat-list updates must refresh the affected plate appearance",
);
assert.match(
  config,
  /castTargetMaxCharacters\s*=\s*10/,
  "spell target name width must allow approximately ten characters",
);
assert.match(
  config,
  /interruptedCastHoldDuration\s*=\s*0\.5/,
  "interrupted casts must remain visible for half a second",
);
assert.match(
  config,
  /interruptedCast\s*=\s*\{\s*1,\s*0,\s*0,\s*1\s*\}/,
  "interrupted castbars must use bright red",
);
assert.match(
  runtime,
  /ShowInterruptedCast[\s\S]*?C_Timer\.NewTimer/,
  "interrupted castbars must use a one-shot timer instead of polling",
);
assert.match(
  runtime,
  /UpdateCastTarget\([\s\S]*?UnitSpellTargetName/,
  "cast target names must use Blizzard's dedicated target-name API",
);
assert.match(
  runtime,
  /UnitSpellTargetClass[\s\S]*?GetClassColor/,
  "spell target names must use Blizzard's secret-safe class color path",
);
const kickIndicatorFactory = runtime.match(
  /local function createKickIndicator[\s\S]*?\nend/,
)?.[0] ?? "";
assert.match(
  kickIndicatorFactory,
  /SetHideCountdownNumbers\(true\)/,
  "kick indicators must hide cooldown countdown text",
);
assert.ok(
  manifest.indexOf("KickTracker.lua") < manifest.indexOf("Runtime.lua"),
  "manifest must load KickTracker before Runtime",
);
assert.match(
  kickTracker,
  /GetInterrupter|ResolveInterruptSpellID|InferAllyInterrupt/,
  "KickTracker must isolate secret-safe attribution policy",
);
assert.doesNotMatch(
  runtime,
  /self:UpdateSelectionIndicators\(\)\s*self:UpdateRaidTarget\(unit\)/,
  "admitting one plate must not refresh selection state for every plate",
);
assert.doesNotMatch(
  interrupts,
  /GetSourcePresentation|GetSourceIconDefinitions|GetSourceGUID/,
  "interrupt helpers must only track the player's own kick",
);
assert.doesNotMatch(
  config,
  /interruptSourceDuration/,
  "Config must not retain interrupter-attribution timing",
);
assert.doesNotMatch(
  auraDisplay,
  /GetInterruptSourceLayout/,
  "aura layout must not reserve space for interrupter attribution",
);

console.log("PASS validates tag-driven CurseForge release configuration");
console.log("PASS applies the configured health font to every health text layer");
console.log("PASS applies the configured cast font to spell names and timers");
console.log("PASS outlines every Runtime Expressway text layer");
console.log("PASS uses the independent hover-border thickness");
console.log("PASS includes secret-safe kick attribution UI");
