local _, namespace = ...

local Config = namespace.Config
local Appearance = namespace.Appearance
local AuraDisplay = namespace.AuraDisplay
local CastDuration = namespace.CastDuration
local CombatState = namespace.CombatState
local DisplayText = namespace.DisplayText
local FriendlyNameStyle = namespace.FriendlyNameStyle
local FrameLayout = namespace.FrameLayout
local HealthFormat = namespace.HealthFormat
local Interrupts = namespace.Interrupts
local NameplateStacking = namespace.NameplateStacking
local NpcClassification = namespace.NpcClassification
local RaidTargetIndicator = namespace.RaidTargetIndicator
local Rules = namespace.Rules
local TargetIndicator = namespace.TargetIndicator

local Runtime = {
    activePlates = {},
    castingPlates = {},
    friendlyPlates = {},
}

function Runtime:AdvanceRefreshClock(current, elapsed, interval)
    local accumulated = (current or 0) + elapsed

    if accumulated >= interval then
        return true, accumulated - interval
    end

    return false, accumulated
end

function Runtime:RefreshUpdateDriver()
    if not self.frame then
        return
    end

    local hasTrackedPlates = next(self.activePlates)
    local handler = hasTrackedPlates and
        self.onUpdateHandler or nil

    self.frame:SetScript("OnUpdate", handler)
end

local function supportsNativeAuraContainers()
    return C_XMLUtil and C_XMLUtil.GetTemplateInfo and
        C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")
end

local function setStatusBarColor(statusBar, color)
    statusBar:SetStatusBarColor(color[1], color[2], color[3], color[4])
end

local function setTextureColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4])
end

function Runtime:SetHealthText(fontString, text)
    fontString:SetText(text)
end

local function setNameText(view, text)
    for _, layer in ipairs(view.nameLayers) do
        layer:SetText(text)
    end
end

local function createBorder(frame, thickness, color)
    thickness = thickness or Config.borderThickness
    color = color or Config.colors.border
    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local border = frame:CreateTexture(nil, "OVERLAY")
        border:SetColorTexture(color[1], color[2], color[3], color[4])

        if edge == "TOP" or edge == "BOTTOM" then
            border:SetHeight(thickness)
            border:SetPoint(edge .. "LEFT", frame, edge .. "LEFT")
            border:SetPoint(edge .. "RIGHT", frame, edge .. "RIGHT")
        else
            border:SetWidth(thickness)
            border:SetPoint("TOP" .. edge, frame, "TOP" .. edge)
            border:SetPoint("BOTTOM" .. edge, frame, "BOTTOM" .. edge)
        end
    end
end

local function createSelectionBorder(healthBar, thickness)
    local indicator = CreateFrame("Frame", nil, healthBar)

    indicator:SetAllPoints(healthBar)
    indicator:SetFrameLevel(healthBar:GetFrameLevel() + 3)
    createBorder(
        indicator,
        thickness,
        Config.colors.target
    )
    indicator:Hide()

    return indicator
end

local function createTargetIndicator(healthBar)
    local indicator = createSelectionBorder(
        healthBar,
        Config.targetBorderThickness
    )
    local color = Config.colors.target

    local arrowLayout = TargetIndicator:GetArrowLayout(
        Config.healthHeight,
        Config.targetArrowScale,
        Config.targetArrowX,
        Config.targetArrowWidthScale,
        Config.targetArrowHeightScale
    )
    local arrowAnchors = TargetIndicator:GetArrowAnchors(arrowLayout.offset)

    indicator.leftArrow = indicator:CreateTexture(nil, "OVERLAY")
    indicator.leftArrow:SetTexture(Config.targetArrowTexture)
    indicator.leftArrow:SetBlendMode("ADD")
    indicator.leftArrow:SetTexCoord(0, 1, 0, 1)
    indicator.leftArrow:SetSize(arrowLayout.width, arrowLayout.height)
    indicator.leftArrow:SetVertexColor(
        color[1],
        color[2],
        color[3],
        color[4]
    )
    indicator.leftArrow:SetPoint(
        arrowAnchors.left.point,
        healthBar,
        arrowAnchors.left.relativePoint,
        arrowAnchors.left.x,
        0
    )

    indicator.rightArrow = indicator:CreateTexture(nil, "OVERLAY")
    indicator.rightArrow:SetTexture(Config.targetArrowTexture)
    indicator.rightArrow:SetBlendMode("ADD")
    indicator.rightArrow:SetTexCoord(1, 0, 0, 1)
    indicator.rightArrow:SetSize(arrowLayout.width, arrowLayout.height)
    indicator.rightArrow:SetVertexColor(
        color[1],
        color[2],
        color[3],
        color[4]
    )
    indicator.rightArrow:SetPoint(
        arrowAnchors.right.point,
        healthBar,
        arrowAnchors.right.relativePoint,
        arrowAnchors.right.x,
        0
    )
    return indicator
end

local function createRaidTargetIndicator(healthBar)
    local layout = RaidTargetIndicator:GetLayout()
    local indicator = CreateFrame("Frame", nil, healthBar)

    indicator:SetAllPoints(healthBar)
    indicator:SetFrameLevel(healthBar:GetFrameLevel() + 4)

    local icon = indicator:CreateTexture(nil, "OVERLAY")

    icon:SetTexture(layout.texture)
    icon:SetSize(layout.size, layout.size)
    icon:SetPoint(
        layout.point,
        healthBar,
        layout.relativePoint,
        layout.x,
        layout.y
    )
    icon:Hide()

    return icon
end

local function createAuraLayer(healthBar, anchor, frameStrata, frameLevel)
    local layer = CreateFrame("Frame", nil, UIParent)

    layer:SetFrameStrata(frameStrata)
    layer:SetFrameLevel(frameLevel)
    if layer.SetIgnoreParentScale then
        layer:SetIgnoreParentScale(true)
    end
    layer:SetScale(Config.scale)
    layer:SetSize(1, 1)
    layer:SetPoint(
        anchor.layerPoint,
        healthBar,
        anchor.platePoint,
        anchor.x,
        anchor.y
    )

    return layer
end

local function applyHealthLayerLevels(view)
    local levels = FrameLayout:GetHealthLayerLevels(view:GetFrameLevel())

    view.emptyBar:SetFrameLevel(levels.empty)
    view.health:SetFrameLevel(levels.health)
    view.absorbBar:SetFrameLevel(levels.absorb)
    view.healthForeground:SetFrameLevel(levels.foreground)
end

local function createAbsorbCalculator()
    if not CreateUnitHealPredictionCalculator then
        return nil
    end

    local calculator = CreateUnitHealPredictionCalculator()

    calculator:SetMaximumHealthMode(
        Enum.UnitMaximumHealthMode[Config.absorbMaximumHealthMode]
    )
    calculator:SetDamageAbsorbClampMode(
        Enum.UnitDamageAbsorbClampMode.MaximumHealth
    )

    return calculator
end

local function createHealthMarkerAlphaCurve()
    local curve = C_CurveUtil.CreateCurve()

    curve:SetType(Enum.LuaCurveType.Step)

    for _, point in ipairs(
        FrameLayout:GetHealthMarkerAlphaCurvePoints()
    ) do
        curve:AddPoint(point.x, point.y)
    end

    return curve
end

