---@class Speedometer
Speedometer = Speedometer or {}

---@class Speedometer
local m = Speedometer

m.events = {}

function Speedometer:init()
	self.frame = CreateFrame( "Frame", "SpeedometerFrame", UIParent )
	self.frame:SetScript( "OnEvent", function()
		if m.events[ event ] then
			m.events[ event ]()
		end
	end )

	for k, _ in pairs( m.events ) do
		m.frame:RegisterEvent( k )
	end

	m.speed_samples = {}
	m.max_samples = 7
	m.status_debounce = {
		current = nil,
		previous = nil,
		candidate = nil,
		start_time = 0,
	}

	SLASH_SPEEDOMETER1 = "/sm"
	SLASH_SPEEDOMETER2 = "/speedometer"
	SlashCmdList[ "SPEEDOMETER" ] = Speedometer.handle_slash
end

function Speedometer.events.PLAYER_LOGIN()
	SpeedometerDB = SpeedometerDB or {}
	m.db = SpeedometerDB
	m.db.use_metric = m.db.use_metric or false
	m.db.skin = m.db.skin or "Classic"

	local frame = m.frame
	if m.db.pos then
		frame:SetPoint( m.db.pos.point, UIParent, m.db.pos.relative_point, m.db.pos.x, m.db.pos.y )
	else
		frame:SetPoint( "Center", UIParent, "Center", 0, 200 )
	end

	frame:SetWidth( 100 )
	frame:SetHeight( 50 )
	frame:EnableMouse( true )
	frame:SetMovable( true )
	frame:RegisterForDrag( "LeftButton" )
	frame:SetFrameStrata( "DIALOG" )
	frame:Show()

	frame:SetScript( "OnUpdate", m.on_update )
	frame:SetScript( "OnDragStart", function() frame:StartMoving() end )
	frame:SetScript( "OnDragStop", function()
		frame:StopMovingOrSizing()

		local point, _, relative_point, x, y = frame:GetPoint()
		m.db.pos = { point = point, relative_point = relative_point, x = x, y = y }
	end )

	frame:SetScript( "OnMouseUp", function()
		if arg1 == "RightButton" then
			m.show_dropdown()
		end
	end )

	m.text_speed = frame:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
	m.text_speed:SetPoint( "Top", frame, "Top", 0, -10 )

	m.text_status = frame:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
	m.text_status:SetPoint( "Bottom", frame, "Bottom", 0, 10 )

	m.update_skin()

	m.dropdown = CreateFrame( "Frame", "SpeedometerDropdown", frame, "UIDropDownMenuTemplate" )
	m.zone = GetRealZoneText()
end

function Speedometer.events.ZONE_CHANGED_NEW_AREA()
	m.zone = GetRealZoneText()
end

function Speedometer.on_update()
	local x, y = GetPlayerMapPosition( "player" )
	local now = GetTime()

	if m.prev_x and m.prev_y and m.prev_time then
		local dt = now - m.prev_time
		if dt > 0.1 then
			local width, height = m.get_yards_per_map_unit()

			if not width or not height then
				m.text_status:SetText( "No zone data" )
				return
			end

			local dx = (x - m.prev_x) * width
			local dy = (y - m.prev_y) * height
			local dist = math.sqrt( dx * dx + dy * dy )
			local speed = dist / dt

			if speed == 0 then
				m.speed_samples = { 0 }
			else
				table.insert( m.speed_samples, speed )
				if getn( m.speed_samples ) > m.max_samples then
					table.remove( m.speed_samples, 1 )
				end
			end

			local total = 0
			for _, s in ipairs( m.speed_samples ) do
				total = total + s
			end

			local avg_speed = total / getn( m.speed_samples )
			local unit = m.db.use_metric and "m/s" or "yd/s"
			local display_speed = m.db.use_metric and (avg_speed * 0.9144) or avg_speed

			m.text_speed:SetText( string.format( "Speed: %.1f %s", display_speed, unit ) )
			m.update_status( now, avg_speed )

			m.prev_x, m.prev_y, m.prev_time = x, y, now
		end
	else
		m.prev_x, m.prev_y, m.prev_time = x, y, now
	end
end

