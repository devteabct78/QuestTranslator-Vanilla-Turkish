local original_GossipFrameUpdate = GossipFrameUpdate;

function GossipFrameUpdate()
    -- Önce orijinal fonksiyonu çalıştır
    original_GossipFrameUpdate(); 
    
    -- AYAR KONTROLÜ: Eğer ayarlar yüklenmişse ve Gossip çevirisi kapalıysa işlemi durdur
    if QuestTranslator_Settings and QuestTranslator_Settings.enableGossip == false then
        return; 
    end
    
    -- NPC'nin söylediği metni al
    local greetingText = GetGossipText();
    
    -- Tablo yüklü mü ve içinde çevirimiz var mı kontrol et
    if greetingText and QuestTranslator_GossipData and QuestTranslator_GossipData[greetingText] then
        GossipGreetingText:SetText(QuestTranslator_GossipData[greetingText]);
    end
end