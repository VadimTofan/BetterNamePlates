local _, namespace = ...

local Interrupts = {}

local CLASS_INTERRUPTS = {
    [1] = {{id = 6552}},
    [2] = {{id = 96231}},
    [3] = {{id = 187707}, {id = 147362}},
    [4] = {{id = 1766}},
    [5] = {{id = 15487}},
    [6] = {{id = 47528}},
    [7] = {{id = 57994}},
    [8] = {{id = 2139}},
    [9] = {
        {id = 89766, bank = "pet"},
        {id = 19647, bank = "pet"},
        {id = 132409},
    },
    [10] = {{id = 116705}},
    [11] = {{id = 78675}, {id = 106839}},
    [12] = {{id = 183752}},
    [13] = {{id = 351338}},
}

function Interrupts:FindKnownSpell(classID, isKnown)
    local candidates = CLASS_INTERRUPTS[classID] or {}

    for _, candidate in ipairs(candidates) do
        if isKnown(candidate.id, candidate.bank) then
            return candidate.id
        end
    end

    return nil
end

namespace.Interrupts = Interrupts

return Interrupts
