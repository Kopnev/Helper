script_name('Coin Miner')
script_author('kopnev')
script_version('2.4')
script_version_number(7)

local sampev = require 'lib.samp.events'
local imgui = require 'imgui'
local encoding = require 'encoding'
local inicfg   = require 'inicfg'
local dlstatus = require('moonloader').download_status

encoding.default = 'CP1251'
u8 = encoding.UTF8

local ids = {
	dialogPhone = 1000, -- ИД диалога выбора телефона
	dialogBoost = 25012, -- ИД диалога покупки переферии 

	phones = {
		{
			name = "Xiaomi Mi 8",
			menuCoin = 2119, -- ИД ТД открытия меню ВКкоин
			menuBoost = 2101, -- ИД ТД кнопки открытия меню покупки переферии (Кнопка boost)
			tdBalance = 2103, -- ИД ТД баланса
			tdClick = 2104, -- ИД ТД для клика (Синия хуевина с надписью PAY в меню коина)
		},
		{
			name = "Huawei P20 PRO",
			menuCoin = 2119,
			menuBoost = 2102,
			tdBalance = 2104,
			tdClick = 2105,
		},
		{
			name = "Google Pixel 3",
			menuCoin = 2118,
			menuBoost = 2099,
			tdBalance = 2101,
			tdClick = 2102,
		},
		{
			--label = "Samsung Galaxy S10 (Золотой)",
			--color = "золотой",
			name = "Samsung Galaxy S10",
			menuCoin = 2123,
			menuBoost = 2104,
			tdBalance = 2106,
			tdClick = 2107,
		},
	}
}

local def = {
	settings = {
		theme = 1,
		style = 0,
		bg = false,
		phone = 0,
		reloadR = false,
		delay = 350,
		delayc = 350,
		limit = 0,
		buy_choose = 0,
		upb = 0.000001,
		tip = 0,
		upbStatus = false, 
		offSoundClick = true,
		noHidePhone = true
	},
	stats = {
		clickAll = 0
	}

}

local directIni = "KopnevScripts\\vkcoin.ini"

local ini = inicfg.load(def, directIni)
local main_window = imgui.ImBool(false)

local upb = imgui.ImFloat(ini.settings.upb) -- начинать покупку, когда баланс выше
local upbError = false
local upbStatus = imgui.ImBool(ini.settings.upbStatus) -- Включение / отключение: "начинать покупку, когда баланс выше"
local tip = imgui.ImInt(ini.settings.tip) -- Тип закупки (Умная, выборочная)
local buy_choose = imgui.ImInt(ini.settings.buy_choose) -- Что закупать (тип: выборочно)
local tema = imgui.ImInt(ini.settings.theme) -- тема
local style = imgui.ImInt(ini.settings.style) -- стиль
local phone = imgui.ImInt(ini.settings.phone) -- телефон
local bg = imgui.ImBool(ini.settings.bg) -- Работа в свёрнутом режиме
local offSoundClick = imgui.ImBool(ini.settings.offSoundClick) -- Работа в свёрнутом режиме
local noHidePhone = imgui.ImBool(ini.settings.noHidePhone) -- Работа в свёрнутом режиме

local limit = imgui.ImInt(0) -- Лимит выборочной закупки 
local nolimit = imgui.ImBool(true) -- Включение лимита (Ну или выключение, хуй его знает )
local delay = imgui.ImInt(ini.settings.delay) -- Задержка закупки
local delayc = imgui.ImInt(ini.settings.delayc) -- Задержка кликера 
local click = imgui.ImBool(false) -- Активация кликера
local new = 0 -- Новая версия обновы
local gou = false -- Для обновы
local value = 0 -- Что-то для лимита
local balance = imgui.ImBuffer(128) -- Баланс
local statclick = imgui.ImInt(0) -- Статистика кликов 
local activebot = false -- Статус бота

local chars = {
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
}

local items = {
	u8"Тёмная тема",
	u8"Синия тема",
	u8"Красная тема",
	u8"Голубая тема",
	u8"Зелёная тема",
	u8"Оранжевая тема",
	u8"Фиолетовая тема",
	u8"Тёмно-светлая тема",
}

local phones = {}

local menu = {true,
	false,
	false,
	false,
	
}

local buy = {
	imgui.ImBool(false), -- 1 Клик мыши
	imgui.ImBool(false), -- 2 Видеокарта
	imgui.ImBool(false), -- 3 Стойка видеокарт
	imgui.ImBool(false), -- 4 Суперкомпьютер
	imgui.ImBool(false), -- 5 Сервер Arizona Games
	imgui.ImBool(false), -- 6 Квантовый компьютер
	imgui.ImBool(false), -- 7 Датацентр
}

function sampev.onPlaySound(id)
	if id == 17803 and click.v then -- Счетчик кликов
		statclick.v = statclick.v + 1
		ini.stats.clickAll = ini.stats.clickAll + 1
		if offSoundClick.v then return false end
	end
end


function sampev.onSendClickTextDraw(id)
	--sampAddChatMessage(id, 0xF1CB09)
	if (activebot or click.v) and noHidePhone.v and id == 65535 then return false end
end

--[[function sampev.onTextDrawSetString(id, text)
	print(id, text)
end]]