local function createHealthLayers(
    view,
    width,
    height,
    outlineThickness,
    healthInset,
    absorbInset
)
    local healthDimensions = FrameLayout:GetHealthDimensions(
        width,
        height,
        healthInset,
        Config.healthRightExtension
    )
    local absorbDimensions = FrameLayout:GetInsetDimensions(
        width,
        height,
        absorbInset
    )
    local absorbPlacement = FrameLayout:GetAbsorbPlacement()
    local markerPlacement = FrameLayout:GetHealthMarkerPlacement()

    view.emptyBar = CreateFrame("StatusBar", nil, view)
    view.emptyBar:SetSize(width, height)
    view.emptyBar:SetStatusBarTexture(Config.texture)
    view.emptyBar:SetMinMaxValues(0, 1)
    view.emptyBar:SetValue(1)
    view.emptyBar:SetClipsChildren(absorbPlacement.clipsChildren)
    setStatusBarColor(view.emptyBar, Config.colors.background)

    view.health = CreateFrame("StatusBar", nil, view)
    view.health:SetSize(healthDimensions.width, healthDimensions.height)
    view.health:SetStatusBarTexture(Config.texture)
    view.health:SetOrientation(Config.healthOrientation)
    view.health:SetReverseFill(Config.healthReverseFill)
    view.health:SetPoint(
        "LEFT",
        view.emptyBar,
        "LEFT",
        healthDimensions.leftInset,
        0
    )

    view.absorbBar = CreateFrame("StatusBar", nil, view.emptyBar)
    view.absorbBar:SetSize(absorbDimensions.width, absorbDimensions.height)
    view.absorbBar:SetStatusBarTexture(Config.absorbTexture)
    view.absorbBar:SetOrientation(Config.absorbOrientation)
    view.absorbBar:SetReverseFill(Config.absorbReverseFill)
    view.absorbBar:SetStatusBarColor(1, 1, 1, Config.absorbOpacity)
    view.absorbBar:SetMinMaxValues(0, 1)
    view.absorbBar:SetValue(0)
    view.absorbBar:SetPoint(
        absorbPlacement.point,
        view.health:GetStatusBarTexture(),
        absorbPlacement.relativePoint
    )
    view.absorbCalculator = createAbsorbCalculator()
    view.absorbInterpolation = Enum.StatusBarInterpolation.Immediate

    view.healthForeground = CreateFrame("Frame", nil, view)
    view.healthForeground:SetSize(width, height)

    view.healthMarker =
        view.healthForeground:CreateTexture(nil, "ARTWORK")
    view.healthMarker:SetSize(Config.healthMarkerWidth, healthDimensions.height)
    setTextureColor(view.healthMarker, Config.colors.healthMarker)
    view.healthMarker:SetPoint(
        markerPlacement.point,
        view.health:GetStatusBarTexture(),
        markerPlacement.relativePoint
    )
    view.healthMarkerAlphaCurve = createHealthMarkerAlphaCurve()
    view.healthMarker:Hide()

    createBorder(view.healthForeground, outlineThickness)
    applyHealthLayerLevels(view)
end

