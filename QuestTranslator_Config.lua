-- ==========================================
-- AYARLARIN BAŞLATILMASI (VARSAYILAN DEĞERLER)
-- ==========================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
    -- Eklenti yüklendiğinde ayar dosyası yoksa veya boşsa varsayılanları oluştur
    if event == "ADDON_LOADED" and arg1 == "QuestTranslator-Vanilla-Turkish" then -- arg1 kısmına .toc dosyanın ana adını yaz (Örn: "QuestTranslator")
        if not QuestTranslator_Settings then
            QuestTranslator_Settings = {
                enableGossip = true -- Varsayılan olarak Gossip çevirisi açık
            }
        end
    end
end)

-- ==========================================
-- SLASH KOMUTU (/qtvt)
-- ==========================================
SLASH_QTVT1 = "/qtvt"
SlashCmdList["QTVT"] = function(msg)
    if QTVT_ConfigFrame:IsVisible() then
        QTVT_ConfigFrame:Hide()
    else
        QTVT_ConfigFrame:Show()
    end
end

-- ==========================================
-- AYAR PENCERESİ ARAYÜZÜ (UI)
-- ==========================================
-- Ana Pencere
local ConfigFrame = CreateFrame("Frame", "QTVT_ConfigFrame", UIParent)
ConfigFrame:SetWidth(300)
ConfigFrame:SetHeight(150)
ConfigFrame:SetPoint("CENTER", UIParent, "CENTER")
ConfigFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
ConfigFrame:SetMovable(true)
ConfigFrame:EnableMouse(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetScript("OnDragStart", function() this:StartMoving() end)
ConfigFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
ConfigFrame:Hide() -- İlk başta gizli olsun

-- Başlık Metni
local title = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", ConfigFrame, "TOP", 0, -15)
title:SetText("Quest Translator Ayarları")

-- Kapat Butonu
local closeButton = CreateFrame("Button", nil, ConfigFrame, "UIPanelButtonTemplate")
closeButton:SetWidth(80)
closeButton:SetHeight(22)
closeButton:SetPoint("BOTTOM", ConfigFrame, "BOTTOM", 0, 15)
closeButton:SetText("Kapat")
closeButton:SetScript("OnClick", function() ConfigFrame:Hide() end)

-- Gossip Aktif/Pasif Checkbox (Onay Kutusu)
local gossipCheck = CreateFrame("CheckButton", "QTVT_GossipCheckButton", ConfigFrame, "UICheckButtonTemplate")
gossipCheck:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 20, -50)
-- Yanındaki yazıyı ayarlayalım
_G[gossipCheck:GetName().."Text"]:SetText(" Gossip Çevirilerini Aktifleştir")

-- Pencere açıldığında checkbox'ın durumunu ayardan çek
gossipCheck:SetScript("OnShow", function()
    if QuestTranslator_Settings and QuestTranslator_Settings.enableGossip then
        this:SetChecked(1)
    else
        this:SetChecked(nil)
    end
end)

-- Checkbox'a tıklandığında ayarı kaydet
gossipCheck:SetScript("OnClick", function()
    if this:GetChecked() then
        QuestTranslator_Settings.enableGossip = true
    else
        QuestTranslator_Settings.enableGossip = false
    end
end)

function QTVT_ShowGossipCopy()
    local t = GetGossipText()
    if t then
        local f = QTVT_C or CreateFrame("Frame", "QTVT_C", UIParent)
        f:SetWidth(320)
        f:SetHeight(80)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=32, insets={left=11, right=12, top=12, bottom=11}})
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function() this:StartMoving() end)
        f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
        
        local e = QTVT_CE or CreateFrame("EditBox", nil, f)
        e:SetWidth(280)
        e:SetHeight(30)
        e:SetPoint("CENTER", f, "CENTER", 0, 0)
        e:SetMultiLine(true)
        e:SetFontObject(ChatFontNormal)
        e:SetText(t)
        e:HighlightText()
        e:SetScript("OnEscapePressed", function() f:Hide() end)
        f:Show()
    else
        DEFAULT_CHAT_FRAME:AddMessage("Gossip yok.")
    end
end