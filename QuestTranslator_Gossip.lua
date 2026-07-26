-- Metindeki tüm boşlukları, newlineları ve görünmeyen gizli karakterleri silip sadece harf/rakam bırakır
local function NormalizeText(str)
    if not str then return "" end
    -- Sadece alfanümerik karakterleri ve temel noktalama işaretlerini tut, gerisini temizle
    str = string.lower(str)
    str = string.gsub(str, "[%s%c]", "") -- Bütün whitespace ve control karakterlerini sil
    return str
end

local function ApplyGossipTranslations()
    if QuestTranslator_Settings and QuestTranslator_Settings.enableGossip == false then
        return; 
    end
    
    -- 1. Ana NPC Karşılama Metni
    local rawGreetingText = GetGossipText();
    if rawGreetingText and QuestTranslator_GossipData then
        local targetNormalized = NormalizeText(rawGreetingText);
        
        for engText, trText in pairs(QuestTranslator_GossipData) do
            if NormalizeText(engText) == targetNormalized then
                GossipGreetingText:SetText(trText);
                break;
            end
        end
    end
    
    -- 2. Tıklanabilir Seçenekler
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