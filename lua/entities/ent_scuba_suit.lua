AddCSLuaFile()

ENT.Type        = "anim"
ENT.Base        = "base_anim"
ENT.PrintName   = "Scuba Suit"
ENT.Author      = "alagri"
ENT.Category    = "ZTrauma"
ENT.Spawnable   = true

local MODEL = "models/props_c17/suitcase001a.mdl"

if SERVER then
    function ENT:Initialize()
        self:SetModel(MODEL)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
    end

    local SUIT_MODEL = "models/player/charple.mdl"

    function ENT:Use(activator, caller)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if not activator:Alive() then return end
        if activator:GetNWBool("HasScubaSuit", false) then return end

        activator:SetNWBool("HasScubaSuit", true)
        self.EquippedBy     = activator
        self.StoredAppearance = table.Copy(activator.CurAppearance or {})
        self:SetNoDraw(true)
        self:SetSolid(SOLID_NONE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end

        hg.Appearance.ForceApplyAppearance(activator, {
            AModel       = SUIT_MODEL,
            AColor       = self.StoredAppearance.AColor or Color(255, 255, 255),
            AName        = self.StoredAppearance.AName  or activator:Nick(),
            AClothes     = {},
            AAttachments = {},
        })

        -- activator:ChatPrint("Scuba suit equipped.")
    end

    function ENT:Think()
        if IsValid(self.EquippedBy) then
            self:SetPos(self.EquippedBy:GetPos())
            self:NextThink(CurTime())
            return true
        elseif self.EquippedBy ~= nil then
            self.EquippedBy       = nil
            self.StoredAppearance = nil
            self:SetNoDraw(false)
            self:SetSolid(SOLID_VPHYSICS)
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
                phys:EnableMotion(true)
            end
        end
    end
end

if CLIENT then
    function ENT:Initialize()
        local key = string.upper(input.LookupBinding("+use") or "E")
        self.HudHintMarkup = markup.Parse(
            "<font=ZCity_Tiny>" .. self.PrintName .. "</font>\n" ..
            "<font=ZCity_SuperTiny><colour=125,125,125>" .. key .. " to wear</colour></font>",
            450
        )
    end

    function ENT:Draw()
        if self:GetNoDraw() then return end
        self:DrawModel()
    end
end