local function createPlateView(basePlate)
    local view = CreateFrame("Frame", nil, basePlate)
    local blizzardUnitFrame = basePlate.UnitFrame
    local blizzardFrameLevel = blizzardUnitFrame and
        blizzardUnitFrame:GetFrameLevel() or basePlate:GetFrameLevel()

    view:SetFrameStrata(
        blizzardUnitFrame and blizzardUnitFrame:GetFrameStrata() or
            basePlate:GetFrameStrata()
    )
    view:SetFrameLevel(FrameLayout:GetOverlayLevel(blizzardFrameLevel))
    if view.SetIgnoreParentScale then
        view:SetIgnoreParentScale(true)
    end
    view:SetScale(Config.scale)
    view:SetSize(Config.healthWidth, Config.healthHeight + Config.castHeight)
    view:SetPoint("CENTER", basePlate, "CENTER", 0, Config.plateOffsetY)

    createHealthLayers(
        view,
        Config.healthWidth,
        Config.healthHeight,
        Config.healthOutlineThickness,
        Config.healthInset,
        Config.absorbInset
    )
    view.emptyBar:SetPoint("TOP", view, "TOP")
    view.healthForeground:SetPoint("TOP", view, "TOP")
    view.health:SetClipsChildren(
        FrameLayout:ShouldClipHealthChildren()
    )

    view.targetIndicator = createTargetIndicator(view.healthForeground)
    view.hoverIndicator = createSelectionBorder(
        view.healthForeground,
        Config.hoverBorderThickness
    )
    view.raidTargetIcon = createRaidTargetIndicator(view.healthForeground)

    view.focusOverlay =
        view.healthForeground:CreateTexture(nil, "OVERLAY", nil, 2)
    view.focusOverlay:SetAllPoints(view.healthForeground)
    view.focusOverlay:SetTexture(Config.focusTexture)
    view.focusOverlay:SetVertexColor(
        Config.colors.focusOverlay[1],
        Config.colors.focusOverlay[2],
        Config.colors.focusOverlay[3],
        Config.colors.focusOverlay[4]
    )
    view.focusOverlay:SetAlpha(0)

    view.focusBorder = CreateFrame("Frame", nil, view.healthForeground)
    view.focusBorder:SetAllPoints(view.healthForeground)
    view.focusBorder:SetFrameLevel(
        view.healthForeground:GetFrameLevel() + 2
    )
    createBorder(
        view.focusBorder,
        Config.borderThickness,
        Config.colors.focus
    )
    view.focusBorder:Hide()

    local nameAnchor = FrameLayout:GetNameAnchor(Config.nameGap)
    local outlineOffsets = FrameLayout:GetNameOutlineOffsets(
        Config.nameOutlineThickness
    )

    view.nameLayers = {}

    for _, offset in ipairs(outlineOffsets) do
        local outline =
            view.healthForeground:CreateFontString(nil, "OVERLAY")

        outline:SetFont(
            Config.nameFont,
            Config.nameFontSize,
            Config.nameFontFlags
        )
        outline:SetTextColor(
            Config.nameOutlineColor[1],
            Config.nameOutlineColor[2],
            Config.nameOutlineColor[3],
            Config.nameOutlineColor[4]
        )
        outline:SetPoint(
            nameAnchor.point,
            view.healthForeground,
            nameAnchor.relativePoint,
            nameAnchor.x + offset.x,
            nameAnchor.y + offset.y
        )
        outline:SetHeight(Config.nameFontSize)
        outline:SetWidth(Config.healthWidth)
        outline:SetJustifyH("LEFT")
        table.insert(view.nameLayers, outline)
    end

    local boldOffset = FrameLayout:GetNameBoldOffset(
        Config.nameBoldOffset
    )

    view.nameBold =
        view.healthForeground:CreateFontString(nil, "OVERLAY")
    view.nameBold:SetFont(
        Config.nameFont,
        Config.nameFontSize,
        Config.nameFontFlags
    )
    view.nameBold:SetPoint(
        nameAnchor.point,
        view.healthForeground,
        nameAnchor.relativePoint,
        nameAnchor.x + boldOffset.x,
        nameAnchor.y + boldOffset.y
    )
    view.nameBold:SetHeight(Config.nameFontSize)
    view.nameBold:SetWidth(Config.healthWidth)
    view.nameBold:SetJustifyH("LEFT")
    table.insert(view.nameLayers, view.nameBold)

    view.name = view.healthForeground:CreateFontString(nil, "OVERLAY")
    view.name:SetFont(
        Config.nameFont,
        Config.nameFontSize,
        Config.nameFontFlags
    )

    view.name:SetPoint(
        nameAnchor.point,
        view.healthForeground,
        nameAnchor.relativePoint,
        nameAnchor.x,
        nameAnchor.y
    )
    view.name:SetHeight(Config.nameFontSize)
    view.name:SetWidth(Config.healthWidth)
    view.name:SetJustifyH("LEFT")
    table.insert(view.nameLayers, view.name)

    local healthTextAnchors = FrameLayout:GetHealthTextAnchors(
        Config.healthTextLeftPadding,
        Config.contentPadding,
        Config.healthTextBottomPadding
    )

    view.healthText = view.healthForeground:CreateFontString(nil, "OVERLAY")
    view.healthText:SetFont(
        Config.healthFont,
        Config.healthFontSize,
        Config.expresswayFontFlags
    )
    view.healthText:SetPoint(
        healthTextAnchors.health.point,
        view.healthForeground,
        healthTextAnchors.health.relativePoint,
        healthTextAnchors.health.x,
        healthTextAnchors.health.y
    )
    view.healthText:SetHeight(
        Config.healthHeight - Config.contentPadding * 2
    )
    view.healthPercentage =
        view.healthForeground:CreateFontString(nil, "OVERLAY")
    view.healthPercentage:SetFont(
        Config.healthFont,
        Config.healthFontSize,
        Config.expresswayFontFlags
    )
    view.healthPercentage:SetPoint(
        healthTextAnchors.percentage.point,
        view.healthForeground,
        healthTextAnchors.percentage.relativePoint,
        healthTextAnchors.percentage.x,
        healthTextAnchors.percentage.y
    )
    view.healthPercentage:SetHeight(
        Config.healthHeight - Config.contentPadding * 2
    )
    view.cast = CreateFrame("StatusBar", nil, view)
    view.cast:SetSize(Config.healthWidth, Config.castHeight)
    view.cast:SetPoint(
        "TOP",
        view.healthForeground,
        "BOTTOM",
        0,
        -Config.castGap
    )
    view.cast:SetStatusBarTexture(Config.texture)
    view.cast:SetClipsChildren(true)
    view.cast:Hide()

    view.castBackground = view.cast:CreateTexture(nil, "BACKGROUND")
    view.castBackground:SetAllPoints()
    setTextureColor(view.castBackground, Config.colors.background)

    view.interruptMarkerTrack = CreateFrame("StatusBar", nil, view.cast)
    view.interruptMarkerTrack:SetAllPoints(view.cast)
    view.interruptMarkerTrack:SetFrameLevel(view.cast:GetFrameLevel() + 1)
    view.interruptMarkerTrack:SetStatusBarTexture(Config.texture)
    view.interruptMarkerTrack:SetStatusBarColor(0, 0, 0, 0)
    view.interruptMarkerTrack:SetReverseFill(false)

    view.castForeground = CreateFrame("Frame", nil, view.cast)
    view.castForeground:SetAllPoints(view.cast)
    view.castForeground:SetFrameLevel(
        FrameLayout:GetCastForegroundLevel(view.cast:GetFrameLevel())
    )
    createBorder(view.castForeground)

    view.interruptMarkerClip = CreateFrame("Frame", nil, view.cast)
    view.interruptMarkerClip:SetSize(
        FrameLayout:GetInterruptMarkerClipWidth(
            Config.healthWidth,
            Config.castMarkerMaximumProgress,
            Config.castMarkerWidth
        ),
        Config.castHeight
    )
    view.interruptMarkerClip:SetPoint("LEFT", view.cast, "LEFT")
    view.interruptMarkerClip:SetClipsChildren(true)
    view.interruptMarkerClip:SetFrameLevel(
        FrameLayout:GetCastForegroundLevel(view.cast:GetFrameLevel())
    )

    view.interruptMarkerFrame =
        CreateFrame("Frame", nil, view.interruptMarkerClip)
    view.interruptMarkerFrame:SetSize(
        Config.castMarkerWidth,
        Config.castHeight
    )
    view.interruptMarkerFrame:SetFrameLevel(
        FrameLayout:GetCastMarkerLevel(view.cast:GetFrameLevel())
    )
    view.interruptMarker =
        view.interruptMarkerFrame:CreateTexture(nil, "OVERLAY")
    view.interruptMarker:SetAllPoints(view.interruptMarkerFrame)
    setTextureColor(view.interruptMarker, Config.colors.interruptMarker)

    view.castText = view.castForeground:CreateFontString(nil, "OVERLAY")
    view.castText:SetFont(
        Config.castFont,
        Config.castFontSize,
        Config.expresswayFontFlags
    )
    local castTextAnchor = FrameLayout:GetCastTextAnchor(
        Config.castTextLeftPadding,
        Config.castTextBottomPadding
    )
    view.castText:SetPoint(
        castTextAnchor.point,
        view.castForeground,
        castTextAnchor.relativePoint,
        castTextAnchor.x,
        castTextAnchor.y
    )
    view.castText:SetWidth(90)
    view.castText:SetJustifyH("LEFT")

    view.castTime = view.castForeground:CreateFontString(nil, "OVERLAY")
    view.castTime:SetFont(
        Config.castFont,
        Config.castFontSize,
        Config.expresswayFontFlags
    )
    local castTimeAnchor = FrameLayout:GetCastTimeAnchor(
        Config.castTimeRightPadding,
        Config.castTimeBottomPadding
    )
    view.castTime:SetPoint(
        castTimeAnchor.point,
        view.castForeground,
        castTimeAnchor.relativePoint,
        castTimeAnchor.x,
        castTimeAnchor.y
    )

    view.castIconFrame = CreateFrame("Frame", nil, view)
    view.castIconFrame:SetSize(Config.castIconSize, Config.castIconSize)
    view.castIconFrame:SetPoint(
        "RIGHT",
        view.cast,
        "LEFT",
        -Config.castIconGap,
        0
    )
    view.castIconFrame:SetFrameLevel(
        FrameLayout:GetCastForegroundLevel(view.cast:GetFrameLevel())
    )
    view.castIcon = view.castIconFrame:CreateTexture(nil, "ARTWORK")
    view.castIcon:SetAllPoints(view.castIconFrame)
    createBorder(view.castIconFrame)
    view.castIconFrame:Hide()

    if C_DurationUtil and C_StringUtil then
        view.castTimeBinding = C_DurationUtil.CreateDurationTextBinding()
        view.castTimeBinding:SetFontString(view.castTime)
        view.castTimeBinding:SetFormatter(Runtime.castTimeFormatter)
        view.castTimeBinding:SetExpiredText("")
        view.castTimeBinding:SetZeroDurationText("")
        view.castTimeBinding:SetUpdateInterval(0.05)
        view.castTimeBinding:SetEnabled(true)

    end

    local debuffLayout = AuraDisplay:GetDebuffLayout(Config)
    local auraAnchor = AuraDisplay:GetAnchorLayout()

    view.auraAnchor = auraAnchor
    view.auraLayer = createAuraLayer(
        view.healthForeground,
        auraAnchor,
        FrameLayout:GetAuraStrata(),
        FrameLayout:GetAuraLevel()
    )

    local arrowLayout = TargetIndicator:GetArrowLayout(
        Config.healthHeight,
        Config.targetArrowScale,
        Config.targetArrowX,
        Config.targetArrowWidthScale,
        Config.targetArrowHeightScale
    )

    view.importantBuffAnchor = AuraDisplay:GetImportantBuffAnchorLayout(
        Config.auraIconSpacing,
        arrowLayout.width
    )
    view.importantBuffLayer = createAuraLayer(
        view.healthForeground,
        view.importantBuffAnchor,
        view.healthForeground:GetFrameStrata(),
        view.healthForeground:GetFrameLevel() + 10
    )
    view.auras = {}

    if not supportsNativeAuraContainers() then
        for index = 1, Config.auraMaxCount do
            local aura = CreateFrame("Frame", nil, view.auraLayer)

            aura:SetSize(debuffLayout.iconSize, debuffLayout.iconSize)
            aura:SetPoint(
                auraAnchor.itemPoint,
                view.auraLayer,
                auraAnchor.itemPoint,
                (index - 1) *
                    (debuffLayout.iconSize + debuffLayout.iconSpacing) *
                    auraAnchor.horizontalStep,
                0
            )
            aura.icon = aura:CreateTexture(nil, "ARTWORK")
            aura.icon:SetAllPoints()
            aura.count = aura:CreateFontString(nil, "OVERLAY")
            aura.count:SetFont(
                Config.font,
                debuffLayout.fontSize,
                "OUTLINE"
            )
            aura.count:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT")
            aura:Hide()
            view.auras[index] = aura
        end
    end

    return view
