---@class Speedometer
Speedometer = Speedometer or {}

---@class Speedometer
local m = Speedometer

m.events = {}

function Speedometer:init()
  self.frame = self:create_frame()

  for k, _ in pairs( self.events ) do
    self.frame:RegisterEvent( k )
  end

  self.speed_samples = {}
  self.max_samples = 5
  self.in_combat = false
  self.is_mounted = false
  self.on_boat = nil
  self.zone_width = 0
  self.zone_height = 0
  self.status_debounce = {
    current = nil,
    previous = nil,
    candidate = nil,
    start_time = 0,
  }
  self.api = getfenv( 0 )
  self.db = {}

  SLASH_SPEEDOMETER1 = "/sm"
  SLASH_SPEEDOMETER2 = "/speedometer"
  SlashCmdList[ "SPEEDOMETER" ] = Speedometer.handle_slash

  self.dropdown = CreateFrame( "Frame", "SpeedometerDropdown", self.frame, "UIDropDownMenuTemplate" )
  self.tooltip = CreateFrame( "GameTooltip", "SpeedometerTooltip", UIParent, "GameTooltipTemplate" )
  self.tooltip:SetOwner( WorldFrame, "ANCHOR_NONE" )
end

function Speedometer.events:PLAYER_LOGIN()
  SpeedometerDB = SpeedometerDB or {}
  self.db = SpeedometerDB
  if self.db.use_metric == nil then self.db.use_metric = false end
  if self.db.show_status == nil then self.db.show_status = true end
  if self.db.skin == nil then self.db.skin = "Classic" end

  if self.db.pos then
    self.frame:SetPoint( self.db.pos.point, UIParent, self.db.pos.relative_point, self.db.pos.x, self.db.pos.y )
  else
    self.frame:SetPoint( "Center", UIParent, "Center", 0, 200 )
  end

  self.frame:SetHeight( self.db.show_status and 50 or 30 )
  self:update_skin()
end

function Speedometer.events:PLAYER_ENTERING_WORLD()
  SetMapToCurrentZone()
  self.map_zone_id = GetCurrentMapZone()
  self.zone_width, self.zone_height = ZONE_SIZES:get_current_zone_size()
end

function Speedometer.events:ZONE_CHANGED_NEW_AREA()
  SetMapToCurrentZone()
  self.map_zone_id = GetCurrentMapZone()
  self.zone_width, self.zone_height = ZONE_SIZES:get_current_zone_size()
end

function Speedometer.events:ZONE_CHANGED_INDOORS()
  if self.map_zone_id ~= GetCurrentMapZone() then
    self.map_zone_id = GetCurrentMapZone()
    self.zone_width, self.zone_height = ZONE_SIZES:get_current_zone_size()
  end
end

function Speedometer.events:ZONE_CHANGED()
  if self.map_zone_id ~= GetCurrentMapZone() then
    self.map_zone_id = GetCurrentMapZone()
    self.zone_width, self.zone_height = ZONE_SIZES:get_current_zone_size()
  end
end

function Speedometer.events:PLAYER_REGEN_DISABLED()
  self.in_combat = true
end

function Speedometer.events:PLAYER_REGEN_ENABLED()
  self.in_combat = false
end

function Speedometer.events:PLAYER_AURAS_CHANGED()
  local buff_index = 1
  self.is_mounted = false

  while true do
    local texture = UnitBuff( "player", buff_index )
    if not texture then
      return
    end

    self.tooltip:ClearLines()
    self.tooltip:SetUnitBuff( "player", buff_index )

    local text = self.api[ "SpeedometerTooltipTextLeft2" ]:GetText()
    if text and (string.find( text, "Riding" ) or string.find( text, "Slow and steady..." )) then
      self.is_mounted = true
    end

    buff_index = buff_index + 1
  end
end

