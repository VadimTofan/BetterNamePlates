local failures = 0
local tests = {}

function Describe(_, defineTests)
    defineTests()
end

function It(name, test)
    tests[#tests + 1] = {name = name, test = test}
end

function ExpectEqual(actual, expected)
    if actual ~= expected then
        error(
            "expected " .. tostring(expected) ..
            ", received " .. tostring(actual),
            2
        )
    end
end

function LoadAddonFile(path, namespace)
    local chunk, loadError = loadfile(path)

    if not chunk then
        error(loadError, 2)
    end

    return chunk("BetterNamePlates", namespace)
end

dofile("tests/test_core.lua")
dofile("tests/test_combat_state.lua")
dofile("tests/test_interrupts.lua")
dofile("tests/test_kick_tracker.lua")
dofile("tests/test_cast_duration.lua")
dofile("tests/test_aura_display.lua")
dofile("tests/test_nameplate_stacking.lua")
dofile("tests/test_rules.lua")
dofile("tests/test_config.lua")
dofile("tests/test_plate_dimensions.lua")
dofile("tests/test_frame_layout.lua")
dofile("tests/test_runtime_debug.lua")
dofile("tests/test_identity.lua")
dofile("tests/test_health_format.lua")
dofile("tests/test_display_text.lua")
dofile("tests/test_npc_classification.lua")
dofile("tests/test_target_indicator.lua")
dofile("tests/test_raid_target_indicator.lua")
dofile("tests/test_appearance.lua")
dofile("tests/test_friendly_name_style.lua")

for _, testCase in ipairs(tests) do
    local passed, testError = pcall(testCase.test)

    if passed then
        print("PASS " .. testCase.name)
    else
        failures = failures + 1
        print("FAIL " .. testCase.name .. ": " .. testError)
    end
end

if failures > 0 then
    error(tostring(failures) .. " test(s) failed")
end
