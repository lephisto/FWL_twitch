-- Pathes to ref's
-- Speeds
	DataRef( "groundspeed", "sim/flightmodel/position/groundspeed" )
	DataRef( "v_normal", "sim/aircraft/view/acf_Vno" )
	DataRef( "v_stall0", "sim/aircraft/view/acf_Vso" )
	DataRef( "v_stall", "sim/aircraft/view/acf_Vs" )
	DataRef( "v_maxflaps", "sim/aircraft/view/acf_Vfe" )
	DataRef( "v_no", "sim/aircraft/view/acf_Vno" )
	DataRef( "v_ne", "sim/aircraft/view/acf_Vne" )
	DataRef( "m_mo", "sim/aircraft/view/acf_Mmo" )
	DataRef( "v_airi", "sim/flightmodel/position/indicated_airspeed2" )
	DataRef( "v_airtrue", "sim/flightmodel/position/true_airspeed" )

-- Wind
	DataRef( "wind_dir", "sim/weather/wind_direction_degt" )
	DataRef( "wind_speed", "sim/weather/wind_speed_kt" )
	DataRef( "wind_head", "sim/cockpit2/gauges/indicators/wind_heading_deg_mag" )
	DataRef( "wind_speed_acting", "sim/cockpit2/gauges/indicators/wind_speed_kts" )

-- Fuel
	DataRef( "fuel_total_lbs", "sim/aircraft/weight/acf_m_fuel_tot" ) -- kg max fuel -> (Jetfuel) Gallons = m_fuel * 0.3290865
	DataRef( "fuel_total_weight", "sim/flightmodel/weight/m_fuel_total" ) -- kg
	fuel_flow_kg_sec = dataref_table("sim/cockpit2/engine/indicators/fuel_flow_kg_sec")


-- Climb/Sink-Rates and Altitude
	DataRef( "elevation_msl", "sim/flightmodel/position/elevation" ) -- in m
	DataRef( "ind_bar_alt", "sim/flightmodel/misc/h_ind2" ) -- in ft
	DataRef( "v_z", "sim/flightmodel/position/local_vz" ) -- up/down-speed in m/s
	DataRef( "alt_ap", "sim/cockpit/autopilot/altitude" ) -- in ftmsl
	DataRef( "vertical_velocity_ap", "sim/cockpit/autopilot/vertical_velocity" ) -- in fpm
	DataRef( "vpath", "sim/flightmodel/position/vpath" ) -- in degree
	DataRef( "vspeed", "sim/flightmodel/position/vh_ind" ) -- in m/s
	DataRef( "vspeed2", "sim/flightmodel/position/vh_ind_fpm" ) -- in fpm

-- Times
	DataRef( "UTC", "sim/time/zulu_time_sec" ) -- in s
	DataRef( "zulu_h", "sim/cockpit2/clock_timer/zulu_time_hours" )
	DataRef( "zulu_min", "sim/cockpit2/clock_timer/zulu_time_minutes" )
	DataRef( "zulu_sec", "sim/cockpit2/clock_timer/zulu_time_seconds" )

-- Pressure
	DataRef( "FID_QNH", "sim/weather/barometer_sealevel_inhg" ) -- in inHG
	DataRef( "FID_QNH_Pilot", "sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot", "writable" )
	DataRef( "FID_QNH_Co", "sim/cockpit2/gauges/actuators/barometer_setting_in_hg_copilot" , "writable")

-- Weather
	DataRef( "FID_Wind_Alt_0", "sim/weather/wind_altitude_msl_m[0]" )
	DataRef( "FID_Wind_Alt_1", "sim/weather/wind_altitude_msl_m[1]" )
	DataRef( "FID_Wind_Alt_2", "sim/weather/wind_altitude_msl_m[2]" )
	DataRef( "FID_WindSpd_0", "sim/weather/wind_speed_kt[0]" )
	DataRef( "FID_WindSpd_1", "sim/weather/wind_speed_kt[1]" )
	DataRef( "FID_WindSpd_2", "sim/weather/wind_speed_kt[2]" )
	DataRef( "FID_OTA", "sim/weather/temperature_ambient_c")


