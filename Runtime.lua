local _, namespace = ...

local Config = namespace.Config
local AbsorbPrediction = namespace.AbsorbPrediction
local Appearance = namespace.Appearance
local AuraDisplay = namespace.AuraDisplay
local CastDuration = namespace.CastDuration
local CombatState = namespace.CombatState
local DisplayText = namespace.DisplayText
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
    activeCasts = {},
    lightweightPlates = {},
    lightweightPool = {},
}

function Runtime:AdvanceRefreshClock(current, elapsed, interval)
    local accumulated = (current or 0) + elapsed

    if accumulated >= interval then
        return true, accumulated - interval
    end

    return false, accumulated
end

function Runtime:CreateAbsorbUpdateApi()
    return {
        predict = UnitGetDetailedHealPrediction,
        enums = {
            defaultMaximumHealth =
                Enum.UnitMaximumHealthMode.Default,
            maximumHealthClamp =
                Enum.UnitDamageAbsorbClampMode.MaximumHealth,
            missingHealthClamp = Enum.UnitDamageAbsorbClampMode
                .MissingHealthWithoutIncomingHeals,
            immediate = Enum.StatusBarInterpolation.Immediate,
        },
    }
end

function Runtime:SetCastActive(unit, view, isActive)
    if isActive then
        self.activeCasts[unit] = view
        return
    end

    self.activeCasts[unit] = nil
end

function Runtime:RefreshUpdateDriver()
    if not self.frame then
        return
    end

    local hasTrackedPlates = next(self.activePlates) or
        next(self.lightweightPlates)
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

local function createSelectionBorder(healthBar)
    local indicator = CreateFrame("Frame", nil, healthBar)

    indicator:SetAllPoints(healthBar)
    indicator:SetFrameLevel(healthBar:GetFrameLevel() + 3)
    createBorder(
        indicator,
        Config.targetBorderThickness,
        Config.colors.target
    )
    indicator:Hide()

    return indicator
end

local function createTargetIndicator(healthBar)
    local indicator = createSelectionBorder(healthBar)
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

local function createAbsorbPrediction(view, width)
    if not CreateUnitHealPredictionCalculator or
        not UnitGetDetailedHealPrediction then
        return
    end

    view.absorbCalculator = CreateUnitHealPredictionCalculator()
    view.absorbSnapshot = view.absorbSnapshot or {}
    view.absorbSnapshot.captured = nil
    view.absorbSnapshot.maximum = nil
    view.absorbClip = CreateFrame("Frame", nil, view.health)
    view.absorbClip:SetAllPoints(view.health)
    view.absorbClip:SetClipsChildren(true)
    view.absorbClip:SetFrameLevel(view.health:GetFrameLevel())

    view.absorb = CreateFrame("StatusBar", nil, view.absorbClip)
    view.absorb:SetFrameLevel(view.health:GetFrameLevel())
    view.absorb:SetWidth(width or Config.healthWidth)
    view.absorb:SetPoint(
        "TOPLEFT",
        view.health:GetStatusBarTexture(),
        "TOPRIGHT"
    )
    view.absorb:SetPoint(
        "BOTTOMLEFT",
        view.health:GetStatusBarTexture(),
        "BOTTOMRIGHT"
    )
    view.absorb:SetStatusBarTexture(
        "Interface\\RaidFrame\\Shield-Fill"
    )

    AbsorbPrediction:Configure(view.absorbCalculator, {
        maximumHealthClamp =
            Enum.UnitDamageAbsorbClampMode.MaximumHealth,
        healAbsorbMaximumHealth =
            Enum.UnitHealAbsorbClampMode.MaximumHealth,
        healAbsorbTotal = Enum.UnitHealAbsorbMode.Total,
        incomingHealMissingHealth =
            Enum.UnitIncomingHealClampMode.MissingHealth,
    })
end

