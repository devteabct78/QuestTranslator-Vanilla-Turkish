-- Addon: QuestTranslator-Vanilla-Turkish for Vanilla Wow (classic 1.12.1) 
-- Description: Türkçe çeviri addonu. (Karma Eşleştirme Güncellemesi)
-- Autor: Platine  (e-mail: fuat.tatar@hotmail.com)
-- Based on addon "QuestJapanizer" v.0.5.8 by lalha and QuestTranslator from Platine

-- Global Variables
local QTR_version = "1.0.20261026.2307";
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

-- Türkçe font yolunu eklenti klasörünüzü hedefleyecek şekilde buraya tanımlıyoruz.
local QTR_Font = "Interface\\AddOns\\QuestTranslator-Vanilla-Turkish\\Fonts\\ipagui.ttf";

if not QuestTranslator then
   QuestTranslator = { };
end

-- Eklenti pencerelerindeki yazı elemanlarına fontu güvenli bir şekilde basan yardımcı fonksiyon.
local function ApplyTurkishFont()
    if (QuestTranslator_QuestTitle) then QuestTranslator_QuestTitle:SetFont(QTR_Font, 17) end
    if (QuestTranslator_QuestDetail) then QuestTranslator_QuestDetail:SetFont(QTR_Font, 14) end
    if (QuestTranslator_QuestTitle2) then QuestTranslator_QuestTitle2:SetFont(QTR_Font, 17) end
    if (QuestTranslator_QuestDetail2) then QuestTranslator_QuestDetail2:SetFont(QTR_Font, 14) end
    if (QuestTranslator_QuestWarning2) then QuestTranslator_QuestWarning2:SetFont(QTR_Font, 12) end
    
    -- Kitap/Mektup Yazı Elemanları fontları
    if (QuestTranslator_BookTitle) then QuestTranslator_BookTitle:SetFont(QTR_Font, 18) end
    if (QuestTranslator_BookDetail) then QuestTranslator_BookDetail:SetFont(QTR_Font, 14) end
end

-- İç metinlerdeki tırnak ve ters slaşları korur, satır sonlarını doğrudan tek tırnak içinde NEW_LINE yapar
local function QTR_CleanLuaText(txt)
    if (not txt or txt == "") then return ""; end
    txt = string.gsub(txt, "\\", "\\\\");
    txt = string.gsub(txt, '"', '\\"');
    txt = string.gsub(txt, "\r\n", "NEW_LINE");
    txt = string.gsub(txt, "\n", "NEW_LINE");
    txt = string.gsub(txt, QTR_name, "YOUR_NAME");
    txt = string.gsub(txt, QTR_class, "YOUR_CLASS");
    txt = string.gsub(txt, QTR_race, "YOUR_RACE");
    return txt;
end

