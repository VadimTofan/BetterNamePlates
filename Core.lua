local _, namespace = ...

local Identity = namespace.Identity
local Config = namespace.Config
local PlateDimensions = namespace.PlateDimensions

local Core = {
    enabled = false,
}

function Core:SetRuntime(runtime)
    self.runtime = runtime
end

function Core:SetDatabase(database)
    self.database = database
end

function Core:InitializeDimensions()
    PlateDimensions:ApplySaved(self.database, Config)
end

function Core:HandleDimensionCommand(message)
    local result = PlateDimensions:ApplyCommand(message, self.database)

    if result.changed then
        PlateDimensions:ApplySaved(self.database, Config)
        self.runtime:ApplyDimensions()
    end

    return result
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
    _G.BetterNamePlatesDB = _G.BetterNamePlatesDB or {}
    Core:SetDatabase(_G.BetterNamePlatesDB)
    Core:InitializeDimensions()
    Core:Start()

    _G["SLASH_" .. Identity.slashKey .. "1"] = Identity.slashCommand
    SlashCmdList[Identity.slashKey] = function(message)
        local command = message:lower():match("^%s*(%S*)")

        if command == "" or command == "width" or
            command == "height" or command == "reset" then
            local result = Core:HandleDimensionCommand(message)

            if result.changed or command == "" then
                print(
                    Identity.name .. ": size=" ..
                    tostring(Config.healthWidth) .. "x" ..
                    tostring(Config.healthHeight)
                )
            else
                print(
                    Identity.name .. ": use " .. Identity.slashCommand ..
                    " width 50-400, " .. Identity.slashCommand ..
                    " height 6-40, or " .. Identity.slashCommand ..
                    " reset"
                )
            end
            return
        end

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
                " debug, " .. Identity.slashCommand .. " absorbtest, " ..
                Identity.slashCommand .. " width, or " ..
                Identity.slashCommand .. " height"
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
