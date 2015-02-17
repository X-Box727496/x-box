local version = "1.27"

if myHero.charName ~= "Lucian" then return end
require 'VPrediction'

local ProdOneLoaded = false
local ProdFile = LIB_PATH .. "Prodiction.lua"
local fh = io.open(ProdFile, 'r')
if fh ~= nil then
  local line = fh:read()
  local Version = string.match(line, "%d+.%d+")
  if Version == nil or tonumber(Version) == nil then
    ProdOneLoaded = false
  elseif tonumber(Version) > 0.8 then
    ProdOneLoaded = true
  end
  if ProdOneLoaded then
    require 'Prodiction'
    print("<font color=\"#FF0000\">Prodiction 1.0 Loaded for DienoLucian, 1.0 option is usable</font>")
  else
    print("<font color=\"#FF0000\">Prodiction 1.0 not detected for DienoLucian, 1.0 is not usable (will cause errors if checked)</font>")
  end
else
  print("<font color=\"#FF0000\">No Prodiction.lua detected, using only VPRED</font>")
end


--Honda7
local AUTOUPDATE= true
local UPDATE_SCRIPT_NAME = "Lucian"
local UPDATE_NAME = "Lucian"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/Lucian.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>"..UPDATE_NAME..":</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH, "", 5)
	if ServerData then
		local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
		ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
		if ServerVersion then
			ServerVersion = tonumber(ServerVersion)
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end
--end Honda7

local Config = nil
local VP = VPrediction()
local SpellQ = {Speed = math.huge, Range = 500, Delay = 0.320, Width = 65, ExtendedRange = 1100}
local SpellW = {Speed = 1600, Range = 1000, Delay = 0.300, Width = 55}
local SpellR = {Range = 1400, Width = 110, Speed = 2800, Delay= 0}
local QReady, WReady, EReady, RReady = nil, nil, nil, nil
local RObject = nil
local REndPos = nil
local rendname = 'lucianrdisable'
local isBuffed = false
local LastSpellCast = 0
local isPressedR = false
local target = nil
local lastAttack = 0
local lastWindUpTime = 0
local lastAttackCD = 0
local animation_time = 0
local initDone = false
function OnLoad()
	DelayAction(checkOrbwalker,2)
	DelayAction(Menu,4)
	DelayAction(Init,4)
end

function Init()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100, DAMAGE_PHYSICAL)
	ts.name = "Ranged Main"
	Config:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 1100, myHero, MINION_SORT_MAXHEALTH_DEC)
    -- print('Dienofail Lucian ' .. tostring(version) .. ' loaded!')
    -- if _G.MMA_Loaded then
    -- 	print('MMA detected, using MMA compatibility')
    -- elseif _G.AutoCarry.Orbwalker then
    -- 	print('SAC detected, using SAC compatibility')
    -- end
    initDone = true
end

function checkOrbwalker()
    if _G.MMA_Loaded ~= nil and _G.MMA_Loaded then
        IsMMALoaded = true
        print('MMA detected')
    elseif _G.AutoCarry then
        IsSACLoaded = true
        print('SAC detected')
    elseif FileExist(LIB_PATH .."SOW.lua") then
        require "SOW"
        SOWi = SOW(VP)
        IsSowLoaded = true
        SOWi:RegisterAfterAttackCallback(AutoAttackReset)
        print('SOW loaded')
    else
        print('Please use SAC, MMA, or SOW for your orbwalker')
    end