local function createLightweightView()
    local layout = FrameLayout:GetLightweightLayout(Config)
    local view = CreateFrame("Frame")
    local health = CreateFrame("StatusBar", nil, view)

    view.health = health
    view:SetSize(layout.width, layout.height)
    health:SetAllPoints(view)
    health:SetStatusBarTexture(Config.texture)
    health:SetStatusBarColor(
        Config.colors.safe[1],
        Config.colors.safe[2],
        Config.colors.safe[3],
        Config.colors.safe[4]
    )
    createBorder(health, layout.borderThickness)

    local background = health:CreateTexture(nil, "BACKGROUND")

    background:SetAllPoints(health)
    background:SetColorTexture(
        Config.colors.background[1],
        Config.colors.background[2],
        Config.colors.background[3],
        Config.colors.background[4]
    )
    createAbsorbPrediction(view, layout.width)

    local name = health:CreateFontString(nil, "OVERLAY")

    view.name = name
    name:SetFont(Config.font, layout.fontSize, Config.nameFontFlags)
    name:SetShadowColor(
        Config.nameShadowColor[1],
        Config.nameShadowColor[2],
        Config.nameShadowColor[3],
        Config.nameShadowColor[4]
    )
    name:SetShadowOffset(
        Config.nameShadowOffset * Config.lightweightScale,
        -Config.nameShadowOffset * Config.lightweightScale
    )
    name:SetPoint(
        "LEFT",
        health,
        "LEFT",
        layout.padding,
        0
    )
    name:SetWidth(layout.width - layout.padding * 2)
    name:SetJustifyH("LEFT")

    return view
end

