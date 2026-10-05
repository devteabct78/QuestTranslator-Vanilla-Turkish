local fontPath = "Interface\\AddOns\\QuestTranslator-Vanilla-Turkish\\Fonts\\ipagui.ttf"

local function ApplyTurkishFontToZones()
    MinimapZoneText:SetFont(fontPath, 12, "OUTLINE")
    ZoneTextString:SetFont(fontPath, 32, "OUTLINE")
    SubZoneTextString:SetFont(fontPath, 24, "OUTLINE")
end

-- Bölgeleri kontrol eden ve ekleyen yardımcı fonksiyon
local function CheckAndLogZone(zName)
    if zName and zName ~= "" then
        -- [YENİ EKLENEN KISIM] Sadece Debug Modu aktifse kaydet
        if QuestTranslator_Settings and QuestTranslator_Settings.enableDebugMode then
            if not DiscoveredZones then DiscoveredZones = {} end
            
            if not ZoneTranslator_ZoneData[zName] and not DiscoveredZones[zName] then
                DiscoveredZones[zName] = ""
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[QTVT]|r " .. zName .. " bölgesi eklendi.")
            end
        end
    end
end

-- ANA ÇEVİRİ VE EKRANA BASMA FONKSİYONU
local function UpdateZoneTexts()
    if not ZoneTranslator_ZoneData then return; end

    local miniMapName = GetMinimapZoneText()
    CheckAndLogZone(miniMapName)
    if miniMapName and ZoneTranslator_ZoneData[miniMapName] then
        MinimapZoneText:SetText(ZoneTranslator_ZoneData[miniMapName])
    end

    local zoneName = GetZoneText()
    CheckAndLogZone(zoneName)
    if zoneName and ZoneTranslator_ZoneData[zoneName] then
        ZoneTextString:SetText(ZoneTranslator_ZoneData[zoneName])
    end

    local subZoneName = GetSubZoneText()
    CheckAndLogZone(subZoneName)
    if subZoneName and ZoneTranslator_ZoneData[subZoneName] then
        SubZoneTextString:SetText(ZoneTranslator_ZoneData[subZoneName])
    end
end

local ZT_Frame = CreateFrame("Frame")

ZT_Frame:RegisterEvent("ZONE_CHANGED")
ZT_Frame:RegisterEvent("ZONE_CHANGED_INDOORS")
ZT_Frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ZT_Frame:RegisterEvent("MINIMAP_ZONE_CHANGED")
ZT_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")

ZT_Frame:SetScript("OnEvent", function()
    if not QuestTranslator_Settings.enableZoneTranslator then
        return
    end
    ApplyTurkishFontToZones() 
    UpdateZoneTexts()
end)