end
function Menu()
	Config = scriptConfig("Lucian", "Lucian")
	Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
	Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
	Config:addSubMenu("Combo options", "ComboSub")
	Config:addSubMenu("Harass options", "HarassSub")
	Config:addSubMenu("Farm", "FarmSub")
	Config:addSubMenu("KS", "KS")
	Config:addSubMenu("Extra Config", "Extras")
	Config:addSubMenu("Draw", "Draw")

	--Combo
	Config.ComboSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("lockR", "Lock on R (not functional)", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("mManager", "Mana Slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
	--Harass
	Config.HarassSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, false)
	Config.HarassSub:addParam("mManager", "Mana Slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
	--Farm
	Config.FarmSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.FarmSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	--Draw
	Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	--Extras
	Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("ExtendE", "Extend E to mouse direction", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("ESlows", "E Slows", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("CheckQ", "Check Q Using Minions", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("AoEQ", "Check AoE Q", SCRIPT_PARAM_ONOFF, true)
	--Config.Extras:addParam("spellweavedelay", "Spell Wave Delay (S)", SCRIPT_PARAM_SLICE, 0.6, 0.2, 1.5, 0)
	Config.Extras:addParam("wcollision", "Collision on W", SCRIPT_PARAM_ONOFF, false)
	if ProdOneLoaded then
		Config.Extras:addParam("Prodiction", "Use Prodiction 1.0 instead of VPred", SCRIPT_PARAM_ONOFF, false)
	end
	--Permashow
	Config:permaShow("Combo")
	Config:permaShow("Farm")
	Config:permaShow("Harass")


    if IsSowLoaded then
        Config:addSubMenu("Orbwalker", "SOWiorb")
        SOWi:LoadToMenu(Config.SOWiorb)
    end
end

function IsMyManaLow()
    if myHero.mana < (myHero.maxMana * ( Config.ComboSub.mManager / 100)) then
        return true
    else
        return false
    end
end

function IsMyManaLowHarass()
    if myHero.mana < (myHero.maxMana * ( Config.HarassSub.mManager / 100)) then
        return true
    else
        return false
    end
end

--Credit Trees
function GetCustomTarget()
	ts:update()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
    return ts.target
end
--End Credit Trees

function OnTick()
	if initDone then
		Check()
		target = GetCustomTarget()
		Qtarget = ts.target
		if Config.Combo and Qtarget ~= nil then
			Combo(Qtarget)
		end

		if Config.Harass and Qtarget ~= nil then
			Harass(Qtarget)
		end

		if Config.Farm then
			Farm()
		end
	end
end

function OnWndMsg(msg,key)
	if key == string.byte("E") and msg == KEY_DOWN and EReady and Config.Extras.ExtendE then
		-- mark Q key is release
		if Config.Extras.Debug then
			print('E key override enabled')
		end
		CastE()
	end
end


function Combo(Target)
	if QReady and Config.ComboSub.useQ and not IsMyManaLow() and GetDistance(Target) > 500 + VP:GetHitBox(Target) then
		-- if Config.Extras.Debug then
		-- 	print('Cast Q called')
		-- end
		CastQ(Target)
	end

	if WReady and Config.ComboSub.useW and not IsMyManaLow() and GetDistance(Target) > 500 + VP:GetHitBox(Target) then
		CastW(Target)
	end

	if isPressedR and Config.ComboSub.lockR then
		--LockR(Target)
	end
end


function Harass(Target)
	if QReady and Config.HarassSub.useQ and not IsMyManaLowHarass() and GetDistance(Target) > 500 + VP:GetHitBox(Target) then
		CastQ(Target)
	end

	if WReady and Config.HarassSub.useW and not IsMyManaLowHarass() and GetDistance(Target) > 500 + VP:GetHitBox(Target)  then
		CastW(Target)
	end
end

function CastQ(Target)
	EnemyMinions:update()
		if Config.Extras.Debug then
			print('CastQ called')
		end
	-- print(CountEnemyNearPerson(Target,800))
	-- print(ValidTarget(Target, 1300))
	if ValidTarget(Target, 1300) and not Target.dead and GetDistance(Target) > 500 + VP:GetHitBox(Target) and GetDistance(Target) < SpellQ.ExtendedRange then
		local CastPosition = FindBestCastPosition(Target)
		if CastPosition ~= nil and GetDistance(CastPosition) < SpellQ.Range + 100 then
			CastSpell(_Q, CastPosition)
			if Config.Extras.Debug then
				print('CastQ casted')
			end
		end
		-- if Config.Extras.Debug then
		-- 	print('Returning CastQ2')
		-- end
	--elseif ValidTarget(Target, 1300) and not Target.dead and GetDistance(Target) < 500 + VP:GetHitBox(Target) and ShouldCast(Target) then
	elseif ValidTarget(Target, 1300) and not Target.dead and GetDistance(Target) < 500 + VP:GetHitBox(Target) then
		-- if Config.Extras.Debug then
		-- 	print('Returning CastQ1')
		-- end
		CastSpell(_Q, Target)
		if Config.Extras.Debug then
			print('CastQ casted')
		end
	end
end


function LockR(Target)
	if isPressedR then
		local _, _, TargetPos =  CombinedPredict(enemy, SpellR.Delay, SpellR.Width, SpellR.Range, SpellR.Speed, myHero, false)
		local UnitVector1 = Vector(myHero) + Vector(REndPos):perpendicular()*650
		local UnitVector2 = Vector(myHero) + Vector(REndPos):perpendicular2()*650
		local pointSegment1, pointLine1, isOnSegment = VectorPointProjectionOnLineSegment(Vector(myHero), Vector(UnitVector1), Vector(TargetPos))
		local pointSegment2, pointLine2, isOnSegment2 = VectorPointProjectionOnLineSegment(Vector(myHero), Vector(UnitVector1), Vector(TargetPos))
		local pointSegment13D = {x=pointSegment1.x, y= myHero.y, z=pointSegment1.y}
		local pointSegment23D = {x=pointSegment2.x, y= myHero.y, z=pointSegment2.y}
		if GetDistance(pointLine23D) >= GetDistance(pointLine13D) then
			OrbwalkToPosition(pointLine13D)
		else
			OrbwalkToPosition(pointLine23D)
		end
	else
		OrbwalkToPosition(nil)
	end
end
function CastE()
	if EReady then
		local CastPoint = Vector(myHero) + Vector(Vector(mousePos) - Vector(myHero)):normalized()*445
		CastSpell(_E, CastPoint.x, CastPoint.z)
	end
end

function CastW(Target)
	if WReady and Target ~= nil then
		local CastPoint, HitChance, pos = nil, nil, nil
		if not Config.Extras.wcollision then
			CastPoint, HitChance, pos =  VP:GetCircularCastPosition(Target, SpellW.Delay, SpellW.Width, SpellW.Range, SpellW.Speed, myHero, false)
		else
			CastPoint, HitChance, pos =  VP:GetCircularCastPosition(Target, SpellW.Delay, SpellW.Width, SpellW.Range, SpellW.Speed, myHero, true)
		end
		if CastPoint ~= nil and HitChance ~= nil and pos ~= nil then
			if GetDistance(CastPoint) < SpellW.Range and HitChance >= 1 then
				CastSpell(_W, CastPoint.x, CastPoint.z)
			end
		end
	end
end

function OnAnimation(unit, animation)
	if unit.isMe and animation:lower():find("attack") and target ~= nil then
		if Config.Extras.Debug then
			print(animation)
		end

		--[[
		if (Config.Combo or Config.Harass) and ((Config.ComboSub.useQ or Config.HarassSub.useQ) and QReady) and target.type == myHero.type and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target) + 25 and not IsMyManaLow() then
			DelayAction(function() CastQ(target) end, animation_time + 0.1)
			if Config.Extras.Debug then
				print('QChained')
			end
		elseif (Config.Combo or Config.Harass) and ((Config.ComboSub.useW or Config.HarassSub.useW) and WReady) and target.type == myHero.type and not QReady and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target) + 25 and not IsMyManaLow() then
			DelayAction(function() CastW(target) end, animation_time + 0.1)
			if Config.Extras.Debug then
				print('WChained')
			end
		end
		]]
		if Config.Combo then
			if (Config.ComboSub.useQ and QReady) and target.type == myHero.type and not isBuffed and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target) and not IsMyManaLow() then -- Q combo
				DelayAction(function() CastQ(target) end, animation_time + 0.05)
				if Config.Extras.Debug then
					print('QChainedCombo')
				end
			elseif (Config.ComboSub.useW and WReady) and target.type == myHero.type and not isBuffed and not QReady and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target)and not IsMyManaLow() then -- W combo
				DelayAction(function() CastW(target) end, animation_time + 0.05)
				if Config.Extras.Debug then
					print('WChainedCombo')
				end
			end
		elseif Config.Harass then
			if (Config.HarassSub.useQ and QReady) and target.type == myHero.type and not isBuffed  and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target) and not IsMyManaLowHarass() then -- Q Harass
				DelayAction(function() CastQ(target) end, animation_time + 0.05)
				if Config.Extras.Debug then
					print('QChainedHarass')
				end
			elseif (Config.HarassSub.useW and WReady) and target.type == myHero.type and not isBuffed  and not QReady and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target) and not IsMyManaLowHarass() then -- W Harass
				DelayAction(function() CastW(target) end, animation_time + 0.05)
				if Config.Extras.Debug then
					print('WChainedHarass')
				end
			end
		end
	end
