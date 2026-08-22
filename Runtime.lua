local _, namespace = ...

local Config = namespace.Config
local Appearance = namespace.Appearance
local CastDuration = namespace.CastDuration
local CombatState = namespace.CombatState
local DisplayText = namespace.DisplayText
local FrameLayout = namespace.FrameLayout
local HealthFormat = namespace.HealthFormat
local Interrupts = namespace.Interrupts
local NpcClassification = namespace.NpcClassification
local Rules = namespace.Rules
local TargetIndicator = namespace.TargetIndicator

local Runtime = {
    activePlates = {},
}

local function setStatusBarColor(statusBar, color)
    statusBar:SetStatusBarColor(color[1], color[2], color[3], color[4])
end

local function setTextureColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4])
end

local function createBorder(frame)
    local thickness = Config.borderThickness
    local color = Config.colors.border

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

local function createTargetIndicator(healthBar)
    local indicator = CreateFrame("Frame", nil, healthBar)
    local thickness = Config.targetBorderThickness
    local color = Config.colors.target

    indicator:SetAllPoints(healthBar)
    indicator:SetFrameLevel(healthBar:GetFrameLevel() + 3)

    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local border = indicator:CreateTexture(nil, "OVERLAY")

        border:SetColorTexture(color[1], color[2], color[3], color[4])

        if edge == "TOP" or edge == "BOTTOM" then
            border:SetHeight(thickness)
            border:SetPoint(edge .. "LEFT", indicator, edge .. "LEFT")
            border:SetPoint(edge .. "RIGHT", indicator, edge .. "RIGHT")
        else
            border:SetWidth(thickness)
            border:SetPoint("TOP" .. edge, indicator, "TOP" .. edge)
            border:SetPoint("BOTTOM" .. edge, indicator, "BOTTOM" .. edge)
        end
    end

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
    indicator:Hide()

    return indicator
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
    view:SetPoint("CENTER", basePlate, "CENTER", 0, 0)

    view.health = CreateFrame("StatusBar", nil, view)
    view.health:SetSize(Config.healthWidth, Config.healthHeight)
    view.health:SetPoint("TOP", view, "TOP")
    view.health:SetStatusBarTexture(Config.texture)
    createBorder(view.health)

    view.healthBackground = view.health:CreateTexture(nil, "BACKGROUND")
    view.healthBackground:SetAllPoints()
    view.healthBackground:SetColorTexture(
        Config.colors.background[1],
        Config.colors.background[2],
        Config.colors.background[3],
        Config.colors.background[4]
    )
    view.targetIndicator = createTargetIndicator(view.health)

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
    view.cast:SetPoint("TOP", view.health, "BOTTOM", 0, -1)
    view.cast:SetStatusBarTexture(Config.texture)
    view.cast:SetClipsChildren(true)
    view.cast:Hide()

    view.castBackground = view.cast:CreateTexture(nil, "BACKGROUND")
    view.castBackground:SetAllPoints()
    setTextureColor(view.castBackground, Config.colors.background)

    view.interruptOverlay = CreateFrame("StatusBar", nil, view.cast)
    view.interruptOverlay:SetSize(Config.healthWidth, Config.castHeight)
    view.interruptOverlay:SetFrameLevel(view.cast:GetFrameLevel() + 1)
    view.interruptOverlay:SetStatusBarTexture(Config.texture)
    setStatusBarColor(
        view.interruptOverlay,
        Config.colors.interruptUnavailableCast
    )

    view.interruptMarkerTrack = CreateFrame("StatusBar", nil, view.cast)
    view.interruptMarkerTrack:SetAllPoints(view.cast)
    view.interruptMarkerTrack:SetFrameLevel(view.cast:GetFrameLevel() + 1)
    view.interruptMarkerTrack:SetStatusBarTexture(Config.texture)
    view.interruptMarkerTrack:SetStatusBarColor(0, 0, 0, 0)
    view.interruptMarkerTrack:SetReverseFill(true)

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

    view.auras = {}

    for index = 1, 5 do
        local aura = CreateFrame("Frame", nil, view)
        aura:SetSize(18, 18)
        aura:SetPoint("BOTTOMLEFT", view.health, "TOPLEFT", (index - 1) * 20, 2)
        aura.icon = aura:CreateTexture(nil, "ARTWORK")
        aura.icon:SetAllPoints()
        aura.count = aura:CreateFontString(nil, "OVERLAY")
        aura.count:SetFont(Config.font, 8, "OUTLINE")
        aura.count:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT")
        aura:Hide()
        view.auras[index] = aura
    end

    return view
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
    local totalDuration = duration:GetTotalDuration()

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
        view.interruptOverlay:Hide()
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

    view.interruptOverlay:SetMinMaxValues(0, totalDuration)
    view.interruptOverlay:SetValue(cooldown:GetRemainingDuration())

    local overlayAlpha = C_CurveUtil.EvaluateColorValueFromBoolean(
        cooldownReady,
        0,
        1
    )
    overlayAlpha = C_CurveUtil.EvaluateColorValueFromBoolean(
        view.castNotInterruptible,
        0,
        overlayAlpha
    )
    view.interruptOverlay:SetAlpha(overlayAlpha)
    view.interruptOverlay:Show()
    view.interruptMarkerFrame:SetAlpha(overlayAlpha)
    view.interruptMarkerFrame:Show()
