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

-- Oyuncunun ad bilgisi
local playerName = UnitName("player")
local playerNameLower = string.lower(playerName or "")

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
    if not str or str == "" then return "" end
    
    -- 1. WoW Renk Kodlarını Temizle (|cFFFF0000 ve |r)
    str = string.gsub(str, "|c%x%x%x%x%x%x%x%x", "")
    str = string.gsub(str, "|r", "")

    -- 2. Cinsiyet etiketlerini çöz (Tüm $g varyasyonları)
    local sex = UnitSex("player")
    str = string.gsub(str, "%$[gG]%s*([^%s:;%p]+)%s*:%s*([^%s:;%p]+)%s*;?", function(maleWord, femaleWord)
        return (sex == 3) and femaleWord or maleWord
    end)

    -- 3. WoW DB Satır Başı ve Değişken Etiketlerini Temizle ($B, $N, $C, $R vb.)
    str = string.gsub(str, "%$[a-zA-Z]", "")
    
    -- 4. Hepsini küçük harfe çevir
    str = string.lower(str)
    
    -- 5. NÜKLEER SEÇENEK: Sadece harfler ve rakamlar kalsın!
    -- Tüm boşluklar, görünmez karakterler ve noktalama işaretleri silinir.
    str = string.gsub(str, "[^a-z0-9]", "")
    
    return str
end

-- Metindeki oyuncu adını, kelime bütünlüğünü koruyarak değiştiren fonksiyon
local function ReplaceNameWithTag(text, nameLower)
    if not text or nameLower == "" then return text end
    local paddedText = " " .. string.lower(text) .. " "
    local pattern = "(%A)" .. nameLower .. "(%A)"
    paddedText = string.gsub(paddedText, pattern, "%1YOUR_NAME%2")
    paddedText = string.gsub(paddedText, pattern, "%1YOUR_NAME%2")
    return string.sub(paddedText, 2, -2)
end

-- Metindeki ingilizce sınıf adını, kelime bütünlüğünü koruyarak değiştiren fonksiyon
local function ReplaceClassWithTag(text, classLower)
    if not text or classLower == "" then return text end
    local paddedText = " " .. string.lower(text) .. " "
    local pattern = "(%A)" .. classLower .. "(%A)"
    paddedText = string.gsub(paddedText, pattern, "%1YOUR_CLASS%2")
    paddedText = string.gsub(paddedText, pattern, "%1YOUR_CLASS%2")
    return string.sub(paddedText, 2, -2)
end

-- Metindeki ingilizce ırk adını, kelime bütünlüğünü koruyarak değiştiren fonksiyon
local function ReplaceRaceWithTag(text, raceLower)
    if not text or raceLower == "" then return text end
    local paddedText = " " .. string.lower(text) .. " "
    local pattern = "(%A)" .. raceLower .. "(%A)"
    paddedText = string.gsub(paddedText, pattern, "%1YOUR_RACE%2")
    paddedText = string.gsub(paddedText, pattern, "%1YOUR_RACE%2")
    return string.sub(paddedText, 2, -2)
end

-------------------------------------------------------------------------------
-- OPTİMİZASYON: HASH TABLE (ÖNBELLEK) SİSTEMİ
-------------------------------------------------------------------------------
local GossipCache = {}

local function BuildGossipCache()
    if not QuestTranslator_MergedGossip then return end
    
    -- Önceki veriyi temizle (Eğer tablo güncellenirse diye)
    GossipCache = {}
    
    for engText, trText in pairs(QuestTranslator_MergedGossip) do
        local normKey = NormalizeText(engText)
        if normKey ~= "" then
            GossipCache[normKey] = trText
        end
    end
end
-------------------------------------------------------------------------------