end

function AutoAttackReset()
	if target ~= nil and IsSowLoaded then
		if Config.Combo then
			if (Config.ComboSub.useQ and QReady) and target.type == myHero.type and not isBuffed  and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target) and not IsMyManaLow() then -- Q combo
				CastQ(target)
				if Config.Extras.Debug then
					print('QChainedCombo')
				end
			elseif (Config.ComboSub.useW and WReady) and target.type == myHero.type and not isBuffed  and not QReady and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target) and not IsMyManaLow() then -- W combo
				CastW(target)
				if Config.Extras.Debug then
					print('WChainedCombo')
				end
			end
		elseif Config.Harass then
			if (Config.HarassSub.useQ and QReady) and target.type == myHero.type and not isBuffed  and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target) and not IsMyManaLowHarass() then -- Q Harass
				CastQ(target)
				if Config.Extras.Debug then
					print('QChainedHarass')
				end
			elseif (Config.HarassSub.useW and WReady) and target.type == myHero.type and not isBuffed  and not QReady and target ~= nil and GetDistance(target) < 500 + VP:GetHitBox(target)  and not IsMyManaLowHarass() then -- W Harass
				CastW(target)
				if Config.Extras.Debug then
					print('WChainedHarass')
				end
			end
		end
	end

end

function Farm()
	EnemyMinions:update()
	if Config.FarmSub.useQ then
		FarmQ()
	end
	if Config.FarmSub.useW then
		FarmW()
	end
