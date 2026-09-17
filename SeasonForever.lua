local _, namespace = ...

-- Forever content starts with generic cast presentation. Content-specific
-- rules remain isolated from Retail and can be added as the beta stabilizes.
namespace.Rules:RegisterSeason({
    casts = {},
    auras = {},
    npcs = {},
})
