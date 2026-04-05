local _, ns = ...
local LibEditMode = ns.LibEditMode
local ADDON_NAME = "SurGiveInnervatePI"
local SurIPI = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
local LGF = LibStub("LibGetFrame-1.0")
local LCG = LibStub("LibCustomGlow-1.0")

local defaults = {
    x = 0,
    y = 0,
    size = 50,
    displayName = true,
    nameSize = 12,
    glow = true,
    glowType = 1, -- pixel
    piColor = CreateColor(1,1,0,1),
    innervateColor = CreateColor(0,0,1,1),
    duration = 5,
    glowScale = 2,
    glowOffset = 0,
}

function SurIPI:OnInitialize()
    if not SurGiveInnervatePISaved then
        SurGiveInnervatePISaved = CopyTable(defaults)
    end
end

local lastColorChanged
local editModeActive = false
function SurIPI:OnEnable()
    local alertFrame = CreateFrame("Frame", "SurGiveInnervatePI", UIParent)
    alertFrame:SetSize(SurGiveInnervatePISaved.size, SurGiveInnervatePISaved.size)
    alertFrame:SetPoint("CENTER", UIParent, "CENTER", SurGiveInnervatePISaved.x, SurGiveInnervatePISaved.y)
    alertFrame:SetFrameStrata("HIGH")
    alertFrame:Hide()

    -- Innervate icon texture (spell icon)
    local icon = alertFrame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(alertFrame)

    local function onPositionChanged(frame, layoutName, point, x, y)
        SurGiveInnervatePISaved.point = point
        SurGiveInnervatePISaved.x = x
        SurGiveInnervatePISaved.y = y
    end

    LibEditMode:RegisterCallback('enter', function()
        editModeActive = true
        self.alertFrame:Show()
        if SurGiveInnervatePISaved.displayName then
            self.label:SetText(UnitName("player"))
        end
    end)
    LibEditMode:RegisterCallback('exit', function()
        editModeActive = false
        self.alertFrame:Hide()
        self.label:SetText("")
        local frame = LGF.GetFrame("player")
        if frame then
            LCG.PixelGlow_Stop(frame)
            LCG.AutoCastGlow_Stop(frame)
            LCG.ButtonGlow_Stop(frame)
            LCG.ProcGlow_Stop(frame)
        end
    end)
    LibEditMode:RegisterCallback('layout', function(layoutName)
        if not SurGiveInnervatePISaved then
            SurGiveInnervatePISaved = CopyTable(defaults)
        end

        alertFrame:ClearAllPoints()
        alertFrame:SetPoint("CENTER", UIParent, "CENTER", SurGiveInnervatePISaved.x, SurGiveInnervatePISaved.y)
    end)

    LibEditMode:AddFrame(alertFrame, onPositionChanged, defaults)
    -- All settings
    LibEditMode:AddFrameSettings(alertFrame, {
        {
            name = 'Icon size',
            kind = LibEditMode.SettingType.Slider,
            default = defaults.size,
            get = function()
                return SurGiveInnervatePISaved.size
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.size = value
                alertFrame:SetSize(value,value)
            end,
            minValue = 10,
            maxValue = 100,
            valueStep = 1,
            formatter = function(value)
                return value
            end,
        },
        {
            name = 'X-Position',
            kind = LibEditMode.SettingType.Slider,
            default = defaults.x,
            get = function()
                return SurGiveInnervatePISaved.x
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.x = value
                alertFrame:SetPoint("CENTER", UIParent, "CENTER", value, SurGiveInnervatePISaved.y)
            end,
            minValue = -500,
            maxValue = 500,
            valueStep = 1,
        },
        {
            name = 'Y-Position',
            kind = LibEditMode.SettingType.Slider,
            default = defaults.y,
            get = function()
                return SurGiveInnervatePISaved.y
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.y = value
                alertFrame:SetPoint("CENTER", UIParent, "CENTER", SurGiveInnervatePISaved.x, value)
            end,
            minValue = -500,
            maxValue = 500,
            valueStep = 1,
        },
        {
            name = 'Duration to show for',
            kind = LibEditMode.SettingType.Slider,
            default = defaults.duration,
            get = function()
                return SurGiveInnervatePISaved.duration
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.duration = value
            end,
            minValue = 1,
            maxValue = 10,
            valueStep = 1,
        },
        {
            name = 'General Divider',
            kind = LibEditMode.SettingType.Divider,
            hideLabel = true,
        },
        {
            name = 'Display Name',
            kind = LibEditMode.SettingType.Checkbox,
            default = defaults.displayName,
            get = function()
                if SurGiveInnervatePISaved.displayName then
                    self.label:SetText(UnitName("player"))
                else
                    self.label:SetText("")
                end
                return SurGiveInnervatePISaved.displayName
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.displayName = value
                if value then
                    self.label:SetText(UnitName("player"))
                else
                    self.label:SetText("")
                end
            end,
        },
        {
            name = 'Name size',
            kind = LibEditMode.SettingType.Slider,
            default = defaults.nameSize,
            get = function()
                return SurGiveInnervatePISaved.nameSize
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.nameSize = value
                self.label:SetFont("Fonts\\FRIZQT__.TTF", value)
            end,
            minValue = 6,
            maxValue = 20,
            valueStep = 1,
            hidden = function()
                return not SurGiveInnervatePISaved.displayName
            end,
        },
        {
            name = 'Name Divider',
            kind = LibEditMode.SettingType.Divider,
            hideLabel = true,
        },
        {
            name = 'Glow Unitframe',
            kind = LibEditMode.SettingType.Checkbox,
            default = defaults.glow,
            get = function()
                return SurGiveInnervatePISaved.glow
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.glow = value
                if value then
                    local frame = LGF.GetFrame("player")
                    if frame then
                        local color = lastColorChanged or UnitClass("player") == 5 and SurGiveInnervatePISaved.innervateColor or SurGiveInnervatePISaved.piColor
                        local formattedColor = {color.r, color.g, color.b, color.a}
                        if SurGiveInnervatePISaved.glowType == 1 then
                            LCG.PixelGlow_Start(frame, formattedColor, nil, nil, nil, SurGiveInnervatePISaved.glowOffset, SurGiveInnervatePISaved.glowOffset)
                        elseif SurGiveInnervatePISaved.glowType == 2 then
                            LCG.AutoCastGlow_Start(frame, formattedColor, 8, nil, 2, SurGiveInnervatePISaved.glowOffset,SurGiveInnervatePISaved.glowOffset)
                        elseif SurGiveInnervatePISaved.glowType == 3 then
                            LCG.ButtonGlow_Start(frame, formattedColor)
                        elseif SurGiveInnervatePISaved.glowType == 4 then
                            LCG.ProcGlow_Start(frame, {color = formattedColor, xOffset = SurGiveInnervatePISaved.glowOffset, yOffset = SurGiveInnervatePISaved.glowOffset})
                        end
                    end
                else
                    local frame = LGF.GetFrame("player")
                    if frame then
                        LCG.PixelGlow_Stop(frame)
                        LCG.AutoCastGlow_Stop(frame)
                        LCG.ButtonGlow_Stop(frame)
                        LCG.ProcGlow_Stop(frame)
                    end
                end
            end,
        },
        {
            name = 'Glow Type',
            kind = LibEditMode.SettingType.Dropdown,
            default = defaults.glowType,
            get = function()
                return SurGiveInnervatePISaved.glowType
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.glowType = value
                local frame = LGF.GetFrame("player")
                if frame then
                    LCG.PixelGlow_Stop(frame)
                    LCG.AutoCastGlow_Stop(frame)
                    LCG.ButtonGlow_Stop(frame)
                    LCG.ProcGlow_Stop(frame)
                end
                local color = lastColorChanged or UnitClass("player") == 5 and SurGiveInnervatePISaved.innervateColor or SurGiveInnervatePISaved.piColor
                local formattedColor = {color.r, color.g, color.b, color.a}
                if value == 1 then
                    LCG.PixelGlow_Start(frame, formattedColor, nil, nil, nil, SurGiveInnervatePISaved.glowScale*2, SurGiveInnervatePISaved.glowOffset, SurGiveInnervatePISaved.glowOffset)
                elseif value == 2 then
                    LCG.AutoCastGlow_Start(frame, formattedColor, 8, nil, SurGiveInnervatePISaved.glowScale, SurGiveInnervatePISaved.glowOffset, SurGiveInnervatePISaved.glowOffset)
                elseif value == 3 then
                    LCG.ButtonGlow_Start(frame, formattedColor)
                elseif value == 4 then
                    LCG.ProcGlow_Start(frame, {color = formattedColor, xOffset = SurGiveInnervatePISaved.glowOffset, yOffset = SurGiveInnervatePISaved.glowOffset})
                end
            end,
            values = {
                {text = "pixel", value = 1},
                {text = "autocast", value = 2},
                {text = "button", value = 3},
                {text = "procc", value = 4},
            },
            hidden = function()
                return not SurGiveInnervatePISaved.glow
            end,
        },
        {
            name = 'Glow size',
            kind = LibEditMode.SettingType.Slider,
            default = defaults.glowScale,
            get = function()
                return SurGiveInnervatePISaved.glowScale
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.glowScale = value
                local frame = LGF.GetFrame("player")
                if frame then
                    LCG.PixelGlow_Stop(frame)
                    LCG.AutoCastGlow_Stop(frame)
                    LCG.ButtonGlow_Stop(frame)
                    LCG.ProcGlow_Stop(frame)
                end
                local color = lastColorChanged or UnitClass("player") == 5 and SurGiveInnervatePISaved.innervateColor or SurGiveInnervatePISaved.piColor
                local formattedColor = {color.r, color.g, color.b, color.a}
                if SurGiveInnervatePISaved.glowType == 1 then
                    LCG.PixelGlow_Start(frame, formattedColor, nil, nil, nil, value*2, SurGiveInnervatePISaved.glowOffset, SurGiveInnervatePISaved.glowOffset)
                elseif SurGiveInnervatePISaved.glowType == 2 then
                    LCG.AutoCastGlow_Start(frame, formattedColor, 8, nil, value, SurGiveInnervatePISaved.glowOffset, SurGiveInnervatePISaved.glowOffset)
                elseif SurGiveInnervatePISaved.glowType == 3 then
                    LCG.ButtonGlow_Start(frame, formattedColor)
                elseif SurGiveInnervatePISaved.glowType == 4 then
                    LCG.ProcGlow_Start(frame, {color = formattedColor, xOffset = SurGiveInnervatePISaved.glowOffset, yOffset = SurGiveInnervatePISaved.glowOffset})
                end
            end,
            minValue = 0.4,
            maxValue = 4,
            valueStep = 0.1,
            hidden = function()
                return not SurGiveInnervatePISaved.glow
            end,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
        {
            name = 'Glow offset',
            kind = LibEditMode.SettingType.Slider,
            default = defaults.glowOffset,
            get = function()
                return SurGiveInnervatePISaved.glowOffset
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.glowOffset = value
                local frame = LGF.GetFrame("player")
                if frame then
                    LCG.PixelGlow_Stop(frame)
                    LCG.AutoCastGlow_Stop(frame)
                    LCG.ButtonGlow_Stop(frame)
                    LCG.ProcGlow_Stop(frame)
                end
                local color = lastColorChanged or UnitClass("player") == 5 and SurGiveInnervatePISaved.innervateColor or SurGiveInnervatePISaved.piColor
                local formattedColor = {color.r, color.g, color.b, color.a}
                if SurGiveInnervatePISaved.glowType == 1 then
                    LCG.PixelGlow_Start(frame, formattedColor, nil, nil, nil, SurGiveInnervatePISaved.glowScale*2, value, value)
                elseif SurGiveInnervatePISaved.glowType == 2 then
                    LCG.AutoCastGlow_Start(frame, formattedColor, 8, nil, SurGiveInnervatePISaved.glowScale, value, value)
                elseif SurGiveInnervatePISaved.glowType == 3 then
                    LCG.ButtonGlow_Start(frame, formattedColor)
                elseif SurGiveInnervatePISaved.glowType == 4 then
                    LCG.ProcGlow_Start(frame, {color = formattedColor, xOffset = value, yOffset = value})
                end
            end,
            minValue = -10,
            maxValue = 10,
            valueStep = 0.1,
            hidden = function()
                return not SurGiveInnervatePISaved.glow
            end,
            formatter = function(value)
                return string.format("%.1f", value)
            end,
        },
        {
            name = 'PI Glow Color',
            kind = LibEditMode.SettingType.ColorPicker,
            default = defaults.piColor,
            get = function()
                return CreateColor(SurGiveInnervatePISaved.piColor.r, SurGiveInnervatePISaved.piColor.g, SurGiveInnervatePISaved.piColor.b, SurGiveInnervatePISaved.piColor.a)
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.piColor = value
                lastColorChanged = value
                local frame = LGF.GetFrame("player")
                if frame then
                    local formattedColor = {value.r, value.g, value.b, value.a}
                    if SurGiveInnervatePISaved.glowType == 1 then
                        LCG.PixelGlow_Start(frame, formattedColor, nil, nil, nil, SurGiveInnervatePISaved.glowScale*2, SurGiveInnervatePISaved.glowOffset, SurGiveInnervatePISaved.glowOffset)
                    elseif SurGiveInnervatePISaved.glowType == 2 then
                        LCG.AutoCastGlow_Start(frame, formattedColor, 8, nil, SurGiveInnervatePISaved.glowScale, SurGiveInnervatePISaved.glowOffset, SurGiveInnervatePISaved.glowOffset)
                    elseif SurGiveInnervatePISaved.glowType == 3 then
                        LCG.ButtonGlow_Start(frame, formattedColor)
                    elseif SurGiveInnervatePISaved.glowType == 4 then
                        LCG.ProcGlow_Start(frame, {color = formattedColor, xOffset = SurGiveInnervatePISaved.glowOffset, yOffset = SurGiveInnervatePISaved.glowOffset})
                    end
                end
            end,
            hidden = function()
                return not SurGiveInnervatePISaved.glow
            end,
        },
        {
            name = 'Innervate Glow Color',
            kind = LibEditMode.SettingType.ColorPicker,
            default = defaults.innervateColor,
            get = function()
                return CreateColor(SurGiveInnervatePISaved.innervateColor.r, SurGiveInnervatePISaved.innervateColor.g, SurGiveInnervatePISaved.innervateColor.b, SurGiveInnervatePISaved.innervateColor.a)
            end,
            set = function(_, value)
                SurGiveInnervatePISaved.innervateColor = value
                lastColorChanged = value
                local frame = LGF.GetFrame("player")
                if frame then
                    local formattedColor = {value.r, value.g, value.b, value.a}
                    if SurGiveInnervatePISaved.glowType == 1 then
                        LCG.PixelGlow_Start(frame, formattedColor, nil, nil, nil, SurGiveInnervatePISaved.glowScale*2, SurGiveInnervatePISaved.glowOffset, SurGiveInnervatePISaved.glowOffset)
                    elseif SurGiveInnervatePISaved.glowType == 2 then
                        LCG.AutoCastGlow_Start(frame, formattedColor, 8, nil, SurGiveInnervatePISaved.glowScale, SurGiveInnervatePISaved.glowOffset, SurGiveInnervatePISaved.glowOffset)
                    elseif SurGiveInnervatePISaved.glowType == 3 then
                        LCG.ButtonGlow_Start(frame, formattedColor)
                    elseif SurGiveInnervatePISaved.glowType == 4 then
                        LCG.ProcGlow_Start(frame, {color = formattedColor, xOffset = SurGiveInnervatePISaved.glowOffset, yOffset = SurGiveInnervatePISaved.glowOffset})
                    end
                end
            end,
            hidden = function()
                return not SurGiveInnervatePISaved.glow
            end,
        },
    })
    -- Glowing pulsing animation
    local ag = alertFrame:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local anim = ag:CreateAnimation("Alpha")
    anim:SetFromAlpha(1.0)
    anim:SetToAlpha(0.4)
    anim:SetDuration(0.6)
    anim:SetSmoothing("IN_OUT")

    -- Player Name, perhaps class color later?
    local label = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", alertFrame, "BOTTOM", 0, -4)

    self.alertFrame = alertFrame
    self.icon = icon
    self.ag = ag
    self.label = label
end

local function ShowAlert(unit)
    SurIPI.alertFrame:Show()
    if SurGiveInnervatePISaved.displayName then
        SurIPI.label:SetText(unit)
    else
        SurIPI.label:SetText("")
    end
    if SurGiveInnervatePISaved.glow then
        local frame = LGF.GetFrame(unit)
        if frame then
            SurIPI.frame = frame
            local color = spell == 10060 and SurGiveInnervatePISaved.innervateColor or SurGiveInnervatePISaved.piColor
            local formattedColor = {color.r, color.g, color.b, color.a}
            if SurGiveInnervatePISaved.glowType == 1 then
                LCG.PixelGlow_Start(frame, formattedColor, nil, nil, nil, SurGiveInnervatePISaved.glowScale*2,SurGiveInnervatePISaved.glowOffset,SurGiveInnervatePISaved.glowOffset)
            elseif SurGiveInnervatePISaved.glowType == 2 then
                LCG.AutoCastGlow_Start(frame, formattedColor, 8, nil, SurGiveInnervatePISaved.glowScale, SurGiveInnervatePISaved.glowOffset,SurGiveInnervatePISaved.glowOffset)
            elseif SurGiveInnervatePISaved.glowType == 3 then
                LCG.ButtonGlow_Start(frame, formattedColor)
            elseif SurGiveInnervatePISaved.glowType == 4 then
                LCG.ProcGlow_Start(frame, {color = formattedColor, xOffset = SurGiveInnervatePISaved.glowOffset, yOffset = SurGiveInnervatePISaved.glowOffset})
            end
        end
    end
    SurIPI.ag:Play()
end

local function HideAlert()
    if editModeActive then return end
    if SurIPI.frame then
        if SurGiveInnervatePISaved.glowType == 1 then
            LCG.PixelGlow_Stop(SurIPI.frame)
        elseif SurGiveInnervatePISaved.glowType == 2 then
            LCG.AutoCastGlow_Stop(SurIPI.frame)
        elseif SurGiveInnervatePISaved.glowType == 3 then
            LCG.ButtonGlow_Stop(SurIPI.frame)
        elseif SurGiveInnervatePISaved.glowType == 4 then
            LCG.ProcGlow_Stop(SurIPI.frame)
        end
        SurIPI.frame = nil
    end
    SurIPI.ag:Stop()
    SurIPI.alertFrame:Hide()
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local spell
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_WHISPER" then
        local message, unit = ...
        local name = Ambiguate(unit,"short")
        local spellInfo = C_Spell.GetSpellCooldown(spell)
        if spellInfo and not spellInfo.isActive and name and UnitIsUnit("player",message) then
            ShowAlert(name)
            SurIPI.timer = C_Timer.NewTimer(SurGiveInnervatePISaved.duration, function() HideAlert() end)
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _,_, spellID = ...
        if spellID == spell then
            HideAlert()
        end
    elseif event == "PLAYER_ENTERING_WORLD"then
        local _,class = UnitClassBase("player")
        if class == 5 then
            spell = 10060
            SurIPI.icon:SetTexture(135939)
        elseif class == 11 then
            spell = 29166
            SurIPI.icon:SetTexture(136048)
        else
            spell = nil
        end
        if spell then
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player")
            eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
        end
    end
end)