function sampev.onServerMessage(color,text)
    if activebot and text:find("Недостаточно VKoin's для преобретения данной переферии") then
        return false
    end
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	sampRegisterChatCommand("coinbot", function() main_window.v = not main_window.v end)

	update()
	SCM("Скрипт загружен. Активация: {F1CB09}/coinbot")

	if doesFileExist(thisScript().path) then
		os.rename(thisScript().path, 'moonloader/Coin Miner.lua')
	end
	if not doesDirectoryExist('moonloader/config/KopnevScripts/') then
		createDirectory('moonloader/config/KopnevScripts/')
	end

	for i, s in ipairs(ids['phones']) do
		if s['label'] then table.insert(phones, u8(s['label'])) else table.insert(phones, s['name']) end
	end

    while true do
		wait(350)
		imgui.Process = main_window.v	

		if testCheat("bb") and activebot == true then
		  	activebot = false
		  	SCM("Бот завершил свою работу")
		end

		if ini.settings.reloadR == true then
			ini.settings.reloadR = false
			inicfg.save(def, directIni)
		end

		if gou then goupdate() end

		WorkInBackground(bg.v)
	end
end

lua_thread.create(function() -- Защита от ложной ошибки 
	while true do
		wait(30)
		if isKeyDown(17) and isKeyDown(82) then -- CTRL+R
			ini.settings.reloadR = true
			inicfg.save(def, directIni)
		end
	end
end)

lua_thread.create(function()
	while true do
		wait(0)
		if click.v then
			wait(delayc.v)
			local t = phone.v + 1
			sampSendClickTextdraw(ids['phones'][t]['tdClick'])
		end
	end
end)

lua_thread.create(function()
	while true do
		wait(0)
		if activebot then
			wait(delay.v)
			if sampGetCurrentDialogId() ~= ids['dialogBoost'] and sampGetCurrentDialogId() ~= 25013 then 
				SCM('Откройте диалог с покупкой перефирии.') 
				activebot = false 
			end
		
			if tip.v == 1 then
				if value.v ~= 0 or nolimit.v then
					if sampGetCurrentDialogId() == ids['dialogBoost'] then
						repeat 
							wait(20) 
							if sampGetCurrentDialogId() == 25012 then sampSendDialogResponse(ids['dialogBoost'], 1, buy_choose.v, -1) end
						until sampGetCurrentDialogId() == 25013 or not activebot
						
						repeat 
							wait(20) 
							if sampGetCurrentDialogId() == 25013 then sampCloseCurrentDialogWithButton(1) end
						until sampGetCurrentDialogId() == 25012 or not activebot
						if nolimit.v == false then value.v = value.v -1 end
					end
				else
					SCM('Бот завершил работу')
					activebot = false
				end
			end
			if tip.v == 0 then
				local continue = false

				if upbStatus.v and tostring(upb.v) > balance then
					continue = true
					if not upbError then 
						upbError = true 
						SCM("Баланс ниже указанного, бот приостановлен.")
					end
				end

				if not continue then
					upbError = false
					for i = 1, 7, 1 do
						if buy[i].v then
							local d = i-1
							--sampSendDialogResponse(ids['dialogBoost'], 1, d, -1)
							repeat 
								wait(20) 
								if sampGetCurrentDialogId() == 25012 then sampSendDialogResponse(ids['dialogBoost'], 1, d, -1) end
							until sampGetCurrentDialogId() == 25013 or not activebot
							
							repeat 
								wait(20) 
								if sampGetCurrentDialogId() == 25013 then sampCloseCurrentDialogWithButton(1) end
							until sampGetCurrentDialogId() == 25012 or not activebot
						end
					end
				end
			end
		end
	end
end)