local function ApplyGossipTranslations()
    if QuestTranslator_Settings and QuestTranslator_Settings.enableGossip == false then
        return; 
    end
    
    if not QuestTranslator_MergedGossip then return end

    if not next(GossipCache) then
        BuildGossipCache()
    end

    local rawGreetingText = GetGossipText();
    if rawGreetingText then
        playerName = playerName or UnitName("player")
        playerNameLower = playerNameLower == "" and string.lower(playerName or "") or playerNameLower
        
        -- 1. ADIM: Önce metnin orijinal halini (etiketlere çevirmeden) normalize edip arayalım
        local rawNormalized = NormalizeText(rawGreetingText)
        local trText = GossipCache[rawNormalized]
        
        -- 2. ADIM: Orijinal haliyle eşleşme yoksa (DB'de YOUR_NAME/CLASS/RACE kullanılmış olabilir), etiketli halini arayalım
        if not trText then
            local textWithTag = ReplaceNameWithTag(rawGreetingText, playerNameLower)
            textWithTag = ReplaceClassWithTag(textWithTag, currentClassLower)
            textWithTag = ReplaceRaceWithTag(textWithTag, localizedRaceLower)
            
            local targetNormalized = NormalizeText(textWithTag)
            trText = GossipCache[targetNormalized]
        end
        
        if trText then
            -- Türkçe çevirideki etiketleri karşılıklarıyla değiştir
            local trClass = classTrNames[currentClassLower] or currentClassLower
            local trRace = raceTrNames[systemRace] or raceTrNames[localizedRace] or localizedRace
            
            local finalTrText = string.gsub(trText, "YOUR_NAME", playerName or "")
            finalTrText = string.gsub(finalTrText, "YOUR_CLASS", trClass)
            finalTrText = string.gsub(finalTrText, "YOUR_RACE", trRace)
            
            -- Türkçe çeviride $g kullanılmışsa onu da cinsiyete göre ekrana bas
            local sex = UnitSex("player")
            finalTrText = string.gsub(finalTrText, "%$[gG]%s*([^%s:;%p]+)%s*:%s*([^%s:;%p]+)%s*;?", function(maleWord, femaleWord)
                return (sex == 3) and femaleWord or maleWord
            end)
            
            GossipGreetingText:SetText(finalTrText);
        end
    end
    
    -- Tıklanabilir Seçenekler (Gossip Options)
    for i = 1, 32 do
        local button = getglobal("GossipTitleButton" .. i);
        if button and button:IsShown() then
            local currentText = button:GetText();
            if currentText then
                -- Butonlar için de aynı 2 aşamalı aramayı uyguluyoruz
                local rawBtnNormalized = NormalizeText(currentText);
                local trOpt = GossipCache[rawBtnNormalized]
                
                if not trOpt then
                    local btnWithTag = ReplaceNameWithTag(currentText, playerNameLower)
                    btnWithTag = ReplaceClassWithTag(btnWithTag, currentClassLower)
                    btnWithTag = ReplaceRaceWithTag(btnWithTag, localizedRaceLower)
                    
                    local targetBtnNormalized = NormalizeText(btnWithTag)
                    trOpt = GossipCache[targetBtnNormalized]
                end
                
                if trOpt then
                    local trClass = classTrNames[currentClassLower] or currentClassLower
                    local trRace = raceTrNames[systemRace] or raceTrNames[localizedRace] or localizedRace
                    
                    local finalTrOpt = string.gsub(trOpt, "YOUR_NAME", playerName or "")
                    finalTrOpt = string.gsub(finalTrOpt, "YOUR_CLASS", trClass)
                    finalTrOpt = string.gsub(finalTrOpt, "YOUR_RACE", trRace)
                    
                    -- Butonlarda $g etiketleri varsa cinsiyete göre düzenle
                    local sex = UnitSex("player")
                    finalTrOpt = string.gsub(finalTrOpt, "%$[gG]%s*([^%s:;%p]+)%s*:%s*([^%s:;%p]+)%s*;?", function(maleWord, femaleWord)
                        return (sex == 3) and femaleWord or maleWord
                    end)
                    
                    button:SetText(finalTrOpt);
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