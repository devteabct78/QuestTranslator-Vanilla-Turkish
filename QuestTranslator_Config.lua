-- ==========================================
-- AYARLARIN BAŞLATILMASI (VARSAYILAN DEĞERLER)
-- ==========================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
    -- Eklenti yüklendiğinde ayar dosyası yoksa veya eksik ayarlar varsa varsayılanları oluştur
    if event == "ADDON_LOADED" and arg1 == "QuestTranslator-Vanilla-Turkish" then
        if not QuestTranslator_Settings then
            QuestTranslator_Settings = {}
        end

        -- Mevcut Gossip ayarı korunuyor
        if QuestTranslator_Settings.enableGossip == nil then
            QuestTranslator_Settings.enableGossip = true
        end

        -- Yeni: Zone Translator varsayılan olarak KAPALI
        if QuestTranslator_Settings.enableZoneTranslator == nil then
            QuestTranslator_Settings.enableZoneTranslator = false
        end

        -- Yeni: Mob/NPC Translator varsayılan olarak KAPALI
        if QuestTranslator_Settings.enableMobNpcTranslator == nil then
            QuestTranslator_Settings.enableMobNpcTranslator = false
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
ConfigFrame:SetWidth(320)
ConfigFrame:SetHeight(210)
ConfigFrame:SetPoint("CENTER", UIParent, "CENTER")
ConfigFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {
        left = 11,
        right = 12,
        top = 12,
        bottom = 11
    }
})
ConfigFrame:SetMovable(true)
ConfigFrame:EnableMouse(true)
ConfigFrame:RegisterForDrag("LeftButton")

ConfigFrame:SetScript("OnDragStart", function()
    this:StartMoving()
end)

ConfigFrame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)

ConfigFrame:Hide()

-- ==========================================
-- BAŞLIK
-- ==========================================
local title = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", ConfigFrame, "TOP", 0, -15)
title:SetText("Quest Translator Ayarları")

-- ==========================================
-- KAPAT BUTONU
-- ==========================================
local closeButton = CreateFrame("Button", nil, ConfigFrame, "UIPanelButtonTemplate")
closeButton:SetWidth(80)
closeButton:SetHeight(22)
closeButton:SetPoint("BOTTOM", ConfigFrame, "BOTTOM", 0, 15)
closeButton:SetText("Kapat")
closeButton:SetScript("OnClick", function()
    ConfigFrame:Hide()
end)

-- ==========================================
-- GOSSIP CHECKBOX
-- ==========================================
local gossipCheck = CreateFrame(
    "CheckButton",
    "QTVT_GossipCheckButton",
    ConfigFrame,
    "UICheckButtonTemplate"
)

gossipCheck:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 20, -50)

_G[gossipCheck:GetName() .. "Text"]:SetText(
    " Gossip Çevirileri"
)

-- Pencere açıldığında ayarı checkbox'a yansıt
gossipCheck:SetScript("OnShow", function()
    if QuestTranslator_Settings
        and QuestTranslator_Settings.enableGossip then

        this:SetChecked(1)
    else
        this:SetChecked(nil)
    end
end)

-- Checkbox değiştiğinde ayarı kaydet
gossipCheck:SetScript("OnClick", function()
    if this:GetChecked() then
        QuestTranslator_Settings.enableGossip = true
    else
        QuestTranslator_Settings.enableGossip = false
    end
end)

-- ==========================================
-- ZONE TRANSLATOR CHECKBOX
-- ==========================================
local zoneCheck = CreateFrame(
    "CheckButton",
    "QTVT_ZoneCheckButton",
    ConfigFrame,
    "UICheckButtonTemplate"
)

zoneCheck:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 20, -90)

_G[zoneCheck:GetName() .. "Text"]:SetText(
    " Bölge Adı Çevirileri"
)

-- Pencere açıldığında ayarı checkbox'a yansıt
zoneCheck:SetScript("OnShow", function()
    if QuestTranslator_Settings
        and QuestTranslator_Settings.enableZoneTranslator then

        this:SetChecked(1)
    else
        this:SetChecked(nil)
    end
end)

-- Checkbox değiştiğinde ayarı kaydet
zoneCheck:SetScript("OnClick", function()
    if this:GetChecked() then
        QuestTranslator_Settings.enableZoneTranslator = true
    else
        QuestTranslator_Settings.enableZoneTranslator = false
    end
end)

-- ==========================================
-- MOB / NPC TRANSLATOR CHECKBOX
-- ==========================================
local mobNpcCheck = CreateFrame(
    "CheckButton",
    "QTVT_MobNpcCheckButton",
    ConfigFrame,
    "UICheckButtonTemplate"
)

mobNpcCheck:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 20, -130)

_G[mobNpcCheck:GetName() .. "Text"]:SetText(
    " Mob/NPC Çevirileri"
)

-- Pencere açıldığında ayarı checkbox'a yansıt
mobNpcCheck:SetScript("OnShow", function()
    if QuestTranslator_Settings
        and QuestTranslator_Settings.enableMobNpcTranslator then

        this:SetChecked(1)
    else
        this:SetChecked(nil)
    end
end)

-- Checkbox değiştiğinde ayarı kaydet
mobNpcCheck:SetScript("OnClick", function()
    if this:GetChecked() then
        QuestTranslator_Settings.enableMobNpcTranslator = true
    else
        QuestTranslator_Settings.enableMobNpcTranslator = false
    end
end)

-- ==========================================
-- GOSSIP METNİNİ GÖSTER
-- ==========================================
function QTVT_ShowGossipCopy()
    local t = GetGossipText()

    if t then
        local f = QTVT_C or CreateFrame("Frame", "QTVT_C", UIParent)

        f:SetWidth(320)
        f:SetHeight(80)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = {
                left = 11,
                right = 12,
                top = 12,
                bottom = 11
            }
        })

        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")

        f:SetScript("OnDragStart", function()
            this:StartMoving()
        end)

        f:SetScript("OnDragStop", function()
            this:StopMovingOrSizing()
        end)

        local e = QTVT_CE or CreateFrame("EditBox", nil, f)

        e:SetWidth(280)
        e:SetHeight(30)
        e:SetPoint("CENTER", f, "CENTER", 0, 0)
        e:SetMultiLine(true)
        e:SetFontObject(ChatFontNormal)
        e:SetText(t)
        e:HighlightText()

        e:SetScript("OnEscapePressed", function()
            f:Hide()
        end)

        f:Show()
    else
        DEFAULT_CHAT_FRAME:AddMessage("Gossip yok.")
    end
end
-- ==========================================
-- MINIMAP BUTTON
-- ==========================================

local minimapButton = CreateFrame(
    "Button",
    "QTVT_MinimapButton",
    Minimap
)

minimapButton:SetWidth(32)
minimapButton:SetHeight(32)

minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)

-- Başlangıç konumu
minimapButton:SetPoint(
    "TOPLEFT",
    Minimap,
    "TOPLEFT",
    -4,
    -4
)

-- Icon
local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")

-- Minimap buton çerçevesi
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetWidth(53)
border:SetHeight(53)
border:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Mouse üzerine gelince tooltip
minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Quest Translator")
    GameTooltip:AddLine("Ayarları açmak için tıklayın.", 1, 1, 1)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Sol tıklama
minimapButton:RegisterForClicks("LeftButtonUp")

minimapButton:SetScript("OnClick", function()
    if QTVT_ConfigFrame:IsVisible() then
        QTVT_ConfigFrame:Hide()
    else
        QTVT_ConfigFrame:Show()
    end
end)