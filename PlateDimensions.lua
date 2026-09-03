local _, namespace = ...

local PlateDimensions = {}
local MIN_WIDTH = 50
local MAX_WIDTH = 400
local MIN_HEIGHT = 6
local MAX_HEIGHT = 40
local MIN_NAME_LEVEL = 1
local MAX_NAME_LEVEL = 10
local DEFAULT_NAME_LEVEL = 5

local function parseNumber(value)
    local number = tonumber(value)

    if not number then
        return nil
    end

    return math.floor(number * 100 + 0.5) / 100
end

local function parseNameLevel(value)
    local level = tonumber(value)

    if not level or level ~= math.floor(level) or
        level < MIN_NAME_LEVEL or level > MAX_NAME_LEVEL then
        return nil
    end

    return level
end

function PlateDimensions:ApplySaved(saved, config)
    if not self.defaultWidth then
        self.defaultWidth = config.healthWidth
        self.defaultHeight = config.healthHeight
    end

    if not self.defaultNameFontSize and config.nameFontSize then
        self.defaultNameFontSize = config.nameFontSize
    end

    local width = parseNumber(saved.width)
    local height = parseNumber(saved.height)
    local nameLevel = parseNameLevel(saved.name)

    if not width or width < MIN_WIDTH or width > MAX_WIDTH then
        width = nil
        saved.width = nil
    end

    if not height or height < MIN_HEIGHT or height > MAX_HEIGHT then
        height = nil
        saved.height = nil
    end

    config.healthWidth = width or self.defaultWidth
    config.healthHeight = height or self.defaultHeight

    if saved.name ~= nil and not nameLevel then
        saved.name = nil
    end

    if self.defaultNameFontSize then
        config.nameFontSize = self.defaultNameFontSize +
            (nameLevel or DEFAULT_NAME_LEVEL) - DEFAULT_NAME_LEVEL
    end
end

function PlateDimensions:ApplyCommand(message, saved)
    local command, rawValue = message:lower():match("^%s*(%S+)%s*(%S*)%s*$")

    if command == "reset" then
        saved.width = nil
        saved.height = nil
        saved.name = nil

        return {changed = true, action = "reset"}
    end

    local value = parseNumber(rawValue)

    if command == "width" and value and
        value >= MIN_WIDTH and value <= MAX_WIDTH then
        saved.width = value
        return {changed = true, action = "width", value = value}
    end

    if command == "height" and value and
        value >= MIN_HEIGHT and value <= MAX_HEIGHT then
        saved.height = value
        return {changed = true, action = "height", value = value}
    end

    local nameLevel = parseNameLevel(rawValue)

    if command == "name" and nameLevel then
        saved.name = nameLevel
        return {changed = true, action = "name", value = nameLevel}
    end

    return {changed = false, action = "usage"}
end

function PlateDimensions:GetDefaults()
    return self.defaultWidth, self.defaultHeight
end

namespace.PlateDimensions = PlateDimensions

return PlateDimensions
