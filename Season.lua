local _, namespace = ...

-- Unknown units and spells use the generic presentation. Seasonal rules are
-- intentionally isolated here so a new dungeon pool does not change the core.
namespace.Rules:RegisterSeason({
    casts = {},
    auras = {
        [328501] = {priority = 1},
        [328986] = {priority = 1},
        [204490] = {priority = 1},
        [409463] = {priority = 1},
        [323059] = {priority = 1},
        [438706] = {priority = 1},
        [460603] = {priority = 1},
        [1215595] = {priority = 1},
        [1215194] = {priority = 1},
        [1226890] = {priority = 1},
        [1233415] = {priority = 1},
        [1228265] = {priority = 1},
        [1228317] = {priority = 1},
        [1219731] = {priority = 1},
        [1226492] = {priority = 1},
        [1231328] = {priority = 1},
        [1236971] = {priority = 1},
        [1245292] = {priority = 1},
    },
    npcs = {},
})