function Speedometer:on_update()
  local x, y = GetPlayerMapPosition( "player" )
  local unit = self.db.use_metric and "m/s" or "yd/s"
  local now = GetTime()

  if self.prev_x and self.prev_y and self.prev_time then
    local dt = now - self.prev_time
    if dt > 0.1 then
      local width, height = self.zone_width, self.zone_height

      if not width or not height then
        self.text_status:SetText( "No zone data" )
        return
      end

      local dx = (x - self.prev_x) * width
      local dy = (y - self.prev_y) * height
      local dist = math.sqrt( dx * dx + dy * dy )
      local speed = dist / dt

      if speed < 0 or speed > 100 then
        speed = self.speed_samples[ getn( self.speed_samples ) ]
      end

      table.insert( self.speed_samples, speed )
      if getn( self.speed_samples ) > self.max_samples then
        table.remove( self.speed_samples, 1 )
      end

      local total = 0
      for _, s in ipairs( self.speed_samples ) do
        total = total + s
      end

      local avg_speed = total / getn( self.speed_samples )
      local display_speed = self.db.use_metric and (avg_speed * 0.9144) or avg_speed

      self.text_speed:SetText( string.format( "Speed: %.1f %s", display_speed, unit ) )
      self:update_status( now, avg_speed )

      self.prev_x, self.prev_y, self.prev_time = x, y, now
    end
  else
    self.prev_x, self.prev_y, self.prev_time = x, y, now
  end
end

function Speedometer.dropdown_initialize( level )
  local info = {}

  if level == 1 then
    info.text = m.db.use_metric and "Use Imperial (yards)" or "Use Metric (meters)"
    info.arg1 = "use_metric"
    info.func = function( setting )
      m.db[ setting ] = not m.db[ setting ]
    end
    UIDropDownMenu_AddButton( info )

    info.text = "Show status"
    info.arg1 = "show_status"
    info.checked = m.db.show_status
    UIDropDownMenu_AddButton( info )

    ---@diagnostic disable-next-line: undefined-global
    if gOutfitter_Settings then
      info.text = "Auto-equip \"Swimming\" outfit"
      info.arg1 = "autoequip_swimming"
      info.checked = m.db.autoequip_swimming
      UIDropDownMenu_AddButton( info )
      info.text = "Auto-unequip \"Swimming\" outfit"
      info.arg1 = "autounequip_swimming"
      info.checked = m.db.autounequip_swimming
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
      m:update_skin()
      CloseDropDownMenus()
    end
    UIDropDownMenu_AddButton( info, level )

    info.text = "Flat"
    info.arg1 = "Flat"
    info.checked = m.db.skin == info.arg1
    UIDropDownMenu_AddButton( info, level )
  end
end

function Speedometer:show_dropdown()
  UIDropDownMenu_Initialize( self.dropdown, self.dropdown_initialize, "MENU" )
  ToggleDropDownMenu( 1, nil, self.dropdown, "cursor", 0, 0 )
end

function Speedometer.handle_slash( args )
  if not args or args == "" then
    if m.frame:IsShown() then
      m.frame:Hide()
    else
      m.frame:Show()
    end
  elseif string.find( args, "^c" ) then
    m.db.unequip_click = not m.db.unequip_click
    if m.db.unequip_click then
      DEFAULT_CHAT_FRAME:AddMessage( "|cFF00A2E8Speedometer|r: Unequip swimming outfit on click: |cFF00FF00ON|r" )
    else
      DEFAULT_CHAT_FRAME:AddMessage( "|cFF00A2E8Speedometer|r: Unequip swimming outfit on click: |cFFFF0000OFF|r" )
    end
  else
    DEFAULT_CHAT_FRAME:AddMessage( "|cFF00A2E8Speedometer|r: |cFFBBBBBB/sm click|r to toggle unequip of swimming outfit when clicking Speedometer window." )
  end
end

function Speedometer:update_skin()
  local skin = self.db.skin

  if skin == "Classic" then
    self.frame:SetBackdrop( {
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
    } )
    self.frame:SetBackdropColor( 0, 0, 0, 0.8 )
  elseif skin == "Flat" then
    self.frame:SetBackdrop( {
      bgFile = "Interface/Buttons/WHITE8x8",
      edgeFile = "Interface/Buttons/WHITE8x8",
      edgeSize = 0.8,
    } )
    self.frame:SetBackdropColor( 0, 0, 0, 0.8 )
    self.frame:SetBackdropBorderColor( 0.2, 0.2, 0.2, 1 )
  end