end

function Runtime:SetCastingPlate(unit, view, isCasting)
    if isCasting then
        self.castingPlates[unit] = view
        return
    end

    self.castingPlates[unit] = nil
end

function Runtime:AcquirePlateView(basePlate, factory)
    local view = basePlate.BetterNamePlatesView

    if view then
        return view, false
    end

    view = factory(basePlate)
    basePlate.BetterNamePlatesView = view

    return view, true
end

function Runtime:PreparePlateView(view, unit, basePlate)
    view:SetParent(basePlate)
    view:Show()
    view.auraLayer:Show()
    view.importantBuffLayer:Show()
    view.unit = unit
    view.basePlate = basePlate
    view.blizzardUnitFrame = basePlate.UnitFrame
    view.castDuration = nil
    view.interruptCooldown = nil
    view.isChannel = nil
    view.markerInterruptible = nil
    view.identity = nil
    view.identityNameApplied = nil
    view.cast:Hide()
    view.castIconFrame:Hide()
    view.interruptMarkerFrame:Hide()
end

function Runtime:GetPlateIdentity(view, builder)
    if not view.identity then
        view.identity = builder()
    end

    return view.identity
end

local function initializeAuraButton(
    auraButton,
    border,
    iconSize,
    interaction,
    fontSize,
    textPresentation
)
    iconSize = iconSize or Config.auraIconSize
    fontSize = fontSize or Config.auraFontSize
    auraButton:SetSize(iconSize, iconSize)
    interaction = interaction or {
        enableMouse = AuraDisplay:ShouldEnableMouse(),
        enableClicks = AuraDisplay:ShouldEnableMouse(),
        hideTooltipInCombat = AuraDisplay:ShouldHideTooltipInCombat(),
    }

    auraButton:EnableMouse(interaction.enableMouse)
    auraButton:EnableMouseMotion(interaction.enableMouse)
    auraButton:SetMouseClickEnabled(interaction.enableClicks)
    auraButton:SetMouseMotionEnabled(interaction.enableMouse)
    auraButton:SetHideTooltipInCombat(
        interaction.hideTooltipInCombat
    )
    if interaction.tooltipAnchor then
        auraButton:SetTooltipAnchorPoint(
            interaction.tooltipAnchor,
            0,
            0
        )
    end

    auraButton.icon = auraButton:CreateTexture(nil, "ARTWORK")
    auraButton.icon:SetAllPoints(auraButton)
    auraButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    auraButton:SetIcon(auraButton.icon)

    auraButton.cooldown = CreateFrame(
        "Cooldown",
        nil,
        auraButton,
        "CooldownFrameTemplate"
    )
    auraButton.cooldown:SetAllPoints(auraButton)
    auraButton.cooldown:SetDrawBling(false)
    auraButton.cooldown:SetDrawEdge(false)
    auraButton.cooldown:SetHideCountdownNumbers(true)
    auraButton.cooldown:SetReverse(
        AuraDisplay:ShouldReverseCooldown()
    )
    auraButton:SetDurationCooldown(auraButton.cooldown)

    textPresentation = textPresentation or {}
    local textParent = auraButton

    if textPresentation.aboveSwipe then
        auraButton.bnpTextOverlay = CreateFrame("Frame", nil, auraButton)
        auraButton.bnpTextOverlay:SetAllPoints(auraButton)
        auraButton.bnpTextOverlay:SetFrameLevel(
            AuraDisplay:GetTextOverlayFrameLevel(
                auraButton.cooldown:GetFrameLevel()
            )
        )
        textParent = auraButton.bnpTextOverlay
    end

    local textColor = textPresentation.color or Config.colors.auraTimer
    local textFont = textPresentation.font or Config.font
    local textFontFlags = textPresentation.fontFlags or "OUTLINE"

    auraButton.durationText = textParent:CreateFontString(nil, "OVERLAY")
    auraButton.durationText:SetFont(
        textFont,
        fontSize,
        textFontFlags
    )
    auraButton.durationText:SetPoint("CENTER", auraButton, "CENTER")
    auraButton.durationText:SetTextColor(
        textColor[1],
        textColor[2],
        textColor[3],
        textColor[4]
    )
    auraButton:SetDurationText(auraButton.durationText, {
        textFormatter = Runtime.auraTimeFormatter,
    })

    auraButton.countText = textParent:CreateFontString(nil, "OVERLAY")
    auraButton.countText:SetFont(
        Config.font,
        fontSize,
        "OUTLINE"
    )
    auraButton.countText:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT")
    auraButton:SetApplicationCount(auraButton.countText)
    border = border or {}
    createBorder(auraButton, border.thickness, border.color)
end

local function initializeDebuffButton(auraButton)
    local layout = AuraDisplay:GetDebuffLayout(Config)
    local textPresentation =
        AuraDisplay:GetBoldTimerPresentation(Config)

    textPresentation.aboveSwipe = true
    textPresentation.color = Config.colors.debuffTimer

    initializeAuraButton(
        auraButton,
        nil,
        layout.iconSize,
        nil,
        layout.fontSize,
        textPresentation
    )
end

local function initializeImportantBuffButton(auraButton)
    initializeAuraButton(
        auraButton,
        AuraDisplay:GetImportantBuffBorder(),
        AuraDisplay:GetImportantBuffIconSize(Config.auraIconSize),
        AuraDisplay:GetImportantBuffInteraction()
    )
end

function Runtime:GetHiddenBlizzardFrame()
    if not self.hiddenBlizzardFrame then
        self.hiddenBlizzardFrame = CreateFrame("Frame")
        self.hiddenBlizzardFrame:Hide()
    end

    return self.hiddenBlizzardFrame
end

local function initializePurgeableBuffButton(auraButton)
    initializeAuraButton(
        auraButton,
        AuraDisplay:GetPurgeableBuffBorder(),
        AuraDisplay:GetImportantBuffIconSize(Config.auraIconSize),
        AuraDisplay:GetImportantBuffInteraction(),
        nil,
        AuraDisplay:GetBoldTimerPresentation(Config)
    )
end

local function createNativeAuraContainer(
    layer,
    anchor,
    unit,
    groups,
    maximumLineSize
)
    local container = CreateFrame(
        "AuraContainer",
        nil,
        layer,
        "CustomAuraContainerTemplate"
    )

    container:SetFrameLevel(layer:GetFrameLevel())
    container:SetSize(1, 1)
    container:SetPoint(
        anchor.itemPoint,
        layer,
        anchor.itemPoint,
        0,
        0
    )

    for _, group in ipairs(groups) do
        local options = AuraDisplay:GetGroupOptions({
            iconSize = group.iconSize or Config.auraIconSize,
            iconSpacing = group.iconSpacing or Config.auraIconSpacing,
            maxCount = Config.auraMaxCount,
        })

        if not group.excludeSpellIDs then
            options.candidateFilters = nil
        end
        options.sortMethod = AuraContainerSortMethod.Expiration
        options.sortDirection = AuraContainerSortDirection.Normal
        options.initializeFrame =
            group.initializeFrame or initializeAuraButton

        container:AddAuraGroup(group.key, group.filter, options)
        container:SetAuraGroupLayout(group.key, options.layout)
    end

    container:SetFlowLayoutAnchorPoint(anchor.itemPoint)
    container:SetFlowLayoutGrowthDirection(
        AnchorUtil.FlowDirection[anchor.flowDirection],
        AnchorUtil.FlowDirection.Up
    )
    container:SetFlowLayoutMaximumLineSize(maximumLineSize)
    container:SetEnabled(true)
    container:SetUnit(unit)

    return container
