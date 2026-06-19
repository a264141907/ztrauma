if SERVER then
    util.AddNetworkString("ZTrauma_RemoveSuit")

    local function StripSuit(ply, dropVel)
        ply:SetNWBool("HasScubaSuit", false)

        for _, ent in ipairs(ents.FindByClass("ent_scuba_suit")) do
            if ent.EquippedBy ~= ply then continue end

            if ent.StoredAppearance then
                hg.Appearance.ForceApplyAppearance(ply, ent.StoredAppearance)
                ent.StoredAppearance = nil
            end

            ent.EquippedBy = nil
            ent:SetNoDraw(false)
            ent:SetSolid(SOLID_VPHYSICS)
            ent:SetPos(ply:GetPos() + Vector(0, 0, 20))

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(true)
                phys:Wake()
                if dropVel then phys:SetVelocity(dropVel) end
            end
            return
        end

        local suit = ents.Create("ent_scuba_suit")
        if IsValid(suit) then
            suit:SetPos(ply:GetPos() + Vector(0, 0, 20))
            suit:Spawn()
        end
    end

    net.Receive("ZTrauma_RemoveSuit", function(len, ply)
        if not IsValid(ply) or not ply:Alive() then return end
        if not ply:GetNWBool("HasScubaSuit", false) then return end

        local throwVel = ply:GetForward() * 80
        StripSuit(ply, throwVel)
        -- ply:ChatPrint("Scuba suit removed.")
    end)

    local PRESSURE_LIMBS = { "rleg", "lleg", "rarm", "larm" }
    local PRESSURE_TIMES = { 6, 14, 25, 38 }

    hook.Add("Org Think", "ZTrauma_ScubaBreath", function(owner, org, timeValue)
        if not owner:GetNWBool("HasScubaSuit", false) then return end
        if not org.o2 then return end
        org.o2[1] = org.o2.range
    end)

    hook.Add("Think", "ZTrauma_UnderwaterThink", function()
        local t = CurTime()
        for _, ply in player.Iterator() do
            if not ply:Alive() then
                ply.ztrSubStart = nil
                continue
            end

            if ply:WaterLevel() < 3 then
                ply.ztrSubStart = nil
                continue
            end

            if ply:GetNWBool("HasScubaSuit", false) then continue end

            local org = ply.organism
            if not org then continue end

            ply.ztrSubStart = ply.ztrSubStart or t
            local elapsed = t - ply.ztrSubStart

            for i, limb in ipairs(PRESSURE_LIMBS) do
                if elapsed >= PRESSURE_TIMES[i] and org[limb .. "amputated"] == false then
                    hg.organism.AmputateLimb(org, limb)
                end
            end
        end
    end)

    hook.Add("HG_ReplacePhrase", "ZTrauma_ScubaMuffle", function(ply, phrase, muffed, pitch)
        if IsValid(ply) and ply:GetNWBool("HasScubaSuit", false) then
            return ply, phrase, true, pitch
        end
    end)

    hook.Add("PlayerDeath", "ZTrauma_DropSuit", function(ply)
        if not ply:GetNWBool("HasScubaSuit", false) then return end
        StripSuit(ply)
    end)

    hook.Add("ZB_EndRound", "ZTrauma_RoundEndStrip", function()
        for _, ply in player.Iterator() do
            if ply:GetNWBool("HasScubaSuit", false) then
                StripSuit(ply)
            end
        end
    end)
end

if CLIENT then
    local BREATH_SND = "breath_normal"

    local function StopBreathSound(ply)
        if ply.ztr_breathloop then
            ply:StopSound(BREATH_SND)
            ply.ztr_breathloop = nil
        end
    end

    hook.Add("Think", "ZTrauma_BreathSound", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local shouldPlay = ply:Alive()
            and ply:GetNWBool("HasScubaSuit", false)
            -- and ply:WaterLevel() >= 1

        if shouldPlay and not ply.ztr_breathloop then
            ply:StartLoopingSound(BREATH_SND)
            ply.ztr_breathloop = true
        elseif not shouldPlay then
            StopBreathSound(ply)
        end
    end)

    hook.Add("Player_Death", "ZTrauma_StopBreathOnDeath", function(ply)
        if ply == LocalPlayer() then
            StopBreathSound(ply)
        end
    end)

    hook.Add("radialOptions", "ZTrauma_ScubaSuitRemove", function()
        if not LocalPlayer():GetNWBool("HasScubaSuit", false) then return end

        hg.radialOptions[#hg.radialOptions + 1] = {
            function()
                net.Start("ZTrauma_RemoveSuit")
                net.SendToServer()
            end,
            "Remove Scuba Suit"
        }
    end)

    -- hook.Add("HUDPaint", "ZTrauma_UnderwaterHUD", function()
    --     local ply = LocalPlayer()
    --     if not IsValid(ply) or not ply:Alive() then return end
    --     if ply:WaterLevel() < 3 then return end
    --     if not ply:GetNWBool("HasScubaSuit", false) then return end

    --     local x = ScrW() / 2
    --     local y = ScrH() - 80
    --     draw.RoundedBox(6, x - 80, y - 15, 160, 30, Color(0, 70, 160, 210))
    --     draw.SimpleText(
    --         "SCUBA SUIT ACTIVE",
    --         "DermaDefault",
    --         x, y,
    --         Color(255, 255, 255, 255),
    --         TEXT_ALIGN_CENTER,
    --         TEXT_ALIGN_CENTER
    --     )
    -- end)
end
