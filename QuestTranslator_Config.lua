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

        -- Yeni: Minimap butonunun açısını kaydediyoruz ki her girişte
        -- başka bir addonla aynı noktaya (2.5 rad) düşüp üst üste binmesin
        if QuestTranslator_Settings.minimapAngle == nil then
            QuestTranslator_Settings.minimapAngle = 2.5
        end

        if QTVT_MinimapButton and QTVT_UpdateMinimapButtonPosition then
            QTVT_UpdateMinimapButtonPosition(QuestTranslator_Settings.minimapAngle)
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
ConfigFrame:SetHeight(250)
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

gossipCheck:SetPoint(
    "TOPLEFT",
    ConfigFrame,
    "TOPLEFT",
    20,
    -90
)
_G[gossipCheck:GetName() .. "Text"]:SetText(
    " Gossip Çevirileri"
)
gossipCheck:SetChecked(1)
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

zoneCheck:SetPoint(
    "TOPLEFT",
    ConfigFrame,
    "TOPLEFT",
    20,
    -130
)

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

mobNpcCheck:SetPoint(
    "TOPLEFT",
    ConfigFrame,
    "TOPLEFT",
    20,
    -170
)

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
-- GÖREV ÇEVİRİLERİ CHECKBOX
-- ==========================================
local questCheck = CreateFrame(
    "CheckButton",
    "QTVT_QuestCheckButton",
    ConfigFrame,
    "UICheckButtonTemplate"
)

questCheck:SetPoint(
    "TOPLEFT",
    ConfigFrame,
    "TOPLEFT",
    20,
    -50
)

_G[questCheck:GetName() .. "Text"]:SetText(
    " Görev Çevirileri"
)

-- Her zaman işaretli
questCheck:SetChecked(1)

-- Read Only:
-- Kullanıcının checkbox'a tıklayıp durumunu değiştirmesini engeller
questCheck:SetScript("OnClick", function()
    this:SetChecked(1)
end)

questCheck:SetScript("OnShow", function()
    this:SetChecked(1)
end)

-- Mouse tıklamalarını tamamen engelle
questCheck:EnableMouse(false)
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
-- MINIMAP BUTTON (KESİN ÇÖZÜM)
-- ==========================================

local minimapButton = CreateFrame("Button", "QTVT_MinimapButton", Minimap)
minimapButton:SetWidth(32)
minimapButton:SetHeight(32)

-- Diğer minimap butonları genelde MEDIUM katmanda çizildiği için, LOW'da kalırsak
-- onların arkasında/altında eziliyoruz (ikon görünmeyip sadece boş halka kalıyor).
-- Katmanı MEDIUM'a çekip level'ı da belirgin şekilde yüksek tutuyoruz.
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)

minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:RegisterForDrag("LeftButton")

-- 1. ADIM: İkonun altının boş kalmaması için siyah bir zemin oluşturuyoruz
local bg = minimapButton:CreateTexture(nil, "BACKGROUND")
bg:SetWidth(20)
bg:SetHeight(20)
bg:SetPoint("CENTER", minimapButton, "CENTER", -1, 1)
bg:SetTexture(0, 0, 0, 1) -- Katı siyah zemin

-- İkonu kesin çalışan bir parşömen ikonuyla güncelliyoruz
local icon = minimapButton:CreateTexture(nil, "ARTWORK")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", minimapButton, "CENTER", -1, 1)
icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")

-- 3. ADIM: Metal çerçeveyi en üste (OVERLAY) koyuyoruz
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetWidth(53)
border:SetHeight(53)
border:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Tooltip Eventleri
minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Quest Translator")
    GameTooltip:AddLine("Ayarları açmak için tıklayın.", 1, 1, 1)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

minimapButton:RegisterForClicks("LeftButtonUp")
minimapButton:SetScript("OnClick", function()
    if QTVT_ConfigFrame:IsVisible() then
        QTVT_ConfigFrame:Hide()
    else
        QTVT_ConfigFrame:Show()
    end
end)

-- Dairesel Sürükleme (Drag & Drop)
local currentAngle = 2.5

function QTVT_UpdateMinimapButtonPosition(angle)
    currentAngle = angle
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Kayıtlı bir açı varsa onu kullan (yoksa varsayılan 2.5 ile başla).
-- QuestTranslator_Settings henüz yüklenmediyse (ilk açılış) ADDON_LOADED
-- tetiklendiğinde yukarıdaki blok pozisyonu tekrar günceller.
if QuestTranslator_Settings and QuestTranslator_Settings.minimapAngle then
    QTVT_UpdateMinimapButtonPosition(QuestTranslator_Settings.minimapAngle)
else
    QTVT_UpdateMinimapButtonPosition(currentAngle)
end

minimapButton:SetScript("OnDragStart", function()
    this:SetScript("OnUpdate", function()
        local xpos, ypos = GetCursorPosition()
        local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
        
        xpos = xpos / Minimap:GetEffectiveScale()
        ypos = ypos / Minimap:GetEffectiveScale()
        
        local dx = xpos - (xmin + Minimap:GetWidth() / 2)
        local dy = ypos - (ymin + Minimap:GetHeight() / 2)
        
        local angle = math.atan2(dy, dx)
        QTVT_UpdateMinimapButtonPosition(angle)
    end)
end)

minimapButton:SetScript("OnDragStop", function()
    this:SetScript("OnUpdate", nil)
    -- Kullanıcının seçtiği konumu kaydet, bir daha başka addonla çakışmasın
    if QuestTranslator_Settings then
        QuestTranslator_Settings.minimapAngle = currentAngle
    end
end)