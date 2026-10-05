-- Klasör adı değiştiği için font yolu da ZoneTranslator-Vanilla-Turkish olarak ayarlandı.
local fontPath = "Interface\\AddOns\\QuestTranslator-Vanilla-Turkish\\Fonts\\ipagui.ttf"

local function ApplyTurkishFontToZones()
    -- Yorum satırları kaldırıldı ve daha net görünmesi için OUTLINE eklendi
    MinimapZoneText:SetFont(fontPath, 12, "OUTLINE")
    ZoneTextString:SetFont(fontPath, 32, "OUTLINE")
    SubZoneTextString:SetFont(fontPath, 24, "OUTLINE")
end

-- Bölgeleri kontrol eden ve ekleyen yardımcı fonksiyon
local function CheckAndLogZone(zName)
    if zName and zName ~= "" then
        -- [DÜZELTME] Tablo henüz oluşmamışsa anında oluştur
        if not DiscoveredZones then DiscoveredZones = {} end
        
        -- Eğer veri tabanında çevirisi yoksa ve daha önce eklenmemişse
        if not ZoneTranslator_ZoneData[zName] and not DiscoveredZones[zName] then
            DiscoveredZones[zName] = ""
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[QTVT]|r " .. zName .. " bölgesi eklendi.")
        end
    end
end

-- ANA ÇEVİRİ VE EKRANA BASMA FONKSİYONU
local function UpdateZoneTexts()
    if not ZoneTranslator_ZoneData then return; end

    -- A) MİNİMAP ÇEVİRİSİ
    local miniMapName = GetMinimapZoneText()
    CheckAndLogZone(miniMapName)
    if miniMapName and ZoneTranslator_ZoneData[miniMapName] then
        MinimapZoneText:SetText(ZoneTranslator_ZoneData[miniMapName])
    end

    -- B) EKRAN ORTASI BÜYÜK YAZI (Ana Bölge)
    local zoneName = GetZoneText()
    CheckAndLogZone(zoneName)
    if zoneName and ZoneTranslator_ZoneData[zoneName] then
        ZoneTextString:SetText(ZoneTranslator_ZoneData[zoneName])
    end

    -- C) EKRAN ORTASI KÜÇÜK YAZI (Alt Bölge)
    local subZoneName = GetSubZoneText()
    CheckAndLogZone(subZoneName)
    if subZoneName and ZoneTranslator_ZoneData[subZoneName] then
        SubZoneTextString:SetText(ZoneTranslator_ZoneData[subZoneName])
    end
end

-- OLAY (EVENT) DİNLEYİCİSİ ÇERÇEVESİ
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
    -- Fontu aktif etmek için buradaki yorum satırı da kaldırıldı:
    ApplyTurkishFontToZones() 
    
    UpdateZoneTexts()
end)