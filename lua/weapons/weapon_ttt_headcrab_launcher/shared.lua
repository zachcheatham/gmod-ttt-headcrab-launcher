
AddCSLuaFile()

SWEP.HoldType = "rpg"

if CLIENT then
	LANG.AddToLanguage("english", "headcrab_launcher_help", "Use Mouse 1 to launch a headcrab canister at where you're aiming.")

	SWEP.PrintName = "Headcrab Launcher"
	SWEP.Slot = 6

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "Causes a headcrab canister to rain down upon the inncoents.\n\nRequires the sky to be visible!"
	};

	SWEP.Icon = "vgui/ttt/icon_z_headcrab_launcher"
else
	resource.AddFile("materials/vgui/ttt/icon_z_headcrab_launcher.vmt")
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/v_rpg.mdl"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"

SWEP.DrawCrosshair = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = falsew
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo	= "none"

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

SWEP.NoSights = true

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 65

local yawIncrement = 20
local pitchIncrement = 10
local shootSoundFire = Sound("Airboat.FireGunHeavy")
local shootSoundFail = Sound("WallHealth.Deny")

-- Code for launch found at http://www.zombiemaster.org/smf/index.php?topic=12279.0
function SWEP:PrimaryAttack()
	if self:GetNWBool("Used", false) then return false end

	if not self:GetOwner():IsTraitor() then
		self:EmitSound(shootSoundFail)
		return
	end

	local tr = self.Owner:GetEyeTrace()
	local baseAngle = tr.HitNormal:Angle()
	local basePos = tr.HitPos
	local scanning = true
	local pitch = 10
	local yaw = -180
	local scanLimit = 0
	local processed = 0
	local validHits = {}

	-- Find a valid angle to spawn from
	while (scanning and scanLimit < 500) do
		yaw = yaw + yawIncrement
		processed = processed + 1

		if yaw >= 180 then
			yaw = -180
			pitch = pitch - pitchIncrement
		end

		local loopTr = util.QuickTrace(basePos, (baseAngle + Angle(pitch, yaw, 0)):Forward() * 40000)
		if loopTr.HitSky then
			table.insert(validHits, loopTr)
		end

		if pitch <= -80 then
			scanning = false
		end
		scanLimit = scanLimit + 1
	end

	-- Spawn the canister
	local hits = table.Count(validHits)
	if hits > 0 then
		self:SetNWBool("Used", true)
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

		if SERVER then
			self.Owner:SetAnimation(PLAYER_ATTACK1)
			local hit = validHits[math.random(1, hits)]

			local ent = ents.Create("env_headcrabcanister")
			ent:SetPos(basePos)
			ent:SetAngles((hit.HitPos - hit.StartPos):Angle())
			ent:SetKeyValue("HeadcrabType", math.random(0,2))
			ent:SetKeyValue("HeadcrabCount", math.random(4,10))
			ent:SetKeyValue("FlightSpeed", math.random(2500,6000))
            ent:SetKeyValue("FlightTime", math.random(2,5))
            ent:SetKeyValue("Damage", math.random(50,90))
            ent:SetKeyValue("DamageRadius", math.random(300,512))
            ent:SetKeyValue("SmokeLifetime", math.random(5,10))
            ent:SetKeyValue("StartingHeight",  1000)

            ent:Spawn()
            ent:Input("FireCanister", self.Owner, self.Owner)

            self:EmitSound(shootSoundFire)
		end
	else
		self:EmitSound(shootSoundFail)
	end
end

function SWEP:SecondaryAttack()
end

if CLIENT then
	function SWEP:Initialize()
		self:AddHUDHelp("headcrab_launcher_help", nil, true)

		return self.BaseClass.Initialize(self)
	end
end