-- Eksik görevleri panoya kopyalama
function QuestTranslator_CopyMissingToClipboard()
    local questSelected = GetQuestLogSelection();
    if (questSelected == 0) then 
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[QTR] Hata: Quest Log ekranından bir görev seçmelisiniz!|r");
        return; 
    end
    
    local q_title = GetQuestLogTitle(questSelected) or "Bilinmeyen Gorev";
    local desc = QTR_CleanLuaText(GetQuestLogQuestText());
    
    local rawObj = GetObjectiveText();
    if (not rawObj or rawObj == "") then
        _, rawObj = GetQuestLogQuestText();
    end
    local obj = QTR_CleanLuaText(rawObj);
    
    local prog = "";
    local comp = "";

    -- ID'yi yeni API ile doğrudan alıyoruz
    local qid = 0;
    if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
        qid = C_QuestLog.GetQuestIDForLogIndex(questSelected);
    end
    local str_id = tostring(qid or "0");

    local template = "-- " .. q_title .. "\n" ..
                     '    ["' .. str_id .. '"] = {\n' ..
                     '    ["Title"]="' .. q_title .. '",\n' ..
                     '    ["Description"]="' .. desc .. '",\n' ..
                     '    ["Objectives"]="' .. obj .. '",\n' ..
                     '    ["Progress"]="' .. prog .. '",\n' ..
                     '    ["Completion"]="' .. comp .. '",\n' ..
                     '    ["minlevel"]="0",\n' ..
                     '    ["questlevel"]="0",\n' ..
                     '    },';

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
  if (not QTR_PS) then QTR_PS = {}; end
  if (not QTR_PC) then QTR_PC = {}; end
  if (not QTR_SAVED) then QTR_SAVED = {}; end
  if (not QTR_PS["active"]) then QTR_PS["active"] = "1"; end
  if (not QTR_PS["mode"] ) then QTR_PS["mode"] = "2"; end
  if (not QTR_PS["transtitle"] ) then QTR_PS["transtitle"] = "0"; end
  if (not QTR_PS["size"] ) then QTR_PS["size"] = "1"; end
  if (not QTR_PS["width"] ) then QTR_PS["width"] = "1"; end

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

  ApplyTurkishFont();
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

  QTR_CopyButton = CreateFrame("Button", "QTR_CopyButton", QuestTranslatorFrame1, "UIPanelButtonTemplate");
  QTR_CopyButton:SetWidth(110);
  QTR_CopyButton:SetHeight(22);
  QTR_CopyButton:SetText("Kopyala");
  QTR_CopyButton:SetFrameStrata("HIGH"); 
  QTR_CopyButton:SetPoint("BOTTOMLEFT", QuestTranslatorFrame1, "BOTTOMRIGHT", -155, 9);
  QTR_CopyButton:SetScript("OnClick", QuestTranslator_CopyMissingToClipboard);
  QTR_CopyButton:Hide();

  if hooksecurefunc then
       hooksecurefunc("QuestLogTitleButton_OnClick", function() 
           local delay = CreateFrame("Frame")
           delay.t = 0
           delay:SetScript("OnUpdate", function()
               this.t = this.t + arg1
               if this.t >= 0.05 then
                   this:SetScript("OnUpdate", nil)
                   QuestTranslator_UpdateQuestInfo()
               end
           end)
       end);
  else
       local QTR_QuestLogTitleButton_OnClik = QuestLogTitleButton_OnClick;
       function QuestLogTitleButton_OnClick(button)
          QTR_QuestLogTitleButton_OnClik(button);
          local delayFrame = CreateFrame("Frame")
          delayFrame.t = 0
          delayFrame:SetScript("OnUpdate", function()
              this.t = this.t + arg1
              if this.t >= 0.05 then
                  this:SetScript("OnUpdate", nil)
                  QuestTranslator_UpdateQuestInfo();
              end
          end)
       end
  end
end

