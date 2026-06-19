-- Addon: QuestTranslator-Vanilla-Turkish for Vanilla Wow (classic 1.12.1) 2015.02.12
-- Description: Türkçe çeviri addonu.
-- Autor: Platine  (e-mail: fuat.tatar@hotmail.com)
-- Based on addon "QuestJapanizer" v.0.5.8 by lalha and QuestTranslator from Platine  (e-mail: platine.wow@gmail.com)


-- Global Variables
local QTR_version = "1.0.20260619.0529";
local QTR_name = UnitName("player");
local QTR_class= UnitClass("player");
local QTR_race = UnitRace("player");
local QTR_event="";
local QuestTranslator_MessOrig = {
      details    = "Description", 
      objectives = "Objectives", 
      rewards    = "Rewards", 
      itemchoose1= "You will be able to choose one of these rewards:", 
      itemchoose2= "Choose one of these rewards:", 
      itemreceiv1= "You will also receive:", 
      itemreceiv2= "You receiving the reward:", 
      learnspell = "Learn Spell:", 
      reqmoney   = "Required Money:", 
      reqitems   = "Required items:", 
      experience = "Experience:", 
      currquests = "Current Quests", 
      avaiquests = "Available Quests", };
local Original_Font1 = "Fonts\\MORPHEUS.ttf";
local Original_Font2 = "Fonts\\FRIZQT__.ttf";

-- [DÜZELTME] Türkçe font yolunu eklenti klasörünüzü hedefleyecek şekilde buraya tanımlıyoruz.
local QTR_Font = "Interface\\AddOns\\QuestTranslator-Vanilla-Turkish\\Fonts\\ipagui.ttf";

if not QuestTranslator then
   QuestTranslator = { };
end

-- [DÜZELTME] Eklenti pencerelerindeki yazı elemanlarına fontu güvenli bir şekilde basan yardımcı fonksiyon.
local function ApplyTurkishFont()
    if (QuestTranslator_QuestTitle) then QuestTranslator_QuestTitle:SetFont(QTR_Font, 17) end
    if (QuestTranslator_QuestDetail) then QuestTranslator_QuestDetail:SetFont(QTR_Font, 14) end
    if (QuestTranslator_QuestTitle2) then QuestTranslator_QuestTitle2:SetFont(QTR_Font, 17) end
    if (QuestTranslator_QuestDetail2) then QuestTranslator_QuestDetail2:SetFont(QTR_Font, 14) end
    if (QuestTranslator_QuestWarning2) then QuestTranslator_QuestWarning2:SetFont(QTR_Font, 12) end
end

-- İç metinlerdeki tırnak ve ters slaşları korur, satır sonlarını doğrudan tek tırnak içinde NEW_LINE yapar
local function QTR_CleanLuaText(txt)
    if (not txt or txt == "") then return ""; end
    -- 1. Ters slaşları çiftle
    txt = string.gsub(txt, "\\", "\\\\");
    -- 2. Çift tırnakları escape et
    txt = string.gsub(txt, '"', '\\"');
    -- 3. Satır sonlarını doğrudan tırnağı kapatmadan metin içi düz NEW_LINE kelimesine çevir
    txt = string.gsub(txt, "\r\n", "NEW_LINE");
    txt = string.gsub(txt, "\n", "NEW_LINE");
    -- 4. Oyuncu değişkenlerini şablonlaştır
    txt = string.gsub(txt, QTR_name, "YOUR_NAME");
    txt = string.gsub(txt, QTR_class, "YOUR_CLASS");
    txt = string.gsub(txt, QTR_race, "YOUR_RACE");
    return txt;
end