-- table for fms data
local fms = {count = 0, disp = 0, dest = 0, type = 0, id = "--", ref = 0, alt = 0, lat = 0, lon = 0}

local fms_destination_icao
local fms_destination_name
local fms_origin_icao
local fms_origin_name



-- Here goes the normal stuff

-- we will show the last metar at the top of the screen
-- and we will give the next airport too
-- plus we show the FPS value

local standing = true
local start_fuel = 0
local FUEL_USED_value
local FFPS_value
local FUEL_TIME_value
local FUEL_DISTANCE_value
local TOC_BOD_TIME_value
local TOC_BOD_TIME_Mins_value
local TOC_BOD_TIME_Secs_value
local TOC_BOD_DISTANCE_value
local UTC_h
local UTC_min
local UTC_sec
local START_UP_h = 0
local START_UP_min = 0
local START_UP_sec = 0
local FLIGHT_TIME_value = 0
local FLIGHT_TIME_h = 0
local FLIGHT_TIME_min = 0
local FLIGHT_TIME_sec = 0
local UTC_temp

-- Let's look for the show_metar_and_airport
local home_dir = os.getenv( "HOME" )

-- we need a local DataRef for FPS calc
local frame_rate_ref = XPLMFindDataRef("sim/operation/misc/frame_rate_period")
local fps = 0

-- If the function calc_metar_and_airport() fails, we provide a dummy text.
-- This is important when Lua starts the script, and the drawing callback starts before the calculation.
local last_metar_and_airport_info = "Something goes wrong!"

-- We will also have to provide the length of the string in pixel
local info_lenght = measure_string( last_metar_and_airport_info )

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function mysplit(inputstr, sep)
        if sep == nil then
          sep = "%s"
        end
				if inputstr == nil then
					return nil
				end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end

function START_UP_calc()
  if standing == true
    then
      START_UP_h = zulu_h
      START_UP_min = zulu_min
      START_UP_sec = zulu_sec
  end
  if UTC < START_UP_h * 3600 + START_UP_min * 60 + START_UP_sec - 2 -- 2 sec delay tolerated
    then UTC_temp = UTC + 24*3600
    else UTC_temp = UTC
  end
  FLIGHT_TIME_value = UTC_temp - (START_UP_h * 3600 + START_UP_min * 60 + START_UP_sec)
  FLIGHT_TIME_h = math.floor(FLIGHT_TIME_value / 3600)
  FLIGHT_TIME_min = math.floor((FLIGHT_TIME_value - FLIGHT_TIME_h * 3600)/60)
  FLIGHT_TIME_sec = math.floor(FLIGHT_TIME_value - FLIGHT_TIME_h * 3600 - FLIGHT_TIME_min * 60)
end

-- sum up the fuel flow
function fuel_flow_per_sec()
FFPS_value = 0
  for i = 0, 7 do
    FFPS_value = FFPS_value + fuel_flow_kg_sec[i]
  end
end

-- calculate fuel time in minutes
function fuel_time()
  FUEL_TIME_value = fuel_total_weight/FFPS_value/60
end

-- calculate fuel distance in nm
function fuel_distance()
--	local g = groundspeed
--	local t = fuel_time() * 60
--	local d = g*t/1852
  FUEL_DISTANCE_value = groundspeed *(FUEL_TIME_value*60)/1852
end

-- calculate used fuel after first time gs > 5 m/s
function calc_used_fuel()
  FUEL_USED_value = 0
  local ftw = fuel_total_weight
  if groundspeed > 5
    then standing = false
  end
  if standing == true
    then start_fuel = fuel_total_weight
  end
  FUEL_USED_value = start_fuel - fuel_total_weight
end

-- calculate TOC/BOD distance -- in m
function TOC_BOD_distance()
  TOC_BOD_DISTANCE_value = TOC_BOD_TIME_value * groundspeed
end