function QuestTranslator_OnEvent1()
  if (event == "ADDON_LOADED") then
     QuestTranslator_CheckVars();
     
     if not DiscoveredMobsAndNpcs then DiscoveredMobsAndNpcs = {} end
     if not DiscoveredZones then DiscoveredZones = {} end
     if not DiscoveredQuestIds then DiscoveredQuestIds = {} end
     
     local loadMsg = "|cffffff00QuestTranslator-Vanilla-Turkish eklentisi (Karma Eşleştirme) yüklendi.|r"
     if (DEFAULT_CHAT_FRAME) then
         DEFAULT_CHAT_FRAME:AddMessage(loadMsg);
     else
         UIErrorsFrame:AddMessage(loadMsg, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
     end
     QuestTranslator.frame1:UnregisterEvent("ADDON_LOADED");
  end

  if (event == "QUEST_LOG_UPDATE") then
     if (QuestTranslatorFrame1:IsVisible()) then
        local delayFrame = CreateFrame("Frame")
        delayFrame.t = 0
        delayFrame:SetScript("OnUpdate", function()
            this.t = this.t + arg1
            if this.t >= 0.05 then
                this:SetScript("OnUpdate", nil)
                QuestTranslator_UpdateQuestInfo();
            end
        end)
     end
  end
end
  
function QuestTranslator_OnLoad2()
  QuestTranslator.frame2 = CreateFrame("Frame");
  QuestTranslator.frame2:RegisterEvent("QUEST_GREETING");
  QuestTranslator.frame2:RegisterEvent("QUEST_DETAIL");
  QuestTranslator.frame2:RegisterEvent("QUEST_PROGRESS");
  QuestTranslator.frame2:RegisterEvent("QUEST_COMPLETE");
  QuestTranslator.frame2:RegisterEvent("ITEM_TEXT_READY");
  QuestTranslator.frame2:RegisterEvent("ITEM_TEXT_CLOSED");
  QuestTranslator.frame2:SetScript("OnEvent", QuestTranslator_OnEvent3);
  
  ApplyTurkishFont();
  
  QuestTranslatorFrame2:ClearAllPoints();
  QuestTranslatorFrame2:SetPoint("TOPLEFT", QuestFrame, "TOPRIGHT", -31, -19);
  QuestFrame:SetScript("OnHide", QuestTranslator_Frame2Close);
  
  if ItemTextFrame then
      ItemTextFrame:SetScript("OnHide", QuestTranslator_BookFrameClose);
  end
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
       AvailableQuestsText:SetText(QuestTranslator_Messages.avaiquests);
       AvailableQuestsText:SetFont(Original_Font1, 18);
    end
  end

  if (event == "QUEST_DETAIL") then
     QTR_event = "QUEST_DETAIL";
     QuestTranslator_OnEvent2();
     ApplyTurkishFont();
  end

  if (event == "QUEST_PROGRESS") then
     QTR_event = "QUEST_PROGRESS";
     QuestTranslator_OnEvent2();
     ApplyTurkishFont();
  end

  if (event == "QUEST_COMPLETE") then
     QTR_event = "QUEST_COMPLETE";
     QuestTranslator_OnEvent2();
     ApplyTurkishFont();
  end
  
  if (event == "ITEM_TEXT_READY") then
     QuestTranslator_ProcessBookText();
  end
  
  if (event == "ITEM_TEXT_CLOSED") then
     QuestTranslator_BookFrameClose();
  end
end

-- Eski Sisteme Dönüş: QuestList.lua kullanarak isim ve metin eşleştirme
function QuestTranslator_SearchIDforName(qqq_title)
    local qqq_ID = 0;
    local qqq_lists = nil;
    local found_match = false;
    
    -- Oyundaki metni al ve temizle
    local currentText = GetObjectiveText() or "";
    if (currentText == "" and GetQuestLogQuestText) then
        _, currentText = GetQuestLogQuestText();
        currentText = currentText or "";
    end
    
    if currentText ~= "" then
        currentText = string.gsub(currentText, QTR_name, "YOUR_NAME");
        currentText = string.gsub(currentText, QTR_class, "YOUR_CLASS");
        currentText = string.gsub(currentText, QTR_race, "YOUR_RACE");
        currentText = string.gsub(currentText, "^%s*(.-)%s*$", "%1");
    end

    -- 1. Aşama: Birebir Metin Eşleşmesi Arama (QuestList.lua üzerinden)
    if QuestTranslator_QuestList then
        for questKey, questData in pairs(QuestTranslator_QuestList) do
            if type(questData) == "table" and string.find(questKey, qqq_title, 1, true) == 1 then
                
                local targetMatchText = questData[2] or "";
                targetMatchText = string.gsub(targetMatchText, "<name>", "YOUR_NAME");
                targetMatchText = string.gsub(targetMatchText, "<class>", "YOUR_CLASS");
                targetMatchText = string.gsub(targetMatchText, "<race>", "YOUR_RACE");
                targetMatchText = string.gsub(targetMatchText, "^%s*(.-)%s*$", "%1");

                if targetMatchText ~= "" and currentText ~= "" then
                    local matchLength = string.len(targetMatchText);
                    local currentCutText = string.sub(currentText, 1, matchLength);

                    if currentCutText == targetMatchText or string.find(currentText, targetMatchText, 1, true) then
                        qqq_lists = questData[1];
                        found_match = true;
                        break;
                    end
                end
            end
        end

        -- 2. Aşama: Fallback (Sadece başlık eşleşmesi)
        if not found_match then
            if QuestTranslator_QuestList[qqq_title] then
                qqq_lists = QuestTranslator_QuestList[qqq_title];
                found_match = true;
            else
                local fallbackKey = qqq_title .. "_QTR_DUP_1";
                if QuestTranslator_QuestList[fallbackKey] then
                    qqq_lists = QuestTranslator_QuestList[fallbackKey][1];
                    found_match = true;
                end
            end
        end
    end

    -- ID Çözümleme Alanı
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
                    if QuestTranslator_QuestWarning2 then
                        QuestTranslator_QuestWarning2:SetText(QuestTranslator_Messages.multipleID .. QTR_multiple);
                    end
                end
            end
        end
    end
    return qqq_ID;
end

-- NPC ile konuşurken Görev çevirilerini çeken fonksiyon (Eski sistem QuestList.lua kullanır)
function QuestTranslator_OnEvent2()
  local q_ID = 0;
  local q_title = GetTitleText();
  
  if ( QTR_PS["active"]=="1" )then
     QuestTranslator_QuestID2:SetText("");
     QuestTranslator_QuestTitle2:SetText(q_title);
     QuestTranslator_QuestDetail2:SetText(QuestTranslator_Messages.missing);
     QuestTranslator_QuestWarning2:SetText("");
     
     -- 1. Eğer GetQuestID API'si varsa yine de bir şans veriyoruz
     if GetQuestID then
        q_ID = GetQuestID();
     end
     
     -- 2. [KRİTİK DÜZELTME] Progress veya Complete aşamasında görev zaten günlüktedir (Quest Log).
     -- Quest Log'daki ID'yi çekerek seri görevlerdeki isim çakışmasını (DUP) kesin olarak çözüyoruz.
     if (not q_ID or q_ID == 0) and (QTR_event == "QUEST_PROGRESS" or QTR_event == "QUEST_COMPLETE") then
         if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
             local numEntries = GetNumQuestLogEntries() or 0;
             for i = 1, numEntries do
                 local title, _, _, isHeader = GetQuestLogTitle(i);
                 if not isHeader and title == q_title then
                     local log_id = C_QuestLog.GetQuestIDForLogIndex(i);
                     if log_id and log_id > 0 then
                         q_ID = log_id;
                         break;
                     end
                 end
             end
         end
     end
     
     -- 3. Eğer API boş döndüyse ve Günlükten de bulamadıysak (örneğin QUEST_DETAIL aşaması yeni görev alırken) QuestList.lua üzerinden arama yapıyoruz
     if (not q_ID or q_ID == 0) then
         q_ID = QuestTranslator_SearchIDforName(q_title);
     end
     
     if ( q_ID > 0 ) then
        local str_id = tostring(q_ID);
        QuestTranslator_QuestID2:SetText("QuestID: " .. str_id);
        QuestTranslator_QuestTitle2:SetText(q_title);
        
        -- Doğrudan ID bazlı arama yapıyoruz
        if (QuestTranslator_QuestData[str_id]) then
           if (QTR_PS["mode"]=="2") then
              QuestTranslator_ShowFrame2(QTR_event, str_id);
           end
        else
           if not DiscoveredQuestIds then DiscoveredQuestIds = {} end
           if not DiscoveredQuestIds[str_id] then
               DiscoveredQuestIds[str_id] = ""
               DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[QTVT]|r " .. str_id .. " numaralı görev (quest) veritabanında bulunamadı, eklendi.")
           end
           
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
     if ( q_ID and q_ID > 0) then
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

-- Kitap Sayfalama
local QTR_BookPagesData = {}; 
local QTR_BookPage = 1;
local QTR_MaxBookPages = 1;

local function QTR_AutoWrapText(text, maxCharsPerPage)
    local pages = {};
    local currentPageText = "";
    
    text = string.gsub(text, "\r\n", " NEW_LINE ");
    text = string.gsub(text, "\n", " NEW_LINE ");
    
    local words = QTR_split(text, " ");
    
    for _, word in ipairs(words) do
        if word ~= "" then
            if word == "NEW_LINE" then
                if currentPageText == "" then
                    currentPageText = "NEW_LINE";
                else
                    currentPageText = currentPageText .. " NEW_LINE";
                end
            else
                local cleanLength = string.len(string.gsub(currentPageText, "NEW_LINE", ""));
                if cleanLength + string.len(word) + 1 > maxCharsPerPage then
                    table.insert(pages, currentPageText);
                    currentPageText = word;
                else
                    if currentPageText == "" then
                        currentPageText = word;
                    else
                        currentPageText = currentPageText .. " " .. word;
                    end
                end
            end
        end
    end
    
    if currentPageText ~= "" then
        table.insert(pages, currentPageText);
    end
    
    return pages;
end

function QuestTranslator_ProcessBookText()
    if (QTR_PS["active"] == "0") then return; end
    
    local delayFrame = CreateFrame("Frame")
    delayFrame.timeSinceUpdate = 0
    delayFrame:SetScript("OnUpdate", function()
        this.timeSinceUpdate = this.timeSinceUpdate + arg1
        if this.timeSinceUpdate >= 0.05 then
            this:SetScript("OnUpdate", nil) 
            
            local book_title = nil;
            if ItemTextFrameTitleText and ItemTextFrameTitleText.GetText then
                book_title = ItemTextFrameTitleText:GetText();
            end
            
            if (not book_title or book_title == "") and ItemTextFrame then
                local regions = { ItemTextFrame:GetRegions() };
                for _, region in ipairs(regions) do
                    if region and region.GetText then
                        local text = region:GetText() or "";
                        if text ~= "" and string.find(text, "%c") == nil and string.len(text) < 50 then
                            if text ~= "Next" and text ~= "Previous" and text ~= NEXT and text ~= PREVIOUSTEXT then
                                book_title = text;
                                break;
                            end
                        end
                    end
                end
            end
            
            if (not book_title or book_title == "") and ItemTextGetTitle then
                book_title = ItemTextGetTitle();
            end

            book_title = book_title or "Bilinmeyen Kitap";
            
            if QuestTranslator_BookData and QuestTranslator_BookData[book_title] then
                QuestTranslator_BookTitle:SetText(QuestTranslator_ExpandUnitInfo(QuestTranslator_BookData[book_title]["Title"] or book_title));
                local full_text = QuestTranslator_BookData[book_title]["Text"] or "";
                full_text = QuestTranslator_ExpandUnitInfo(full_text);
                QTR_BookPagesData = QTR_AutoWrapText(full_text, 650);
                
                QTR_MaxBookPages = table.getn(QTR_BookPagesData);
                if QTR_MaxBookPages < 1 then QTR_MaxBookPages = 1; end
                
                QTR_BookPage = 1;
                QuestTranslator_UpdateBookPageDisplay();
            else
                if QTR_BookPrevBtn then QTR_BookPrevBtn:Hide() end
                if QTR_BookNextBtn then QTR_BookNextBtn:Hide() end
                QuestTranslator_BookTitle:SetText(book_title);
                QuestTranslator_BookDetail:SetText("|cffff0000Metin çevirisi eksik!|r\n\nBu mektubun ismini direkt anahtar kabul edecek şekilde veritabanına ekleyin.");
            end
            
            QuestTranslatorFrame3:ClearAllPoints();
            QuestTranslatorFrame3:SetPoint("TOPLEFT", ItemTextFrame, "TOPRIGHT", -31, -19);
            QuestTranslatorFrame3:Show();
            
            ApplyTurkishFont();
        end
    end)
end

function QuestTranslator_UpdateBookPageDisplay()
    local page_text = QTR_BookPagesData[QTR_BookPage] or "";
    page_text = QuestTranslator_ExpandUnitInfo(page_text);
    page_text = page_text .. "\n\n|cffffff00Sayfa: " .. QTR_BookPage .. " / " .. QTR_MaxBookPages .. "|r";
    QuestTranslator_BookDetail:SetText(page_text);
    
    if QTR_BookPrevBtn and QTR_BookNextBtn then
        if QTR_BookPage > 1 then QTR_BookPrevBtn:Show() else QTR_BookPrevBtn:Hide() end
        if QTR_BookPage < QTR_MaxBookPages then QTR_BookNextBtn:Show() else QTR_BookNextBtn:Hide() end
    end
end

function QuestTranslator_BookPageNext()
    if QTR_BookPage < QTR_MaxBookPages then
        QTR_BookPage = QTR_BookPage + 1;
        QuestTranslator_UpdateBookPageDisplay();
    end
end

function QuestTranslator_BookPagePrev()
    if QTR_BookPage > 1 then
        QTR_BookPage = QTR_BookPage - 1;
        QuestTranslator_UpdateBookPageDisplay();
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

function QuestTranslator_BookFrameClose()
  if QuestTranslatorFrame3 then
      QuestTranslatorFrame3:Hide();
  end
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
     QTR_PS["width"] = "1";
  end
end

function QuestTranslator_OnMouseDown1() QuestTranslatorFrame1:StartMoving(); end
function QuestTranslator_OnMouseUp1() QuestTranslatorFrame1:StopMovingOrSizing(); end
function QuestTranslator_OnMouseDown2() QuestTranslatorFrame2:StartMoving(); end
function QuestTranslator_OnMouseUp2() QuestTranslatorFrame2:StopMovingOrSizing(); end
function QuestTranslator_OnMouseDown3() QuestTranslatorFrame3:StartMoving(); end
function QuestTranslator_OnMouseUp3() QuestTranslatorFrame3:StopMovingOrSizing(); end

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
  if (QTR_PS["active"]=="0") then return; end
  if (QTR_PS["mode"]=="2") then QuestTranslatorFrame1:Show(); end;
  QuestTranslator_UpdateQuestInfo();
end

function QuestTranslator_HideQuestInfo()
  if QTR_CopyButton then QTR_CopyButton:Hide() end
  if QTR_CopyFrame then QTR_CopyFrame:Hide() end
  QuestTranslatorFrame1:Hide();
end

-- Görev Günlüğünde (Quest Log) çevirileri çeken fonksiyon
function QuestTranslator_UpdateQuestInfo()
  if (QTR_PS["active"]=="0") then return; end
  local questSelected = GetQuestLogSelection();
  local questTitle, _, _, isHeader = GetQuestLogTitle(questSelected);
  if (questTitle == nil or isHeader) then return; end

  -- Yeni API ile ID'yi çekiyoruz
  local qid = 0;
  if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
      qid = C_QuestLog.GetQuestIDForLogIndex(questSelected);
  elseif GetQuestID then
      qid = GetQuestID();
  end
  
  local str_id = tostring(qid or "0");
  QuestTranslator_QuestID:SetText("QuestID: " .. str_id);

  if (QuestTranslator_QuestData[str_id] and str_id ~= "0") then
     if QTR_CopyButton then QTR_CopyButton:Hide() end
     QTR_objectives  = QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[str_id]["Objectives"]);
     QTR_description = QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[str_id]["Description"]);
    QTR_descripFull = "|cffFFD100" .. QuestTranslator_Messages.details .. "|r\n\n" .. QTR_description;
     QTR_translator = "";
     if (QuestTranslator_QuestData[str_id]["Translator"]) then
        if (QuestTranslator_QuestData[str_id]["Translator"]>"") then
             QTR_translator = "\n\n" .. QuestTranslator_Messages.translator .. " " .. QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[str_id]["Translator"]);
        end
     end
     QuestTranslator_QuestTitle:SetText(QuestTranslator_ExpandUnitInfo(QuestTranslator_QuestData[str_id]["Title"]));
     QuestTranslator_QuestDetail:SetText(QTR_objectives .. "\n\n" .. QTR_descripFull .. QTR_translator);
  else
     if not DiscoveredQuestIds then DiscoveredQuestIds = {} end

     if str_id ~= "0" and not DiscoveredQuestIds[str_id] then
         DiscoveredQuestIds[str_id] = ""
         DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[QTVT]|r " .. str_id .. " numaralı görev (quest) eklendi.")
     end

     QuestTranslator_QuestTitle:SetText(questTitle);
     QuestTranslator_QuestDetail:SetText("|cffff0000" .. QuestTranslator_Messages.missing .. "|r\n\nBu görevin temiz Lua şablonunu panoya kopyalamak için sağ alttaki butona tıklayın.");
     if QTR_CopyButton then QTR_CopyButton:Show() end
  end 
  ApplyTurkishFont();
end

function QuestTranslator_ExpandUnitInfo(msg)
  if (not msg) then return ""; end
  msg = string.gsub(msg, "NEW_LINE", "\n\n");
  msg = string.gsub(msg, "YOUR_NAME", QTR_name);
  msg = string.gsub(msg, "YOUR_CLASS", QTR_class);
  msg = string.gsub(msg, "YOUR_RACE", QTR_race);
  return msg;
end

function QuestTranslator_Toggle()
    QuestTranslator_Config.enabled = not QuestTranslator_Config.enabled
    if QuestTranslator_Config.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00QuestTranslator aktif edildi.|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000QuestTranslator pasif edildi. (Orijinal metinler gösterilecek)|r")
    end
end