-- Vanilla WoW 1.12 API uyumlu çalışan kopyalama fonksiyonu
function QuestTranslator_CopyMissingToClipboard()
    local questSelected = GetQuestLogSelection();
    if (questSelected == 0) then 
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[QTR] Hata: Quest Log ekranından bir görev seçmelisiniz!|r");
        return; 
    end
    
    local q_title = GetQuestLogTitle(questSelected) or "Bilinmeyen Gorev";
    
    -- Metinleri al ve temizle
    local desc = QTR_CleanLuaText(GetQuestLogQuestText());
    
    -- Hedef metni (Eğer GetObjectiveText boşsa oyun logundaki asıl hedefleri seç)
    local rawObj = GetObjectiveText();
    if (not rawObj or rawObj == "") then
        _, rawObj = GetQuestLogQuestText();
    end
    local obj = QTR_CleanLuaText(rawObj);
    
    local prog = "";
    local comp = "";

    -- ID'yi eklentinin kendi İngilizce başlık listesinden arıyoruz
    local qid = QuestTranslator_SearchIDforName(q_title);
    local str_id = tostring(qid or "0");

    -- İstenen tam ve hatasız Lua format şablonu (Tek bütün tırnak içinde NEW_LINE formatı)
    local template = "-- " .. q_title .. "\n" ..
                     '    ["' .. str_id .. '"] = {\n' ..
                     '    ["Title"]="' .. q_title .. '",\n' ..
                     '    ["Description"]="' .. desc .. '",\n' ..
                     '    ["Objectives"]="' .. obj .. '",\n' ..
                     '    ["Progress"]="' .. prog .. '",\n' ..
                     '    ["Completion"]="' .. comp .. '",\n' ..
                     '    ["minlevel"]="0",\n' ..
                     '    ["questlevel"]="0",\n' ..
                     '    }, -- end ' .. q_title;

    -- Kopyalama Penceresi Oluşturma
    if (not QTR_CopyFrame) then
        QTR_CopyFrame = CreateFrame("Frame", "QTR_CopyFrame", UIParent);
        QTR_CopyFrame:SetWidth(400);
        QTR_CopyFrame:SetHeight(80);
        QTR_CopyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100);
        QTR_CopyFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        });
        QTR_CopyFrame:SetBackdropColor(0, 0, 0, 0.9);
        QTR_CopyFrame:SetFrameStrata("TOOLTIP");
        
        local lbl = QTR_CopyFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
        lbl:SetPoint("TOPLEFT", QTR_CopyFrame, "TOPLEFT", 15, -12);
        lbl:SetText("|cffffff00Şablon Hazır! Kopyalamak için CTRL + C tuşlarına basın:|r");

        QTR_CopyEditBox = CreateFrame("EditBox", "QTR_CopyEditBox", QTR_CopyFrame);
        QTR_CopyEditBox:SetWidth(370);
        QTR_CopyEditBox:SetHeight(20);
        QTR_CopyEditBox:SetPoint("TOPLEFT", QTR_CopyFrame, "TOPLEFT", 15, -30);
        QTR_CopyEditBox:SetFontObject(GameFontHighlightSmall);
        QTR_CopyEditBox:SetAutoFocus(true);
        
        QTR_CopyEditBox:SetScript("OnEscapePressed", function() QTR_CopyFrame:Hide() end);
        
        local ebBg = QTR_CopyEditBox:CreateTexture(nil, "BACKGROUND");
        ebBg:SetTexture(0, 0, 0, 0.6);
        ebBg:SetAllPoints(QTR_CopyEditBox);

        local closeBtn = CreateFrame("Button", nil, QTR_CopyFrame, "UIPanelButtonTemplate");
        closeBtn:SetWidth(60);
        closeBtn:SetHeight(18);
        closeBtn:SetText("Kapat");
        closeBtn:SetPoint("BOTTOMRIGHT", QTR_CopyFrame, "BOTTOMRIGHT", -15, 10);
        closeBtn:SetScript("OnClick", function() QTR_CopyFrame:Hide() end);
    end

    QTR_CopyFrame:Show();
    QTR_CopyEditBox:SetText(template);
    QTR_CopyEditBox:HighlightText();
    QTR_CopyEditBox:SetFocus();
end


