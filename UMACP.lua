--------------------------------------------------------------
------------------------ UMACP -------------------------------
-- This is a modification of the MACP 
-- mod originally developed by Winter
-- for the XPLANE community <3
-- Original Mod -> https://forums.x-plane.org/index.php?/files/file/86193-macp-mini-autopilot-control-panel-for-xplane-12/&tab=reviews
--------------------------------------------------------------
-- UMACP stands for Ultra Mini Autopilot Control Panel 
-- Ultra Modifications by TreeBaron
-- This script (and its derivatives) is, and will always be, FREEWARE. Thx for using it :)
--------------------------------------------------------------
-- Goals of 'Ultra' Modifications
-- 1. Reduce complexity and size of the interface
-- 2. Make it more compatible with MiniHUD mod
-- 3. Auto-view switching in future? Other mods that diverge from MACPs purpose.

------------------------------------------------------------
--- window parameter=
------------------------------------------------------------
window_border_color = {0.0, 0.0 , 0.0} 	-- these are RGB values, 0 to 1. Try some !
window_background_color = {0.01, 0.01 , 0.01}
opacity = 0.4							-- opacity of the window
maximized = 1							-- 1 if window is visible at startup
draw_title_bar = 1						-- 0 to hide title bar, 1 to show. Pretty useless I guess.
window_x = 15	;	window_y = 70		-- Defaut position of the window = 15 / 75 
btn_width = 45	;	btn_height = 20		-- size of the buttons. You may adjust sizes at will = 45 / 20
sep_width = 8	;	sep_height = 6		-- Size of the separator between buttons = 8 / 6