end

local function createNativeAuraContainers(view, unit)
    if not supportsNativeAuraContainers() then
        return
    end

    if view.auraContainer and view.importantBuffContainer then
        view.auraContainer:SetUnit(unit)
        view.auraContainer:SetEnabled(true)
        view.importantBuffContainer:SetUnit(unit)
        view.importantBuffContainer:SetEnabled(true)
        return
    end

    local debuffLayout = AuraDisplay:GetDebuffLayout(Config)
    local groupOptions = {
        iconSize = debuffLayout.iconSize,
        iconSpacing = debuffLayout.iconSpacing,
        maxCount = Config.auraMaxCount,
    }
    local debuffOptions = AuraDisplay:GetGroupOptions(groupOptions)

    view.auraContainer = createNativeAuraContainer(
        view.auraLayer,
        view.auraAnchor,
        unit,
        {{
            key = "playerDebuffs",
            filter = AuraDisplay:GetFilter(),
            excludeSpellIDs = true,
            iconSize = debuffLayout.iconSize,
            iconSpacing = debuffLayout.iconSpacing,
            initializeFrame = initializeDebuffButton,
        }},
        debuffOptions.layout.maximumLineSize
    )

    local importantBuffIconSize =
        AuraDisplay:GetImportantBuffIconSize(Config.auraIconSize)
    local rightAuraGroups = {}

    for index, group in ipairs(AuraDisplay:GetRightAuraGroups()) do
        local initializeFrame = initializeImportantBuffButton

        if group.key == "purgeableBuffs" then
            initializeFrame = initializePurgeableBuffButton
        end

        rightAuraGroups[index] = {
            key = group.key,
            filter = group.filter,
            iconSize = importantBuffIconSize,
            initializeFrame = initializeFrame,
        }
    end

    local importantBuffOptions = {
        iconSize = importantBuffIconSize,
        iconSpacing = Config.auraIconSpacing,
        maxCount = Config.auraMaxCount,
    }

    view.importantBuffContainer = createNativeAuraContainer(
        view.importantBuffLayer,
        view.importantBuffAnchor,
        unit,
        rightAuraGroups,
        AuraDisplay:GetRightAuraMaximumLineSize(importantBuffOptions)
    )
end

function Runtime:RefreshInterruptSpell()
    local classID = select(3, UnitClass("player"))

    self.interruptSpellID = Interrupts:FindKnownSpell(
        classID,
        function(spellID, bank)
            if not C_SpellBook then
                return false
            end

            if bank == "pet" then
                local petBank = Enum.SpellBookSpellBank.Pet

                return C_SpellBook.IsSpellKnown(spellID, petBank)
            end

            if C_SpellBook.IsSpellKnown(spellID) then
                return true
            end

            return spellID == 132409 and
                C_SpellBook.IsSpellKnownOrInSpellBook and
                C_SpellBook.IsSpellKnownOrInSpellBook(spellID)
        end
    )
end

function Runtime:GetInterruptCooldown()
    if not self.interruptSpellID or not C_Spell then
        return nil
    end

    if C_Spell.GetSpellCooldownDuration then
        return C_Spell.GetSpellCooldownDuration(
            self.interruptSpellID,
            true
        )
    end

    return nil
end

function Runtime:UpdateAuras(unit)
    local view = self.activePlates[unit]

    if not view or not C_UnitAuras then
        return
    end

    if view.auraContainer then
        return
    end

    local inCombat = InCombatLockdown and InCombatLockdown()

    if not CombatState:CanReadAuras(inCombat) then
        for _, aura in ipairs(view.auras) do
            aura:Hide()
        end

        return
    end

    local shown = 0

    for _, filter in ipairs({"HELPFUL", "HARMFUL"}) do
        for index = 1, 40 do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)

            if not auraData then
                break
            end

            if Rules:GetAura(auraData.spellId) and shown < #view.auras then
                shown = shown + 1
                local aura = view.auras[shown]
                aura.icon:SetTexture(auraData.icon)
                aura.count:SetText(
                    auraData.applications > 1 and auraData.applications or ""
                )
                aura:Show()
            end
        end
    end

    for index = shown + 1, #view.auras do
        view.auras[index]:Hide()
    end
end

local function evaluateColorBoolean(value, trueColor, falseColor)
    return
        C_CurveUtil.EvaluateColorValueFromBoolean(
            value,
            trueColor[1],
            falseColor[1]
        ),
        C_CurveUtil.EvaluateColorValueFromBoolean(
            value,
            trueColor[2],
            falseColor[2]
        ),
        C_CurveUtil.EvaluateColorValueFromBoolean(
            value,
            trueColor[3],
            falseColor[3]
        )
end

local function updateCastVisual(view, duration, cooldown)
    local readyColor = Config.colors.interruptReadyCast
    local unavailableColor = Config.colors.interruptUnavailableCast
    local protectedColor = Config.colors.protectedCast

    if not cooldown then
        local red, green, blue = evaluateColorBoolean(
            view.castNotInterruptible,
            protectedColor,
            unavailableColor
        )
        local backgroundRed, backgroundGreen, backgroundBlue =
            evaluateColorBoolean(
                view.castNotInterruptible,
                Config.colors.background,
                unavailableColor
            )

        view.cast:SetStatusBarColor(red, green, blue, 1)
        view.castBackground:SetVertexColor(
            backgroundRed,
            backgroundGreen,
            backgroundBlue,
            1
        )
        view.interruptMarkerFrame:Hide()
        return
    end

    local cooldownReady = cooldown:IsZero()
    local activeRed, activeGreen, activeBlue = evaluateColorBoolean(
        cooldownReady,
        readyColor,
        unavailableColor
    )
    local castRed = C_CurveUtil.EvaluateColorValueFromBoolean(
        view.castNotInterruptible,
        protectedColor[1],
        activeRed
    )
    local castGreen = C_CurveUtil.EvaluateColorValueFromBoolean(
        view.castNotInterruptible,
        protectedColor[2],
        activeGreen
    )
    local castBlue = C_CurveUtil.EvaluateColorValueFromBoolean(
        view.castNotInterruptible,
        protectedColor[3],
        activeBlue
    )
    local backgroundRed, backgroundGreen, backgroundBlue =
        evaluateColorBoolean(
            view.castNotInterruptible,
            Config.colors.background,
            readyColor
        )

    view.cast:SetStatusBarColor(castRed, castGreen, castBlue, 1)
    view.castBackground:SetVertexColor(
        backgroundRed,
        backgroundGreen,
        backgroundBlue,
        1
    )

    local markerAlpha = C_CurveUtil.EvaluateColorValueFromBoolean(
        cooldownReady,
        0,
        1
    )
    markerAlpha = C_CurveUtil.EvaluateColorValueFromBoolean(
        view.castNotInterruptible,
        0,
        markerAlpha
    )
    view.interruptMarkerFrame:SetAlpha(markerAlpha)
    view.interruptMarkerFrame:Show()
end