function QuestTranslator_CheckVars()
  if (not QTR_PS) then
     QTR_PS = {};
  end
  if (not QTR_PC) then
     QTR_PC = {};
  end
  if (not QTR_SAVED) then
     QTR_SAVED = {};
  end
  if (not QTR_PS["active"]) then
     QTR_PS["active"] = "1";   
  end
  if (not QTR_PS["mode"] ) then
     QTR_PS["mode"] = "2";   
  end
  if (not QTR_PS["transtitle"] ) then
     QTR_PS["transtitle"] = "0";   
  end
  if (not QTR_PS["size"] ) then
     QTR_PS["size"] = "1";   
  end
  if (not QTR_PS["width"] ) then
     QTR_PS["width"] = "1";   
  end

  if (QTR_PS["size"] == "1") then
     QuestTranslator_SizeH = 1;
  else 
     QuestTranslator_SizeH = 2;    
     QuestTranslatorFrame1:SetHeight(525);
     QuestTranslator_QuestDetail:SetHeight(430);
     QTR_ToggleButton2:SetText("^");
  end
  if (QTR_PS["width"] == "1") then
     QuestTranslator_SizeW = 1;
  else 
     QuestTranslator_SizeW = 2;    
     QuestTranslatorFrame1:SetWidth(525);
     QuestTranslator_QuestDetail:SetWidth(495);
     QuestTranslator_QuestTitle:SetWidth(495);
     QTR_ToggleButton3:SetText("<");
  end
  if ( QTR_PS["isGetQuestID"] ) then
     isGetQuestID=QTR_PS["isGetQuestID"];
  end;
end


function QuestTranslator_SetCheckButtonState()
  QuestTranslatorCheckButton0:SetChecked(QTR_PS["active"]=="1");
  QuestTranslatorCheckButton1:SetChecked(QTR_PS["mode"]=="1");
  QuestTranslatorCheckButton2:SetChecked(QTR_PS["mode"]=="2");
  QuestTranslatorCheckButton3:SetChecked(QTR_PS["transtitle"]=="1");
  QuestTranslatorCheckButton4:SetChecked(QTR_PS["size"]=="1");
  QuestTranslatorCheckButton5:SetChecked(QTR_PS["size"]=="2");
  QuestTranslatorCheckButton6:SetChecked(QTR_PS["width"]=="1");
  QuestTranslatorCheckButton7:SetChecked(QTR_PS["width"]=="2");
end


function QuestTranslator_OnLoad1()
  QuestTranslator.frame1 = CreateFrame("Frame");
  QuestTranslator.frame1:RegisterEvent("ADDON_LOADED");
  QuestTranslator.frame1:RegisterEvent("QUEST_LOG_UPDATE");
  QuestTranslator.frame1:SetScript("OnEvent", QuestTranslator_OnEvent1);
  QuestLogDetailScrollFrame:SetScript("OnShow", QuestTranslator_ShowAndUpdateQuestInfo);
  QuestLogDetailScrollFrame:SetScript("OnHide", QuestTranslator_HideQuestInfo);

  ApplyTurkishFont(); -- [DÜZELTME] Boş değişken hatası engellendi ve güvenli fonksiyon çağrıldı.
  QuestTranslatorFrame1:ClearAllPoints();
  QuestTranslatorFrame1:SetPoint("TOPLEFT", QuestLogFrame, "TOPRIGHT", -3, -12);

  QTR_ToggleButton1 = CreateFrame("Button",nil, QuestLogFrame, "UIPanelButtonTemplate");
  QTR_ToggleButton1:SetWidth(35);
  QTR_ToggleButton1:SetHeight(18);
  QTR_ToggleButton1:SetText("QTR");
  QTR_ToggleButton1:Show();
  QTR_ToggleButton1:ClearAllPoints();
  QTR_ToggleButton1:SetPoint("TOPLEFT", QuestLogFrame, "TOPRIGHT", -100, -15);
  QTR_ToggleButton1:SetScript("OnClick", QuestTranslator_ToggleVisibility);

  QTR_ToggleButton2 = CreateFrame("Button",nil, QuestTranslatorFrame1, "UIPanelButtonTemplate");
  QTR_ToggleButton2:SetWidth(15);
  QTR_ToggleButton2:SetHeight(22);
  QTR_ToggleButton2:SetText("v");
  QTR_ToggleButton2:Show();
  QTR_ToggleButton2:ClearAllPoints();
  QTR_ToggleButton2:SetPoint("BOTTOMLEFT", QuestTranslatorFrame1, "BOTTOMRIGHT", -40, 9);
  QTR_ToggleButton2:SetScript("OnClick", QuestTranslator_ChangeFrameHeight);

  QTR_ToggleButton3 = CreateFrame("Button",nil, QuestTranslatorFrame1, "UIPanelButtonTemplate");
  QTR_ToggleButton3:SetWidth(15);
  QTR_ToggleButton3:SetHeight(22);
  QTR_ToggleButton3:SetText(">");
  QTR_ToggleButton3:Show();
  QTR_ToggleButton3:ClearAllPoints();
  QTR_ToggleButton3:SetPoint("BOTTOMLEFT", QuestTranslatorFrame1, "BOTTOMRIGHT", -25, 9);
  QTR_ToggleButton3:SetScript("OnClick", QuestTranslator_ChangeFrameWidth);

  -- Kopyala Butonu kurulumu
  QTR_CopyButton = CreateFrame("Button", "QTR_CopyButton", QuestTranslatorFrame1, "UIPanelButtonTemplate");
  QTR_CopyButton:SetWidth(110);
  QTR_CopyButton:SetHeight(22);
  QTR_CopyButton:SetText("Kopyala");
  QTR_CopyButton:SetFrameStrata("HIGH"); 
  QTR_CopyButton:SetPoint("BOTTOMLEFT", QuestTranslatorFrame1, "BOTTOMRIGHT", -155, 9);
  QTR_CopyButton:SetScript("OnClick", QuestTranslator_CopyMissingToClipboard);
  QTR_CopyButton:Hide();

  if hooksecurefunc then
       hooksecurefunc("QuestLogTitleButton_OnClick", function() QuestTranslator_UpdateQuestInfo() end);
  else
       local QTR_QuestLogTitleButton_OnClik = QuestLogTitleButton_OnClick;
       function QuestLogTitleButton_OnClick(button)
          QuestTranslator_UpdateQuestInfo();
          QTR_QuestLogTitleButton_OnClik(button);
       end
  end
