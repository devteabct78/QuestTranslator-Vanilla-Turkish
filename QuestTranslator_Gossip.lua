-- Font dosyasının addon içindeki tam yolu
local trFontPath = "Interface\\AddOns\\QuestTranslator-Vanilla-Turkish\\Fonts\\ipagui.ttf"

local function ApplyTurkishFont()
    -- NPC ana konuşma metni
    if GossipGreetingText then
        GossipGreetingText:SetFont(trFontPath, 13)
    end

    -- NPC tıklanabilir sohbet/görev seçenekleri (Gossip Butonları)
    for i = 1, 32 do
        local button = getglobal("GossipTitleButton" .. i)
        if button then
            local fontString = button:GetFontString()
            if fontString then
                fontString:SetFont(trFontPath, 13)
            end
        end
    end
    
    -- Eğer normal görev detay pencerelerinde de (Accept/Decline ekranı) font sorunu varsa şunları da dahil edebilirsin:
    if QuestFont then
        QuestFont:SetFont(trFontPath, 13)
    end
    if QuestFontNormalSmall then
        QuestFontNormalSmall:SetFont(trFontPath, 12)
    end
end

-- Oyuncunun sınıf bilgisi
local playerClassEng = UnitClass("player") -- örn: "Hunter", "Warrior"
local currentClassLower = string.lower(playerClassEng or "")

-- Oyuncunun ırk bilgisi (localized: arayüzdeki ad, system: motorun kullandığı ad)
local localizedRace, systemRace = UnitRace("player")
local systemRaceLower = string.lower(systemRace or "")
local localizedRaceLower = string.lower(localizedRace or "")

-- Türkçe ırk adları haritası
local raceTrNames = {
    ["Human"] = "İnsan",
    ["Dwarf"] = "Cüce",
    ["Night Elf"] = "Gece Elfi",
    ["Gnome"] = "Gnom",
    ["Orc"] = "Ork",
    ["Undead"] = "Ölümsüz",
    ["Scourge"] = "Ölümsüz", -- Vanilla API'sinde Undead için sistem "Scourge" döndürür
    ["Tauren"] = "Tauren",
    ["Troll"] = "Trol"
}

-- Türkçe sınıf adları haritası
local classTrNames = {
    ["hunter"] = "avcı",
    ["warrior"] = "savaşçı",
    ["mage"] = "büyücü",
    ["rogue"] = "hırsız",
    ["priest"] = "rahip",
    ["warlock"] = "cadı",
    ["paladin"] = "paladin",
    ["druid"] = "druid",
    ["shaman"] = "şaman"
}

local function NormalizeText(str)
    if not str then return "" end
    str = string.lower(str)
    str = string.gsub(str, "[%s%c]", "")
    return str
end

-- Metindeki ingilizce sınıf adını (hunter vb.) YOUR_CLASS ile değiştiren yardımcı fonksiyon
local function ReplaceClassWithTag(text, classLower)
    if not text or classLower == "" then return text end
    
    local lowerText = string.lower(text)
    local s, e = string.find(lowerText, classLower, 1, true)
    
    if s and e then
        local before = string.sub(text, 1, s - 1)
        local after = string.sub(text, e + 1)
        return before .. "YOUR_CLASS" .. after
    end
    
    return text
end

-- Metindeki ingilizce ırk adını (orc vb.) YOUR_RACE ile değiştiren yardımcı fonksiyon
local function ReplaceRaceWithTag(text, sysRaceLow, locRaceLow)
    if not text then return text end
    local lowerText = string.lower(text)
    
    -- Önce lokal ırk adını kontrol et (örn: undead)
    if locRaceLow ~= "" then
        local s, e = string.find(lowerText, locRaceLow, 1, true)
        if s and e then
            local before = string.sub(text, 1, s - 1)
            local after = string.sub(text, e + 1)
            return before .. "YOUR_RACE" .. after
        end
    end

    -- Eğer sistem adı lokal addan farklıysa (örn: scourge) onu da kontrol et
    if sysRaceLow ~= "" and sysRaceLow ~= locRaceLow then
        local s, e = string.find(lowerText, sysRaceLow, 1, true)
        if s and e then
            local before = string.sub(text, 1, s - 1)
            local after = string.sub(text, e + 1)
            return before .. "YOUR_RACE" .. after
        end
    end
    
    return text
end

local function ApplyGossipTranslations()
    if QuestTranslator_Settings and QuestTranslator_Settings.enableGossip == false then
        return; 
    end
    
    local rawGreetingText = GetGossipText();
    if rawGreetingText and QuestTranslator_GossipData then
        -- 1. Oyundan gelen ham metindeki sınıf ve ırk adını ilgili etiketler ile değiştir
        local textWithTag = ReplaceClassWithTag(rawGreetingText, currentClassLower)
        textWithTag = ReplaceRaceWithTag(textWithTag, systemRaceLower, localizedRaceLower)
        
        local targetNormalized = NormalizeText(textWithTag)
        
        for engText, trText in pairs(QuestTranslator_GossipData) do
            if NormalizeText(engText) == targetNormalized then
                -- 2. Türkçe çevirideki etiketleri Türkçe adlarıyla değiştir
                local trClass = classTrNames[currentClassLower] or currentClassLower
                local trRace = raceTrNames[systemRace] or raceTrNames[localizedRace] or localizedRace
                
                local finalTrText = string.gsub(trText, "YOUR_CLASS", trClass)
                finalTrText = string.gsub(finalTrText, "YOUR_RACE", trRace)
                
                GossipGreetingText:SetText(finalTrText);
                break;
            end
        end
    end
    
    -- Tıklanabilir Seçenekler
    for i = 1, 32 do
        local button = getglobal("GossipTitleButton" .. i);
        if button and button:IsShown() then
            local currentText = button:GetText();
            if currentText and QuestTranslator_OptionData then
                local btnNormalized = NormalizeText(currentText);
                for engOpt, trOpt in pairs(QuestTranslator_OptionData) do
                    if NormalizeText(engOpt) == btnNormalized then
                        button:SetText(trOpt);
                        break;
                    end
                end
            end
        end
    end
end

-- Hook
local original_GossipFrameUpdate = GossipFrameUpdate;
function GossipFrameUpdate()
    original_GossipFrameUpdate();
    ApplyTurkishFont();    
    ApplyGossipTranslations();
end