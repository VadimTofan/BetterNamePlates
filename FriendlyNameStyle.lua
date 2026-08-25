local _, namespace = ...

local Config = namespace.Config
local DisplayText = namespace.DisplayText

local FriendlyNameStyle = {}

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
        boldOffset = Config.nameBoldOffset,
    }
end

function FriendlyNameStyle:Apply(unitFrame, text)
    local name = unitFrame.name
    local presentation = self:GetPresentation()
    local originalFont, originalSize, originalFlags = name:GetFont()
    local originalAlpha = name:GetAlpha()
    local bold = unitFrame.BetterNamePlatesFriendlyNameBold
    local red, green, blue, alpha = name:GetTextColor()

    if not bold then
        bold = unitFrame:CreateFontString(nil, "OVERLAY")
        unitFrame.BetterNamePlatesFriendlyNameBold = bold
        bold:SetPoint(
            "TOPLEFT",
            name,
            "TOPLEFT",
            presentation.boldOffset,
            0
        )
        bold:SetPoint(
            "BOTTOMRIGHT",
            name,
            "BOTTOMRIGHT",
            presentation.boldOffset,
            0
        )
        bold:SetJustifyH(name:GetJustifyH())
        bold:SetJustifyV(name:GetJustifyV())
    end

    name:SetFont(
        presentation.font,
        presentation.fontSize,
        presentation.fontFlags
    )
    name:SetAlpha(0)
    bold:SetFont(
        presentation.font,
        presentation.fontSize,
        presentation.fontFlags
    )
    bold:SetTextColor(red, green, blue, alpha)
    bold:SetText(text)
    bold:Show()

    return {
        bold = bold,
        name = name,
        originalFlags = originalFlags,
        originalFont = originalFont,
        originalSize = originalSize,
        originalAlpha = originalAlpha,
    }
end

function FriendlyNameStyle:Restore(view)
    view.name:SetFont(
        view.originalFont,
        view.originalSize,
        view.originalFlags
    )
    view.name:SetAlpha(view.originalAlpha)
    view.bold:Hide()
end

namespace.FriendlyNameStyle = FriendlyNameStyle

return FriendlyNameStyle
