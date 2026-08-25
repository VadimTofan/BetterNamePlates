local _, namespace = ...

local Config = namespace.Config
local DisplayText = namespace.DisplayText

local FriendlyNameStyle = {}
local originalFonts = {}
local NATIVE_CVARS = {
    {"nameplateShowOnlyNameForFriendlyPlayerUnits", 1},
    {"nameplateUseClassColorForFriendlyPlayerUnitNames", 1},
    {"nameplateShowFriendlyRealmName", 0},
}

function FriendlyNameStyle:ShouldStyle(unitInfo)
    local isPlayer = DisplayText:SafeValue(unitInfo.isPlayer, false)
    local canAttack = DisplayText:SafeValue(unitInfo.canAttack, true)

    return isPlayer and not canAttack
end

function FriendlyNameStyle:GetPresentation()
    return {
        font = Config.nameFont,
        fontSize = Config.nameFontSize * Config.friendlyNameFontScale,
        fontFlags = Config.expresswayFontFlags,
    }
end

function FriendlyNameStyle:ApplyNativeCVars(setCVar)
    for _, setting in ipairs(NATIVE_CVARS) do
        pcall(setCVar, setting[1], setting[2])
    end
end

function FriendlyNameStyle:ApplyFontObjects(fontObjects)
    local presentation = self:GetPresentation()

    for _, fontObject in ipairs(fontObjects) do
        if fontObject and fontObject.GetFont and fontObject.SetFont then
            if not originalFonts[fontObject] then
                local font, size, flags = fontObject:GetFont()

                originalFonts[fontObject] = {font, size, flags}
            end

            fontObject:SetFont(
                presentation.font,
                presentation.fontSize,
                presentation.fontFlags
            )
        end
    end
end

function FriendlyNameStyle:RestoreFontObjects()
    for fontObject, original in pairs(originalFonts) do
        fontObject:SetFont(original[1], original[2], original[3])
        originalFonts[fontObject] = nil
    end
end

namespace.FriendlyNameStyle = FriendlyNameStyle

return FriendlyNameStyle