end

function GetEnemiesHitByQ(startpos, endpos)
	if startpos ~= nil and endpos ~= nil then
		local count = 0
		local HitMainTarget = false
		local Enemies = GetEnemyHeroes()
		--print(endpos)
		local realendpos = Vector(myHero) + Vector(Vector(endpos)-Vector(myHero)):normalized()*SpellQ.ExtendedRange
		if Config.Extras.Debug then
			print('Printing realendpos')
			print(realendpos)
		end
		for idx, enemy in ipairs(Enemies) do
			if enemy ~= nil and ValidTarget(enemy, 1600) and not enemy.dead and GetDistance(enemy, startpos) < SpellQ.ExtendedRange then
				local throwaway, HitChance, PredictedPos = CombinedPredict(enemy, SpellQ.Delay, SpellQ.Width, SpellQ.ExtendedRange, SpellQ.Speed, myHero, false)
				local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(startpos), Vector(realendpos), Vector(PredictedPos))
				local pointSegment3D = {x=pointSegment.x, y=enemy.y, z=pointSegment.y}
				if isOnSegment and pointSegment3D ~= nil and GetDistance(pointSegment3D, PredictedPos) < VP:GetHitBox(enemy) + SpellQ.Width - 30 and HitChance >= 2 then
					count = count + 1
					if enemy.networkID == target.networkID then
						HitMainTarget = true
					end
				end
			end
		end
		if Config.Extras.Debug then
			print('Returning GetEnemiesByQ with ' .. tostring(count))
		end
		return count, HitMainTarget
	end
end