function Speedometer.dropdown_initialize( level )
	local info = {}

	if level == 1 then
		info.text = m.db.use_metric and "Use Imperial (yards)" or "Use Metric (meters)"
		info.func = function()
			m.db.use_metric = not m.db.use_metric
		end
		UIDropDownMenu_AddButton( info )

		---@diagnostic disable-next-line: undefined-global
		if gOutfitter_Settings then
			info.text = "Autoequip \"Swimming\" outfit"
			info.func = function()
				m.db.autoequip_swimming = not m.db.autoequip_swimming
			end
			info.checked = m.db.autoequip_swimming
			UIDropDownMenu_AddButton( info )
		end

		info.func = nil
		info.text = "Skin"
		info.menuList = "Skin"
		info.hasArrow = true
		info.checked = false

		UIDropDownMenu_AddButton( info )
	end

	if level == 2 then
		info.text = "Classic"
		info.arg1 = "Classic"
		info.hasArrow = false
		info.checked = m.db.skin == info.arg1
		info.func = function( skin )
			m.db.skin = skin
			m.update_skin()
			CloseDropDownMenus()
		end
		UIDropDownMenu_AddButton( info, level )

		info.text = "Flat"
		info.arg1 = "Flat"
		info.checked = m.db.skin == info.arg1
		UIDropDownMenu_AddButton( info, level )
	end
end

function Speedometer.show_dropdown()
	UIDropDownMenu_Initialize( m.dropdown, m.dropdown_initialize, "MENU" )
	ToggleDropDownMenu( 1, nil, m.dropdown, "cursor", 0, 0 )
end

function Speedometer.handle_slash( args )
	if not args then
		if m.frame:IsShown() then
			m.frame:Hide()
		else
			m.frame:Show()
		end
		return
	end

	if string.find( args, "^size" ) then
		local w, h = string.match( args, "^size (%d*) (%d*)" )
		m.zone_sizes[ m.zone ].width = w
		m.zone_sizes[ m.zone ].height = h
	end
end

function Speedometer.update_skin()
	local skin = m.db.skin

	if skin == "Classic" then
		m.frame:SetBackdrop( {
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		} )
		m.frame:SetBackdropColor( 0, 0, 0, 0.8 )
	elseif skin == "Flat" then
		m.frame:SetBackdrop( {
			bgFile = "Interface/Buttons/WHITE8x8",
			edgeFile = "Interface/Buttons/WHITE8x8",
			edgeSize = 0.8,
		} )
		m.frame:SetBackdropColor( 0, 0, 0, 0.8 )
		m.frame:SetBackdropBorderColor( 0.2, 0.2, 0.2, 1 )
	end
end

function Speedometer.update_status( current_time, speed )
	local new_state = m.classify_speed( speed or 0 )
	local sdb = m.status_debounce

	-- Keep flying until we stand still
	if sdb.previous == "Flying" and new_state ~= "Standing" then
		return
	end

	if sdb.candidate ~= new_state then
		sdb.candidate = new_state
		sdb.start_time = current_time
	elseif current_time - m.status_debounce.start_time >= 0.7 then
		if sdb.current ~= sdb.candidate then
			sdb.current = sdb.candidate
			m.text_status:SetText( sdb.current )

			if sdb.current == "Swimming" or sdb.previous == "Swimming" then
				m.outfitter_swimming( sdb.current == "Swimming" )
			end

			sdb.previous = sdb.current
		end
	end
end

function Speedometer.get_yards_per_map_unit()
	local data = m.zone_sizes[ m.zone ]
	if not data then return nil end

	return data.width, data.height
end

function Speedometer.classify_speed( speed )
	if speed < 0.1 then
		return "Standing"
	elseif speed < 3 then
		return "Walking"
	elseif speed < 4.6 then
		return "Moonwalking"
	elseif speed < 6.6 then
		return "Swimming"
	elseif speed < 10 then
		return "Running"
	elseif speed < 20 then
		return "Mounted"
	elseif speed < 40 then
		return "Flying"
	else
		return "Unknown"
	end
end

function Speedometer.outfitter_swimming( equip )
	if not m.db.autoequip_swimming then
		return
	end

	---@diagnostic disable-next-line: undefined-global
	if gOutfitter_Settings then
		---@diagnostic disable-next-line: undefined-global
		local vOutfit = Outfitter_FindOutfitByName( "Swimming" )

		---@diagnostic disable-next-line: undefined-global
		if vOutfit and Outfitter_WearingOutfit( vOutfit ) and not equip then
			---@diagnostic disable-next-line: undefined-global
			Outfitter_RemoveOutfit( vOutfit )
		elseif vOutfit and equip then
			---@diagnostic disable-next-line: undefined-global
			Outfitter_WearOutfit( vOutfit )
		end
	end
end

Speedometer:init()
