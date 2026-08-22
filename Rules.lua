local _, namespace = ...

local GENERIC_CAST = {
    priority = false,
}

local Rules = {
    casts = {},
    auras = {},
    npcs = {},
}

function Rules:RegisterSeason(season)
    for spellID, rule in pairs(season.casts or {}) do
        self.casts[spellID] = rule
    end

    for spellID, rule in pairs(season.auras or {}) do
        self.auras[spellID] = rule
    end

    for npcID, rule in pairs(season.npcs or {}) do
        self.npcs[npcID] = rule
    end
end

function Rules:GetCast(spellID)
    return self.casts[spellID] or GENERIC_CAST
end

function Rules:GetAura(spellID)
    return self.auras[spellID]
end

function Rules:GetNpc(npcID)
    return self.npcs[npcID]
end

namespace.Rules = Rules

return Rules
