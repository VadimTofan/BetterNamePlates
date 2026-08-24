local _, namespace = ...

local Identity = namespace.Identity

local Core = {
    enabled = false,
}

function Core:SetRuntime(runtime)
    self.runtime = runtime
end

function Core:IsEnabled()
    return self.enabled
end

function Core:Start()
    self:Refresh(true)
end

function Core:Refresh(isChallengeActive)
    if isChallengeActive == self.enabled then
        return
    end

    self.enabled = isChallengeActive

    if isChallengeActive then
        self.runtime:Enable()
    else
        self.runtime:Disable()
    end
end

namespace.Core = Core

if CreateFrame then
    Core:SetRuntime(namespace.Runtime)
    Core:Start()

    _G["SLASH_" .. Identity.slashKey .. "1"] = Identity.slashCommand
    SlashCmdList[Identity.slashKey] = function(message)
        if message == "absorbtest" then
            print(
                Identity.name .. ": absorb test=" ..
                tostring(namespace.Runtime:DebugForceTargetAbsorb())
            )
            return
        end

        if message ~= "debug" then
            print(
                Identity.name .. ": use " .. Identity.slashCommand ..
                " debug or " .. Identity.slashCommand .. " absorbtest"
            )
            return
        end

        local runtimeState = namespace.Runtime:GetDebugState()
        local stackingState = namespace.NameplateStacking:GetDebugState(
            GetCVar
        )
        print(
            Identity.name .. ":",
            "enabled=" .. tostring(Core:IsEnabled()),
            "plates=" .. tostring(runtimeState.activePlateCount),
            "last=" .. runtimeState.lastAddResult
        )
        print(
            Identity.name .. ": layout",
            "overlapH=" .. tostring(stackingState.overlapH),
            "overlapV=" .. tostring(stackingState.overlapV),
            "bounds=custom"
        )
    end
end

return Core