function ShowHelpMarker(desc)
    imgui.TextDisabled('(?)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450.0)
        imgui.TextUnformatted(desc)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function imgui.OnDrawFrame()
	easy_style()
	if ini.settings.theme == 0 then theme1() end
	if ini.settings.theme == 1 then theme2() end
	if ini.settings.theme == 2 then theme3() end
	if ini.settings.theme == 3 then theme4() end
	if ini.settings.theme == 4 then theme5() end
	if ini.settings.theme == 5 then theme6() end
	if ini.settings.theme == 6 then theme7() end
	if ini.settings.theme == 7 then theme8() end
	if ini.settings.theme == 8 then theme9() end

	if main_window.v then
		imgui.ShowCursor = true
		imgui.SetNextWindowPos(imgui.ImVec2(imgui.GetIO().DisplaySize.x / 2, imgui.GetIO().DisplaySize.y / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(600, 340), imgui.Cond.FirstUseEver)
		imgui.Begin( '		  Coin Miner | version ' .. thisScript().version, main_window, 2)
		if imgui.Button(u8'Автозакупка', imgui.ImVec2(135, 30)) then uu() menu[1] = true end imgui.SameLine()
		if imgui.Button(u8'Кликер', imgui.ImVec2(135, 30)) then uu() menu[2] = true end imgui.SameLine()
		if imgui.Button(u8'Настройки', imgui.ImVec2(135, 30)) then uu() menu[3] = true end imgui.SameLine()
		if imgui.Button(u8'Информация', imgui.ImVec2(135, 30)) then uu() menu[4] = true end
		imgui.Separator()
		imgui.NewLine()
		imgui.SameLine(3)

		if menu[1] then
			imgui.SameLine(25) imgui.Text(u8'Выберите тип закупки: ') imgui.SameLine(235)
			if imgui.RadioButton(u8'"Умная закупка"', tip, 0) then ini.settings.tip = tip.v end
			imgui.SameLine()
			if imgui.RadioButton(u8'Выборочно', tip, 1) then ini.settings.tip = tip.v end
			imgui.SetCursorPosY(90)
			imgui.Separator()
			if tip.v == 0 then
				imgui.SameLine(25)
				imgui.SetCursorPosY(95)
				imgui.BeginGroup()
					imgui.Text(u8'Баланс ВК коинов: ' )
					if getbalance() then balance = getbalance() else balance = u8"У вас не открыть телефон" end
					
					if balance == u8"У вас не открыть телефон" then
						imgui.SameLine(325) 
						if imgui.Button(u8'Открыть') then
							openPhone()
						end
						imgui.SameLine()
						ShowHelpMarker(u8'Если с первого раза не открылось, попробуйте ещё раз.')
					end

					
					imgui.SameLine(165) imgui.Text(balance)
					imgui.SetCursorPosY(125)
					--imgui.Separator()
					imgui.BeginChild('buylist', imgui.ImVec2(500, 130), true)
						imgui.Text(u8'Выберите что покупать:')
						imgui.SetCursorPosY(30)
						imgui.Text(u8'Клик мыши') imgui.SameLine(200) imgui.Checkbox('##1', buy[1]) imgui.SameLine(250)
						imgui.Text(u8 "Видеокарта") imgui.SameLine(420) imgui.Checkbox('##2', buy[2])
						imgui.Text(u8 "Стойка видеокарт") imgui.SameLine(200) imgui.Checkbox('##3', buy[3]) imgui.SameLine(250)
						imgui.Text(u8 "Суперкомпьютер") imgui.SameLine(420) imgui.Checkbox('##4', buy[4])
						imgui.Text(u8 "Сервер Arizona Games") imgui.SameLine(200) imgui.Checkbox('##5', buy[5]) imgui.SameLine(250)
						imgui.Text(u8 "Квантовый компьютер") imgui.SameLine(420) imgui.Checkbox('##6', buy[6])
						imgui.Text(u8 "Датацентр") imgui.SameLine(200) imgui.Checkbox('##7', buy[7])
					imgui.EndChild()
					--imgui.Separator()
					
					imgui.SetCursorPosY(240)

					imgui.NewLine() imgui.Text(u8'Задержка:')
					imgui.SameLine()
					ShowHelpMarker(u8'Задержка закупки улучшений, влияет на скорость закупки улучшений.')
					imgui.SameLine(250) imgui.Text(u8'Начинать покупку когда баланс выше:') imgui.SameLine() ShowHelpMarker(u8"Может работать некорректно")

					imgui.PushItemWidth(150) 
					if imgui.InputInt('ms', delay, 15) then
						ini.settings.delay = delay.v
					end
					imgui.PopItemWidth()

					imgui.SameLine(250)
					if imgui.Checkbox("##upbStatus", upbStatus) then
						ini.settings.upbStatus = upbStatus.v
					end imgui.SameLine()
					if upbStatus.v then
						imgui.SameLine(280)
						imgui.PushItemWidth(150) 
						if imgui.InputFloat('coins', upb, 1) then ini.settings.upb = upb.v end
						imgui.PopItemWidth()
					end
				imgui.EndGroup()
			end
			if tip.v == 1 then
				imgui.SameLine(80)
				imgui.BeginGroup()
					imgui.NewLine() imgui.NewLine()
					imgui.RadioButton(u8'Клик мыши', buy_choose, 0) imgui.SameLine(250)
					imgui.RadioButton(u8'Видеокарта', buy_choose, 1)
					imgui.RadioButton(u8'Стойка видеокарт', buy_choose, 2) imgui.SameLine(250)
					imgui.RadioButton(u8'Суперкомпьютер', buy_choose, 3)
					imgui.RadioButton(u8'Сервер Arizona Games', buy_choose, 4) imgui.SameLine(250)
					imgui.RadioButton(u8'Квантовый компьютер', buy_choose, 5)
					imgui.RadioButton(u8'Датацентр', buy_choose, 6) imgui.SameLine(250)
					imgui.Checkbox(u8'Без лимита', nolimit)
					imgui.NewLine()
					imgui.Text(u8'Задержка:')
					imgui.SameLine()
					ShowHelpMarker(u8'Задержка закупки улучшений, влияет на скорость закупки улучшений.')
					if nolimit.v == false then
						imgui.SameLine(250) imgui.Text(u8'Лимит:')
						imgui.SameLine()
						ShowHelpMarker(u8'Если вы установите лимит, тогда бот выполнет то кол-во закупок, которое вы установили.')
					end
					imgui.PushItemWidth(150) imgui.InputInt(' ', delay, 15) imgui.PopItemWidth()
					imgui.SameLine()
					if nolimit.v == false then
						imgui.SameLine(250)
						imgui.PushItemWidth(150)
						imgui.InputInt('', limit, 1) imgui.PopItemWidth() 
					end
				imgui.EndGroup()
			end

			imgui.SetCursorPos(imgui.ImVec2(25, 305)) imgui.Separator()
			imgui.SetCursorPos(imgui.ImVec2(25, 310))
			if imgui.Button(u8'Открыть диалог', imgui.ImVec2(110, 22)) then
				openDialog()
			end
			imgui.SameLine()
			ShowHelpMarker(u8'Открыть диалог с покупкой улчешний / перефирии. Если телефон открыт, рекомендуется его закрыть или открыть в ручную. Если с первого раза не открылось, попробуйте ещё раз.')
			if activebot then
				imgui.SameLine(410)
				if imgui.Button(u8'Стоп', imgui.ImVec2(80, 25)) then
					activebot = false
				end
			end
			imgui.SameLine(500) if imgui.Button(u8'Начать', imgui.ImVec2(80, 25)) then
				if limit.v == 0 and nolimit.v == false then
					SCM('Вы не установили лимит')
				else
					value = limit
					activebot = true
				end
			end
		end

		if menu[2] then
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(270) imgui.Text(u8'Авто Кликер')
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(100) imgui.Text(u8' Активация:') imgui.SameLine(189) imgui.Checkbox(u8' ', click) imgui.SameLine(310) imgui.Text(u8'Задержка:') imgui.SameLine(390)  
			imgui.PushItemWidth(150) 
			if imgui.InputInt('  ', delayc, 15) then
				ini.settings.delayc = delayc.v
			end
			imgui.PopItemWidth()
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(100)	imgui.Text(u8'Баланс ВК коинов: ' )
			if getbalance() then balance = getbalance() else balance = u8"У вас не открыть телефон" end
			imgui.SameLine(310) imgui.Text(balance)
			if balance == u8"У вас не открыть телефон" then
				imgui.SameLine(480) 
				if imgui.Button(u8'Открыть') then
					openPhone()
				end
				imgui.SameLine()
				ShowHelpMarker(u8'Если с первого раза не открылось, попробуйте ещё раз.')
			end
			
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(250) imgui.Text(u8'Статистика:')
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(100) imgui.Text(u8'Сделано кликов за текущий сеанс:      '..statclick.v)
			imgui.SameLine(390) if imgui.Button(u8'Очистить ') then statclick.v = 0 end
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(100) imgui.Text(u8'Сделано кликов за всё время:             '..ini.stats.clickAll)
			imgui.SameLine(390) if imgui.Button(u8'Очистить') then ini.stats.clickAll = 0 inicfg.save(ini, directIni) end
		end

		if menu[3] then
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(270)
			imgui.Text(u8'Настройки')
			imgui.NewLine() imgui.NewLine() imgui.NewLine()
			imgui.SameLine(50) imgui.Text(u8'Выбор темы: ') imgui.SameLine(250)
			imgui.PushItemWidth(200)
			if imgui.Combo('##theme', tema, items)then
				ini.settings.theme = tema.v
				inicfg.save(def, directIni)
			end imgui.PopItemWidth()
			--[[imgui.SameLine(310)
			imgui.Text(u8'Выбор стиля: ') imgui.SameLine()
			imgui.PushItemWidth(150)
			if imgui.Combo('##style', style, styles)then
				ini.settings.style = style.v
				inicfg.save(def, directIni)
			end imgui.PopItemWidth()]]
			imgui.NewLine() --imgui.NewLine()
			imgui.SameLine(50) imgui.Text(u8'Выбор телефона: ') imgui.SameLine(250)
			imgui.PushItemWidth(200)
			if imgui.Combo('##phone', phone, phones)then
				ini.settings.phone = phone.v
				inicfg.save(def, directIni)
			end imgui.PopItemWidth()
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(50) imgui.Text(u8'Не убирать телефон:   ') imgui.SameLine(250) if imgui.Checkbox('##noHidePhone', noHidePhone) then ini.settings.noHidePhone = noHidePhone.v inicfg.save(ini, directIni) end
			imgui.NewLine() --imgui.NewLine()
			imgui.SameLine(50) imgui.Text(u8'Отключить звук кликера:   ') imgui.SameLine(250) if imgui.Checkbox('##offSoundClick', offSoundClick) then ini.settings.offSoundClick = offSoundClick.v inicfg.save(ini, directIni) end
			imgui.NewLine() --imgui.NewLine()
			imgui.SameLine(50) imgui.Text(u8'Работа в свёрнутом режиме:   ') imgui.SameLine(250) if imgui.Checkbox(' ', bg) then ini.settings.bg = bg.v inicfg.save(ini, directIni) end
			imgui.NewLine() imgui.NewLine() imgui.NewLine() imgui.SameLine(50) 
			if imgui.Button(u8"Проверить обновление") then update() end
			imgui.SameLine()
			if new == 1 then
				if imgui.Button(u8"Обновить") then gou = true end
			end
		end

		if menu[4] then
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(270)
			imgui.Text(u8'Информация')
			imgui.NewLine() imgui.NewLine() imgui.NewLine() imgui.NewLine()
			imgui.SameLine(160) imgui.Text(u8'Автор: Даниил Копнев')
			imgui.NewLine()
			imgui.SameLine(160) imgui.Text(u8'Наша группа: vk.com/kscripts   ')
			imgui.SameLine(360) if imgui.Button(u8'Перейти') then os.execute('explorer "https://vk.com/kscripts"') end
			imgui.NewLine() imgui.NewLine()
			imgui.SameLine(160) imgui.Text(u8'Версия скрипта: '..thisScript().version)
			if new == 1 then 
				imgui.SameLine() imgui.Text(u8'( Доступна новая версия: '..ver..' )') 
			else
				imgui.SameLine() imgui.Text(u8'( Последняя версия )') 
			end
		end
		imgui.End()
	end
end

function uu()
    for i = 0,4 do
        menu[i] = false
    end
end

function WorkInBackground(work)
    local memory = require 'memory'
    if work then
        memory.setuint8(7634870, 1)
        memory.setuint8(7635034, 1)
        memory.fill(7623723, 144, 8)
        memory.fill(5499528, 144, 6)
    else
        memory.setuint8(7634870, 0)
        memory.setuint8(7635034, 0)
        memory.hex2bin('5051FF1500838500', 7623723, 8)
        memory.hex2bin('0F847B010000', 5499528, 6)
    end
end

function getbalance()
	local t = phone.v + 1
	if sampTextdrawIsExists(ids['phones'][t]['tdBalance']) then
		for s in ipairs(chars) do
			if sampTextdrawGetString(ids['phones'][t]['tdBalance']):find(chars[s]) then
				return nil
			end
		end
		return sampTextdrawGetString(ids['phones'][t]['tdBalance'])
	end
	return nil
end

function openPhone()
	sampSendChat('/phone')
	local i = -1
	local t = phone.v + 1
	local continue = false
	lua_thread.create(function()
		for s in string.gmatch(sampGetDialogText(), "[^\n]+") do
			if s:find(ids['phones'][t]['name']) then
				if ids['phones'][t]['color'] then
					if not s:find(ids['phones'][t]['color']) then continue = true end
				end
				if not continue then
					sampSendDialogResponse(ids['dialogPhone'],1,i,-1)
					repeat 
						wait(20) 
						if sampGetCurrentDialogId() == ids['dialogPhone'] then sampSendDialogResponse(ids['dialogPhone'],1,i,-1) end
					until sampGetCurrentDialogId() == ids['dialogPhone']
					sampSendClickTextdraw(ids['phones'][t]['menuCoin'])
				end
			end
			i = i + 1
		end
	end)	
end

function openDialog()
	sampSendChat('/phone')
	local i = -1
	local t = phone.v + 1
	local continue = false
	lua_thread.create(function() 
		for s in string.gmatch(sampGetDialogText(), "[^\n]+") do
			if s:find(ids['phones'][t]['name']) then
				if ids['phones'][t]['color'] then
					if not s:find(ids['phones'][t]['color']) then continue = true end
				end
				if not continue then
					if sampTextdrawIsExists(ids['phones'][t]['menuBoost']) then
						sampSendClickTextdraw(ids['phones'][t]['menuBoost'])
					else
						sampSendDialogResponse(ids['dialogPhone'],1,i,-1)
						repeat 
							wait(20) 
							if sampGetCurrentDialogId() == ids['dialogPhone'] then sampSendDialogResponse(ids['dialogPhone'],1,i,-1) end
						until sampGetCurrentDialogId() == ids['dialogPhone']
						sampSendClickTextdraw(ids['phones'][t]['menuCoin'])
						sampSendClickTextdraw(ids['phones'][t]['menuBoost']) 
					end
				end
			end
			i = i + 1
		end
	end)
end

function update()
    local fpath = os.getenv('TEMP') .. '\\CoinMiner_version.json' -- куда будет качаться наш файлик для сравнения версии
    downloadUrlToFile("https://kscripts.ru/scripts/version.php?script=vkcoin", fpath, function(id, status, p1, p2) -- ссылку на ваш гитхаб где есть строчки которые я ввёл в теме или любой другой сайт
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            local f = io.open(fpath, 'r') -- открывает файл
            if f then
                local info = decodeJson(f:read('*a')) -- читает
                if info and info.num then
                    version = tonumber(info.num) -- переводит версию в число
                    ver = tonumber(info.version)
                    if version > thisScript().version_num then -- если версия больше чем версия установленная то...
                        SCM("Доступно обновление!")
                        new = 1
                    else -- если меньше, то
                        SCM("У вас установлена последняя версия")
                    end
                end
            end
        end
    end)
end
  
function goupdate()
	gou = false
    SCM('Обнаружено обновление. AutoReload может конфликтовать. Обновляюсь...')
    SCM('Текущая версия: '..thisScript().version..". Новая версия: "..ver)
    wait(300)
    downloadUrlToFile("https://kscripts.ru/scripts/download.php?script=vkcoin&src=true", thisScript().path, function(id, status, p1, p2)
    	if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            thisScript():reload()
        end
    end)
end

function onScriptTerminate(LuaScript, quitGame)
	if LuaScript == thisScript() and not quitGame and not ini.settings.reloadR then
		ini.settings.buy_choose = buy_choose.v
		inicfg.save(def, directIni)
		sampShowDialog(6405, "                                        {FF0000}Произошла ошибка!", "{FFFFFF}Этот сообщение может быть ложным, если вы \nиспользовали скрипт AutoReboot \n\nК сожалению скрипт {F1CB09}Coin Miner{FFFFFF} завершился неудачно\nЕсли вы хотите помочь разработчику\nТо можете описать при каком действии произошла ошибка\nНаша группа: {0099CC}vk.com/kscripts", "ОК", "", DIALOG_STYLE_MSGBOX)
		SCM('Произошла ошибка')
		showCursor(false, false)
	end
end

function onQuitGame()
	ini.settings.buy_choose = buy_choose.v
    inicfg.save(def, directIni)
end

function SCM(arg1)
	sampAddChatMessage("[Coin-Miner]: {FFFFFF}"..arg1, 0xF1CB09)
end

function theme1()
	local style = imgui.GetStyle()
	local Colors = style.Colors
	local ImVec4 = imgui.ImVec4
	Colors[imgui.Col.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
	Colors[imgui.Col.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
	Colors[imgui.Col.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
	Colors[imgui.Col.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
	Colors[imgui.Col.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
	Colors[imgui.Col.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
	Colors[imgui.Col.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
	Colors[imgui.Col.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	Colors[imgui.Col.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
	Colors[imgui.Col.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
	Colors[imgui.Col.TitleBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	Colors[imgui.Col.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
	Colors[imgui.Col.TitleBgActive] = ImVec4(0.07, 0.07, 0.09, 1.00)
	Colors[imgui.Col.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	Colors[imgui.Col.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	Colors[imgui.Col.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
	Colors[imgui.Col.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
	Colors[imgui.Col.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	Colors[imgui.Col.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
	Colors[imgui.Col.CheckMark] = ImVec4(0.80, 0.80, 0.83, 0.31)
	Colors[imgui.Col.SliderGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
	Colors[imgui.Col.SliderGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	Colors[imgui.Col.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
	Colors[imgui.Col.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
	Colors[imgui.Col.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
	Colors[imgui.Col.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
	Colors[imgui.Col.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
	Colors[imgui.Col.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	Colors[imgui.Col.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
	Colors[imgui.Col.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
	Colors[imgui.Col.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	Colors[imgui.Col.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
	Colors[imgui.Col.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
	Colors[imgui.Col.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
	Colors[imgui.Col.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
	Colors[imgui.Col.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
	Colors[imgui.Col.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
	Colors[imgui.Col.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
	Colors[imgui.Col.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
	Colors[imgui.Col.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

function theme2()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
	colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
	colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
	colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
	colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
	colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function theme3()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	colors[clr.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
	colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
	colors[clr.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
	colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
	colors[clr.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
	colors[clr.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
	colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function theme4()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	colors[clr.FrameBg]                = ImVec4(0.16, 0.48, 0.42, 0.54)
	colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.98, 0.85, 0.40)
	colors[clr.FrameBgActive]          = ImVec4(0.26, 0.98, 0.85, 0.67)
	colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.16, 0.48, 0.42, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.CheckMark]              = ImVec4(0.26, 0.98, 0.85, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.24, 0.88, 0.77, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.98, 0.85, 1.00)
	colors[clr.Button]                 = ImVec4(0.26, 0.98, 0.85, 0.40)
	colors[clr.ButtonHovered]          = ImVec4(0.26, 0.98, 0.85, 1.00)
	colors[clr.ButtonActive]           = ImVec4(0.06, 0.98, 0.82, 1.00)
	colors[clr.Header]                 = ImVec4(0.26, 0.98, 0.85, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.26, 0.98, 0.85, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.26, 0.98, 0.85, 1.00)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.10, 0.75, 0.63, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.10, 0.75, 0.63, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.26, 0.98, 0.85, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.98, 0.85, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.98, 0.85, 0.95)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.81, 0.35, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.98, 0.85, 0.35)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function theme5()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
	style.Alpha = 1.0
	style.Colors[clr.Text] = ImVec4(1.000, 1.000, 1.000, 1.000)
	style.Colors[clr.TextDisabled] = ImVec4(0.000, 0.543, 0.983, 1.000)
	style.Colors[clr.WindowBg] = ImVec4(0.000, 0.000, 0.000, 0.895)
	style.Colors[clr.ChildWindowBg] = ImVec4(0.00, 0.00, 0.00, 0.00)
	style.Colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
	style.Colors[clr.Border] = ImVec4(0.184, 0.878, 0.000, 0.500)
	style.Colors[clr.BorderShadow] = ImVec4(1.00, 1.00, 1.00, 0.10)
	style.Colors[clr.TitleBg] = ImVec4(0.026, 0.597, 0.000, 1.000)
	style.Colors[clr.TitleBgCollapsed] = ImVec4(0.099, 0.315, 0.000, 0.000)
	style.Colors[clr.TitleBgActive] = ImVec4(0.026, 0.597, 0.000, 1.000)
	style.Colors[clr.MenuBarBg] = ImVec4(0.86, 0.86, 0.86, 1.00)
	style.Colors[clr.ScrollbarBg] = ImVec4(0.000, 0.000, 0.000, 0.801)
	style.Colors[clr.ScrollbarGrab] = ImVec4(0.238, 0.238, 0.238, 1.000)
	style.Colors[clr.ScrollbarGrabHovered] = ImVec4(0.238, 0.238, 0.238, 1.000)
	style.Colors[clr.ScrollbarGrabActive] = ImVec4(0.004, 0.381, 0.000, 1.000)
	style.Colors[clr.CheckMark] = ImVec4(0.009, 0.845, 0.000, 1.000)
	style.Colors[clr.SliderGrab] = ImVec4(0.139, 0.508, 0.000, 1.000)
	style.Colors[clr.SliderGrabActive] = ImVec4(0.139, 0.508, 0.000, 1.000)
	style.Colors[clr.Button] = ImVec4(0.000, 0.000, 0.000, 0.400)
	style.Colors[clr.ButtonHovered] = ImVec4(0.000, 0.619, 0.014, 1.000)
	style.Colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1.00)
	style.Colors[clr.Header] = ImVec4(0.26, 0.59, 0.98, 0.31)
	style.Colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.80)
	style.Colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1.00)
	style.Colors[clr.ResizeGrip] = ImVec4(0.000, 1.000, 0.221, 0.597)
	style.Colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
	style.Colors[clr.ResizeGripActive] = ImVec4(0.26, 0.59, 0.98, 0.95)
	style.Colors[clr.PlotLines] = ImVec4(0.39, 0.39, 0.39, 1.00)
	style.Colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
	style.Colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
	style.Colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
	style.Colors[clr.TextSelectedBg] = ImVec4(0.26, 0.59, 0.98, 0.35)
	style.Colors[clr.ModalWindowDarkening] = ImVec4(0.20, 0.20, 0.20, 0.35)

	style.ScrollbarSize = 16.0
	style.GrabMinSize = 8.0
	style.WindowRounding = 0.0

	style.AntiAliasedLines = true
end

function theme6()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	colors[clr.Text] = ImVec4(0.90, 0.90, 0.90, 1.00)
	colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
	colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
	colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
	colors[clr.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
	colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
	colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
	colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.TitleBg] = ImVec4(0.76, 0.31, 0.00, 1.00)
	colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
	colors[clr.TitleBgActive] = ImVec4(0.80, 0.33, 0.00, 1.00)
	colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
	colors[clr.CheckMark] = ImVec4(1.00, 0.42, 0.00, 0.53)
	colors[clr.SliderGrab] = ImVec4(1.00, 0.42, 0.00, 0.53)
	colors[clr.SliderGrabActive] = ImVec4(1.00, 0.42, 0.00, 1.00)
	colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
	colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
	colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
	colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
	colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
	colors[clr.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
	colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
	colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
	colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
	colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

function theme7()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	colors[clr.WindowBg]              = ImVec4(0.14, 0.12, 0.16, 1.00);
	colors[clr.ChildWindowBg]         = ImVec4(0.30, 0.20, 0.39, 0.00);
	colors[clr.PopupBg]               = ImVec4(0.05, 0.05, 0.10, 0.90);
	colors[clr.Border]                = ImVec4(0.89, 0.85, 0.92, 0.30);
	colors[clr.BorderShadow]          = ImVec4(0.00, 0.00, 0.00, 0.00);
	colors[clr.FrameBg]               = ImVec4(0.30, 0.20, 0.39, 1.00);
	colors[clr.FrameBgHovered]        = ImVec4(0.41, 0.19, 0.63, 0.68);
	colors[clr.FrameBgActive]         = ImVec4(0.41, 0.19, 0.63, 1.00);
	colors[clr.TitleBg]               = ImVec4(0.41, 0.19, 0.63, 0.45);
	colors[clr.TitleBgCollapsed]      = ImVec4(0.41, 0.19, 0.63, 0.35);
	colors[clr.TitleBgActive]         = ImVec4(0.41, 0.19, 0.63, 0.78);
	colors[clr.MenuBarBg]             = ImVec4(0.30, 0.20, 0.39, 0.57);
	colors[clr.ScrollbarBg]           = ImVec4(0.30, 0.20, 0.39, 1.00);
	colors[clr.ScrollbarGrab]         = ImVec4(0.41, 0.19, 0.63, 0.31);
	colors[clr.ScrollbarGrabHovered]  = ImVec4(0.41, 0.19, 0.63, 0.78);
	colors[clr.ScrollbarGrabActive]   = ImVec4(0.41, 0.19, 0.63, 1.00);
	colors[clr.ComboBg]               = ImVec4(0.30, 0.20, 0.39, 1.00);
	colors[clr.CheckMark]             = ImVec4(0.56, 0.61, 1.00, 1.00);
	colors[clr.SliderGrab]            = ImVec4(0.41, 0.19, 0.63, 0.24);
	colors[clr.SliderGrabActive]      = ImVec4(0.41, 0.19, 0.63, 1.00);
	colors[clr.Button]                = ImVec4(0.41, 0.19, 0.63, 0.44);
	colors[clr.ButtonHovered]         = ImVec4(0.41, 0.19, 0.63, 0.86);
	colors[clr.ButtonActive]          = ImVec4(0.64, 0.33, 0.94, 1.00);
	colors[clr.Header]                = ImVec4(0.41, 0.19, 0.63, 0.76);
	colors[clr.HeaderHovered]         = ImVec4(0.41, 0.19, 0.63, 0.86);
	colors[clr.HeaderActive]          = ImVec4(0.41, 0.19, 0.63, 1.00);
	colors[clr.ResizeGrip]            = ImVec4(0.41, 0.19, 0.63, 0.20);
	colors[clr.ResizeGripHovered]     = ImVec4(0.41, 0.19, 0.63, 0.78);
	colors[clr.ResizeGripActive]      = ImVec4(0.41, 0.19, 0.63, 1.00);
	colors[clr.CloseButton]           = ImVec4(1.00, 1.00, 1.00, 0.75);
	colors[clr.CloseButtonHovered]    = ImVec4(0.88, 0.74, 1.00, 0.59);
	colors[clr.CloseButtonActive]     = ImVec4(0.88, 0.85, 0.92, 1.00);
	colors[clr.PlotLines]             = ImVec4(0.89, 0.85, 0.92, 0.63);
	colors[clr.PlotLinesHovered]      = ImVec4(0.41, 0.19, 0.63, 1.00);
	colors[clr.PlotHistogram]         = ImVec4(0.89, 0.85, 0.92, 0.63);
	colors[clr.PlotHistogramHovered]  = ImVec4(0.41, 0.19, 0.63, 1.00);
	colors[clr.TextSelectedBg]        = ImVec4(0.41, 0.19, 0.63, 0.43);
	colors[clr.ModalWindowDarkening]  = ImVec4(0.20, 0.20, 0.20, 0.35);
end

function theme8()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4

	colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
	colors[clr.TextDisabled]           = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.ChildWindowBg]          = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.PopupBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.Border]                 = ImVec4(0.82, 0.77, 0.78, 1.00)
	colors[clr.BorderShadow]           = ImVec4(0.35, 0.35, 0.35, 0.66)
	colors[clr.FrameBg]                = ImVec4(1.00, 1.00, 1.00, 0.28)
	colors[clr.FrameBgHovered]         = ImVec4(0.68, 0.68, 0.68, 0.67)
	colors[clr.FrameBgActive]          = ImVec4(0.79, 0.73, 0.73, 0.62)
	colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.46, 0.46, 0.46, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.MenuBarBg]              = ImVec4(0.00, 0.00, 0.00, 0.80)
	colors[clr.ScrollbarBg]            = ImVec4(0.00, 0.00, 0.00, 0.60)
	colors[clr.ScrollbarGrab]          = ImVec4(1.00, 1.00, 1.00, 0.87)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(1.00, 1.00, 1.00, 0.79)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.80, 0.50, 0.50, 0.40)
	colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 0.99)
	colors[clr.CheckMark]              = ImVec4(0.99, 0.99, 0.99, 0.52)
	colors[clr.SliderGrab]             = ImVec4(1.00, 1.00, 1.00, 0.42)
	colors[clr.SliderGrabActive]       = ImVec4(0.76, 0.76, 0.76, 1.00)
	colors[clr.Button]                 = ImVec4(0.51, 0.51, 0.51, 0.60)
	colors[clr.ButtonHovered]          = ImVec4(0.68, 0.68, 0.68, 1.00)
	colors[clr.ButtonActive]           = ImVec4(0.67, 0.67, 0.67, 1.00)
	colors[clr.Header]                 = ImVec4(0.72, 0.72, 0.72, 0.54)
	colors[clr.HeaderHovered]          = ImVec4(0.92, 0.92, 0.95, 0.77)
	colors[clr.HeaderActive]           = ImVec4(0.82, 0.82, 0.82, 0.80)
	colors[clr.Separator]              = ImVec4(0.73, 0.73, 0.73, 1.00)
	colors[clr.SeparatorHovered]       = ImVec4(0.81, 0.81, 0.81, 1.00)
	colors[clr.SeparatorActive]        = ImVec4(0.74, 0.74, 0.74, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.80, 0.80, 0.80, 0.30)
	colors[clr.ResizeGripHovered]      = ImVec4(0.95, 0.95, 0.95, 0.60)
	colors[clr.ResizeGripActive]       = ImVec4(1.00, 1.00, 1.00, 0.90)
	colors[clr.CloseButton]            = ImVec4(0.45, 0.45, 0.45, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.70, 0.70, 0.90, 0.60)
	colors[clr.CloseButtonActive]      = ImVec4(0.70, 0.70, 0.70, 1.00)
	colors[clr.PlotLines]              = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(1.00, 1.00, 1.00, 0.35)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.88, 0.88, 0.88, 0.35)
end

function easy_style()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4

	style.WindowPadding = imgui.ImVec2(9, 5)
	style.WindowRounding = 10
	style.ChildWindowRounding = 10
	style.FramePadding = imgui.ImVec2(5, 3)
	style.FrameRounding = 6.0
	style.ItemSpacing = imgui.ImVec2(9.0, 3.0)
	style.ItemInnerSpacing = imgui.ImVec2(9.0, 3.0)
	style.IndentSpacing = 21
	style.ScrollbarSize = 6.0
	style.ScrollbarRounding = 13
	style.GrabMinSize = 17.0
	style.GrabRounding = 16.0

	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
end