end

function Runtime:RefreshCastCooldowns()
    for _, view in pairs(self.activePlates) do
        if view.cast:IsShown() and view.castDuration then
            view.interruptCooldown = self:GetInterruptCooldown()

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

function Runtime:UpdateHealth(unit)
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
    local classification = DisplayText:SafeValue(
        UnitClassification(unit),
        "normal"
    )
    local effectiveLevel = DisplayText:SafeValue(
        UnitEffectiveLevel(unit),
        nil
    )
    local powerType = DisplayText:SafeValue(
        UnitPowerType(unit),
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
    local profileColorKey = NpcClassification:GetColorKey({
        playerLevel = UnitLevel("player"),
        effectiveLevel = effectiveLevel,
        isLieutenant = isLieutenant,
        isKnownCaster = view.isKnownCaster,
        classBase = classBase,
        powerType = powerType,
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
        threatState
    )

    setStatusBarColor(view.health, Config.colors[colorKey])
    view.name:SetText(DisplayText:ShortenName(UnitName(unit)))

    view.health:SetMinMaxValues(0, maximum)
    view.health:SetValue(health)

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
        view.cast:Hide()
        return
    end

    view.cast:SetReverseFill(false)
    CastDuration:BindRemainingTime(
        view.cast,
        view.castDuration,
        Enum.StatusBarInterpolation.Immediate,
        Enum.StatusBarTimerDirection.RemainingTime
    )
    local cooldownOverlayLayout =
        CastDuration:GetCooldownOverlayLayout()

    view.interruptOverlay:ClearAllPoints()
    view.interruptMarkerFrame:ClearAllPoints()
    view.interruptOverlay:SetReverseFill(
        cooldownOverlayLayout.reverseFill
    )
    view.interruptOverlay:SetPoint(
        cooldownOverlayLayout.point,
        view.cast:GetStatusBarTexture(),
        cooldownOverlayLayout.relativePoint
    )
    view.interruptMarkerFrame:SetPoint(
        cooldownOverlayLayout.markerAnchor,
        view.interruptMarkerTrack:GetStatusBarTexture(),
        cooldownOverlayLayout.markerPoint
    )

    view.castText:SetText(name)
    view.castIcon:SetTexture(textureID)
    view.castIconFrame:Show()
    view.isKnownCaster = true
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
    view.cast:Show()
    self:UpdateHealth(unit)
end

function Runtime:AddPlate(unit)
    if self.activePlates[unit] then
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

    local view = createPlateView(basePlate)
    view.unit = unit
    view.blizzardUnitFrame = basePlate.UnitFrame

    if Config.hideBlizzardFrame and view.blizzardUnitFrame then
        view.blizzardAlpha = view.blizzardUnitFrame:GetAlpha()
        view.blizzardUnitFrame:SetAlpha(0)
    end

    self.activePlates[unit] = view
    self.lastAddResult = "added:" .. tostring(unit)
    local isTarget = DisplayText:SafeValue(
        UnitIsUnit(unit, "target"),
        false
    )

    view.targetIndicator:SetShown(TargetIndicator:ShouldShow(isTarget))
    self:UpdateHealth(unit)
    self:UpdateCast(unit)
    self:UpdateAuras(unit)
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

function Runtime:RemovePlate(unit)
    local view = self.activePlates[unit]

    if not view then
        return
    end

    view:Hide()

    if view.blizzardUnitFrame then
        view.blizzardUnitFrame:SetAlpha(view.blizzardAlpha or 1)
    end

    view:SetParent(nil)
    self.activePlates[unit] = nil
end

function Runtime:OnUpdate()
    for _, view in pairs(self.activePlates) do
        if Config.hideBlizzardFrame and view.blizzardUnitFrame and
            view.blizzardUnitFrame:GetAlpha() ~= 0 then
            view.blizzardUnitFrame:SetAlpha(0)
        end

        if view.cast:IsShown() and view.castDuration then
            updateCastVisual(
                view,
                view.castDuration,
                view.interruptCooldown
            )
        end
    end
end

function Runtime:OnEvent(event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        self:AddPlate(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        self:RemovePlate(unit)
    elseif event == "UNIT_HEALTH" or event == "UNIT_THREAT_SITUATION_UPDATE" then
        self:UpdateHealth(unit)
    elseif event == "UNIT_AURA" then
        self:UpdateAuras(unit)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or
        event == "TRAIT_CONFIG_UPDATED" or event == "SPELLS_CHANGED" then
        self:RefreshInterruptSpell()

        for plateUnit in pairs(self.activePlates) do
            self:UpdateCast(plateUnit)
        end
    elseif Interrupts:IsCooldownEvent(event) then
        self:RefreshCastCooldowns()
    elseif event:find("UNIT_SPELLCAST", 1, true) == 1 then
        self:UpdateCast(unit, event)
    elseif event == "PLAYER_TARGET_CHANGED" then
        for plateUnit, view in pairs(self.activePlates) do
            local isTarget = DisplayText:SafeValue(
                UnitIsUnit(plateUnit, "target"),
                false
            )

            view:SetAlpha(Appearance:GetTargetAlpha(
                isTarget
            ))
            view.targetIndicator:SetShown(
                TargetIndicator:ShouldShow(isTarget)
            )
        end
    end
end

function Runtime:Enable()
    if self.frame then
        return
    end

    self.castTimeFormatter = C_StringUtil.CreateSecondsFormatter()
    self.castTimeFormatter:SetMillisecondsThreshold(5)
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event, unit)
        self:OnEvent(event, unit)
    end)
    self.frame:SetScript("OnUpdate", function()
        self:OnUpdate()
    end)

    local events = {
        "NAME_PLATE_UNIT_ADDED",
        "NAME_PLATE_UNIT_REMOVED",
        "PLAYER_TARGET_CHANGED",
        "PLAYER_SPECIALIZATION_CHANGED",
        "SPELL_UPDATE_COOLDOWN",
        "TRAIT_CONFIG_UPDATED",
        "SPELLS_CHANGED",
        "UNIT_HEALTH",
        "UNIT_AURA",
        "UNIT_THREAT_SITUATION_UPDATE",
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTIBLE",
        "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
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
end

function Runtime:Disable()
    if not self.frame then
        return
    end

    self.frame:UnregisterAllEvents()
    self.frame:SetScript("OnUpdate", nil)
    self.frame = nil
    self.interruptSpellID = nil
    self.castTimeFormatter = nil

    local units = {}

    for unit in pairs(self.activePlates) do
        units[#units + 1] = unit
    end

    for _, unit in ipairs(units) do
        self:RemovePlate(unit)
    end
end

namespace.Runtime = Runtime

return Runtime