end


function QuestTranslator_OnEvent1()
  if (event == "ADDON_LOADED") then
     QuestTranslator_CheckVars();
     if (DEFAULT_CHAT_FRAME) then
         DEFAULT_CHAT_FRAME:AddMessage("|cffffff00QuestTranslator ver. "..QTR_version.." "..QTR_lang.." - " .. QuestTranslator_Messages.loaded);
     else
         UIErrorsFrame:AddMessage("|cffffff00QuestTranslator ver. "..QTR_version.." "..QTR_lang.." - " .. QuestTranslator_Messages.loaded, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
     end
     QuestTranslator.frame1:UnregisterEvent("ADDON_LOADED");
     if (not isGetQuestID) then
        DetectEmuServer();
     end;
  end

  if (event == "QUEST_LOG_UPDATE") then
     if (QuestTranslatorFrame1:IsVisible()) then
        QuestTranslator_UpdateQuestInfo();
     end
  end
end
  

function QuestTranslator_OnLoad2()
  QuestTranslator.frame2 = CreateFrame("Frame");
  QuestTranslator.frame2:RegisterEvent("QUEST_GREETING");
  QuestTranslator.frame2:RegisterEvent("QUEST_DETAIL");
  QuestTranslator.frame2:RegisterEvent("QUEST_PROGRESS");
  QuestTranslator.frame2:RegisterEvent("QUEST_COMPLETE");
  QuestTranslator.frame2:SetScript("OnEvent", QuestTranslator_OnEvent3);
  
  ApplyTurkishFont(); -- [DÜZELTME] Boş değişken hatası engellendi ve güvenli fonksiyon çağrıldı.
  
  QuestTranslatorFrame2:ClearAllPoints();
  QuestTranslatorFrame2:SetPoint("TOPLEFT", QuestFrame, "TOPRIGHT", -31, -19);
  QuestFrame:SetScript("OnHide", QuestTranslator_Frame2Close);
end


function DetectEmuServer()
  QTR_PS["isGetQuestID"]="0";
  isGetQuestID="0";
end


function QuestTranslator_OnEvent3()
  if (event == "QUEST_GREETING") then
    if (QTR_PS["active"]=="1" and QTR_PS["mode"]=="1") then
       CurrentQuestsText:SetText(QuestTranslator_Messages.currquests);
       CurrentQuestsText:SetFont(QTR_Font, 18);
       AvailableQuestsText:SetText(QuestTranslator_Messages.avaiquests);
       AvailableQuestsText:SetFont(QTR_Font, 18);
    else
       CurrentQuestsText:SetText(QuestTranslator_MessOrig.currquests);
       CurrentQuestsText:SetFont(Original_Font1, 18);
       AvailableQuestsText:SetText(QuestTranslator_MessOrig.avaiquests);
       AvailableQuestsText:SetFont(Original_Font1, 18);
    end
  end

  if (event == "QUEST_DETAIL") then
     QTR_event = "QUEST_DETAIL";
     QuestTranslator_OnEvent2();
     ApplyTurkishFont(); -- [DÜZELTME] Metinler değiştikçe fontu tazelemek için çağrıldı.
  end

  if (event == "QUEST_PROGRESS") then
     QTR_event = "QUEST_PROGRESS";
     QuestTranslator_OnEvent2();
     ApplyTurkishFont(); -- [DÜZELTME] Metinler değiştikçe fontu tazelemek için çağrıldı.
  end

  if (event == "QUEST_COMPLETE") then
     QTR_event = "QUEST_COMPLETE";
     QuestTranslator_OnEvent2();
     ApplyTurkishFont(); -- [DÜZELTME] Metinler değiştikçe fontu tazelemek için çağrıldı.
  end
end


-- [YENİ SİSTEM] Tamamen Objectives (Hedef) Odaklı Dinamik Filtrelemeli Arama Fonksiyonu
function QuestTranslator_SearchIDforName(qqq_title)
    local qqq_ID = 0;
    local qqq_lists = nil;
    local found_match = false;
    local first_fallback_id = nil;
    
    -- Oyundaki mevcut penceredeki Objectives (Görevin Amacı) metnini çekiyoruz
    local currentText = GetObjectiveText() or "";
    
    -- [GÜVENLİK KORUMASI] Eğer Objectives alanı boş geldiyse (İlerleme/Teslimat ekranı veya asenkron gecikme)
    -- ve Quest Log API'si mevcutsa yedek kaynak olarak logdaki metni taramayı dene
    if (currentText == "" and GetQuestLogQuestText) then
        _, currentText = GetQuestLogQuestText();
        currentText = currentText or "";
    end
    
    -- [DİNAMİK REVERSE-TEMPLATE] Oyundan dönen Objectives içinde nadir de olsa isim/sınıf parametresi
    -- bulunma ihtimaline karşı string temizliği ve normalizasyon yapıyoruz
    if currentText ~= "" then
        currentText = string.gsub(currentText, QTR_name, "YOUR_NAME");
        currentText = string.gsub(currentText, QTR_class, "YOUR_CLASS");
        currentText = string.gsub(currentText, QTR_race, "YOUR_RACE");
    end
    
    -- Oyun metninin ilk 25 karakterini kesiyoruz
    local current25Chars = string.sub(currentText, 1, 25);

    -- 1. ADIM: Dizi/Metin kontrolü formatında arama yapıyoruz (Mükerrer zincir görevler için)
    for questKey, questData in pairs(QuestTranslator_QuestList) do
        -- Anahtarın aradığımız görev ismiyle başlayıp başlamadığına bakar (Örn: "Missing in Action")
        if type(questData) == "table" and string.find(questKey, qqq_title, 1, true) == 1 then
            -- Zamanlama ve asenkron veri boşluklarına karşı bulduğumuz İLK geçerli id'yi acil durum fallback'i olarak sakla
            if not first_fallback_id then
                first_fallback_id = questData[1];
            end
            
            -- Veritabanındaki eşleşecek 25 karakterlik veriyi oku ve normalize et
            local targetMatchText = questData[2] or "";
            targetMatchText = string.gsub(targetMatchText, "<name>", "YOUR_NAME");
            targetMatchText = string.gsub(targetMatchText, "<class>", "YOUR_CLASS");
            targetMatchText = string.gsub(targetMatchText, "<race>", "YOUR_RACE");

            -- 25 karakter tam oturuyorsa aradığımız doğru aşamanın ID'sini alıyoruz
            if targetMatchText ~= "" and current25Chars ~= "" and current25Chars == targetMatchText then
                qqq_lists = questData[1];
                found_match = true;
                break;
            end
        end
    end

    -- 2. ADIM: [ASENKRON KİLİTLENME KORUMASI]
    -- Eğer metin oyundan tamamen boş geldiyse ve eşleşme çıkmadıysa arayüzün çökmesini veya 
    -- pencerenin hiç açılmamasını engellemek için hafızadaki ilk geçerli ID'yi otomatik devreye sok
    if not found_match and current25Chars == "" and first_fallback_id then
        qqq_lists = first_fallback_id;
        found_match = true;
    end

    -- 3. ADIM: Eğer yukarıdaki döngüde bir dizi metni eşleşmesi bulamadıysak, standart tekil düz göreve bakıyoruz
    if not found_match then
        qqq_lists = QuestTranslator_QuestList[qqq_title];
    end

    -- 4. ADIM: Orijinal ID ayıklama ve virgüllü çoklu ID yönetimi mantığı
    if (qqq_lists) then
        if ( type(qqq_lists) == "string" and string.find(qqq_lists, ",")==nil ) then
            qqq_ID=tonumber(qqq_lists);
        else
            local QTR_table=QTR_split(tostring(qqq_lists), ",");
            local QTR_multiple = "";
            local QTR_Center="";
            for ii,vv in ipairs(QTR_table) do
                if (not QTR_PC[vv]) then
                    if (QTR_Center=="") then
                        QTR_Center=vv;
                    else
                        QTR_multiple = QTR_multiple .. ", " .. vv;
                    end
                end
            end
            if ( string.len(QTR_Center)>0 ) then
                qqq_ID=tonumber(QTR_Center);
                if ( string.len(QTR_multiple)>0 ) then
                    QTR_multiple = " (" .. string.sub(QTR_multiple, 3) .. ")";
                    QuestTranslator_QuestWarning2:SetText(QuestTranslator_Messages.multipleID .. QTR_multiple);
                end
            end
        end
    end
    return qqq_ID;
end


function QuestTranslator_OnEvent2()
  local q_ID = 0;
  local q_title = GetTitleText();
  
  if ( QTR_PS["active"]=="1" )then
     QuestTranslator_QuestID2:SetText("");
     QuestTranslator_QuestTitle2:SetText(q_title);
     QuestTranslator_QuestDetail2:SetText(QuestTranslator_Messages.missing);
     QuestTranslator_QuestWarning2:SetText("");
     
     if ( q_ID == 0 ) then
        if ( isGetQuestID=="1" ) then
           q_ID = GetQuestID();
        end
        if ( q_ID == 0 ) then
         q_ID = QuestTranslator_SearchIDforName(q_title);
        end
     end
     if ( q_ID > 0 ) then
        local str_id = tostring(q_ID);
        QuestTranslator_QuestID2:SetText("QuestID: " .. str_id);
        QuestTranslator_QuestTitle2:SetText(q_title);
        if (QuestTranslator_QuestData[str_id]) then
           if (QTR_PS["mode"]=="2") then
              QuestTranslator_ShowFrame2(QTR_event, str_id);
           end
        else
           QTR_SAVED[str_id.." TITLE"]=GetTitleText();
           if (QTR_event=="QUEST_DETAIL") then
              QTR_SAVED[str_id.." DESCRIPTION"]=GetQuestText();
              QTR_SAVED[str_id.." OBJECTIVE"]=GetObjectiveText();
           end
           if (QTR_event=="QUEST_PROGRESS") then
              QTR_SAVED[str_id.." PROGRESS"]=GetProgressText();
           end
           if (QTR_event=="QUEST_COMPLETE") then
              QTR_SAVED[str_id.." COMPLETE"]=GetRewardText();
           end
           QuestTranslatorFrame2:Hide();
        end
     end
  end
  if (QTR_event == "QUEST_COMPLETE") then
     if ( q_ID > 0) then
        local str_id = tostring(q_ID);
        QTR_PC[str_id]="OK";
     end
  end
end


function QuestTranslator_ShowFrame2(eventStr, qid)
  QuestTranslator_QuestID2:SetText("QuestID: " .. qid);
  QuestTranslator_QuestDetail2:SetText(QuestTranslator_Messages.missing);
  if (QuestTranslator_QuestData[qid]) then
     QuestTranslator_QuestTitle2:SetText(QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[qid]["Title"]));
     local QTR_text = "";
     if (eventStr == "QUEST_DETAIL") then
        if (QuestTranslator_QuestData[qid]["Description"]) then
           QTR_text = QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[qid]["Description"]);
        end
        local QTR_text2 = "";
        if (QuestTranslator_QuestData[qid]["Objectives"]) then
           QTR_text2 = QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[qid]["Objectives"]);
        end
        QTR_text = QTR_text .. "\n\n" .. QuestTranslator_Messages.objectives .. "\n" .. QTR_text2;
     end
     if (eventStr == "QUEST_PROGRESS") then
        if (QuestTranslator_QuestData[qid]["Progress"]) then
           QTR_text = QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[qid]["Progress"]);
        end
     end
     if (eventStr == "QUEST_COMPLETE") then
        if (QuestTranslator_QuestData[qid]["Completion"]) then
           QTR_text = QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[qid]["Completion"]);
        end
     end
     QuestTranslator_QuestDetail2:SetText(QTR_text);
     QuestTranslatorFrame2:ClearAllPoints();
     QuestTranslatorFrame2:SetPoint("TOPLEFT", QuestFrame, "TOPRIGHT", -31, -19);
     if ( QuestNPCModel ) then
        if ( QuestNPCModel:IsVisible() ) then
           QuestTranslatorFrame2:SetPoint("TOPLEFT", QuestNPCModel, "TOPRIGHT", 0, 42);
        end
     end
     QuestTranslatorFrame2:Show();
  end
