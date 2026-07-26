local original_GossipFrameUpdate = GossipFrameUpdate;

function GossipFrameUpdate()
    original_GossipFrameUpdate(); 
    
    if QuestTranslator_Settings and QuestTranslator_Settings.enableGossip == false then
        return; 
    end
    
    -- 1. Ana NPC Karşılama Metnini Çevir
    local greetingText = GetGossipText();
    if greetingText and QuestTranslator_GossipData and QuestTranslator_GossipData[greetingText] then
        GossipGreetingText:SetText(QuestTranslator_GossipData[greetingText]);
    end
    
    -- 2. Ekrandaki Tüm Gossip / Seçenek Butonlarını Doğrudan Metin Üzerinden Çevir
    for i = 1, 32 do
        local button = getglobal("GossipTitleButton" .. i);
        if button and button:IsShown() then
            local currentText = button:GetText();
            if currentText and QuestTranslator_OptionData and QuestTranslator_OptionData[currentText] then
                button:SetText(QuestTranslator_OptionData[currentText]);
            end
        end
    end
end