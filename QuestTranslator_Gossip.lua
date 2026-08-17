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

    -- 2. WoW DB Satır Başı ve Değişken Etiketlerini ($B, $b, $N, $C, $R, $g/G vb.) Temizle
    str = string.gsub(str, "%$[bB]", "")
    str = string.gsub(str, "%$[nN]", "")
    str = string.gsub(str, "%$[cC]", "")
    str = string.gsub(str, "%$[rR]", "")
    str = string.gsub(str, "%$[gG]", "")

    -- 3. Tipografik/akıllı tırnak işaretlerini standart tırnağa dönüştür
    str = string.gsub(str, "’", "'")
    str = string.gsub(str, "‘", "'")
    str = string.gsub(str, "`", "'")
    
    -- 4. Hepsini küçük harfe çevir
    str = string.lower(str)
    
    -- 5. Tüm boşlukları, satır başlarını (\n, \r) ve kontrol karakterlerini sil
    str = string.gsub(str, "[%s%c]", "")
    
    return str
end

-- Metindeki oyuncu adını YOUR_NAME ile değiştiren yardımcı fonksiyon
local function ReplaceNameWithTag(text, nameLower)
    if not text or nameLower == "" then return text end
    
    local lowerText = string.lower(text)
    local s, e = string.find(lowerText, nameLower, 1, true)
    
    if s and e then
        local before = string.sub(text, 1, s - 1)
        local after = string.sub(text, e + 1)
        return before .. "YOUR_NAME" .. after
    end
    
    return text
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
    
    -- EĞER BİRLEŞTİRİLMİŞ TABLO YOKSA İŞLEM YAPMA
    if not QuestTranslator_MergedGossip then return end

    -- Eğer önbellek henüz oluşturulmadıysa ilk kullanımda bir kere oluştur
    -- Bu sayede her NPC'ye tıkladığında değil, sadece ilkinde çalışır ve indeksler
    if not next(GossipCache) then
        BuildGossipCache()
    end

    local rawGreetingText = GetGossipText();
    if rawGreetingText then
        playerName = playerName or UnitName("player")
        playerNameLower = playerNameLower == "" and string.lower(playerName or "") or playerNameLower
        
        -- 1. Oyundan gelen ham metindeki ad, sınıf ve ırk adını etiketler ile değiştir
        local textWithTag = ReplaceNameWithTag(rawGreetingText, playerNameLower)
        textWithTag = ReplaceClassWithTag(textWithTag, currentClassLower)
        textWithTag = ReplaceRaceWithTag(textWithTag, systemRaceLower, localizedRaceLower)
        
        local targetNormalized = NormalizeText(textWithTag)
        
        -- SADECE ÖNBELLEKTE (HASH TABLE) DOĞRUDAN ARA - O(1) HIZI
        local trText = GossipCache[targetNormalized]
        if trText then
            -- 2. Türkçe çevirideki etiketleri karşılıklarıyla değiştir
            local trClass = classTrNames[currentClassLower] or currentClassLower
            local trRace = raceTrNames[systemRace] or raceTrNames[localizedRace] or localizedRace
            
            local finalTrText = string.gsub(trText, "YOUR_NAME", playerName or "")
            finalTrText = string.gsub(finalTrText, "YOUR_CLASS", trClass)
            finalTrText = string.gsub(finalTrText, "YOUR_RACE", trRace)
            
            GossipGreetingText:SetText(finalTrText);
        end
    end
    
    -- Tıklanabilir Seçenekler (Gossip Options)
    for i = 1, 32 do
        local button = getglobal("GossipTitleButton" .. i);
        if button and button:IsShown() then
            local currentText = button:GetText();
            if currentText then
                local btnNormalized = NormalizeText(currentText);
                
                -- YİNE AYNI ŞEKİLDE DÖNGÜ YERİNE ÖNBELLEKTE DOĞRUDAN ARA
                local trOpt = GossipCache[btnNormalized]
                if trOpt then
                    button:SetText(trOpt);
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