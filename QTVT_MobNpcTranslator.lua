-- Ana Çeviri Fonksiyonu
local function TranslateUnitName(originalName, isPlayer)
    if not originalName or not MobNpcTranslator_Data then return originalName; end
    
    if MobNpcTranslator_Data[originalName] then
        return MobNpcTranslator_Data[originalName]
    else
        -- Eğer bu bir oyuncuysa veya debug modu kapalıysa kaydetme
        if isPlayer then
            return originalName
        end

        -- [YENİ EKLENEN KISIM] Sadece Debug Modu aktifse kaydet
        if QuestTranslator_Settings and QuestTranslator_Settings.enableDebugMode then
            if not DiscoveredMobsAndNpcs then DiscoveredMobsAndNpcs = {} end
            
            if not DiscoveredMobsAndNpcs[originalName] then
                DiscoveredMobsAndNpcs[originalName] = ""
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[QTVT]|r " .. originalName .. " mob/npc eklendi.")
            end
        end
    end
    
    return originalName
end

-- [TÜRKÇE KARAKTER FIX] Yazı nesnesine güvenli ve Türkçe destekli font nesnesini basar
local function ApplySafeFont(fontStringObject, size)
    if not fontStringObject then return end
    
    if ChatFontNormal and fontStringObject.SetFont then
        local fontPath, _, fontFlags = ChatFontNormal:GetFont()
        if fontPath then
            fontStringObject:SetFont(fontPath, size or 13, fontFlags)
            return true
        end
    end
    
    if GameFontNormal and fontStringObject.SetFontObject then
        fontStringObject:SetFontObject(GameFontNormal)
    end
    return false
end

-- [AKILLI BÖLGE TARAYICISI] Nesne ismi ne olursa olsun ekranda mob adını basan FontString'i bulur
local function FindNameObject(frame, nameToFind)
    if not frame then return nil end
    
    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r and r.GetText and r:GetText() == nameToFind then
                return r
            end
        end
    end
    
    if frame.GetChildren then
        local children = { frame:GetChildren() }
        for i = 1, table.getn(children) do
            local c = children[i]
            local found = FindNameObject(c, nameToFind)
            if found then return found end
        end
    end
    
    return nil
end

-- Çeviri Gövdesi
local function DoTargetTranslation()
    if UnitExists("target") then
        local rawName = UnitName("target")
        if rawName then
            local nameFrame = getglobal("TargetFrameName")
            
            if not nameFrame then
                local baseFrame = getglobal("TargetFrame")
                if baseFrame then
                    nameFrame = FindNameObject(baseFrame, rawName)
                end
            end
            
            if nameFrame and nameFrame.SetText then
                ApplySafeFont(nameFrame, 13)
                -- [DÜZELTME] UnitIsPlayer yerine UnitPlayerControlled kullanıldı
                nameFrame:SetText(TranslateUnitName(rawName, UnitPlayerControlled("target")))
            end
        end
    end
end

local function TriggerDelayedTranslation()
    local delayFrame = CreateFrame("Frame")
    delayFrame.t = 0
    delayFrame:SetScript("OnUpdate", function()
        this.t = this.t + arg1
        if this.t >= 0.01 then
            this:SetScript("OnUpdate", nil)
            DoTargetTranslation()
        end
    end)
end

-- ====================================================================
-- EVENT DİNLEYİCİLERİ
-- ====================================================================
local MNT_Frame = CreateFrame("Frame")
MNT_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
MNT_Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
MNT_Frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
MNT_Frame:RegisterEvent("GOSSIP_SHOW")
MNT_Frame:RegisterEvent("QUEST_GREETING")
MNT_Frame:RegisterEvent("QUEST_DETAIL")
MNT_Frame:RegisterEvent("QUEST_PROGRESS")
MNT_Frame:RegisterEvent("QUEST_COMPLETE")

MNT_Frame:SetScript("OnEvent", function()
    if not QuestTranslator_Settings.enableMobNpcTranslator then
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MobNpcTranslator] Türkçe Karakter Desteği Aktif Edildi!|r")
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        TriggerDelayedTranslation()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        if UnitExists("mouseover") and GameTooltipTextLeft1 then
            local rawName = UnitName("mouseover")
            if rawName then
                -- [DÜZELTME] UnitIsPlayer yerine UnitPlayerControlled kullanıldı
                local trName = TranslateUnitName(rawName, UnitPlayerControlled("mouseover"))
                if GameTooltipTextLeft1:GetText() ~= trName then
                    ApplySafeFont(GameTooltipTextLeft1, 14)
                    GameTooltipTextLeft1:SetText(trName)
                    GameTooltip:Show()
                end
            end
        end
    else
        local npcName = UnitName("npc") or UnitName("target")
        if npcName then
            local isPlayer = false
            
            -- [DÜZELTME] Hedef veya NPC bir oyuncu kontrolündeyse (pet dahil) isPlayer = true yap
            if UnitExists("target") and UnitName("target") == npcName and UnitPlayerControlled("target") then
                isPlayer = true
            elseif UnitExists("npc") and UnitName("npc") == npcName and UnitPlayerControlled("npc") then
                isPlayer = true
            end
            
            local trName = TranslateUnitName(npcName, isPlayer)
            
            if event == "GOSSIP_SHOW" and GossipFrameNpcNameText then
                ApplySafeFont(GossipFrameNpcNameText, 16)
                GossipFrameNpcNameText:SetText(trName)
            elseif (event == "QUEST_GREETING" or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE") and QuestFrameNpcNameText then
                ApplySafeFont(QuestFrameNpcNameText, 16)
                QuestFrameNpcNameText:SetText(trName)
            end
        end
    end
end)