end


function QuestTranslator_QuestLog_OnHide()
  if QTR_CopyButton then QTR_CopyButton:Hide() end
  if QTR_CopyFrame then QTR_CopyFrame:Hide() end
end


function QuestTranslator_Frame2Close()
  QuestTranslatorFrame2:Hide();
  QuestFrame_OnHide();
end


function QTR_split(str, c)
  local aCount = 0;
  local array = {};
  local a = string.find(str, c);
  while a do
     aCount = aCount + 1;
     array[aCount] = string.sub(str, 1, a-1);
     str=string.sub(str, a+1);
     a = string.find(str, c);
  end
  aCount = aCount + 1;
  array[aCount] = str;
  return array;
end


function QTR_findlast(source, char)
  if (not source) then
     return 0;
  end
  local lastpos = 0;
  local byte_char = string.byte(char);
  for i=1, table.getn(source) do
     if (string.byte(source,i)==byte_char) then
        lastpos = i;
     end
  end
  return lastpos;
end


function QuestTranslator_ChangeFrameHeight()
  if (QuestTranslator_SizeH == 1) then
     QuestTranslatorFrame1:SetHeight(525);
     QuestTranslator_QuestDetail:SetHeight(430);
     QTR_ToggleButton2:SetText("^");
     QuestTranslator_SizeH = 2;
     QTR_PS["size"] = "2";
  else
     QuestTranslatorFrame1:SetHeight(450);
     QuestTranslator_QuestDetail:SetHeight(350);
     QTR_ToggleButton2:SetText("v");
     QuestTranslator_SizeH = 1;
     QTR_PS["size"] = "1";
  end