function FindBestCastPosition(Target)
	if QReady then
		if Config.Extras.Debug then
			print('FindBestCastPosition called')
		end

		if Config.Extras.Debug then
			print('EnemyMinions called ' .. tostring(#EnemyMinions.objects))
		end
		local Enemies = GetEnemyHeroes()
		local BestPosition = nil
		local BestHit = 0
		for idx, enemy in ipairs(Enemies) do
			if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellQ.Range then
				local position, hitchance = CombinedPos(enemy, SpellQ.Delay, math.huge, myHero, false)
				--print(position)
				local count, hitmain = GetEnemiesHitByQ(myHero, position)
				if hitmain and hitchance >= 1 then
					if count > BestHit then
						BestHit = count
						BestPosition = enemy
					end
				end
			end
		end
		if BestPosition ~= nil then
			return BestPosition
		end

		if #EnemyMinions.objects >= 1 then
			if Config.Extras.Debug then
				print('EnemyMinions called 2')
			end
			for i, minion in ipairs(EnemyMinions.objects) do
				if GetDistance(minion) < SpellQ.Range then
					local position, hitchance = CombinedPos(minion, SpellQ.Delay, math.huge, myHero, false)
					-- local waypoints = VP:GetCurrentWayPoints(minion)
					-- local MPos, CastPosition = #waypoints == 1 and Vector(minion.visionPos) or VP:CalculateTargetPosition(minion, SpellQ.Delay, SpellQ.Width, SpellQ.Speed, myHero, "line")
					local count, hitmain = GetEnemiesHitByQ(myHero, Vector(position))

					if Config.Extras.Debug then
						print('Minions iterating ' .. tostring(count))
					end
					if hitmain and hitchance >= 1 and count > BestHit then
						BestHit = count
						BestPosition = minion
					end
				end
			end
		end
		if BestPosition ~= nil then
			return BestPosition
		end
	end
end

--Credit AWA

function KillSteal()
	local Enemies = GetEnemyHeroes()
	for i, enemy in pairs(Enemies) do
	if getDmg("Q", enemy, myHero)  > enemy.health and  Config.KS.useQ and GetDistance(enemy) < SpellQ.Range then
			CastQ(enemy)
		end
	if getDmg("W", enemy, myHero)  > enemy.health and  Config.KS.useW and GetDistance(enemy) < SpellW.Range then
			CastW(enemy)
		end
	end
end



function Reset(Target)
	if GetDistance(Target) > 500 + VP:GetHitBox(Target) then
		return true
	elseif _G.MMA_Loaded and _G.MMA_NextAttackAvailability < 0.6 then
		return true
	elseif _G.AutoCarry and (_G.AutoCarry.shotFired or _G.AutoCarry.Orbwalker:IsAfterAttack()) then
		if Config.Extras.Debug then
			print('SAC shot fired')
		end
		return true
	else
		return false
	end
end

function OnDraw()
	if not initDone then return end
	if initDone and Config ~= nil and Config.Extras.Debug and Qtarget ~= nil then
		DrawText3D("Current IsPressedR status is " .. tostring(isPressedR), myHero.x+200, myHero.y, myHero.z+200, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current isBuffed status is " .. tostring(isBuffed), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current isReset status is " .. tostring(Reset(Qtarget)), myHero.x-100, myHero.y, myHero.z-100, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current ShouldCast status is " .. tostring(ShouldCast(Qtarget)), myHero.x-150, myHero.y, myHero.z-159, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current time since last cast is " .. tostring(animation_time), myHero.x-250, myHero.y, myHero.z-259, 25,  ARGB(255,255,0,0), true)
		DrawCircle3D(Qtarget.x, Qtarget.y, Qtarget.z, 150, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1,  ARGB(255, 0, 255, 255))
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.ExtendedRange, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawW then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellW.Range, 1,  ARGB(255, 0, 255, 255))
	end
end

function OnGainBuff(unit, buff)
	if not initDone then return end
	if unit.isMe and buff.name == 'lucianpassivebuff' then
		isBuffed = true
	end

	if unit.isMe and buff.name == 'LucianR' then
		isPressedR = true
	end

	-- if unit.isMe and (buff.type == 5 or buff.type == 10 or buff.type == 11) and EReady and Config.Extras.ESlows then
	-- 	CastE()
	-- end
end

function OnLoseBuff(unit, buff)
	if not initDone then return end
	if unit.isMe and buff.name == 'lucianpassivebuff' then
		isBuffed = false
	end

	if unit.isMe and buff.name == 'LucianR' then
		isPressedR = true
	end
end

function OrbwalkToPosition(position)
	if position ~= nil then
		if _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(position)
		elseif _G.MMA_Loaded then
			moveToCursor(position.x, position.z)
		end
	else
		if _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(nil)
		elseif _G.MMA_Loaded then
			moveToCursor()
		end
	end
end

function OnProcessSpell(unit, spell)
	if not initDone then return end
    if unit == myHero then
        if spell.name:lower():find("attack") then
            lastAttack = GetTickCount() - GetLatency()/2
            lastWindUpTime = spell.windUpTime*1000
            lastAttackCD = spell.animationTime*1000
            animation_time = spell.windUpTime

        end
    end
	if unit.isMe and spell.name == 'LucianQ' then
		LastSpellCast = GetTickCount()
	end

	if unit.isMe and spell.name == 'LucianW' then
		LastSpellCast = GetTickCount()
	end

	if unit.isMe and spell.name == 'LucianE' then
		LastSpellCast = GetTickCount()
	end

	if unit.isMe and spell.name == 'LucianR' then
		LastSpellCast = GetTickCount()
		RTempEndPos = {x=spell.endPos.x, y=myHero.y, z=spell.endPos.z}
		REndPos = Vector(Vector(RTempEndPos) - Vector(myHero)):normalized()
		isPressedR = true
	end
end

function ShouldCast(Target)
	if not isBuffed and Reset(Target) then
		return true
	else
		return false
	end
end


function Check()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	if not RReady then
		QEndPos = nil
		LastDistance = nil
		isPressedR = false
		RendPos = nil
	end
end


function GetBestQPositionFarm()
	local MaxQ = 0
	local MaxQPos
	for i, minion in pairs(EnemyMinions.objects) do
		if GetDistance(minion) < SpellQ.Range then
			local hitQ = countminionshitQ(minion)
			if hitQ > MaxQ or MaxQPos == nil then
				MaxQPos = minion
				MaxQ = hitQ
			end
		end
	end

	if MaxQPos then
		return MaxQPos
	else
		return nil
	end
end

function countminionshitQ(pos)
	local n = 0
	local ExtendedVector = Vector(myHero) + Vector(Vector(pos) - Vector(myHero)):normalized()*SpellQ.ExtendedRange
	for i, minion in ipairs(EnemyMinions.objects) do
		local MinionPointSegment, MinionPointLine, MinionIsOnSegment =  VectorPointProjectionOnLineSegment(Vector(myHero), Vector(ExtendedVector), Vector(minion))
		local MinionPointSegment3D = {x=MinionPointSegment.x, y=pos.y, z=MinionPointSegment.y}
		if MinionIsOnSegment and GetDistance(MinionPointSegment3D, pos) < SpellQ.Width + 30 then
			n = n +1
			-- if Config.Extras.Debug then
			-- 	print('count minions W returend ' .. tostring(n))
			-- end
		end
	end
	return n
end


function GetBestWPositionFarm()
	local MaxW = 0
	local MaxWPos
	for i, minion in pairs(EnemyMinions.objects) do
		local hitW = countminionshitW(minion)
		if hitW > MaxW or MaxWPos == nil then
			MaxWPos = minion
			MaxW = hitW
		end
	end

	if MaxWPos then
		return MaxWPos
	else
		return nil
	end
end



function countminionshitW(pos)
	local n = 0
	for i, minion in ipairs(EnemyMinions.objects) do
		if GetDistance(minion, pos) < SpellW.Width then
			n = n +1
		end
	end
	return n
end


function FarmW()
	if WReady and #EnemyMinions.objects > 0 then
		local WPos = GetBestWPositionFarm()
		if WPos then
			CastSpell(_W, WPos.x, WPos.z)
		end
	end
end

function FarmQ()
	if QReady and #EnemyMinions.objects > 0 then
		local QPos = GetBestQPositionFarm()
		if QPos then
			CastSpell(_Q, QPos)
		end
	end
end

--Credit Xetrok
function CountEnemyNearPerson(person,vrange)
    count = 0
    for i=1, heroManager.iCount do
        currentEnemy = heroManager:GetHero(i)
        if currentEnemy.team ~= myHero.team then
            if GetDistance(currentEnemy, person) <= vrange and not currentEnemy.dead then count = count + 1 end
        end
    end
    return count
end
--End Credit Xetrok

function CombinedPredict(Target, Delay, Width, Range, Speed, myHero, Collision)
  if Target == nil or Target.dead or not ValidTarget(Target) then return end
  if not ProdOneLoaded or not Config.Extras.Prodiction then
    local CastPosition, Hitchance, Position = VP:GetLineCastPosition(Target, Delay, Width, Range, Speed, myHero, false)
    if CastPosition ~= nil and Hitchance >= 1 then
      return CastPosition, Hitchance+1, Position
    end
  elseif ProdOneLoaded and Config.Extras.Prodiction then
    CastPosition, info = Prodiction.GetPrediction(Target, Range, Speed, Delay, Width, myHero)
    if info ~= nil and info.hitchance ~= nil and CastPosition ~= nil then
      Hitchance = info.hitchance
      return CastPosition, Hitchance, CastPosition
    end
  end
end


function CombinedPos(Target, Delay, Speed, myHero, Collision)
  if Target == nil or Target.dead or not ValidTarget(Target) then return end
  if Collision == nil then Collision = false end
    if not ProdOneLoaded or not Config.Extras.Prodiction then
      local PredictedPos, HitChance = VP:GetPredictedPos(Target, Delay, Speed, myHero, Collision)
      return PredictedPos, HitChance
    elseif ProdOneLoaded and Config.Extras.Prodiction then
      local PredictedPos, info = Prodiction.GetPrediction(Target, 20000, Speed, Delay, 1, myHero)
      if PredictedPos ~= nil and info ~= nil and info.hitchance ~= nil then
        return PredictedPos, info.hitchance
      end
    end
  end