------------------------------------------------------------
--- Datarefs
------------------------------------------------------------
DataRef("dr_act_alt", "sim/cockpit2/gauges/indicators/altitude_ft_pilot", "readonly")		-- actual altitude
DataRef("dr_act_spd", "sim/flightmodel/position/indicated_airspeed", "readonly") 			-- actual airspeed in knots
dataref("dr_act_vs", "sim/cockpit2/gauges/indicators/vvi_fpm_pilot", "readonly")			-- actual vs
DataRef("dr_compass", "sim/cockpit2/gauges/indicators/ground_track_mag_pilot", "readonly")	-- compass (indicated heading)
DataRef("dr_fd_mode", "sim/cockpit2/autopilot/flight_director_mode", "writable")			-- Flight director mode : 0 fd off / 1 fd on / 2 ap on
DataRef("dr_at", "sim/cockpit2/autopilot/autothrottle_on", "readonly")						-- Auto thrust 0 / 1
DataRef("dr_ap_speed", "sim/cockpit2/autopilot/airspeed_dial_kts_mach", "writable")			-- ap speed in knots. Mach not supported yet
DataRef("dr_flc", "sim/cockpit2/autopilot/speed_status", "readonly")						-- Flight level change : 0 off / 1 ? / 2 on
DataRef("dr_alt", "sim/cockpit/autopilot/altitude", "writable")								-- ap altitude
DataRef("dr_alt_hld","sim/cockpit2/autopilot/altitude_hold_status", "readonly")				-- Alt hold 
DataRef("dr_alt_mode","sim/cockpit2/autopilot/altitude_mode", "readonly")					-- Alt mode
DataRef("dr_vs", "sim/cockpit/autopilot/vertical_velocity", "writable")						-- ap vertical speed
dataref("dr_ap_navmode", "sim/cockpit2/autopilot/nav_status", "readonly")					-- nav mode : 0 off / 1 arm / 2 on
DataRef("dr_source", "sim/cockpit/switches/HSI_selector", "readonly")						-- Nav source : 0 Nav1 / 1 nav2 / 2 GPS
DataRef("dr_nav1_freq", "sim/cockpit/radios/nav1_freq_hz", "writable")						-- active nav1 frequency
DataRef("dr_wpt", "sim/cockpit2/radios/indicators/gps_nav_id", "readonly")					-- name of the next GPS waypoint
DataRef("dr_hdg_to_wpt", "sim/cockpit/gps/course", "readonly")								-- heading to the next GPS waypoint
DataRef("dr_dist_to_wpt", "sim/cockpit/radios/gps_dme_dist_m", "writable")					-- distance remaining to the next GPS waypoint
DataRef("dr_time_to_wpt", "sim/cockpit/radios/gps_dme_time_secs", "writable")				-- time remaining to the next GPS waypoint
DataRef("dr_app", "sim/cockpit2/autopilot/approach_status", "readonly")						-- approach 
DataRef("dr_hdg_mode","sim/cockpit2/autopilot/heading_status", "readonly")					-- ap heading mode: : 0 off / 1 ? / 2 on
DataRef("dr_hdg", "sim/cockpit2/autopilot/heading_dial_deg_mag_pilot", "writable")			-- ap heading in degrees
DataRef("dr_n1", "sim/flightmodel/engine/ENGN_N1_", "readonly")								-- N1 (of first engine, that's much easier)
DataRef("dr_flaps", "sim/flightmodel/controls/flaprqst", "readonly")						-- flaps
DataRef("dr_thr_mode", "sim/flightmodel/engine/ENGN_propmode", "readonly")					-- thrust mode : 1 normal / 3 reverse
DataRef("dr_brakes", "sim/flightmodel/controls/parkbrake", "readonly")						-- brakes
-- DataRef("dr_gs", "sim/cockpit2/radios/indicators/nav1_vdef_dots_pilot", "readonly")		-- glideslope vertical deviation (not used in this version)
DataRef("dr_icao", "sim/aircraft/view/acf_ICAO", "writable")								-- aircraft ICAO code
------------------------------------------------------------
--- Global variables
------------------------------------------------------------
dr_ap_speed = 250						-- defaut autopilot settings. Must be placed after datarefs declarations
dr_alt = 30000
dr_vs = 0 
dr_hdg = 0
fd_is_on = 0							-- Dunno why, but accessing directly the datarefs is not always working in my code. gotta use those vars
ap_is_on = 0
desc_mode = 0							-- auto descent mode
MOUSE_WHEEL_CLICKS = 1					-- External ref to mouse library. Increase vaue for faster scrolling. Do not edit symbol name.

------------------------------------------------------------
--- window events 
------------------------------------------------------------
function btn_click(x,y) 				-- return 1 if mouse clicked in the area of left low coords x,y (size is predefined by constants : button width and height)
	if MOUSE_X > x and MOUSE_X < x + btn_width and MOUSE_Y > y and MOUSE_Y < y + btn_height and MOUSE_STATUS == "down"  then return 1 end
end

function btn_max_click()
	if btn_click(btn_max_x , btn_max_y) == 1 then 
		if maximized == 1 then 
			maximized = 0 
		else
			maximized = 1 
		end			
	end
end

function btn_fd_click()
	if maximized == 1 and btn_click(btn_fd_x , btn_fd_y ) == 1 then 
		if fd_is_on == 0 then 			-- all controlled by dataref FD : 0 is off, 1 is on, 2 is ap servos on
			command_once("sim/autopilot/fd_is_on")
			dr_fd_mode = 1
		end
		if fd_is_on == 1 then 
			command_once("sim/autopilot/fd_is_onr_off")
			dr_fd_mode = 0
		end
	end
end

function btn_ap_click()
	if maximized == 1 and btn_click( btn_ap_x , btn_ap_y ) == 1 then
		if ap_is_on == 0 then 
			command_once("sim/autopilot/fd_is_onr_servos_on")
			dr_fd_mode = 2
		end
		if ap_is_on == 1 then 
			command_once("sim/autopilot/servos_down_one")
			dr_fd_mode = 1
		end
	end
end

function btn_at_click()
	if maximized == 1 and btn_click(btn_at_x , btn_at_y) == 1 then 
		command_once("sim/autopilot/autothrottle_toggle")
	end
end

function btn_flc_click()
	if maximized == 1 and btn_click(btn_flc_x , btn_flc_y ) == 1 then 
		if dr_fd_mode >= 1 then
			command_once("sim/autopilot/level_change") 
		end
	end
end

function btn_alt_click()
	if maximized == 1 and btn_click(btn_alt_x , btn_alt_y )then 
		command_once("sim/autopilot/altitude_hold")
		command_once("sim/autopilot/altitude_arm")
	end
end

function btn_vs_click()
	if maximized == 1 and btn_click(btn_vs_x , btn_vs_y ) then 
		command_once("sim/autopilot/vertical_speed_pre_sel")
	end
end

function btn_gps_click()
	if maximized == 1 and btn_click(btn_gps_x ,btn_gps_y ) then 
		if dr_fd_mode > 0 then
			command_once("sim/autopilot/hsi_select_gps") 
			command_once("sim/autopilot/NAV") 
		end
	end
end

function btn_loc_click()
	if maximized == 1 and btn_click(btn_loc_x , btn_loc_y ) == 1 then 
		if dr_fd_mode > 0 then
			command_once("sim/autopilot/hsi_select_nav_1")
			command_once("sim/autopilot/NAV")
		end
	end
end

function btn_app_click()
	if maximized == 1 and btn_click(btn_app_x , btn_app_y ) == 1 then 
		if dr_fd_mode > 0 then
			command_once("sim/autopilot/hsi_select_nav_1")
			command_once("sim/autopilot/approach") 
		end
	end
end

function btn_hdg_click()
	if maximized == 1 and btn_click(btn_hdg_x , btn_hdg_y ) == 1 then 
		if dr_fd_mode > 0 then
			command_once("sim/autopilot/heading") 
		end
	end
end

function btn_des_click()
	if btn_click(btn_desc_x , btn_desc_y) == 1 then 
		if desc_mode == 1 then 
			desc_mode = 0 
		else
			desc_mode = 1 
		end			
	end
end

function sel_alt_scroll()
	if maximized == 1 and MOUSE_X > sel_alt_x and MOUSE_X < sel_alt_x + btn_width and MOUSE_Y > sel_alt_y and MOUSE_Y < sel_alt_y + btn_height then	dr_alt = dr_alt + (MOUSE_WHEEL_CLICKS * 1000) end	
	if dr_alt < 0 then dr_alt = 0 end
end

function sel_vs_scroll()
	if maximized == 1 and MOUSE_X > sel_vs_x and MOUSE_X < sel_vs_x + btn_width and MOUSE_Y > sel_vs_y and MOUSE_Y < sel_vs_y + btn_height then dr_vs = dr_vs + (MOUSE_WHEEL_CLICKS * 100) end
end

function sel_spd_scroll()
	if maximized == 1 and MOUSE_X > sel_spd_x and MOUSE_X < sel_spd_x + btn_width and MOUSE_Y > sel_spd_y and MOUSE_Y < sel_spd_y + btn_height then	dr_ap_speed = dr_ap_speed + (MOUSE_WHEEL_CLICKS) end
	if dr_ap_speed < 0 then dr_ap_speed = 0 end
end

function sel_hdg_scroll()
	if maximized == 1 and MOUSE_X > sel_hdg_x and MOUSE_X < sel_hdg_x + btn_width and MOUSE_Y > sel_hdg_y and MOUSE_Y < sel_hdg_y + btn_height then	dr_hdg = math.floor((dr_hdg + 0.5) + MOUSE_WHEEL_CLICKS) end
end

function sel_nav_scroll()
	if maximized == 1 and MOUSE_X > sel_loc_x and MOUSE_X < sel_loc_x + btn_width and MOUSE_Y > sel_loc_y and MOUSE_Y < sel_loc_y + btn_height then	dr_nav1_freq = dr_nav1_freq + MOUSE_WHEEL_CLICKS * 5 end
	if dr_nav1_freq < 10800 then dr_nav1_freq = 10800 end
	if dr_nav1_freq > 11795 then dr_nav1_freq = 11795 end
end

function check_click_events()
	btn_max_click()
	btn_fd_click()
	btn_ap_click()
	btn_at_click()
	btn_flc_click() 
	btn_alt_click()
	btn_vs_click()
	btn_gps_click()
	btn_loc_click()
	btn_app_click()
	btn_hdg_click()
	btn_des_click()
end
do_on_mouse_click("check_click_events()")

function check_scroll_events()
	if maximized == 1 and MOUSE_X > window_x and MOUSE_X < window_x + window_width and MOUSE_Y > window_y and MOUSE_Y < window_y + window_height  then 
		RESUME_MOUSE_WHEEL = true -- ignore mouse wheel zooming in the simulator
	end
	sel_alt_scroll()
	sel_vs_scroll()
	sel_spd_scroll()
	sel_hdg_scroll()
	sel_nav_scroll()
end
do_on_mouse_wheel("check_scroll_events()")

function check_alt()
	if maximized == 1 and dr_alt_hld == 0 and dr_flc == 2 or dr_alt_hld == 0 and dr_alt_mode == 4 then command_once("sim/autopilot/altitude_arm")	end
end
do_every_frame("check_alt()")




------------------------------------------------------------
--- Graphical utilities
------------------------------------------------------------
function init_graphics()															-- Calculate the coordinates of graphics elements
	--- Main Window
	btn_max_x = 15									;	btn_max_y = 35
	window_width = 6 * sep_width + 5 * btn_width	;	window_height = 3 * sep_height + 5 * btn_height
	btn_desc_x = btn_max_x + window_width + 5 		;	btn_desc_y = btn_max_y
	--- Group AP
	btn_ap_x = window_x + sep_width					;	btn_ap_y = window_y + btn_height + btn_height + btn_height + sep_height
	btn_fd_x = window_x + sep_width					;	btn_fd_y = btn_ap_y + btn_height + sep_height
	--- Group SPEED
	btn_flc_x = (window_x + sep_width) + btn_width + sep_width	;	btn_flc_y = (window_y + sep_height) + 2 * btn_height + sep_height
	sel_spd_x = btn_flc_x							;	sel_spd_y = btn_flc_y + btn_height
	btn_at_x = btn_flc_x							;	btn_at_y = sel_spd_y + btn_height 
	--- Group VERTICAL SPEED
	sel_vs_x = btn_flc_x + btn_width + sep_width	;	sel_vs_y = (window_y + sep_height) 
	btn_vs_x = sel_vs_x								;	btn_vs_y = sel_vs_y +  btn_height 
	--- Group ALTITUDE
	sel_alt_x = btn_vs_x							;	sel_alt_y = sel_spd_y
	btn_alt_x = btn_vs_x							;	btn_alt_y = sel_alt_y + btn_height
	--- Group GPS
	dsp_ttk_x = btn_alt_x + btn_width + sep_width	;	dsp_ttk_y = sel_vs_y  + sep_height
	dsp_dtk_x = dsp_ttk_x							;	dsp_dtk_y = dsp_ttk_y + btn_height
	dsp_trk_x = dsp_ttk_x							;	dsp_trk_y = dsp_ttk_y + 2 * btn_height
	dsp_wpt_x = dsp_ttk_x							;	dsp_wpt_y = dsp_ttk_y + 3 * btn_height
	btn_gps_x = dsp_ttk_x							;	btn_gps_y = dsp_ttk_y + 4 * btn_height
	--- Group HEADING
	sel_hdg_x = btn_gps_x + btn_width + sep_width	;	sel_hdg_y = sel_vs_y 
	btn_hdg_x = sel_hdg_x							;	btn_hdg_y = sel_hdg_y +  btn_height 
	--- Group NAV1 freq.
	btn_app_x = sel_hdg_x							;	btn_app_y = btn_hdg_y  + btn_height + sep_height	
	sel_loc_x = sel_hdg_x							;	sel_loc_y = btn_app_y  + btn_height
	btn_loc_x = sel_hdg_x							;	btn_loc_y = btn_app_y  + 2 * btn_height	
end

function frame(x , y , width , height , line_color , background_color) 				-- draw a colored frame with outline
    local line_padding = 0 -- offset of the line inside d the frame
    glColor4f(background_color[1] , background_color[2] , background_color[3] , opacity) -- background color          
    glRectf(x, y, x + width, y + height) -- background shape
	glColor4f(line_color[1] , line_color[2] , line_color[3] , opacity) -- line color
    glBegin_LINES()
        glVertex2f(x + line_padding, y + line_padding)
        glVertex2f(x + line_padding, y + height -line_padding)
    glEnd()
    glBegin_LINES()
        glVertex2f(x + line_padding, y + height - line_padding)
        glVertex2f(x - line_padding + width, y + height - line_padding)
    glEnd()
    glBegin_LINES()
        glVertex2f(x - line_padding + width, y +  height -line_padding)
        glVertex2f(x - line_padding + width, y + line_padding)
    glEnd()
    glBegin_LINES()
        glVertex2f(x - line_padding + width, y + line_padding)
        glVertex2f(x + line_padding, y + line_padding)
    glEnd()
end

function button(x , y , msg , btn_is_on , btn_is_armed)								-- Draw a button. Color defined by state : off, arm, on
	local padh = 10	;	local padv = 7
	if btn_is_armed == 1 then 
			frame(x, y , btn_width, btn_height, {0.0, 0.0 , 0.0}  , {1.0, 0.5 , 0.0} , opacity)
			draw_string(x + padh , y + padv, msg, "black") 	
	else
		if btn_is_on == 0 then 
				frame(x, y , btn_width, btn_height, {0.0, 0.0 , 0.0}  , {0.3, 0.3 , 0.3} , opacity)
				draw_string(x + padh , y + padv, msg, "white")
		end
		if btn_is_on == 1 then 
				frame(x, y , btn_width, btn_height, {0.0, 0.0 , 0.0}  , {0.0, 1.0 , 0.0} , opacity)
				draw_string(x + padh , y + padv, msg, "black")				
		end
	end
	
	if btn_is_on == 0 then  -- 3d effect
		glColor4f(0.0 , 0.0 , 0.0 , opacity)
		glBegin_LINES()
			glVertex2f(x + 1, y + 1 )
			glVertex2f(x + btn_width  - 1, y + 1 )
		glEnd()
		glBegin_LINES()
			glVertex2f(x + btn_width - 1  , y + 1 )
			glVertex2f(x + btn_width - 1 , y + btn_height )
		glEnd()
		glColor4f(1.0 , 1.0 , 1.0 , opacity)
		glBegin_LINES()
			glVertex2f(x + 1, y + 1 )
			glVertex2f(x + 1 , y + btn_height - 1 )
		glEnd()
		glBegin_LINES()
			glVertex2f(x + 1 , y + btn_height  - 1)
			glVertex2f(x + btn_width - 1 , y + btn_height  -1 )
		glEnd()
	else
		glColor4f(1.0 , 1.0 , 1.0 , opacity)
		glBegin_LINES()
			glVertex2f(x + 1, y + 1 )
			glVertex2f(x + btn_width  - 1, y + 1 )
		glEnd()
		glBegin_LINES()
			glVertex2f(x + btn_width - 1  , y + 1 )
			glVertex2f(x + btn_width - 1 , y + btn_height )
		glEnd()
		glColor4f(0.0 , 0.0 , 0.0 , opacity)
		glBegin_LINES()
			glVertex2f(x + 1, y + 1 )
			glVertex2f(x + 1 , y + btn_height - 1 )
		glEnd()
		glBegin_LINES()
			glVertex2f(x + 1 , y + btn_height  - 1)
			glVertex2f(x + btn_width - 1 , y + btn_height  -1 )
		glEnd()
	end
end

function selector(x , y, msg)														-- Draw a scrollable numeric selector
	frame(x, y , btn_width, btn_height, {0.0, 0.0 , 0.0}  , {0.2, 0.2 , 0.2} , opacity)
	draw_string(x + 4 , y + 6, msg, "white")
end

function displayer(x , y, msg)														-- Draw a displayer for any info
	frame(x, y , btn_width, btn_height, {0.0, 0.0 , 0.0}  , {0.0, 0.0 , 0.9} , opacity)
	draw_string(x + 3 , y + 6 , msg, "yellow")
end

function linear_gauge(x , y , width, height, color, value , is_red, is_downward) 	-- Draw a vertical linear gauge. "value" must be 0 to 1
		frame(x, y, width , height, {0.0, 0.0 , 0.0} , {0.0, 0.0 , 0.0})
		if is_downward == 0 then	
			if is_red == 0 then frame(x, y , width , height * value , {0.0, 0.0 , 0.0} , {1.0, 1.0 , 0.0}) end -- normal gauge
			if is_red == 1 then frame(x, y , width , height * value , {1.0, 0.0 , 0.0} , {1.0, 0.0 , 0.0}) end -- red gauge
		else
			frame(x, y + height , width , - height * value , {0.0, 0.0 , 0.0} , {0.0, 1.0 , 0.5}) -- if downward
			
		end
end

------------------------------------------------------------
--- Inner functions
------------------------------------------------------------

function comma_value(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

------------------------------------------------------------
--- Main
------------------------------------------------------------
function main_chunk()
	init_graphics()	
	if maximized == 0 then button(btn_max_x, btn_max_y, "UACP", 0, 0) end 			-- Minimize / maximize window
	if maximized == 1 then
		
		button(btn_max_x, btn_max_y, "UACP", 1 , 0)														
		frame(window_x, window_y , window_width, window_height, window_border_color, window_background_color) 	-- draw main window
		
		if draw_title_bar == 1 then
			frame(window_x, window_y + window_height, window_width, 25, window_border_color, window_background_color)-- draw window title bar
			draw_string(window_x + 3, window_y + window_height + 8, "ULTRA MACP", "white" )					-- title
		end
		
		local offsetWindow = -12
		frame(window_x + sep_width + window_width - 5, 
		window_y + (2 * btn_height) + (3 * sep_height) + offsetWindow,
		btn_width+45, -- width
		2 * btn_height + 2 * sep_height + 19, -- height
		{1.0, 0.5 , 0.5},
		{0.1, 0.1 , 0.1})
		
		local movingDownPosition = btn_at_y + 19 + offsetWindow
		draw_string(btn_fd_x + window_width, movingDownPosition, "HDG  "..math.floor(dr_compass), "green") 				-- heading
		movingDownPosition = movingDownPosition - 15
		draw_string(btn_fd_x + window_width, movingDownPosition,  "SPD  "..math.floor(dr_act_spd), "white") 			-- actual speed
		movingDownPosition = movingDownPosition - 15
		draw_string(btn_fd_x + window_width, movingDownPosition, "ALT  "..comma_value(math.floor(dr_act_alt)), "green") 	-- actual alt
		movingDownPosition = movingDownPosition - 15
		draw_string(btn_fd_x + window_width, movingDownPosition, "VS   "..math.floor(dr_act_vs), "white") 				-- actual VS
		-- draw_string_Helvetica_18( x, y, "string" 		
				
		if dr_thr_mode == 3 then 														-- let's draw the gauges
			linear_gauge(btn_at_x , btn_ap_y , 10 , 40 , {1.0, 0.0 , 0.0} , dr_n1 / 100 , 1 , 0) -- thrust reverse
		else
			linear_gauge(btn_at_x , btn_ap_y , 10 , 40 , {1.0, 0.0 , 0.0} , dr_n1 / 100 , 0 , 0) -- thrust normal
		end
		if dr_flaps > 0 then 
			linear_gauge(btn_at_x + 15 , btn_ap_y , 10 , 40 , {0.0, 1.0 , 0.0} , dr_flaps , 0 , 1) -- flaps 
		end
						
		if dr_brakes == 1 then 
			draw_string(btn_alt_x , sel_alt_y - 15, "BRAKES", "yellow")  -- brakes
		else
			draw_string(btn_alt_x + 5 , sel_alt_y - 15, dr_icao, "black")
		end
						
		selector(sel_spd_x, sel_spd_y, math.floor(dr_ap_speed))
		if desc_mode == 0 then
			selector(sel_vs_x, sel_vs_y, math.floor(dr_vs))
		else
			displayer(sel_vs_x, sel_vs_y, "AUTO")
		end
		selector(sel_alt_x, sel_alt_y,math.floor(dr_alt))
		selector(sel_hdg_x, sel_hdg_y, math.floor(dr_hdg + 0.5))
		selector(sel_loc_x, sel_loc_y, dr_nav1_freq)
		displayer(dsp_ttk_x, dsp_ttk_y, math.floor(dr_time_to_wpt).."'")
		displayer(dsp_dtk_x, dsp_dtk_y, math.floor(dr_dist_to_wpt).."n")
		displayer(dsp_trk_x, dsp_trk_y, math.floor(dr_hdg_to_wpt).."°")
		displayer(dsp_wpt_x, dsp_wpt_y, dr_wpt, "white")
		----------------  AP  --------------------------------
		if dr_fd_mode == 0 then -- FD off, AP off
			button(btn_fd_x, btn_fd_y, "F/D",0 , 0)	
			button(btn_ap_x, btn_ap_y, "A/P", 0 , 0)
			ap_is_on = 0	;	fd_is_on = 0		
		end
		
		if dr_fd_mode == 1 then -- FD on, AP off
			button(btn_fd_x, btn_fd_y, "F/D", 1 , 0)	
			button(btn_ap_x, btn_ap_y, "A/P", 0 , 0)
			ap_is_on = 0	;	fd_is_on = 1
		end
		
		if dr_fd_mode == 2 then -- FD on, AP on
			button(btn_fd_x, btn_fd_y, "F/D", 1 , 0)
			button(btn_ap_x, btn_ap_y, "A/P", 1 , 0)
			ap_is_on = 1	;	fd_is_on = 1
		end
		----------------  AT  --------------------------------
		if dr_at == 1 then button(btn_at_x, btn_at_y, "A/TH", 1 , 0) end 
		if dr_at == 0 then button(btn_at_x, btn_at_y, "A/TH", 0 , 0) end
		----------------  FLC  --------------------------------
		if dr_flc == 2 then button(btn_flc_x, btn_flc_y, "FLC", 1)	end 
		if dr_flc == 0 or maximized == 1 and dr_flc == 10 then	button(btn_flc_x, btn_flc_y, "FLC", 0 , 0) end
		----------------  ALT  --------------------------------
		if dr_alt_hld == 2 then button(btn_alt_x, btn_alt_y, "ALT", 1 , 0) end 
		if dr_alt_hld == 1 then button(btn_alt_x, btn_alt_y, "ALT", 0 , 1)	end
		if dr_fd_mode == 0 or maximized == 1 and dr_alt_hld == 0 then button(btn_alt_x, btn_alt_y, "ALT", 0 , 0) end -- off
		----------------  VS  --------------------------------
		if dr_alt_mode == 3 or dr_alt_mode >= 5 then button(btn_vs_x, btn_vs_y, "V/S", 0 , 0) end -- other modes
		if dr_alt_mode == 4 then	button(btn_vs_x, btn_vs_y, "V/S", 1 , 0) end  -- VS on
		----------------  NAV  --------------------------------
		if dr_fd_mode == 0 or dr_ap_navmode == 0 then -- NAV is off
			button(btn_loc_x, btn_loc_y, "LOC", 0 , 0)
			button(btn_gps_x, btn_gps_y, "GPS", 0 , 0)
		end 
		if dr_fd_mode > 0 and dr_ap_navmode == 2 then -- NAV on
			if dr_source == 0 then 
				button(btn_loc_x, btn_loc_y, "LOC", 0 , 1) -- LOC arm
				button(btn_gps_x, btn_gps_y, "GPS", 0 , 0) 
			end
			if dr_source == 1 then -- this should never happen. GPS cannot be arm ?
				button(btn_loc_x, btn_loc_y, "LOC", 0 , 0)
				button(btn_gps_x, btn_gps_y, "GPS", 0 , 1)
			end
		end
		if dr_fd_mode > 0 and dr_ap_navmode == 2 then -- NAV on
			if dr_source == 0 then 
				button(btn_loc_x, btn_loc_y, "LOC", 1 , 0) --LOC on
				button(btn_gps_x, btn_gps_y, "GPS", 0 , 0)
			end
			if dr_source == 2 then
				button(btn_loc_x, btn_loc_y, "LOC", 0 , 0) -- GPS on
				button(btn_gps_x, btn_gps_y, "GPS", 1 , 0)
			end
		end
	----------------  APP  --------------------------------
		if dr_app == 0 then	button(btn_app_x, btn_app_y, "APP", 0 , 0) end	-- off
		if dr_app == 1 then	button(btn_app_x, btn_app_y, "APP", 0 , 1) end  -- arm
		if dr_app == 2 then button(btn_app_x, btn_app_y, "APP", 1 , 0) end  -- on
	----------------  HDG  --------------------------------
		if dr_hdg_mode == 0 or dr_hdg_mode == 1 then button(btn_hdg_x, btn_hdg_y, "HDG", 0 , 0) end
		if dr_hdg_mode == 2 then button(btn_hdg_x, btn_hdg_y, "HDG", 1 , 0) end 
	end
end
do_every_draw("main_chunk()")