end


function QuestTranslator_ChangeFrameWidth()
  if (QuestTranslator_SizeW == 1) then
     QuestTranslatorFrame1:SetWidth(525);
     QuestTranslator_QuestDetail:SetWidth(495);
     QuestTranslator_QuestTitle:SetWidth(495);
     QTR_ToggleButton3:SetText("<");
     QuestTranslator_SizeW = 2;
     QTR_PS["width"] = "2";
  else
     QuestTranslatorFrame1:SetWidth(350);
     QuestTranslator_QuestDetail:SetWidth(320);
     QuestTranslator_QuestTitle:SetWidth(320);
     QTR_ToggleButton3:SetText(">");
     QuestTranslator_SizeW = 1;
     QuestTranslator_SizeW = 1;
     QTR_PS["width"] = "1";
  end
end


function QuestTranslator_OnMouseDown1()
  QuestTranslatorFrame1:StartMoving();
end
  

function QuestTranslator_OnMouseUp1()
  QuestTranslatorFrame1:StopMovingOrSizing();
end


function QuestTranslator_OnMouseDown2()
  QuestTranslatorFrame2:StartMoving();
end
  

function QuestTranslator_OnMouseUp2()
  QuestTranslatorFrame2:StopMovingOrSizing();
end


function QuestTranslator_ToggleVisibility()
  if (QTR_PS["active"]=="0") then
     QTR_PS["active"] = "1";
     QuestTranslator_ShowAndUpdateQuestInfo();
  else
     QTR_PS["active"] = "0";
     QuestTranslator_HideQuestInfo();
  end