function Runtime:RefreshCastCooldowns(refreshMarkers)
    for _, view in pairs(self.castingPlates) do
        if view.cast:IsShown() and view.castDuration then
            view.interruptCooldown = self:GetInterruptCooldown()

            if refreshMarkers and view.interruptCooldown then
                CastDuration:PlaceCooldownMarker(
                    view.interruptMarkerTrack,
                    view.castDuration:GetTotalDuration(),
                    view.interruptCooldown
                )
            end

            updateCastVisual(
                view,
                view.castDuration,
                view.interruptCooldown
            )
        end
    end
end

function Runtime:GetPlayerRole()
    if self.playerRole then
        return self.playerRole
    end

    local assignedRole = UnitGroupRolesAssigned("player")
    local specializationIndex = GetSpecialization()
    local specializationRole

    if specializationIndex then
        specializationRole = GetSpecializationRole(specializationIndex)
    end

    self.playerRole = CombatState:ResolvePlayerRole(
        assignedRole,
        specializationRole
    )

    return self.playerRole
end

function Runtime:RefreshPlayerRole()
    self.playerRole = nil

    return self:GetPlayerRole()
end

function Runtime:BuildPlateIdentity(unit)
    local classification = DisplayText:SafeValue(
        UnitClassification(unit),
        "normal"
    )
    local effectiveLevel = DisplayText:SafeValue(
        UnitEffectiveLevel(unit),
        nil
    )
    local rawPowerType, rawPowerToken = UnitPowerType(unit)
    local powerType = DisplayText:SafeValue(
        rawPowerType,
        nil
    )
    local powerToken = DisplayText:SafeValue(
        rawPowerToken,
        nil
    )
    local classBase = DisplayText:SafeValue(UnitClassBase(unit), nil)
    local isLieutenant = DisplayText:SafeValue(
        UnitIsLieutenant(unit),
        false
    )
    local profileColorKey = NpcClassification:GetColorKey({
        playerLevel = UnitLevel("player"),
        effectiveLevel = effectiveLevel,
        isLieutenant = isLieutenant,
        classBase = classBase,
        powerType = powerType,
        powerToken = powerToken,
        manaPowerType = Enum.PowerType.Mana,
        classification = classification,
    })
    local appearanceClassification = classification

    if profileColorKey == "boss" then
        appearanceClassification = "worldboss"
    elseif profileColorKey == "miniboss" then
        appearanceClassification = "rareelite"
    end

    return {
        appearanceClassification = appearanceClassification,
        isCaster = profileColorKey == "caster",
        name = DisplayText:ShortenName(UnitName(unit)),
    }
end

function Runtime:UpdateHealth(unit, shouldUpdateAppearance, shouldUpdateAbsorb)
    local view = self.activePlates[unit]

    if not view then
        return
    end

    local identity = self:GetPlateIdentity(view, function()
        return self:BuildPlateIdentity(unit)
    end)
    local health = UnitHealth(unit)
    local maximum = UnitHealthMax(unit)

    if not view.identityNameApplied then
        setNameText(view, identity.name)
        view.identityNameApplied = true
    end

    if shouldUpdateAppearance ~= false then
        local threatStatus = DisplayText:SafeValue(
            UnitThreatSituation("player", unit),
            nil
        )
        local reaction = DisplayText:SafeValue(
            UnitReaction(unit, "player"),
            nil
        )
        local threatState = CombatState:GetThreatState(
            self:GetPlayerRole(),
            threatStatus
        )
        local isIdleNeutral = CombatState:IsIdleNeutral(
            reaction,
            4,
            threatStatus
        )
        local colorKey = Appearance:GetHealthColorKey(
            identity.appearanceClassification,
            identity.isCaster,
            threatState,
            isIdleNeutral
        )

        setStatusBarColor(view.health, Config.colors[colorKey])
    end

    self:UpdateHealthValues(
        unit,
        view,
        health,
        maximum
    )

    if shouldUpdateAbsorb ~= false then
        self:UpdateAbsorbValues(unit, view)
    end
    view.healthMarker:SetAlpha(UnitHealthPercent(
        unit,
        true,
        view.healthMarkerAlphaCurve
    ))
    self:SetHealthText(
        view.healthText,
        HealthFormat:FormatHealth(health, AbbreviateNumbers)
    )

    if issecretvalue and
        (issecretvalue(health) or issecretvalue(maximum)) then
        local percentage = HealthFormat:GetRestrictedPercentage(
            unit,
            UnitHealthPercent,
            CurveConstants.ScaleTo100
        )

        self:SetHealthText(
            view.healthPercentage,
            HealthFormat:FormatRestrictedPercentage(percentage)
        )
    else
        self:SetHealthText(
            view.healthPercentage,
            HealthFormat:FormatPercentage(health, maximum)
        )
    end
end

function Runtime:UpdateCast(unit, event)
    local view = self.activePlates[unit]

    if not view then
        return
    end

    local name, _, textureID, _, _, _, _, notInterruptible =
        UnitCastingInfo(unit)
    local isChannel = false

    if not name then
        name, _, textureID, _, _, _, notInterruptible =
            UnitChannelInfo(unit)
        isChannel = name ~= nil
    end

    if not name then
        self:SetCastingPlate(unit, view, false)
        view.cast:Hide()
        view.castIconFrame:Hide()
        view.interruptMarkerFrame:Hide()
        return
    end

    view.markerInterruptible = CombatState:GetMarkerInterruptibility(
        event,
        view.markerInterruptible
    )
    view.isChannel = isChannel
    view.castNotInterruptible = notInterruptible
    view.castDuration = CastDuration:GetUnitDuration(
        unit,
        isChannel,
        UnitCastingDuration,
        UnitChannelDuration
    )

    if not view.castDuration then
        self:SetCastingPlate(unit, view, false)
        view.cast:Hide()
        return
    end

    view.cast:SetReverseFill(false)
    CastDuration:BindRemainingTime(
        view.cast,
        view.castDuration,
        Enum.StatusBarInterpolation.Immediate,
        CastDuration:GetTimerDirection(
            isChannel,
            Enum.StatusBarTimerDirection
        )
    )
    local cooldownOverlayLayout =
        CastDuration:GetCooldownOverlayLayout(isChannel)

    view.interruptMarkerFrame:ClearAllPoints()
    view.interruptMarkerTrack:SetReverseFill(
        cooldownOverlayLayout.reverseFill
    )
    view.interruptMarkerFrame:SetPoint(
        cooldownOverlayLayout.markerAnchor,
        view.interruptMarkerTrack:GetStatusBarTexture(),
        cooldownOverlayLayout.markerPoint
    )

    view.castText:SetText(name)
    view.castIcon:SetTexture(textureID)
    view.castIconFrame:Show()
    view.interruptCooldown = self:GetInterruptCooldown()

    if view.interruptCooldown and
        CastDuration:ShouldPlaceCooldownMarker(event) then
        CastDuration:PlaceCooldownMarker(
            view.interruptMarkerTrack,
            view.castDuration:GetTotalDuration(),
            view.interruptCooldown
        )
    end

    if view.castTimeBinding then
        view.castTimeBinding:SetDuration(view.castDuration)
    end

    updateCastVisual(
        view,
        view.castDuration,
        view.interruptCooldown
    )
    self:SetCastingPlate(unit, view, true)
    view.cast:Show()
    self:UpdateHealth(unit)
end

function Runtime:SetBlizzardFrameHidden(view, shouldHide)
    local unitFrame = view and view.blizzardUnitFrame

    if not unitFrame then
        return
    end

    if shouldHide then
        if view.blizzardAlpha == nil then
            view.blizzardAlpha = unitFrame:GetAlpha()
        end

        unitFrame:SetAlpha(0)
        return
    end

    unitFrame:SetAlpha(view.blizzardAlpha or 1)
end

