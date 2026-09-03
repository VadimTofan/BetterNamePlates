Describe("Nameplate kick tracking", function()
    It("decodes interrupters without inspecting their value", function()
        -- Given
        local namespace = {}
        local tracker = LoadAddonFile("KickTracker.lua", namespace)
        local secretLikeValue = {}

        -- When
        local castInterrupter = tracker:GetInterrupter(
            "UNIT_SPELLCAST_INTERRUPTED",
            secretLikeValue,
            nil
        )
        local empowerInterrupter = tracker:GetInterrupter(
            "UNIT_SPELLCAST_EMPOWER_STOP",
            false,
            secretLikeValue
        )

        -- Then
        ExpectEqual(castInterrupter, secretLikeValue)
        ExpectEqual(empowerInterrupter, secretLikeValue)
    end)

    It("suppresses repeated stop events for one cast", function()
        -- Given
        local namespace = {}
        local tracker = LoadAddonFile("KickTracker.lua", namespace)

        -- When
        local first = tracker:ShouldShowInterrupt(false, true)
        local repeated = tracker:ShouldShowInterrupt(true, true)
        local ordinaryStop = tracker:ShouldShowInterrupt(false, nil)
        local startsCast = tracker:IsStartEvent("UNIT_SPELLCAST_START")
        local startsChannel = tracker:IsStartEvent(
            "UNIT_SPELLCAST_CHANNEL_START"
        )

        -- Then
        ExpectEqual(first, true)
        ExpectEqual(repeated, false)
        ExpectEqual(ordinaryStop, false)
        ExpectEqual(startsCast, true)
        ExpectEqual(startsChannel, true)
    end)

    It("uses the player's recent interrupt before ally inference", function()
        -- Given
        local namespace = {}
        local tracker = LoadAddonFile("KickTracker.lua", namespace)
        local pendingPlayerKick = {
            spellID = 47528,
            time = 10,
        }

        -- When
        local recentSpellID = tracker:ResolveInterruptSpellID(
            10.1,
            pendingPlayerKick,
            6552
        )
        local expiredSpellID = tracker:ResolveInterruptSpellID(
            10.2,
            pendingPlayerKick,
            6552
        )

        -- Then
        ExpectEqual(recentSpellID, 47528)
        ExpectEqual(expiredSpellID, 6552)
    end)

    It("infers one ally and otherwise uses generic Kick", function()
        -- Given
        local namespace = {}
        local tracker = LoadAddonFile("KickTracker.lua", namespace)
        local classes = {
            party1 = "WARRIOR",
            party2 = nil,
        }
        local function unitExists(unit)
            return classes[unit] ~= nil
        end
        local function unitClass(unit)
            return nil, classes[unit]
        end

        -- When
        local oneAlly = tracker:InferAllyInterrupt(
            unitExists,
            unitClass
        )
        classes.party2 = "MAGE"
        local ambiguous = tracker:InferAllyInterrupt(
            unitExists,
            unitClass
        )

        -- Then
        ExpectEqual(oneAlly, 6552)
        ExpectEqual(ambiguous, 1766)
    end)

    It("uses the configured school lockout duration", function()
        -- Given
        local namespace = {}
        local tracker = LoadAddonFile("KickTracker.lua", namespace)

        -- When
        local mageDuration = tracker:GetLockoutDuration(2139)
        local fallbackDuration = tracker:GetLockoutDuration(1)

        -- Then
        ExpectEqual(mageDuration, 6)
        ExpectEqual(fallbackDuration, 3)
    end)
end)
