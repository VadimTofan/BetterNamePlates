local namespace = {}
local Compatibility = LoadAddonFile("Compatibility.lua", namespace)

Describe("Compatibility", function()
    It("detects WoW Forever from its interface number", function()
        -- Given a WoW Forever client build
        local version = "1.60.1"
        local interfaceVersion = 11601

        -- When the client flavor is detected
        local flavor = Compatibility:DetectFlavor(version, interfaceVersion)

        -- Then it uses the Forever compatibility path
        ExpectEqual(flavor, "forever")
    end)

    It("keeps Retail clients on the Retail path", function()
        -- Given a Retail client build
        local version = "12.1.0"
        local interfaceVersion = 120100

        -- When the client flavor is detected
        local flavor = Compatibility:DetectFlavor(version, interfaceVersion)

        -- Then it uses the Retail compatibility path
        ExpectEqual(flavor, "retail")
    end)

    It("detects every supported Classic client family", function()
        -- Given each active Classic-family interface
        local profiles = {
            {version = "1.15.9", interfaceVersion = 11509,
                expected = "vanilla"},
            {version = "2.5.6", interfaceVersion = 20506,
                expected = "tbc"},
            {version = "5.5.4", interfaceVersion = 50504,
                expected = "mists"},
        }

        -- When each client flavor is detected
        -- Then it selects the matching compatibility profile
        for _, profile in ipairs(profiles) do
            ExpectEqual(
                Compatibility:DetectFlavor(
                    profile.version,
                    profile.interfaceVersion
                ),
                profile.expected
            )
        end
    end)

    It("omits Retail character-system events on Forever", function()
        -- Given events from shared and Retail-only systems
        local events = {
            "NAME_PLATE_UNIT_ADDED",
            "PLAYER_SPECIALIZATION_CHANGED",
            "TRAIT_CONFIG_UPDATED",
        }

        -- When events are selected for Forever
        local selected = Compatibility:FilterEvents(events, "forever")

        -- Then only the shared event remains
        ExpectEqual(#selected, 1)
        ExpectEqual(selected[1], "NAME_PLATE_UNIT_ADDED")
    end)

    It("omits unsupported events from Vanilla and TBC", function()
        -- Given modern combat and character-system events
        local events = {
            "NAME_PLATE_UNIT_ADDED",
            "PLAYER_SPECIALIZATION_CHANGED",
            "TRAIT_CONFIG_UPDATED",
            "UNIT_SPELLCAST_EMPOWER_START",
            "UNIT_SPELLCAST_EMPOWER_STOP",
        }

        -- When the events are selected for older clients
        local vanilla = Compatibility:FilterEvents(events, "vanilla")
        local tbc = Compatibility:FilterEvents(events, "tbc")

        -- Then only the shared nameplate event remains
        ExpectEqual(#vanilla, 1)
        ExpectEqual(vanilla[1], "NAME_PLATE_UNIT_ADDED")
        ExpectEqual(#tbc, 1)
        ExpectEqual(tbc[1], "NAME_PLATE_UNIT_ADDED")
    end)

    It("falls back to damage when specialization APIs are absent", function()
        -- Given no assigned role and no specialization API
        local assignedRole = "NONE"

        -- When the role is resolved for Forever
        local role = Compatibility:ResolvePlayerRole(assignedRole, nil)

        -- Then threat coloring uses the damage role
        ExpectEqual(role, "DAMAGER")
    end)

    It("normalizes a legacy spell cooldown", function()
        -- Given the legacy start duration and enabled values
        local cooldown = Compatibility:NormalizeCooldown(10, 15, 1)

        -- When the compatibility result is inspected
        -- Then it exposes the duration contract used by the runtime
        ExpectEqual(cooldown.startTime, 10)
        ExpectEqual(cooldown.duration, 15)
        ExpectEqual(cooldown.isEnabled, true)
    end)

    It("adapts legacy cast timestamps to the duration contract", function()
        -- Given a cast running from ten to fifteen seconds
        local now = 12
        local duration = Compatibility:CreateLegacyDuration(
            10000,
            15000,
            function()
                return now
            end
        )

        -- When its duration values are requested
        -- Then they match the modern duration-object contract
        ExpectEqual(duration:GetTotalDuration(), 5)
        ExpectEqual(duration:GetRemainingDuration(), 3)
        ExpectEqual(duration:IsZero(), false)

        now = 15
        ExpectEqual(duration:GetRemainingDuration(), 0)
        ExpectEqual(duration:IsZero(), true)
    end)

    It("creates no-op numeric formatters on legacy clients", function()
        -- Given no modern string formatter factory
        -- When a compatible formatter is created
        local formatter = Compatibility:CreateNumericFormatter(nil)

        -- Then runtime breakpoint setup remains safe
        formatter:AddBreakpoint({threshold = 0})
        ExpectEqual(type(formatter.AddBreakpoint), "function")
    end)

    It("uses legacy spell APIs when modern namespaces are absent", function()
        -- Given legacy spell functions
        local knownSpellID
        local textureSpellID

        -- When spell knowledge and texture are requested
        local known = Compatibility:IsSpellKnown(1766, nil, function(spellID)
            knownSpellID = spellID
            return true
        end)
        local texture = Compatibility:GetSpellTexture(
            1766,
            nil,
            function(spellID)
                textureSpellID = spellID
                return 135856
            end
        )

        -- Then the legacy functions provide the values
        ExpectEqual(known, true)
        ExpectEqual(knownSpellID, 1766)
        ExpectEqual(texture, 135856)
        ExpectEqual(textureSpellID, 1766)
    end)

    It("calculates ordinary health percentages without curve APIs", function()
        -- Given ordinary health values
        -- When their percentage is requested
        local percentage = Compatibility:GetHealthPercent(75, 100)

        -- Then a normalized value is returned
        ExpectEqual(percentage, 0.75)
    end)

    It("uses the curve API before inspecting restricted health values", function()
        -- Given opaque health values and a curve-based percentage API
        local health = {}
        local maximum = {}
        local curve = {}
        local receivedUnit
        local receivedCurve

        local function getHealthPercent(unit, includePredicted, alphaCurve)
            receivedUnit = unit
            receivedCurve = alphaCurve
            ExpectEqual(includePredicted, true)
            return 0.4
        end

        -- When marker alpha is calculated
        local alpha = Compatibility:GetHealthMarkerAlpha(
            "nameplate1",
            health,
            maximum,
            getHealthPercent,
            curve
        )

        -- Then the opaque values are not compared or divided
        ExpectEqual(alpha, 0.4)
        ExpectEqual(receivedUnit, "nameplate1")
        ExpectEqual(receivedCurve, curve)
    end)

    It("selects ordinary boolean values without curve APIs", function()
        -- Given two presentation values
        -- When an ordinary boolean is evaluated
        local selected = Compatibility:EvaluateBoolean(true, "yes", "no")

        -- Then the true presentation is selected
        ExpectEqual(selected, "yes")
    end)
end)