-- calculate TOC/BOD Time
function TOD_BOD_time() -- in s
  local alt_ind = ind_bar_alt*381/1250
  local alt_ap_lcl = alt_ap*381/1250
  if (math.abs(alt_ind - alt_ap_lcl) < 5 or math.abs(vspeed) < 0.5)
    then TOC_BOD_TIME_value = 0
      TOC_BOD_TIME_Mins_value = 0
      TOC_BOD_TIME_Secs_value = 0
    else TOC_BOD_TIME_value = (alt_ap_lcl - alt_ind)/vspeed
      TOC_BOD_TIME_Mins_value = math.floor(TOC_BOD_TIME_value/60)
      TOC_BOD_TIME_Secs_value = math.floor(TOC_BOD_TIME_value - (60*TOC_BOD_TIME_Mins_value))
  end
end

function calculate_Times()
  fuel_flow_per_sec()
  fuel_time()
  fuel_distance()
  calc_used_fuel()
  TOD_BOD_time()
  TOC_BOD_distance()
	START_UP_calc()
end

-- make a function to be every second, finding out the info we need
function twitchinfo_export()
    -- the last metar is a string inside the predefined variable XSB_METAR and only filled when online
    -- we only have to find out the next airport name and position
    -- we will only get an index to the nav database
    -- LATITUDE and LONGITUDE are predefined datarefs representing our plane's position
    -- the nil arguments are used, when we do not care about the search value (name, ID, frequency)
    next_airport_index = XPLMFindNavAid( nil, nil, LATITUDE, LONGITUDE, nil, xplm_Nav_Airport)

    -- let's examine the name of the airport we found, all variables should be local
    -- we do not waste Lua with variables to avoid conflicts with other scripts
    local outID
    local outName

    -- all output we are not intereted in can be send to variable _ (a dummy variable)
    _, _, _, _, _, _, outID, outName = XPLMGetNavAidInfo( next_airport_index )

    -- the last step is to create a global variable the printing function can read out
    fps = 1/XPLMGetDataf(frame_rate_ref)

    -- fms_entries = XPLMCountFMSEntries()
    -- dst_airport_index = dataref_table("sim/cockpit/gps/destination_index")
    -- _, _, _, _, _, _, dstID, dstName = XPLMGetNavAidInfo( dst_airport_index )
    --V_msc = (XPLMGetDataf(XPLMFindDataRef("sim/flightmodel/position/groundspeed"))*3600)/1000
    --V_msc = round(V_msc,0)
    V_hdg = XPLMGetDataf(XPLMFindDataRef("sim/flightmodel/position/mag_psi"))
    V_hdg = round(V_hdg,0)
    V_vsp = XPLMGetDataf(XPLMFindDataRef("sim/cockpit2/gauges/indicators/vvi_fpm_pilot"))
    V_vsp = round(V_vsp,0)
    V_alt = XPLMGetDataf(XPLMFindDataRef("sim/cockpit2/gauges/indicators/altitude_ft_pilot"))
    V_alt = round(V_alt,0)

    V_msc = string.format("%03d", groundspeed*3600/1852) .. " kts"
    V_fuel = string.format("%07.1f", fuel_total_weight)

    V_utc = "UTC: " .. string.format("%02d : %02d : %02d", zulu_h, zulu_min, zulu_sec)
    V_utc_startup = string.format("%02d : %02d : %02d", START_UP_h, START_UP_min, START_UP_sec)
    V_utc_airtime = string.format("%02d : %02d : %02d", FLIGHT_TIME_h, FLIGHT_TIME_min, FLIGHT_TIME_sec)

    V_toc = string.format("%06.2f", TOC_BOD_DISTANCE_value/1852) .. " nm"
    V_ffph = string.format("%05.2f", FFPS_value*60) .. " kg/m"

		DataRef( "V_tailnum", "sim/aircraft/view/acf_tailnum" )
		-- logMsg ("twitchinfo_exporter: tailnum: " .. V_tailnum)

		if V_tailnum == 'ZB738' then
		  -- Zibo
			DataRef( "V_zibo_fms", "laminar/B738/fms/legs" )
			DataRef( "V_zibo_fms_dest", "laminar/B738/fms/dest_icao" )
			V_zibo_fms = mysplit(V_zibo_fms," ")
			V_zibo_fms_dest = mysplit(V_zibo_fms_dest," ")
			if (V_zibo_fms) then
				V_zibo_origin = V_zibo_fms[1]
				V_zibo_destination = V_zibo_fms_dest[1]
				if (V_zibo_origin) and (V_zibo_destination) then
					fms_origin_index = XPLMFindNavAid( nil, V_zibo_origin, LATITUDE, LONGITUDE, nil, xplm_Nav_Airport)
					_, _, _, _, _, _, _, origin_name = XPLMGetNavAidInfo( fms_origin_index )
					fms_destination_index = XPLMFindNavAid( nil, V_zibo_destination, LATITUDE, LONGITUDE, nil, xplm_Nav_Airport)
					_, _, _, _, _, _, _, destination_name = XPLMGetNavAidInfo( fms_destination_index )
					fms_origin_icao = V_zibo_origin
					fms_destination_icao = V_zibo_destination
					fms_origin_name = origin_name
					fms_destination_name = destination_name
				end
			end
		end

		if V_tailnum == 'N816NN' then
			-- Stock 737
			fms.count = XPLMCountFMSEntries()
			if fms.count>1 then
				fms.type, fms.id, fms.ref, fms.alt, fms.lat, fms.lon = XPLMGetFMSEntryInfo( 0 )
				_, _, _, _, _, _, origin_icao, origin_name = XPLMGetNavAidInfo( fms.ref )
			  fms.type, fms.id, fms.ref, fms.alt, fms.lat, fms.lon = XPLMGetFMSEntryInfo( fms.count - 1 )
				_, _, _, _, _, _, destination_icao, destination_name = XPLMGetNavAidInfo( fms.ref )
				fms_origin_icao = origin_icao
				fms_destination_icao = destination_icao
			else
				fms_origin_icao = "NOORG"
				fms_destination_icao = "NODEST"
			end
		end

		if V_tailnum == 'A319' then
			fms.count = XPLMCountFMSEntries()
		end

		if (fms_origin_icao) and (fms_destination_icao) then
			fms_info = '[Origin: ' .. fms_origin_icao .. '/' .. fms_origin_name .. ' >> Destination: ' .. fms_destination_icao .. '/' .. fms_destination_name .. ']'
		else
		  fms_info = '[Unsupported FMS]'
		end

    local twitchinfo_file = io.open(home_dir .. '/xp11_stats.txt',"w")
    twitchinfo_file:write(fms_info..'\n' .. '[Altitude: ' .. V_alt .. ' ft]\n[Groundspeed: ' .. V_msc .. ']\n[Vertical Speed: ' .. V_vsp .. ' fpm]\n[Next Apt: ' .. outName .. ' (' .. outID .. ')]\n[Total Fuel: ' .. V_fuel .. ' at ' .. V_ffph .. ']\n[Airtime: ' .. V_utc_airtime .. ']\n')
    twitchinfo_file:close()

		last_metar_and_airport_info = string.format("Last METAR: %s, your next airport: %s (%s) [%s at %2.1f fps] [Altitude: %s ft] [Groundspeed: %s km/h] [Heading: %s] [VS: %s fpm]", XSB_METAR, outName, outID, PLANE_ICAO, fps, V_alt, V_msc, V_hdg, V_vsp)
		info_lenght = measure_string( last_metar_and_airport_info, "Helvetica_12" )
end


-- This function only prints the info text. If it has to calc it every frame, we will get a poor performance!
function show_metar_and_airport()
    -- we can use the predefined variables SCREEN_WIDTH and SCREEN_HIGHT to position the text at the top of the screen
    -- but we need the lenght of the info in pixel
		glColor4f(1,1,1,1)
		draw_string_Helvetica_12(SCREEN_WIDTH - info_lenght - 10, SCREEN_HIGHT - 15, last_metar_and_airport_info)
end

-- register the functions to the callbacks
do_every_frame("calculate_Times()")
do_often("twitchinfo_export()")
do_every_draw("show_metar_and_airport()")
