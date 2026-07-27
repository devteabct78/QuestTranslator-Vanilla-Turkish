-- Oyuncunun sınıf bilgisi
local playerClassEng = UnitClass("player") -- örn: "Hunter", "Warrior"
local currentClassLower = string.lower(playerClassEng or "")

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

local function ApplyGossipTranslations()
    if QuestTranslator_Settings and QuestTranslator_Settings.enableGossip == false then
        return; 
    end
    
    local rawGreetingText = GetGossipText();
    if rawGreetingText and QuestTranslator_GossipData then
        -- 1. Oyundan gelen ham metindeki sınıf adını "YOUR_CLASS" yap
        local textWithTag = ReplaceClassWithTag(rawGreetingText, currentClassLower)
        local targetNormalized = NormalizeText(textWithTag)
        
        for engText, trText in pairs(QuestTranslator_GossipData) do
            if NormalizeText(engText) == targetNormalized then
                -- 2. Türkçe çevirideki "YOUR_CLASS" etiketini Türkçe sınıf adıyla değiştir
                local trClass = classTrNames[currentClassLower] or currentClassLower
                local finalTrText = string.gsub(trText, "YOUR_CLASS", trClass)
                
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
    ApplyGossipTranslations();
end