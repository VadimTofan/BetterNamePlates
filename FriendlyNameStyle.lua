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

function FriendlyNameStyle:UpdateColor(view)
    if view.classColor then
        view.bold:SetTextColor(
            view.classColor.r,
            view.classColor.g,
            view.classColor.b,
            1
        )
        return
    end

    view.bold:SetTextColor(view.name:GetTextColor())
end

function FriendlyNameStyle:Apply(
    basePlate,
    unitFrame,
    text,
    classColor,
    hiddenParent
)
    local name = unitFrame.name
    local presentation = self:GetPresentation()
    local originalFont, originalSize, originalFlags = name:GetFont()
    local originalAlpha = name:GetAlpha()
    local originalUnitFrameAlpha = unitFrame:GetAlpha()
    local originalUnitFrameParent = unitFrame.GetParent and
        unitFrame:GetParent() or nil
    local bold = basePlate.BetterNamePlatesFriendlyNameBold
    local red, green, blue, alpha = name:GetTextColor()

    if not bold then
        bold = basePlate:CreateFontString(nil, "OVERLAY")
        basePlate.BetterNamePlatesFriendlyNameBold = bold
    end

    bold:ClearAllPoints()
    bold:SetPoint("CENTER", basePlate, "CENTER", 0, 0)
    bold:SetJustifyH("CENTER")
    bold:SetJustifyV("MIDDLE")

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
    if classColor then
        bold:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
    else
        bold:SetTextColor(red, green, blue, alpha)
    end
    bold:SetText(text)
    bold:Show()

    if hiddenParent then
        if unitFrame.WidgetContainer then
            unitFrame.WidgetContainer:SetParent(basePlate)
        end

        unitFrame:SetParent(hiddenParent)
    else
        unitFrame:SetAlpha(0)
    end

    return {
        basePlate = basePlate,
        bold = bold,
        classColor = classColor,
        name = name,
        hiddenParent = hiddenParent,
        unitFrame = unitFrame,
        originalFlags = originalFlags,
        originalFont = originalFont,
        originalSize = originalSize,
        originalAlpha = originalAlpha,
        originalUnitFrameAlpha = originalUnitFrameAlpha,
        originalUnitFrameParent = originalUnitFrameParent,
    }
end

function FriendlyNameStyle:Suppress(view)
    self:UpdateColor(view)

    local currentUnitFrame = view.basePlate and
        view.basePlate.UnitFrame or view.unitFrame

    if view.hiddenParent then
        if currentUnitFrame.WidgetContainer then
            currentUnitFrame.WidgetContainer:SetParent(view.basePlate)
        end

        currentUnitFrame:SetParent(view.hiddenParent)
        return
    end

    currentUnitFrame:SetAlpha(0)
end

function FriendlyNameStyle:Restore(view)
    view.name:SetFont(
        view.originalFont,
        view.originalSize,
        view.originalFlags
    )
    view.name:SetAlpha(view.originalAlpha)
    view.unitFrame:SetAlpha(view.originalUnitFrameAlpha)

    if view.originalUnitFrameParent then
        view.unitFrame:SetParent(view.originalUnitFrameParent)
    end

    if view.unitFrame.WidgetContainer then
        view.unitFrame.WidgetContainer:SetParent(view.unitFrame)
    end

    view.bold:Hide()
end

namespace.FriendlyNameStyle = FriendlyNameStyle

return FriendlyNameStyle