function Runtime:UpdateAbsorbValues(unit, view)
    local calculator = view.absorbCalculator

    if not calculator or not UnitGetDetailedHealPrediction then
        return
    end

    UnitGetDetailedHealPrediction(unit, nil, calculator)
    view.absorbBar:SetMinMaxValues(0, calculator:GetMaximumHealth())
    view.absorbBar:SetValue(
        calculator:GetDamageAbsorbs(),
        view.absorbInterpolation
    )
end

function Runtime:UpdateHealthValues(unit, view, health, maximum)
    view.health:SetMinMaxValues(0, maximum)
    view.health:SetValue(health)
end

function Runtime:AddFriendlyPlate(unit, basePlate)
    local unitFrame = basePlate and basePlate.UnitFrame
    local name = unitFrame and unitFrame.name

    if not name then
        self.lastAddResult = "missing-friendly-name:" .. tostring(unit)
        return
    end

    local classBase = DisplayText:SafeValue(UnitClassBase(unit), nil)
    local classColor = classBase and RAID_CLASS_COLORS[classBase] or nil

    self.friendlyPlates[unit] = FriendlyNameStyle:Apply(
        basePlate,
        unitFrame,
        name:GetText(),
        classColor,
        self:GetHiddenBlizzardFrame()
    )
    self:RefreshUpdateDriver()
    self.lastAddResult = "friendly-player:" .. tostring(unit)
end

function Runtime:RemoveFriendlyPlate(unit)
    local view = self.friendlyPlates[unit]

    if not view then
        return false
    end

    FriendlyNameStyle:Restore(view)
    self.friendlyPlates[unit] = nil
    self:RefreshUpdateDriver()

    return true
end

function Runtime:AddPlate(unit)
    if self.activePlates[unit] or self.friendlyPlates[unit] then
        self.lastAddResult = "duplicate:" .. tostring(unit)
        return
    end

    local canAttack = UnitCanAttack("player", unit)

    if FriendlyNameStyle:ShouldStyle({
        isPlayer = UnitIsPlayer(unit),
        canAttack = canAttack,
    }) then
        local friendlyBasePlate = C_NamePlate.GetNamePlateForUnit(unit)

        self:AddFriendlyPlate(unit, friendlyBasePlate)
        return
    end

    if not canAttack then
        self.lastAddResult = "not-attackable:" .. tostring(unit)
        return
    end

    local basePlate = C_NamePlate.GetNamePlateForUnit(unit)

    if not basePlate then
        self.lastAddResult = "missing-frame:" .. tostring(unit)
        return
    end


    local classification = DisplayText:SafeValue(
        UnitClassification(unit),
        nil
    )
    local effectiveLevel = DisplayText:SafeValue(
        UnitEffectiveLevel(unit),
        nil
    )
    local isLieutenant = DisplayText:SafeValue(
        UnitIsLieutenant(unit),
        false
    )

    if not NpcClassification:ShouldShowNameplate({
        classification = classification,
        effectiveLevel = effectiveLevel,
        isLieutenant = isLieutenant,
        playerLevel = UnitLevel("player"),
    }) then
        self.lastAddResult = "filtered:" .. tostring(unit)
        return
    end

    local view = self:AcquirePlateView(basePlate, createPlateView)

    self:PreparePlateView(view, unit, basePlate)

    if Config.hideBlizzardFrame then
        self:SetBlizzardFrameHidden(view, true)
    end

    self.activePlates[unit] = view
    NameplateStacking:ApplyBounds(basePlate, view)
    createNativeAuraContainers(view, unit)
    self.lastAddResult = "added:" .. tostring(unit)

    self:UpdateSelectionIndicator(unit, view)
    self:UpdateRaidTarget(unit)
    self:UpdateHealth(unit)
    self:UpdateCast(unit)
    self:UpdateAuras(unit)
    self:RefreshUpdateDriver()
end

function Runtime:UpdateRaidTarget(unit)
    local view = self.activePlates[unit]

    if not view then
        return
    end

    local markerIndex = GetRaidTargetIndex(unit)

    RaidTargetIndicator:Apply(
        view.raidTargetIcon,
        markerIndex,
        SetRaidTargetIconTexture
    )
end

function Runtime:RefreshRaidTargets()
    for unit in pairs(self.activePlates) do
        self:UpdateRaidTarget(unit)
    end
end

function Runtime:GetDebugState()
    local activePlateCount = 0

    for _ in pairs(self.activePlates) do
        activePlateCount = activePlateCount + 1
    end

    return {
        activePlateCount = activePlateCount,
        lastAddResult = self.lastAddResult or "none",
    }
end

function Runtime:DebugForceTargetAbsorb()
    for unit, view in pairs(self.activePlates) do
        local isTarget = DisplayText:SafeValue(
            UnitIsUnit(unit, "target"),
            false
        )

        if isTarget then
            view.absorbBar:SetMinMaxValues(0, 1)
            view.absorbBar:SetValue(1)
            return true
        end
    end

    return false
end

function Runtime:ApplyTargetHealthHeight(view, isTarget)
    local height = FrameLayout:GetTargetHealthHeight(
        Config.healthHeight,
        Config.targetHealthScale,
        isTarget
    )

    if view.healthSectionHeight == height then
        return
    end

    local healthHeight = height - Config.healthInset * 2
    local absorbHeight = height - Config.absorbInset * 2
    local textHeight = height - Config.contentPadding * 2
    local regularArrowLayout = TargetIndicator:GetArrowLayout(
        Config.healthHeight,
        Config.targetArrowScale,
        Config.targetArrowX,
        Config.targetArrowWidthScale,
        Config.targetArrowHeightScale
    )
    local arrowHeight = isTarget and height or regularArrowLayout.height

    view:SetHeight(height + Config.castHeight)
    view.emptyBar:SetHeight(height)
    view.health:SetHeight(healthHeight)
    view.absorbBar:SetHeight(absorbHeight)
    view.healthForeground:SetHeight(height)
    view.healthMarker:SetHeight(healthHeight)
    view.healthText:SetHeight(textHeight)
    view.healthPercentage:SetHeight(textHeight)
    view.targetIndicator.leftArrow:SetHeight(arrowHeight)
    view.targetIndicator.rightArrow:SetHeight(arrowHeight)
    view.healthSectionHeight = height
end

function Runtime:UpdateSelectionIndicator(plateUnit, view)
    local isTarget = DisplayText:SafeValue(
        UnitIsUnit(plateUnit, "target"),
        false
    )
    local isMouseover = DisplayText:SafeValue(
        UnitIsUnit(plateUnit, "mouseover"),
        false
    )
    local isFocus = DisplayText:SafeValue(
        UnitIsUnit(plateUnit, "focus"),
        false
    )
    local focusStyle = Appearance:GetFocusStyle(isFocus, isTarget)

    self:ApplyTargetHealthHeight(view, isTarget)
    view:SetAlpha(focusStyle.alpha)
    view.focusOverlay:SetAlpha(focusStyle.overlayAlpha)
    view.focusBorder:SetShown(
        focusStyle.borderColorKey == "focus"
    )
    view.health:GetStatusBarTexture():SetDesaturated(
        focusStyle.desaturated
    )
    view.targetIndicator:SetShown(
        TargetIndicator:ShouldShow(isTarget)
    )
    view.healthMarker:SetShown(
        FrameLayout:ShouldShowHealthMarker(isTarget)
    )
    view.hoverIndicator:SetShown(
        TargetIndicator:ShouldShowHover(isMouseover, isTarget)
    )
end

function Runtime:UpdateSelectionIndicators()
    for plateUnit, view in pairs(self.activePlates) do
        self:UpdateSelectionIndicator(plateUnit, view)
    end
end