end


function QuestTranslator_ShowAndUpdateQuestInfo()
  if (QTR_PS["active"]=="0") then
     return;
  end
  if (QTR_PS["mode"]=="2") then
     QuestTranslatorFrame1:Show();
  end;
  QuestTranslator_UpdateQuestInfo();
end


function QuestTranslator_HideQuestInfo()
  if QTR_CopyButton then QTR_CopyButton:Hide() end
  if QTR_CopyFrame then QTR_CopyFrame:Hide() end
  QuestTranslatorFrame1:Hide();
end


function QuestTranslator_UpdateQuestInfo()
  if (QTR_PS["active"]=="0") then
     return;
  end
  local questSelected = GetQuestLogSelection();
  if (GetQuestLogTitle(questSelected) == nil) then
     return;
  end
  local questTitle = GetQuestLogTitle(questSelected);
  if (isHeader) then
     return;
  end

  local qid = QuestTranslator_SearchIDforName(questTitle);
  local str_id = tostring(qid or "0");
  QuestTranslator_QuestID:SetText("QuestID: " .. str_id);

  if (QuestTranslator_QuestData[str_id] and str_id ~= "0") then
     if QTR_CopyButton then QTR_CopyButton:Hide() end
     QTR_objectives  = QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[str_id]["Objectives"]);
     QTR_description = QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[str_id]["Description"]);
     QTR_descripFull = QuestTranslator_Messages.details .. "\n" .. QTR_description;
     QTR_translator = "";
     if (QuestTranslator_QuestData[str_id]["Translator"]) then
        if (QuestTranslator_QuestData[str_id]["Translator"]>"") then
             QTR_translator = "\n\n" .. QuestTranslator_Messages.translator .. " " .. QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[str_id]["Translator"]);
        end
     end
     QuestTranslator_QuestTitle:SetText(QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[str_id]["Title"]));
     QuestTranslator_QuestDetail:SetText(QTR_objectives .. "\n\n" .. QTR_descripFull .. QTR_translator);
  else
     QuestTranslator_QuestTitle:SetText(questTitle);
     QuestTranslator_QuestDetail:SetText("|cffff0000" .. QuestTranslator_Messages.missing .. "|r\n\nBu görevin temiz Lua şablonunu panoya kopyalamak için sağ alttaki butona tıklayın.");
     if QTR_CopyButton then QTR_CopyButton:Show() end
  end 
  ApplyTurkishFont(); -- [DÜZELTME] Log güncellendikçe fontu yeniler.
end


function QuestTranslator_ExpandUnitInfo(msg)
  if (not msg) then return ""; end -- [DÜZELTME] Çökme ihtimaline karşı nil koruması.
  msg = string.gsub(msg, "NEW_LINE", "\n");
  msg = string.gsub(msg, "YOUR_NAME", QTR_name);
  msg = string.gsub(msg, "YOUR_CLASS", QTR_class);
  msg = string.gsub(msg, "YOUR_RACE", QTR_race);
  return msg;
end