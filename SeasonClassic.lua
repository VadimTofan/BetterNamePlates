local _, namespace = ...

-- Classic-family content uses generic cast presentation until explicit rules
-- are added for a supported dungeon or raid.
namespace.Rules:RegisterSeason({
    casts = {},
    auras = {},
    npcs = {},
})