end

---@param current_time number
---@param speed number
function Speedometer:update_status( current_time, speed )
  if self.db.show_status and not self.text_status:IsShown() then
    self.frame:SetHeight( 50 )
    self.text_status:Show()
  elseif not self.db.show_status then
    if self.text_status:IsShown() then
      self.frame:SetHeight( 30 )
      self.text_status:Hide()
    end
    return
  end

  local new_state = self.classify_speed( speed or 0 )
  local sdb = self.status_debounce

  -- Keep flying until we stand still
  if sdb.previous == "Flying" and new_state ~= "Standing" then
    return
  elseif self.is_mounted then
    new_state = "Mounted"
  end

  if sdb.candidate ~= new_state then
    sdb.candidate = new_state
    sdb.start_time = current_time
  elseif current_time - m.status_debounce.start_time >= 0.7 then
    if sdb.current ~= sdb.candidate then
      sdb.current = sdb.candidate
      self.text_status:SetText( sdb.current )

      if sdb.current == "Swimming" or sdb.previous == "Swimming" then
        self.outfitter_swimming( sdb.current == "Swimming" )
      end

      sdb.previous = sdb.current
    end
  end
end

function Speedometer.classify_speed( speed )
  if speed < 0.1 then
    return m.in_combat and "In combat" or "Standing"
  elseif speed < 3 then
    return "Walking"
  elseif speed < 4.6 then
    return "Moonwalking"
  elseif speed < 6.6 then
    return "Swimming"
  elseif speed < 14 then
    return "Running"
  elseif speed < 20 then
    return "Mounted"
  elseif speed < 40 then
    return "Flying"
  else
    return "Unknown"
  end
end

function Speedometer.outfitter_swimming( equip, force )
  if (m.db.autoequip_swimming and equip) or (m.db.autounequip_swimming and not equip) or force then
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
end

function Speedometer:create_frame()
  local width = 120
  ---@diagnostic disable-next-line: undefined-global
  if IsAddOnLoaded( "pfUI" ) and pfUI and pfUI.api and pfUI.env and pfUI.env.C then
    width = 100
  end
  local frame = CreateFrame( "Frame", "SpeedometerFrame", UIParent )
  frame:SetWidth( width )
  frame:EnableMouse( true )
  frame:SetMovable( true )
  frame:RegisterForDrag( "LeftButton" )
  frame:SetFrameStrata( "DIALOG" )
  frame:Show()

  frame:SetScript( "OnUpdate", function() self:on_update() end )
  frame:SetScript( "OnDragStart", function() frame:StartMoving() end )
  frame:SetScript( "OnDragStop", function()
    frame:StopMovingOrSizing()

    local point, _, relative_point, x, y = frame:GetPoint()
    self.db.pos = { point = point, relative_point = relative_point, x = x, y = y }
  end )

  frame:SetScript( "OnMouseUp", function()
    if arg1 == "RightButton" then
      self:show_dropdown()
    end
    if arg1 == "LeftButton" and m.db.unequip_click then
      self.outfitter_swimming( false, true )
    end
  end )

  frame:SetScript( "OnEvent", function()
    if self.events[ event ] then
      self.events[ event ]( self )
    end
  end )

  self.text_speed = frame:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
  self.text_speed:SetPoint( "Top", frame, "Top", 0, -10 )

  self.text_status = frame:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
  self.text_status:SetPoint( "Bottom", frame, "Bottom", 0, 10 )

  return frame
end

string.match = string.match or function( str, pattern )
  if not str then return nil end

  local _, _, r1, r2, r3, r4, r5, r6, r7, r8, r9 = string.find( str, pattern )
  return r1, r2, r3, r4, r5, r6, r7, r8, r9
end

Speedometer:init()