function Runtime:UpdateHoverIndicators()
    for plateUnit, view in pairs(self.activePlates) do
        local isTarget = DisplayText:SafeValue(
            UnitIsUnit(plateUnit, "target"),
            false
        )
        local isMouseover = DisplayText:SafeValue(
            UnitIsUnit(plateUnit, "mouseover"),
            false
        )

        view.hoverIndicator:SetShown(
            TargetIndicator:ShouldShowHover(isMouseover, isTarget)
        )

        if Config.hideBlizzardFrame and view.blizzardUnitFrame and
            view.blizzardUnitFrame:GetAlpha() ~= 0 then
            view.blizzardUnitFrame:SetAlpha(0)
        end
    end
end

function Runtime:RemovePlate(unit)
    if self:RemoveFriendlyPlate(unit) then
        return
    end

    local view = self.activePlates[unit]

    if not view then
        return
    end

    view:Hide()
    self:SetCastingPlate(unit, view, false)

    if view.auraContainer then
        view.auraContainer:SetEnabled(false)
    end

    if view.importantBuffContainer then
        view.importantBuffContainer:SetEnabled(false)
    end

    view.auraLayer:Hide()
    view.importantBuffLayer:Hide()

    self:SetBlizzardFrameHidden(view, false)

    self.activePlates[unit] = nil
    self:RefreshUpdateDriver()
end

function Runtime:ReleaseAllPlates()
    local units = {}

    for unit in pairs(self.activePlates) do
        units[#units + 1] = unit
    end

    for unit in pairs(self.friendlyPlates) do
        units[#units + 1] = unit
    end

    for _, unit in ipairs(units) do
        self:RemovePlate(unit)
    end

    self.castingPlates = {}

end

function Runtime:ReleaseForLoadingScreen(collect)
    self:ReleaseAllPlates()
    collect()
end

function Runtime:OnUpdate(elapsed)
    local shouldRefreshHover

    shouldRefreshHover, self.hoverRefreshElapsed =
        self:AdvanceRefreshClock(
            self.hoverRefreshElapsed,
            elapsed,
            TargetIndicator:GetHoverRefreshInterval()
        )

    if shouldRefreshHover then
        self:UpdateHoverIndicators()
    end

end

function Runtime:OnEvent(event, unit, _, spellID)
    if event == "PLAYER_LEAVING_WORLD" then
        self:ReleaseForLoadingScreen(function()
            collectgarbage("collect")
        end)
        return
    end

    if NameplateStacking:ShouldApplyOnEvent(
        event,
        self.stackingPending
    ) then
        self.stackingPending = not NameplateStacking:Apply(
            SetCVar,
            InCombatLockdown and InCombatLockdown()
        )
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        self:AddPlate(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        self:RemovePlate(unit)
    elseif event == "UNIT_HEALTH" then
        self:UpdateHealth(unit, false, false)
    elseif event == "UNIT_MAXHEALTH" then
        self:UpdateHealth(unit, false, true)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        local view = self.activePlates[unit]

        if view then
            self:UpdateAbsorbValues(unit, view)
        end
    elseif event == "UNIT_FACTION" or
        event == "UNIT_THREAT_SITUATION_UPDATE" then
        self:UpdateHealth(unit, true, false)
    elseif event == "UNIT_AURA" then
        self:UpdateAuras(unit)
    elseif event == "RAID_TARGET_UPDATE" then
        self:RefreshRaidTargets()
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or
        event == "PLAYER_ROLES_ASSIGNED" or
        event == "TRAIT_CONFIG_UPDATED" or event == "SPELLS_CHANGED" then
        self:RefreshPlayerRole()
        self:RefreshInterruptSpell()

        for plateUnit in pairs(self.activePlates) do
            self:UpdateCast(plateUnit)
        end
    elseif Interrupts:IsPlayerInterruptCast(
        event,
        unit,
        spellID,
        self.interruptSpellID
    ) then
        self.interruptMarkerRefreshPending = true
    elseif Interrupts:IsCooldownEvent(event) then
        local refreshMarkers = self.interruptMarkerRefreshPending

        self.interruptMarkerRefreshPending = false
        self:RefreshCastCooldowns(refreshMarkers)
    elseif event:find("UNIT_SPELLCAST", 1, true) == 1 then
        self:UpdateCast(unit, event)
    elseif event == "PLAYER_TARGET_CHANGED" or
        event == "PLAYER_FOCUS_CHANGED" or
        event == "UPDATE_MOUSEOVER_UNIT" then
        self:UpdateSelectionIndicators()
    end
end

function Runtime:GetEventRegistrationPlan(hasNativeAuras)
    local events = {
        "NAME_PLATE_UNIT_ADDED",
        "NAME_PLATE_UNIT_REMOVED",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_LEAVING_WORLD",
        "PLAYER_TARGET_CHANGED",
        "PLAYER_FOCUS_CHANGED",
        "PLAYER_REGEN_ENABLED",
        "RAID_TARGET_UPDATE",
        "UPDATE_MOUSEOVER_UNIT",
        "PLAYER_SPECIALIZATION_CHANGED",
        "PLAYER_ROLES_ASSIGNED",
        "SPELL_UPDATE_COOLDOWN",
        "TRAIT_CONFIG_UPDATED",
        "SPELLS_CHANGED",
        "UNIT_HEALTH",
        "UNIT_MAXHEALTH",
        "UNIT_ABSORB_AMOUNT_CHANGED",
        "UNIT_FACTION",
        "UNIT_THREAT_SITUATION_UPDATE",
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTIBLE",
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
    }

    if not hasNativeAuras then
        events[#events + 1] = "UNIT_AURA"
    end

    return {
        events = events,
        playerEvents = {
            UNIT_SPELLCAST_SUCCEEDED = true,
        },
    }
end

function Runtime:Enable()
    if self.frame then
        return
    end

    self.stackingPending = not NameplateStacking:Apply(
        SetCVar,
        InCombatLockdown and InCombatLockdown()
    )
    self.castTimeFormatter = C_StringUtil.CreateNumericRuleFormatter()
    self.castTimeFormatter:AddBreakpoint(
        CastDuration:GetTimeBreakpoint()
    )
    self.auraTimeFormatter = C_StringUtil.CreateNumericRuleFormatter()
    self.auraTimeFormatter:AddBreakpoint(
        AuraDisplay:GetDurationBreakpoint()
    )
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event, ...)
        self:OnEvent(event, ...)
    end)
    self.onUpdateHandler = function(_, elapsed)
        self:OnUpdate(elapsed)
    end

    local registrationPlan = self:GetEventRegistrationPlan(
        supportsNativeAuraContainers()
    )

    for _, event in ipairs(registrationPlan.events) do
        self.frame:RegisterEvent(event)
    end

    for event in pairs(registrationPlan.playerEvents) do
        self.frame:RegisterUnitEvent(event, "player")
    end

    self:RefreshPlayerRole()
    self:RefreshInterruptSpell()

    for _, basePlate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = basePlate.namePlateUnitToken

        if unit then
            self:AddPlate(unit)
        end
    end

    self:RefreshUpdateDriver()
end

function Runtime:Disable()
    if not self.frame then
        return
    end

    self.frame:UnregisterAllEvents()
    self.frame:SetScript("OnUpdate", nil)
    self.frame = nil
    self.onUpdateHandler = nil
    self.interruptSpellID = nil
    self.interruptMarkerRefreshPending = nil
    self.stackingPending = nil
    self.hoverRefreshElapsed = nil
    self.castTimeFormatter = nil
    self.auraTimeFormatter = nil
    self:ReleaseAllPlates()
    self.hiddenBlizzardFrame = nil

end

namespace.Runtime = Runtime

return Runtime