local function attachLightweightView(view, basePlate, unit)
    local blizzardUnitFrame = basePlate.UnitFrame
    local blizzardFrameLevel = blizzardUnitFrame and
        blizzardUnitFrame:GetFrameLevel() or basePlate:GetFrameLevel()

    view:SetParent(basePlate)
    view:SetFrameStrata(
        blizzardUnitFrame and blizzardUnitFrame:GetFrameStrata() or
            basePlate:GetFrameStrata()
    )
    view:SetFrameLevel(FrameLayout:GetOverlayLevel(blizzardFrameLevel))
    if view.SetIgnoreParentScale then
        view:SetIgnoreParentScale(true)
    end
    view:SetScale(Config.scale)
    view:ClearAllPoints()
    view:SetPoint("CENTER", basePlate, "CENTER", 0, Config.plateOffsetY)
    view.name:SetText(DisplayText:ShortenName(UnitName(unit)))
    view.unit = unit
    view.blizzardUnitFrame = blizzardUnitFrame
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

    view.health = CreateFrame("StatusBar", nil, view)
    view.health:SetSize(Config.healthWidth, Config.healthHeight)
    view.health:SetPoint("TOP", view, "TOP")
    view.health:SetStatusBarTexture(Config.texture)
    view.health:SetClipsChildren(
        FrameLayout:ShouldClipHealthChildren()
    )
    createBorder(view.health)

    view.healthBackground = view.health:CreateTexture(nil, "BACKGROUND")
    view.healthBackground:SetAllPoints()
    view.healthBackground:SetColorTexture(
        Config.colors.background[1],
        Config.colors.background[2],
        Config.colors.background[3],
        Config.colors.background[4]
    )

    createAbsorbPrediction(view)

    view.targetIndicator = createTargetIndicator(view.health)
    view.hoverIndicator = createSelectionBorder(view.health)
    view.raidTargetIcon = createRaidTargetIndicator(view.health)

    view.focusOverlay = view.health:CreateTexture(nil, "OVERLAY", nil, 2)
    view.focusOverlay:SetAllPoints(view.health)
    view.focusOverlay:SetTexture(Config.focusTexture)
    view.focusOverlay:SetVertexColor(
        Config.colors.focusOverlay[1],
        Config.colors.focusOverlay[2],
        Config.colors.focusOverlay[3],
        Config.colors.focusOverlay[4]
    )
    view.focusOverlay:SetAlpha(0)

    view.focusBorder = CreateFrame("Frame", nil, view.health)
    view.focusBorder:SetAllPoints(view.health)
    view.focusBorder:SetFrameLevel(view.health:GetFrameLevel() + 2)
    createBorder(
        view.focusBorder,
        Config.borderThickness,
        Config.colors.focus
    )
    view.focusBorder:Hide()

    view.name = view.health:CreateFontString(nil, "OVERLAY")
    view.name:SetFont(
        Config.font,
        Config.nameFontSize,
        Config.nameFontFlags
    )
    view.name:SetShadowColor(
        Config.nameShadowColor[1],
        Config.nameShadowColor[2],
        Config.nameShadowColor[3],
        Config.nameShadowColor[4]
    )
    view.name:SetShadowOffset(
        Config.nameShadowOffset,
        -Config.nameShadowOffset
    )
    view.name:SetPoint(
        "LEFT",
        view.health,
        "LEFT",
        Config.contentPadding,
        0
    )
    view.name:SetHeight(
        Config.healthHeight - Config.contentPadding * 2
    )
    view.name:SetWidth(80)
    view.name:SetJustifyH("LEFT")

    view.healthText = view.health:CreateFontString(nil, "OVERLAY")
    view.healthText:SetFont(Config.font, Config.healthFontSize, "OUTLINE")
    view.healthText:SetPoint(
        "RIGHT",
        view.health,
        "RIGHT",
        -Config.contentPadding,
        0
    )
    view.healthText:SetHeight(
        Config.healthHeight - Config.contentPadding * 2
    )

    view.cast = CreateFrame("StatusBar", nil, view)
    view.cast:SetSize(Config.healthWidth, Config.castHeight)
    view.cast:SetPoint(
        "TOP",
        view.health,
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

    view.interruptMarkerFrame = CreateFrame("Frame", nil, view.cast)
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
    view.castText:SetFont(Config.font, Config.castFontSize, "OUTLINE")
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
    view.castTime:SetFont(Config.font, Config.castFontSize, "OUTLINE")
    view.castTime:SetPoint(
        "RIGHT",
        view.castForeground,
        "RIGHT",
        -1,
        -1.5
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

    local auraAnchor = AuraDisplay:GetAnchorLayout(Config.auraIconSpacing)

    view.auraAnchor = auraAnchor
    view.auraLayer = createAuraLayer(
        view.health,
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
        view.health,
        view.importantBuffAnchor,
        view.health:GetFrameStrata(),
        view.health:GetFrameLevel() + 10
    )

    view.auras = {}

    if not supportsNativeAuraContainers() then
        for index = 1, Config.auraMaxCount do
            local aura = CreateFrame("Frame", nil, view.auraLayer)

            aura:SetSize(Config.auraIconSize, Config.auraIconSize)
            aura:SetPoint(
                auraAnchor.itemPoint,
                view.auraLayer,
                auraAnchor.itemPoint,
                (index - 1) *
                    (Config.auraIconSize + Config.auraIconSpacing) *
                    auraAnchor.horizontalStep,
                0
            )
            aura.icon = aura:CreateTexture(nil, "ARTWORK")
            aura.icon:SetAllPoints()
            aura.count = aura:CreateFontString(nil, "OVERLAY")
            aura.count:SetFont(Config.font, Config.auraFontSize, "OUTLINE")
            aura.count:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT")
            aura:Hide()
            view.auras[index] = aura
        end
    end

    return view
end

local function initializeAuraButton(auraButton, border, iconSize, interaction)
    iconSize = iconSize or Config.auraIconSize
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

    auraButton.durationText = auraButton:CreateFontString(nil, "OVERLAY")
    auraButton.durationText:SetFont(
        Config.font,
        Config.auraFontSize,
        "OUTLINE"
    )
    auraButton.durationText:SetPoint("CENTER", auraButton, "CENTER")
    auraButton.durationText:SetTextColor(
        Config.colors.auraTimer[1],
        Config.colors.auraTimer[2],
        Config.colors.auraTimer[3],
        Config.colors.auraTimer[4]
    )
    auraButton:SetDurationText(auraButton.durationText, {
        textFormatter = Runtime.auraTimeFormatter,
    })

    auraButton.countText = auraButton:CreateFontString(nil, "OVERLAY")
    auraButton.countText:SetFont(
        Config.font,
        Config.auraFontSize,
        "OUTLINE"
    )
    auraButton.countText:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT")
    auraButton:SetApplicationCount(auraButton.countText)
    border = border or {}
    createBorder(auraButton, border.thickness, border.color)
end

local function initializeImportantBuffButton(auraButton)
    initializeAuraButton(
        auraButton,
        AuraDisplay:GetImportantBuffBorder(),
        AuraDisplay:GetImportantBuffIconSize(Config.auraIconSize),
        AuraDisplay:GetImportantBuffInteraction()
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
            iconSpacing = Config.auraIconSpacing,
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

    local groupOptions = {
        iconSize = Config.auraIconSize,
        iconSpacing = Config.auraIconSpacing,
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
        }},
        debuffOptions.layout.maximumLineSize
    )

    local importantBuffGroups = {}
    local importantBuffIconSize =
        AuraDisplay:GetImportantBuffIconSize(Config.auraIconSize)

    for index, filter in ipairs(AuraDisplay:GetImportantBuffFilters()) do
        importantBuffGroups[index] = {
            key = "importantBuff" .. index,
            filter = filter,
            iconSize = importantBuffIconSize,
            initializeFrame = initializeImportantBuffButton,
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
        importantBuffGroups,
        AuraDisplay:GetImportantBuffMaximumLineSize(importantBuffOptions)
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
    for _, view in pairs(self.activePlates) do
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
    local assignedRole = UnitGroupRolesAssigned("player")
    local specializationIndex = GetSpecialization()
    local specializationRole

    if specializationIndex then
        specializationRole = GetSpecializationRole(specializationIndex)
    end

    return CombatState:ResolvePlayerRole(
        assignedRole,
        specializationRole
    )
end

function Runtime:UpdateHealth(unit, shouldCaptureAbsorb)
    local view = self.activePlates[unit]

    if not view then
        return
    end

    local health = UnitHealth(unit)
    local maximum = UnitHealthMax(unit)
    local threatStatus = DisplayText:SafeValue(
        UnitThreatSituation("player", unit),
        nil
    )
    local reaction = DisplayText:SafeValue(
        UnitReaction(unit, "player"),
        nil
    )
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
    local threatState = CombatState:GetThreatState(
        self:GetPlayerRole(),
        threatStatus
    )
    local isIdleNeutral = CombatState:IsIdleNeutral(
        reaction,
        4,
        threatStatus
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

    local colorKey = Appearance:GetHealthColorKey(
        appearanceClassification,
        profileColorKey == "caster",
        threatState,
        isIdleNeutral
    )

    setStatusBarColor(view.health, Config.colors[colorKey])
    view.name:SetText(DisplayText:ShortenName(UnitName(unit)))

    self:UpdateHealthValues(
        unit,
        view,
        health,
        maximum,
        shouldCaptureAbsorb
    )

    if issecretvalue and
        (issecretvalue(health) or issecretvalue(maximum)) then
        local percentage = HealthFormat:GetRestrictedPercentage(
            unit,
            UnitHealthPercent,
            CurveConstants.ScaleTo100
        )

        view.healthText:SetText(HealthFormat:FormatRestricted(
            health,
            percentage,
            AbbreviateNumbers
        ))
    else
        view.healthText:SetText(HealthFormat:Format(health, maximum))
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
        self:SetCastActive(unit, view, false)
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
        self:SetCastActive(unit, view, false)
        view.cast:Hide()
        return
    end

    view.cast:SetReverseFill(false)
    CastDuration:BindRemainingTime(
        view.cast,
        view.castDuration,
        Enum.StatusBarInterpolation.Immediate,
        CastDuration:GetTimerDirection(
            Enum.StatusBarTimerDirection
        )
    )
    local cooldownOverlayLayout =
        CastDuration:GetCooldownOverlayLayout()

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
    self:SetCastActive(unit, view, true)
    view.cast:Show()
    self:UpdateHealth(unit)
end

function Runtime:SetBlizzardFrameHidden(view, shouldHide)
    local unitFrame = view and view.blizzardUnitFrame

    if not unitFrame then
        return
    end

    local aurasFrame = unitFrame.AurasFrame

    if shouldHide then
        if view.blizzardAlpha == nil then
            view.blizzardAlpha = unitFrame:GetAlpha()
        end

        unitFrame:SetAlpha(0)

        if aurasFrame then
            if view.blizzardAurasAlpha == nil then
                view.blizzardAurasAlpha = aurasFrame:GetAlpha()
            end

            aurasFrame:SetAlpha(0)
        end

        return
    end

    unitFrame:SetAlpha(view.blizzardAlpha or 1)

    if aurasFrame then
        aurasFrame:SetAlpha(view.blizzardAurasAlpha or 1)
    end
end

function Runtime:AcquireLightweightView(createView)
    return table.remove(self.lightweightPool) or createView()
end

function Runtime:ReleaseLightweightView(view)
    view:Hide()
    view:SetParent(nil)
    view.unit = nil
    view.blizzardUnitFrame = nil
    view.blizzardAlpha = nil
    view.blizzardAurasAlpha = nil

    if view.absorbSnapshot then
        view.absorbSnapshot.captured = nil
        view.absorbSnapshot.maximum = nil
    end

    self.lightweightPool[#self.lightweightPool + 1] = view
end

function Runtime:UpdateHealthValues(
    unit,
    view,
    health,
    maximum,
    shouldCaptureAbsorb
)
    if view.absorbCalculator and self.absorbUpdateApi then
        AbsorbPrediction:Update(
            unit,
            view.absorbCalculator,
            view.health,
            view.absorb,
            self.absorbUpdateApi,
            view.absorbSnapshot,
            shouldCaptureAbsorb
        )
        return
    end

    view.health:SetMinMaxValues(0, maximum)
    view.health:SetValue(health)
end

function Runtime:UpdateLightweightHealth(unit, shouldCaptureAbsorb)
    local view = self.lightweightPlates[unit]

    if not view then
        return
    end

    self:UpdateHealthValues(
        unit,
        view,
        UnitHealth(unit),
        UnitHealthMax(unit),
        shouldCaptureAbsorb
    )
end

function Runtime:ResetAbsorbSnapshots()
    local function resetView(view)
        if not view.absorbSnapshot then
            return
        end

        view.absorbSnapshot.captured = nil
        view.absorbSnapshot.maximum = nil
    end

    for _, view in pairs(self.activePlates) do
        resetView(view)
    end

    for _, view in pairs(self.lightweightPlates) do
        resetView(view)
    end
end

function Runtime:ShowLightweightPlate(unit, basePlate)
    local view = self:AcquireLightweightView(createLightweightView)

    attachLightweightView(view, basePlate, unit)
    self:SetBlizzardFrameHidden(view, true)
    self.lightweightPlates[unit] = view
    NameplateStacking:ApplyBounds(basePlate, view)
    self:UpdateLightweightHealth(unit)
    view:Show()
    self:RefreshUpdateDriver()
end

function Runtime:AddPlate(unit)
    if self.activePlates[unit] or self.lightweightPlates[unit] then
        self.lastAddResult = "duplicate:" .. tostring(unit)
        return
    end

    if not UnitCanAttack("player", unit) then
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
        self:ShowLightweightPlate(unit, basePlate)
        self.lastAddResult = "lightweight-non-elite:" .. tostring(unit)
        return
    end

    local view = createPlateView(basePlate)
    view.unit = unit
    view.blizzardUnitFrame = basePlate.UnitFrame

    if Config.hideBlizzardFrame then
        self:SetBlizzardFrameHidden(view, true)
    end

    self.activePlates[unit] = view
    NameplateStacking:ApplyBounds(basePlate, view)
    createNativeAuraContainers(view, unit)
    self.lastAddResult = "added:" .. tostring(unit)

    self:UpdateSelectionIndicators()
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

function Runtime:UpdateSelectionIndicators()
    for plateUnit, view in pairs(self.activePlates) do
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
        view.hoverIndicator:SetShown(
            TargetIndicator:ShouldShowHover(isMouseover, isTarget)
        )
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
    end
end

function Runtime:RemovePlate(unit)
    local lightweightView = self.lightweightPlates[unit]

    if lightweightView then
        self:SetBlizzardFrameHidden(lightweightView, false)
        self.lightweightPlates[unit] = nil
        self:ReleaseLightweightView(lightweightView)
        self:RefreshUpdateDriver()
        return
    end

    local view = self.activePlates[unit]

    if not view then
        return
    end

    view:Hide()
    self:SetCastActive(unit, view, false)

    if view.auraContainer then
        view.auraContainer:SetEnabled(false)
    end

    if view.importantBuffContainer then
        view.importantBuffContainer:SetEnabled(false)
    end

    view.auraLayer:Hide()
    view.auraLayer:SetParent(nil)
    view.importantBuffLayer:Hide()
    view.importantBuffLayer:SetParent(nil)

    self:SetBlizzardFrameHidden(view, false)

    view:SetParent(nil)
    self.activePlates[unit] = nil
    self:RefreshUpdateDriver()
end

function Runtime:ReleaseAllPlates()
    local units = {}

    for unit in pairs(self.activePlates) do
        units[#units + 1] = unit
    end


    for unit in pairs(self.lightweightPlates) do
        units[#units + 1] = unit
    end

    for _, unit in ipairs(units) do
        self:RemovePlate(unit)
    end

    self.activeCasts = {}
    self.lightweightPlates = {}
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

    if next(self.activeCasts) then
        local shouldRefreshCasts

        shouldRefreshCasts, self.castRefreshElapsed =
            self:AdvanceRefreshClock(
                self.castRefreshElapsed,
                elapsed,
                Config.castRefreshInterval
            )

        if shouldRefreshCasts then
            for _, view in pairs(self.activeCasts) do
                updateCastVisual(
                    view,
                    view.castDuration,
                    view.interruptCooldown
                )
            end
        end
    else
        self.castRefreshElapsed = nil
    end

    local shouldSuppressBlizzardFrames

    shouldSuppressBlizzardFrames, self.frameSuppressionElapsed =
        self:AdvanceRefreshClock(
            self.frameSuppressionElapsed,
            elapsed,
            Config.frameSuppressionInterval
        )

    if shouldSuppressBlizzardFrames and Config.hideBlizzardFrame then
        for _, view in pairs(self.activePlates) do
            if view.blizzardUnitFrame and
                view.blizzardUnitFrame:GetAlpha() ~= 0 then
                view.blizzardUnitFrame:SetAlpha(0)
            end
        end


        for _, view in pairs(self.lightweightPlates) do
            if view.blizzardUnitFrame and
                view.blizzardUnitFrame:GetAlpha() ~= 0 then
                view.blizzardUnitFrame:SetAlpha(0)
            end
        end
    end
end

function Runtime:OnEvent(event, unit, _, spellID)
    if event == "PLAYER_LEAVING_WORLD" then
        self:ReleaseForLoadingScreen(function()
            collectgarbage("collect")
        end)
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        self:ResetAbsorbSnapshots()
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
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        self:UpdateLightweightHealth(unit)
        self:UpdateHealth(unit)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        self:UpdateLightweightHealth(unit, true)
        self:UpdateHealth(unit, true)
    elseif event == "UNIT_HEAL_PREDICTION" or
        event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" or
        event == "UNIT_FACTION" or
        event == "UNIT_THREAT_SITUATION_UPDATE" then
        self:UpdateHealth(unit)
    elseif event == "UNIT_AURA" then
        self:UpdateAuras(unit)
    elseif event == "RAID_TARGET_UPDATE" then
        self:RefreshRaidTargets()
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or
        event == "TRAIT_CONFIG_UPDATED" or event == "SPELLS_CHANGED" then
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
    if CreateUnitHealPredictionCalculator and
        UnitGetDetailedHealPrediction then
        self.absorbUpdateApi = self:CreateAbsorbUpdateApi()
    end
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event, ...)
        self:OnEvent(event, ...)
    end)
    self.onUpdateHandler = function(_, elapsed)
        self:OnUpdate(elapsed)
    end

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
        "SPELL_UPDATE_COOLDOWN",
        "TRAIT_CONFIG_UPDATED",
        "SPELLS_CHANGED",
        "UNIT_HEALTH",
        "UNIT_MAXHEALTH",
        "UNIT_HEAL_PREDICTION",
        "UNIT_ABSORB_AMOUNT_CHANGED",
        "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
        "UNIT_FACTION",
        "UNIT_AURA",
        "UNIT_THREAT_SITUATION_UPDATE",
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTIBLE",
        "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
        "UNIT_SPELLCAST_SUCCEEDED",
    }

    for _, event in ipairs(events) do
        self.frame:RegisterEvent(event)
    end

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
    self.castRefreshElapsed = nil
    self.frameSuppressionElapsed = nil
    self.absorbUpdateApi = nil
    self.castTimeFormatter = nil
    self.auraTimeFormatter = nil
    self:ReleaseAllPlates()

end

namespace.Runtime = Runtime

return Runtime
