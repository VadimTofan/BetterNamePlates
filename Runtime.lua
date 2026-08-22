local _, namespace = ...

local Config = namespace.Config
local Appearance = namespace.Appearance
local CombatState = namespace.CombatState
local DisplayText = namespace.DisplayText
local FrameLayout = namespace.FrameLayout
local HealthFormat = namespace.HealthFormat
local NpcClassification = namespace.NpcClassification
local Rules = namespace.Rules
local TargetIndicator = namespace.TargetIndicator

local Runtime = {
    activePlates = {},
}

local function setStatusBarColor(statusBar, color)
    statusBar:SetStatusBarColor(color[1], color[2], color[3], color[4])
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
    view.cast:Hide()

    view.castText = view.cast:CreateFontString(nil, "OVERLAY")
    view.castText:SetFont(Config.font, Config.castFontSize, "OUTLINE")
    view.castText:SetPoint("LEFT", view.cast, "LEFT", 1, -1.5)
    view.castText:SetWidth(90)
    view.castText:SetJustifyH("LEFT")

    view.castTime = view.cast:CreateFontString(nil, "OVERLAY")
    view.castTime:SetFont(Config.font, Config.castFontSize, "OUTLINE")
    view.castTime:SetPoint("RIGHT", view.cast, "RIGHT", -1, -1.5)

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

function Runtime:UpdateAuras(unit)
    local view = self.activePlates[unit]

    if not view or not C_UnitAuras then
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

function Runtime:GetPlayerRole()
    return UnitGroupRolesAssigned("player") or "NONE"
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

function Runtime:UpdateCast(unit)
    local view = self.activePlates[unit]

    if not view then
        return
    end

    local name, _, _, startTime, endTime, _, _, notInterruptible,
        spellID = UnitCastingInfo(unit)
    local isChannel = false

    if not name then
        name, _, _, startTime, endTime, _, notInterruptible,
            spellID = UnitChannelInfo(unit)
        isChannel = name ~= nil
    end

    if not name then
        view.cast:Hide()
        return
    end

    local rule = Rules:GetCast(spellID)
    local castState = CombatState:GetCastState(
        rule.priority,
        not notInterruptible
    )

    view.castStart = startTime / 1000
    view.castEnd = endTime / 1000
    view.isChannel = isChannel
    view.cast:SetMinMaxValues(view.castStart, view.castEnd)
    view.castText:SetText(name)
    view.isKnownCaster = true
    setStatusBarColor(
        view.cast,
        Config.colors[castState .. "Cast"] or Config.colors.normalCast
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
    local now = GetTime()

    for _, view in pairs(self.activePlates) do
        if Config.hideBlizzardFrame and view.blizzardUnitFrame and
            view.blizzardUnitFrame:GetAlpha() ~= 0 then
            view.blizzardUnitFrame:SetAlpha(0)
        end

        if view.cast:IsShown() then
            local value = view.isChannel and view.castEnd - now or now
            local remaining = math.max(0, view.castEnd - now)

            view.cast:SetValue(value)
            view.castTime:SetFormattedText("%.1f", remaining)
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
    elseif event:find("UNIT_SPELLCAST", 1, true) == 1 then
        self:UpdateCast(unit)
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
