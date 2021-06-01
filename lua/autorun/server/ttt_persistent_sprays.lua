if game.SinglePlayer() then
	return
end

local sprays, map

local function onspray(ent)
	local ply = ent:GetOwner()

	if not (
		IsValid(ply)
		and ply:IsPlayer()
	) then
		return
	end

	local id = ply:AccountID()

	if not id then
		return
	end

	local m = map or {}
	map = m

	local spr = m[id]

	if not spr then
		spr = {id = id}

		m[id] = spr

		local sprs = sprays or {[0] = 0}
		sprays = sprs

		sprs[0] = sprs[0] + 1
		sprs[sprs[0]] = spr
	end

	local td = {
		start = ent:GetPos(),
		endpos = ent:GetForward(),
		filter = ply,
		mask = MASK_SOLID_BRUSHONLY,
		collisiongroup = COLLISION_GROUP_NONE,
		ignoreworld = false,
	}

	td.endpos:Mul(128)
	td.endpos:Add(td.start)

	local tr = util.TraceLine(td)

	if not tr.Hit then
		return
	end

	local hx, hy, hz = tr.HitPos:Unpack()
	local nx, ny, nz = tr.HitNormal:Unpack()

	local s = 1 / 32 + 0.000001
	nx, ny, nz = nx * s, ny * s, nz * s

	spr.sx, spr.sy, spr.sz = hx + nx, hy + ny, hz + nz
	spr.ex, spr.ey, spr.ez = hx - nx, hy - ny, hz - nz

	spr.idx = ply:EntIndex()
end

hook.Add("EntityRemoved", "ttt_persistent_sprays", function(e)
	if e and e:IsValid() and e:GetClass() == "spraycan" then
		return onspray(e)
	end
end)

local function respray()
	local sprs = sprays

	if not sprs then
		return
	end

	local spos, epos

	local len = sprs[0]

	local i = 0

	::loop::

	i = i + 1

	if i > len then
		return
	end

	local s = sprs[i]

	if not s.idx then
		goto loop
	end

	local ply = Entity(s.idx)

	if not (
		IsValid(ply)
		and ply:IsPlayer()
		and ply:AccountID() == s.id
	) then
		s.idx = nil

		goto loop
	end

	if not spos then
		spos, epos = Vector(), Vector()
	end

	spos:SetUnpacked(s.sx, s.sy, s.sz)
	epos:SetUnpacked(s.ex, s.ey, s.ez)

	ply:SprayDecal(spos, epos)

	goto loop
end

hook.Add("PlayerAuthed", "ttt_persistent_sprays", function(ply)
	if sprays and map and IsValid(ply) then
		local id = ply:AccountID()

		if id then
			local spr = map[id]

			if spr then
				spr.idx = ply:EntIndex()
			end
		end
	end

	return respray()
end)

hook.Add("PostCleanupMap", "ttt_persistent_sprays", respray)
