if SERVER then
	return
end
--[[
lua_run_cl for k,v in SortedPairs(PPM)do if type(v)=="IMaterial" and v.SetFloat then v:SetFloat("$phongexponent",255)v:SetFloat("$phongboost",10)end end
lua_run for k,v in ipairs(PPM.m_bodydetails)do v[1]:SetFloat("$phongexponent",255)v[1]:SetFloat("$phongboost",10)end
lua_run_cl for k,v in SortedPairs(PPM)do if type(v)=="IMaterial" and v.SetFloat then v:SetFloat("$$alpha",.1)end end
$alpha
lua_run_cl for k,v in SortedPairs(PPM.m_wings:GetKeyValues())do if type(v)=="number"then print(k.."="..v)elseif type(v)=="Vector"then print(k.."=Vector("..v.x..","..v.y..","..v.z..")")end end
$alpha=1
$alphatestreference=0
$ambientonly=0
$basemapalphaphongmask=1
$blendtintbybasealpha=0
$blendtintcoloroverbase=0
$bumpframe=0
$cloakcolortint=Vector(1,1,1)
$cloakfactor=0
$cloakpassenabled=0
$depthblend=0
$depthblendscale=0
$detailblendfactor=1
$detailblendmode=0
$detailframe=0
$detailscale=4
$detailtint=Vector(1,1,1)
$emissiveblendenabled=0
$emissiveblendscrollvector=Vector(0,0,0)
$emissiveblendstrength=0
$emissiveblendtint=Vector(1,1,1)
$envmapcontrast=0
$envmapframe=0
$envmapfresnel=0
$envmapmaskframe=0
$envmapsaturation=0
$envmaptint=Vector(1,1,1)
$flags=2048
$flags2=262210
$flags_defined=2048
$flags_defined2=0
$flashlightnolambert=0
$flashlighttextureframe=0
$fleshbordernoisescale=0
$fleshbordersoftness=0
$fleshbordertint=Vector(1,1,1)
$fleshborderwidth=0
$fleshdebugforcefleshon=0
$flesheffectcenterradius1=Vector(0,0,0)
$flesheffectcenterradius2=Vector(0,0,0)
$flesheffectcenterradius3=Vector(0,0,0)
$flesheffectcenterradius4=Vector(0,0,0)
$fleshglobalopacity=0
$fleshglossbrightness=0
$fleshinteriorenabled=0
$fleshscrollspeed=0
$fleshsubsurfacetint=Vector(1,1,1)
$frame=0
$invertphongmask=0
$linearwrite=0
$phong=1
$phongalbedotint=1
$phongfresnelranges=Vector(0.21951973438263,1,1)
$phongtint=Vector(1,1,1)
$refractamount=0
$rimlight=1
$rimlightboost=1
$rimlightexponent=2
$rimmask=0
$selfillum_envmapmask_alpha=0
$selfillumfresnel=0
$selfillumfresnelminmaxexp=Vector(0,1,1)
$selfillumtint=Vector(1,1,1)
$separatedetailuvs=0
$srgbtint=Vector(1,1,1)
$time=0
--]]
if CreateConVar("ppm_limit_to_vanilla","0",{FCVAR_ARCHIVE},"if the client sets it to 1,socks and other custom textures will not be drawn by said client"):GetBool() then
	PPM_Render_Cap=13
else
	PPM_Render_Cap=math.huge
end
cvars.AddChangeCallback("ppm_limit_to_vanilla",function(var,old,new)
	if new!="0" then
		PPM_Render_Cap=13
	else
		PPM_Render_Cap=math.huge
	end
end,"ppm_limit_to_vanilla")
function PPM.TextureIsOutdated(ent,name,newhash)
	if not PPM.isValidPony(ent) then return true end
	if!ent.ponydata_tex then return true end
	if!ent.ponydata_tex[name]then return true end
	if!ent.ponydata_tex[name.."_hash"]then return true end
	if ent.ponydata_tex[name.."_hash"]!=newhash then return true end
	return false
end
function PPM.GetBodyHash(ponydata)
	local hash=tostring(ponydata.bodyt0)..tostring(ponydata.bodyt1)..ponydata.coatcolor.x..ponydata.coatcolor.y..ponydata.coatcolor.z..tostring(ponydata.bodyt1_color)
	return hash
end
function FixVertexLitMaterial(Mat)
	local strImage=Mat:GetName()
	if Mat:GetShader():find"VertexLitGeneric" or Mat:GetShader():find"Cable" then
		local t=Mat:GetString("$basetexture")
		if t then
			local params={}
			params["$basetexture"]=t
			params["$vertexcolor"]=1
			params["$vertexalpha"]=1
			Mat=CreateMaterial(strImage.."_DImage","UnlitGeneric",params)
		end
	end
	return Mat
end
function PPM.CreateTexture(tname,data)
	local w,h=ScrW(),ScrH()
	local rttex=nil
	local size=data.size or 512
	rttex=GetRenderTarget(tname,size,size,false)
	if data.predrawfunc then
		data.predrawfunc()
	end
	local OldRT=render.GetRenderTarget()
	render.SetRenderTarget(rttex)
	render.SuppressEngineLighting(true)
	cam.IgnoreZ(true)
	render.SetBlend(1)
	render.SetViewPort(0,0,size,size)
	render.Clear(0,0,0,255,true)
	cam.Start2D()
	render.SetColorModulation(1,1,1)
	if data.drawfunc then
		data.drawfunc()
	end
	cam.End2D()
	render.SetRenderTarget(OldRT)
	render.SetViewPort(0,0,w,h)
	render.SetColorModulation(1,1,1)
	render.SetBlend(1)
	render.SuppressEngineLighting(false)
	cam.IgnoreZ(false)
	return rttex
end
function PPM.CreateBodyTexture(ent,pony)
	if not PPM.isValidPony(ent) then return end
	local w,h=ScrW(),ScrH()
	local function tW(val)
		return val
	end--val/512*w end
	local function tH(val)
		return val
	end--val/512*h end
	local rttex=nil
	ent.ponydata_tex=ent.ponydata_tex or {}
	if ent.ponydata_tex.bodytex then
		rttex=ent.ponydata_tex.bodytex
	else
		rttex=GetRenderTarget(tostring(ent):Replace(".","//point//").."body",tW(512),tH(512),false)
	end
	local OldRT=render.GetRenderTarget()
	render.SetRenderTarget(rttex)
	render.SuppressEngineLighting(true)
	cam.IgnoreZ(true)
	render.SetLightingOrigin(Vector(0,0,0))
	render.ResetModelLighting(1,1,1)
	render.SetColorModulation(1,1,1)
	render.SetBlend(1)
	render.SetModelLighting(BOX_TOP,1,1,1)
	render.SetViewPort(0,0,tW(512),tH(512))
	render.Clear(0,255,255,255,true)
	cam.Start2D()
	render.SetColorModulation(1,1,1)
	if (pony.gender==1) then
		render.SetMaterial(FixVertexLitMaterial(Material("models/ppm/base/render/bodyf")))
	else
		render.SetMaterial(FixVertexLitMaterial(Material("models/ppm/base/render/bodym")))
	end
	render.DrawQuadEasy(Vector(tW(256),tH(256),0),Vector(0,0,-1),tW(512),tH(512),Color(pony.coatcolor.x*255,pony.coatcolor.y*255,pony.coatcolor.z*255,255),-90)--position of the rect
	--direction to face in
	--size of the rect
	--color
	--rotate 90 degrees
	if (pony.bodyt1 > 1) then
		render.SetMaterial(FixVertexLitMaterial(PPM.m_bodydetails[pony.bodyt1-1][1]))
		render.SetBlend(1)
		local colorbl=pony.bodyt1_color or Vector(1,1,1)
		render.DrawQuadEasy(Vector(tW(256),tH(256),0),Vector(0,0,-1),tW(512),tH(512),Color(colorbl.x*255,colorbl.y*255,colorbl.z*255,255),-90)--position of the rect
		--direction to face in
		--size of the rect
		--color
		--rotate 90 degrees
	end
	if (pony.bodyt0 > 1) then
		render.SetMaterial(FixVertexLitMaterial(PPM.m_bodyt0[pony.bodyt0-1][1]))
		render.SetBlend(1)
		render.DrawQuadEasy(Vector(tW(256),tH(256),0),Vector(0,0,-1),tW(512),tH(512),Color(255,255,255,255),-90)--position of the rect
		--direction to face in
		--size of the rect
		--color
		--rotate 90 degrees
	end
	cam.End2D()
	render.SetRenderTarget(OldRT)--Resets the RenderTarget to our screen
	render.SetViewPort(0,0,w,h)
	render.SetColorModulation(1,1,1)
	render.SetBlend(1)
	render.SuppressEngineLighting(false)
	cam.IgnoreZ(false)
	ent.ponydata_tex.bodytex=rttex
	--MsgN("HASHOLD: "..tostring(ent.ponydata_tex.bodytex_hash)) 
	ent.ponydata_tex.bodytex_hash=PPM.GetBodyHash(pony)
	--MsgN("HASHNEW: "..tostring(ent.ponydata_tex.bodytex_hash)) 
	--MsgN("HASHTAR: "..tostring(PPM.GetBodyHash(outpony))) 
	return rttex
end
hook.Add("HUDPaint","pony_render_textures",function()
	for index,ent in ipairs(PPM.Ents) do
		if !ent:IsValid() then continue end
		if PPM.VALIDPONY_CLASSES[ent:GetClass()]then
			if PPM.isValidPonyLight(ent) then
				local pony=PPM.getPonyValues(ent,false)
				if (not PPM.isValidPony(ent)) then
					PPM.setupPony(ent)
				end
				local texturespreframe=1
				for k,v in pairs(PPM.rendertargettasks) do
					if texturespreframe > 0 and PPM.TextureIsOutdated(ent,k,v.hash(pony)) then
						ent.ponydata_tex=ent.ponydata_tex or {}
						PPM.currt_ent=ent
						PPM.currt_ponydata=pony
						PPM.currt_success=false
						ent.ponydata_tex[k]=PPM.CreateTexture(tostring(ent):Replace(".","//point//")..k,v)
						ent.ponydata_tex[k.."_hash"]=v.hash(pony)
						ent.ponydata_tex[k.."_draw"]=PPM.currt_success
						texturespreframe=texturespreframe-1
					end
				end
			end
			--MsgN("Outdated texture at "..tostring(ent):Replace(".","//point//")..tostring(ent:GetClass()))
		elseif ent.isEditorPony or PPM.VALIDPONY_CLASSES[ent:GetClass()]==false or ent.ISPONYNEXTBOT then
			local pony=PPM.getPonyValues(ent,true)
			if !pony then
				PPM.setupPony(ent)
				return
			end
			for k,v in pairs(PPM.rendertargettasks) do
				if PPM.TextureIsOutdated(ent,k,v.hash(pony)) then
					ent.ponydata_tex=ent.ponydata_tex or {}
					PPM.currt_ent=ent
					PPM.currt_ponydata=pony
					PPM.currt_success=false
					ent.ponydata_tex[k]=PPM.CreateTexture(tostring(ent):Replace(".","//point//")..k,v)
					ent.ponydata_tex[k.."_hash"]=v.hash(pony)
					ent.ponydata_tex[k.."_draw"]=PPM.currt_success
				end
			end
		end
	end
end)
local INRANGE=function(check,of)
	if of-5<=check and check<=of+5 then
		return true
	end
	return false
end
PPM.loadrt=function()end
PPM.currt_success=false
PPM.currt_ent=nil
PPM.currt_ponydata=nil
PPM.rendertargettasks={
	bodytex={
		renderTrue=function(ENT,PONY)
			PPM.m_body:SetVector("$color2",Vector(1,1,1))
			PPM.m_body:SetTexture("$basetexture",ENT.ponydata_tex.bodytex)
		end,
		renderFalse=function(ENT,PONY)
			PPM.m_body:SetVector("$color2",PONY.coatcolor)--[ [
			PPM.m_body:SetFloat("$phongexponent",PONY.coatphongexponent)
			PPM.m_body:SetFloat("$phongboost",PONY.coatphongboost)--]]
			if (PONY.gender==1) then
				PPM.m_body:SetTexture("$basetexture",PPM.m_bodyf:GetTexture("$basetexture"))
			else
				PPM.m_body:SetTexture("$basetexture",PPM.m_bodym:GetTexture("$basetexture"))
			end
		end,
		drawfunc=function()
			local pony=PPM.currt_ponydata
			local bodydetails=PPM.m_bodydetails
			if (pony.gender==1) then
				render.SetMaterial(FixVertexLitMaterial(Material("models/ppm/base/render/bodyf")))
				bodydetails=PPM.f_bodydetails or bodydetails
			else
				render.SetMaterial(FixVertexLitMaterial(Material("models/ppm/base/render/bodym")))
			end
			render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),512,512,Color(pony.coatcolor.x*255,pony.coatcolor.y*255,pony.coatcolor.z*255,255),-90)--position of the rect
			--direction to face in
			--size of the rect
			--color
			--rotate 90 degrees
			--MsgN("render.body.prep")
			for C=1,12 do
				local detailvalue=(pony["bodydetail"..C]or 1)-1
				local detailcolor=pony["bodydetail"..C.."_c"]or Vector(0,0,0)
				if detailvalue<PPM_Render_Cap and detailvalue>1 and bodydetails[detailvalue]and bodydetails[detailvalue][1]then
					--MsgN("rendering tex id: ",detailvalue," col: ",detailcolor)
					local mat=bodydetails[detailvalue][1]
					--PPM.m_body:SetFloat("$phong",1)
					--PPM.m_body:SetFloat("$basemapalphaphongmask",1)
					render.SetMaterial(mat)--Material("models/ppm/base/render/clothes_sbs_full")) 
					--surface.SetTexture(surface.GetTextureID("models/ppm/base/render/horn"))
					render.SetBlend(1)
					render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),512,512,Color(detailcolor.x*255,detailcolor.y*255,detailcolor.z*255,255),-90)--position of the rect
					--direction to face in
					--size of the rect
					--color
					--rotate 90 degrees
				end
			end
			local pbt=pony.bodyt0 or 1
			if (pbt > 1) then
				local mmm=PPM.m_bodyt0[pbt-1]
				if (mmm ~=nil) then
					render.SetMaterial(FixVertexLitMaterial(mmm))--Material("models/ppm/base/render/clothes_sbs_full")) 
					--surface.SetTexture(surface.GetTextureID("models/ppm/base/render/horn"))
					render.SetBlend(1)
					render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),512,512,Color(255,255,255,255),-90)--position of the rect
					--direction to face in
					--size of the rect
					--color
					--rotate 90 degrees
				end
			end
			PPM.currt_success=true
		end,
		hash=function(ponydata)
			local hash=ponydata.coatphongexponent..ponydata.coatphongboost..tostring(ponydata.bodyt0)..ponydata.coatcolor.x..ponydata.coatcolor.y..ponydata.coatcolor.z..ponydata.gender
			for C=1,12 do
				local detailvalue=ponydata["bodydetail"..C]or 1
				local detailcolor=ponydata["bodydetail"..C.."_c"]or Vector(0,0,0)
				hash=hash..detailvalue..detailcolor.x..detailcolor.y..detailcolor.z
			end
			return hash
		end,
	},
	hairtex1={--upper mane
		renderTrue=function(ENT,PONY)
	--			print"Hairtex1.renderTrue"
			PPM.m_hair1:SetVector("$color2",Vector(1,1,1))
			--PPM.m_hair2:SetVector("$color2",Vector(1,1,1)) 
			PPM.m_hair1:SetTexture("$basetexture",ENT.ponydata_tex.hairtex1)
		end,
		renderFalse=function(ENT,PONY)
			PPM.m_hair1:SetVector("$color2",PONY.haircolor1)
			PPM.m_hair1:SetFloat("$phongexponent",PONY.hairphongexponent)
			PPM.m_hair1:SetFloat("$phongboost",PONY.hairphongboost)
			--PPM.m_hair2:SetVector("$color2",PONY.haircolor2) 
			PPM.m_hair1:SetTexture("$basetexture",Material("models/ppm/partrender/clean.png"):GetTexture("$basetexture"))
		end,
		--PPM.m_hair2:SetTexture("$basetexture",Material("models/ppm/partrender/clean.png"):GetTexture("$basetexture")) 
		drawfunc=function()
			local pony=PPM.currt_ponydata
			render.Clear(pony.haircolor1.x*255,pony.haircolor1.y*255,pony.haircolor1.z*255,255,true)
			PPM.tex_drawhairfunc(pony,"up",false)
		end,
		hash=function(ponydata)
			local hash=ponydata.hairphongexponent..ponydata.hairphongboost
			..ponydata.haircolor1.x..ponydata.haircolor1.y..ponydata.haircolor1.z
			..ponydata.haircolor2.x..ponydata.haircolor2.y..ponydata.haircolor2.z
			..ponydata.haircolor3.x..ponydata.haircolor3.y..ponydata.haircolor3.z
			..ponydata.haircolor4.x..ponydata.haircolor4.y..ponydata.haircolor4.z
			..ponydata.haircolor5.x..ponydata.haircolor5.y..ponydata.haircolor5.z
			..ponydata.haircolor6.x..ponydata.haircolor6.y..ponydata.haircolor6.z
			..ponydata.manecolor1.x..ponydata.manecolor1.y..ponydata.manecolor1.z
			..ponydata.manecolor2.x..ponydata.manecolor2.y..ponydata.manecolor2.z
			..ponydata.manecolor3.x..ponydata.manecolor3.y..ponydata.manecolor3.z
			..ponydata.manecolor4.x..ponydata.manecolor4.y..ponydata.manecolor4.z
			..ponydata.manecolor5.x..ponydata.manecolor5.y..ponydata.manecolor5.z
			..ponydata.manecolor6.x..ponydata.manecolor6.y..ponydata.manecolor6.z
			..ponydata.tailcolor1.x..ponydata.tailcolor1.y..ponydata.tailcolor1.z
			..ponydata.tailcolor2.x..ponydata.tailcolor2.y..ponydata.tailcolor2.z
			..ponydata.tailcolor3.x..ponydata.tailcolor3.y..ponydata.tailcolor3.z
			..ponydata.tailcolor4.x..ponydata.tailcolor4.y..ponydata.tailcolor4.z
			..ponydata.tailcolor5.x..ponydata.tailcolor5.y..ponydata.tailcolor5.z
			..ponydata.tailcolor6.x..ponydata.tailcolor6.y..ponydata.tailcolor6.z
			..ponydata.mane
			return hash
		end,
	},
	hairtex2={--lower mane
		renderTrue=function(ENT,PONY)
			--PPM.m_hair1:SetVector("$color2",Vector(1,1,1))
			PPM.m_hair2:SetVector("$color2",Vector(1,1,1))
			PPM.m_hair2:SetTexture("$basetexture",ENT.ponydata_tex.hairtex2)
		end,
		renderFalse=function(ENT,PONY)
	--			print"Hairtex2.renderFalse"
			--PPM.m_hair1:SetVector("$color2",PONY.haircolor1) 
			PPM.m_hair2:SetVector("$color2",PONY.manecolor1)
			PPM.m_hair2:SetFloat("$phongexponent",PONY.manephongexponent)
			PPM.m_hair2:SetFloat("$phongboost",PONY.manephongboost)
			--PPM.m_hair1:SetTexture("$basetexture",Material("models/ppm/partrender/clean.png"):GetTexture("$basetexture")) 
			PPM.m_hair2:SetTexture("$basetexture",Material("models/ppm/partrender/clean.png"):GetTexture("$basetexture"))
		end,
		drawfunc=function()
			local pony=PPM.currt_ponydata
			PPM.tex_drawhairfunc(pony,"dn",false)
		end,
		hash=function(ponydata)
			local hash=ponydata.manephongexponent..ponydata.manephongboost
			..ponydata.haircolor1.x..ponydata.haircolor1.y..ponydata.haircolor1.z
			..ponydata.haircolor2.x..ponydata.haircolor2.y..ponydata.haircolor2.z
			..ponydata.haircolor3.x..ponydata.haircolor3.y..ponydata.haircolor3.z
			..ponydata.haircolor4.x..ponydata.haircolor4.y..ponydata.haircolor4.z
			..ponydata.haircolor5.x..ponydata.haircolor5.y..ponydata.haircolor5.z
			..ponydata.haircolor6.x..ponydata.haircolor6.y..ponydata.haircolor6.z
			..ponydata.manecolor1.x..ponydata.manecolor1.y..ponydata.manecolor1.z
			..ponydata.manecolor2.x..ponydata.manecolor2.y..ponydata.manecolor2.z
			..ponydata.manecolor3.x..ponydata.manecolor3.y..ponydata.manecolor3.z
			..ponydata.manecolor4.x..ponydata.manecolor4.y..ponydata.manecolor4.z
			..ponydata.manecolor5.x..ponydata.manecolor5.y..ponydata.manecolor5.z
			..ponydata.manecolor6.x..ponydata.manecolor6.y..ponydata.manecolor6.z
			..ponydata.tailcolor1.x..ponydata.tailcolor1.y..ponydata.tailcolor1.z
			..ponydata.tailcolor2.x..ponydata.tailcolor2.y..ponydata.tailcolor2.z
			..ponydata.tailcolor3.x..ponydata.tailcolor3.y..ponydata.tailcolor3.z
			..ponydata.tailcolor4.x..ponydata.tailcolor4.y..ponydata.tailcolor4.z
			..ponydata.tailcolor5.x..ponydata.tailcolor5.y..ponydata.tailcolor5.z
			..ponydata.tailcolor6.x..ponydata.tailcolor6.y..ponydata.tailcolor6.z
			..ponydata.manel
			return hash
		end,
	},
	tailtex={--the tail
		renderTrue=function(ENT,PONY)
			PPM.m_tail1:SetVector("$color2",Vector(1,1,1))
			PPM.m_tail2:SetVector("$color2",Vector(1,1,1))
			PPM.m_tail1:SetTexture("$basetexture",ENT.ponydata_tex.tailtex)
		end,
		renderFalse=function(ENT,PONY)
			PPM.m_tail1:SetVector("$color2",PONY.tailcolor1)
			PPM.m_tail2:SetVector("$color2",PONY.tailcolor2)
			PPM.m_tail1:SetFloat("$phongexponent",PONY.tailphongexponent)
			PPM.m_tail1:SetFloat("$phongboost",PONY.tailphongboost)
			PPM.m_tail1:SetTexture("$basetexture",Material("models/ppm/partrender/clean.png"):GetTexture("$basetexture"))
			PPM.m_tail2:SetTexture("$basetexture",Material("models/ppm/partrender/clean.png"):GetTexture("$basetexture"))
		end,
		drawfunc=function()
			local pony=PPM.currt_ponydata
			PPM.tex_drawhairfunc(pony,"up",true)
		end,
		hash=function(ponydata)
			local hash=ponydata.tailphongexponent..ponydata.tailphongboost
			..ponydata.haircolor1.x..ponydata.haircolor1.y..ponydata.haircolor1.z
			..ponydata.haircolor2.x..ponydata.haircolor2.y..ponydata.haircolor2.z
			..ponydata.haircolor3.x..ponydata.haircolor3.y..ponydata.haircolor3.z
			..ponydata.haircolor4.x..ponydata.haircolor4.y..ponydata.haircolor4.z
			..ponydata.haircolor5.x..ponydata.haircolor5.y..ponydata.haircolor5.z
			..ponydata.haircolor6.x..ponydata.haircolor6.y..ponydata.haircolor6.z
			..ponydata.manecolor1.x..ponydata.manecolor1.y..ponydata.manecolor1.z
			..ponydata.manecolor2.x..ponydata.manecolor2.y..ponydata.manecolor2.z
			..ponydata.manecolor3.x..ponydata.manecolor3.y..ponydata.manecolor3.z
			..ponydata.manecolor4.x..ponydata.manecolor4.y..ponydata.manecolor4.z
			..ponydata.manecolor5.x..ponydata.manecolor5.y..ponydata.manecolor5.z
			..ponydata.manecolor6.x..ponydata.manecolor6.y..ponydata.manecolor6.z
			..ponydata.tailcolor1.x..ponydata.tailcolor1.y..ponydata.tailcolor1.z
			..ponydata.tailcolor2.x..ponydata.tailcolor2.y..ponydata.tailcolor2.z
			..ponydata.tailcolor3.x..ponydata.tailcolor3.y..ponydata.tailcolor3.z
			..ponydata.tailcolor4.x..ponydata.tailcolor4.y..ponydata.tailcolor4.z
			..ponydata.tailcolor5.x..ponydata.tailcolor5.y..ponydata.tailcolor5.z
			..ponydata.tailcolor6.x..ponydata.tailcolor6.y..ponydata.tailcolor6.z
			..ponydata.tail
			return hash
		end,
	},
	eyeltex={--left eye
		renderTrue=function(ENT,PONY)
			PPM.m_eyel:SetTexture("$Iris",ENT.ponydata_tex.eyeltex)
		end,
		renderFalse=function(ENT,PONY)
			PPM.m_eyel:SetTexture("$Iris",Material("models/ppm/partrender/clean.png"):GetTexture("$basetexture"))
		end,
		drawfunc=function()
			local pony=PPM.currt_ponydata
			PPM.tex_draweyefunc(pony,false)
		end,
		hash=function(ponydata) 
			local hash=tostring(ponydata.modelscale)
			..tostring(ponydata.eye_effect_alpha)
			..tostring(ponydata.eye_effect_color)
			..tostring(ponydata.eye_reflect_alpha)
			..tostring(ponydata.eye_reflect_color)
			..tostring(ponydata.eye_reflect_type)
			..tostring(ponydata.eye_type)
			..tostring(ponydata.eyecolor_bg)
			..tostring(ponydata.eyecolor_grad)
			..tostring(ponydata.eyecolor_hole)
			..tostring(ponydata.eyecolor_iris)
			..tostring(ponydata.eyecolor_line1)
			..tostring(ponydata.eyecolor_line2)
			..tostring(ponydata.eyehaslines)
			..tostring(ponydata.eyeholesize)
			..tostring(ponydata.eyeirissize)
			..tostring(ponydata.eyejholerssize)
			return hash
		end,
	},
	eyertex={--right eye
		renderTrue=function(ENT,PONY)
			PPM.m_eyer:SetTexture("$Iris",ENT.ponydata_tex.eyertex)
		end,
		renderFalse=function(ENT,PONY)
			PPM.m_eyer:SetTexture("$Iris",Material("models/ppm/partrender/clean.png"):GetTexture("$basetexture"))
		end,
		drawfunc=function()
			local pony=PPM.currt_ponydata
			PPM.tex_draweyefunc(pony,true)
		end,
		hash=function(ponydata) 
			local hash=tostring(ponydata.modelscale)
			..tostring(ponydata.eye_effect_alpha_r)
			..tostring(ponydata.eye_effect_color_r)
			..tostring(ponydata.eye_reflect_alpha_r)
			..tostring(ponydata.eye_reflect_color_r)
			..tostring(ponydata.eye_reflect_type_r)
			..tostring(ponydata.eye_type_r)
			..tostring(ponydata.eyecolor_bg_r)
			..tostring(ponydata.eyecolor_grad_r)
			..tostring(ponydata.eyecolor_hole_r)
			..tostring(ponydata.eyecolor_iris_r)
			..tostring(ponydata.eyecolor_line1_r)
			..tostring(ponydata.eyecolor_line2_r)
			..tostring(ponydata.eyehaslines_r)
			..tostring(ponydata.eyeholesize_r)
			..tostring(ponydata.eyeirissize_r)
			..tostring(ponydata.eyejholerssize_r)
			return hash
		end,
	},
	ccmarktex={
		renderTrue=function(ENT,PONY)
			PPM.m_cmark:SetTexture("$basetexture",ENT.ponydata_tex.ccmarktex)
		end,
		renderFalse=function(ENT,PONY)
			--PPM.m_cmark:SetTexture("$basetexture",Material("models/mlp/partrender/clean.png"):GetTexture("$basetexture")) 
			if!PONY then
				if!ENT.PPM_cmark_error_code then
					print(tostring(ENT)..": CMark error code 1")
					ENT.PPM_cmark_error_code=true
				end
			elseif!PONY.cmark then
				if!ENT.PPM_cmark_error_code then
					print(tostring(ENT)..": CMark error code 2")
					ENT.PPM_cmark_error_code=true
				end
			elseif!PPM.m_cmarks[PONY.cmark]then
				if!ENT.PPM_cmark_error_code then
					print(tostring(ENT)..": CMark error code 3")
					ENT.PPM_cmark_error_code=true
				end
			elseif!PPM.m_cmarks[PONY.cmark][2]then
				if!ENT.PPM_cmark_error_code then
					print(tostring(ENT)..": CMark error code 4")
					ENT.PPM_cmark_error_code=true
				end
			elseif!PPM.m_cmarks[PONY.cmark][2]:GetTexture"$basetexture"then
				if!ENT.PPM_cmark_error_code then
					print(tostring(ENT)..": CMark error code 5")
					ENT.PPM_cmark_error_code=true
				end
			else 
				PPM.m_cmark:SetTexture("$basetexture",PPM.m_cmarks[PONY.cmark][2]:GetTexture"$basetexture")
				ENT.PPM_cmark_error_code=nil
			end
		end,
		drawfunc=function()
			local pony=PPM.currt_ponydata
			local R,G,B=0,0,0
			if pony.coatcolor then
				local col=pony.coatcolor*255
				R,G,B=col.x or 0,col.y or 0,col.z or 0
			end
			--print("LOAD STATUS CHANGED!")
			if (pony._cmark_loaded and pony._cmark~=nil) then
				render.Clear(255,255,255,255)
				print("DATA HAS BEEN LOADED...RENDERING!")
				local material=Material("gui/pixel.png")
				--render.SetMaterial(material) 
				render.SetColorMaterialIgnoreZ()
				render.SetBlend(1)
				local data=pony._cmark
				for x=0,256 do
					--local xsub=string.sub(data,x*256*3,x*256*3+256*3)
					for y=0,256 do
						local postition=(x*257+y)*3
						--local ysub=string.sub(xsub,y*3,y*3+3)
						local r=pony._cmark:sub(postition,postition):byte() or 1
						local g=pony._cmark:sub(postition+1,postition+1):byte() or 1
						local b=pony._cmark:sub(postition+2,postition+2):byte() or 0
						--print(r)
						if x<45 or x>250 or y<5 or y>250--out of bounds
						or INRANGE(r,R)and INRANGE(g,G)and INRANGE(b,B)then--close to coat color
							--[[
						render.DrawQuadEasy(Vector(x*2+1,y*2+1,0),	--position of the rect
							Vector(0,0,-1),		--direction to face in
							2,2,			--size of the rect
							Color(0,0,0,0),--color
							-90					--rotate 90 degrees
							)  
						]]
							render.SetScissorRect(x*2,y*2,x*2+2,y*2+2,true)
							render.Clear(0,0,0,0)
							--position of the rect
							--direction to face in
							--size of the rect
							--color
							--rotate 90 degrees
						else
							render.SetScissorRect(x*2,y*2,x*2+2,y*2+2,false)
							render.DrawQuadEasy(Vector(x*2+1,y*2+1,0),Vector(0,0,-1),2,2,Color(r,g,b,255),-90)
						end
					end
				end
				PPM.currt_success=true
				print("cleaned_Surface_")
			else
				render.Clear(0,0,0,0)
				PPM.currt_success=false
			end
		end,
		hash=function(ponydata)return tostring(ponydata._cmark_loaded)end,
	},
}
PPM.tex_drawhairfunc=function(pony,UPDN,TAIL)
	local hairnum=pony.mane
	local PREFIX="hair"
	if UPDN=="dn" then
		hairnum=pony.manel
		PREFIX="mane"
	elseif TAIL then
		hairnum=pony.tail
		PREFIX="tail"
	end
	PPM.hairrenderOp(UPDN,TAIL,hairnum)
	local colorcount=PPM.manerender[UPDN..hairnum]
	if TAIL then
		colorcount=PPM.manerender["tl"..hairnum]
	end
	if colorcount ~=nil then
		local coloroffcet=colorcount[1]
		if UPDN=="up" then--hair on top
			coloroffcet=0
		end
		local prephrase=UPDN.."mane_"
		if TAIL then--drawing the tail
			prephrase="tail_"
		end
		colorcount=colorcount[2]
		local backcolor=pony[PREFIX.."color"..(coloroffcet+1)]or PPM.defaultHairColors[coloroffcet+1]
		render.Clear(backcolor.x*255,backcolor.y*255,backcolor.z*255,255,true)
		for I=0,colorcount-1 do
			local color=pony[PREFIX.."color"..(I+2+coloroffcet)]or PPM.defaultHairColors[I+2+coloroffcet]or Vector(1,1,1)
			local material=Material("models/ppm/partrender/"..prephrase..hairnum.."_mask"..I..".png")
			render.SetMaterial(material)
			render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),512,512,Color(color.x*255,color.y*255,color.z*255,255),-90)--position of the rect
			--direction to face in
			--size of the rect
			--color
			--rotate 90 degrees
		end
	else
		if TAIL then end
		if UPDN=="dn" then
			render.Clear(pony.haircolor2.x*255,pony.haircolor2.y*255,pony.haircolor2.z*255,255,true)
		else
			render.Clear(pony.haircolor1.x*255,pony.haircolor1.y*255,pony.haircolor1.z*255,255,true)
		end
	end
end
PPM.tex_draweyefunc=function(pony,isR)
	local modelscale=math.min(pony.modelscale,1)
--	if modelscale>1.1 then
--		modelscale=2.2-pony.modelscale
--	end
	local prefix="l"
	local SUFFIX=""
	if isR then
		SUFFIX="_r"
	else
		prefix="r"
	end
	local backcolor=pony["eyecolor_bg"..SUFFIX]or Vector(1,1,1)
	local color=1.3*pony["eyecolor_iris"..SUFFIX]or Vector(0.5,0.5,0.5)
	local colorg=1.3*pony["eyecolor_grad"..SUFFIX]or Vector(1,0.5,0.5)
	local colorl1=1.3*pony["eyecolor_line1"..SUFFIX]or Vector(0.6,0.6,0.6)
	local colorl2=1.3*pony["eyecolor_line2"..SUFFIX]or Vector(0.7,0.7,0.7)
	local holecol=1.3*pony["eyecolor_hole"..SUFFIX]or Vector(0,0,0)
	render.Clear(backcolor.x*255,backcolor.y*255,backcolor.z*255,255,true)--[[
	if file.Exists("materials/models/ppm/partrender/test_tile.png","GAME")then
		material=Material"models/ppm/partrender/test_tile.png"
		render.SetMaterial(material)
		render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),modelscale*512,modelscale*512,Color(255,255,255,255),-90)
		PPM.currt_success=true
		return
	end--]]
	local material=PPM.m_eyes[1]
	if isR then
		material=PPM.m_eyes[pony.eye_type_r]or material
	else
		material=PPM.m_eyes[pony.eye_type]or material
	end
	render.SetMaterial(material)
	local drawlines=false
	if isR and pony.eye_type_r==1 then
		drawlines=pony.eyehaslines_r==1
	end
	if !isR and pony.eye_type==1 then
		drawlines=pony.eyehaslines==1
	end
	local holewidth=pony.eyejholerssize or 1
	local irissize=pony["eyeirissize"..SUFFIX]or 0.6
	local holesize=(pony["eyeirissize"..SUFFIX]or 0.6)*(pony["eyeholesize"..SUFFIX]or 0.7)
	render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),modelscale*512*irissize,modelscale*512*irissize,Color(color.x*255,color.y*255,color.z*255),-90)--position of the rect
	--direction to face in
	--size of the rect
	--color
	--rotate 90 degrees
	--grad 
	local material=PPM.m_eye_grads[1]
	if isR then
		material=PPM.m_eye_grads[pony.eye_type_r]or material
	else
		material=PPM.m_eye_grads[pony.eye_type]or material
	end
	render.SetMaterial(material)
	render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),modelscale*512*irissize,modelscale*512*irissize,Color(colorg.x*255,colorg.y*255,colorg.z*255),-90)--position of the rect
	--direction to face in
	--size of the rect
	--color
	--rotate 90 degrees
	if drawlines then
		--eye_line_l1
		local material=Material("models/ppm/partrender/eye_line_"..prefix.."2.png")
		render.SetMaterial(material)
		render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),modelscale*512*irissize,modelscale*512*irissize,Color(colorl2.x*255,colorl2.y*255,colorl2.z*255,255),-90)--position of the rect
		--direction to face in
		--size of the rect
		--color
		--rotate 90 degrees
		local material=Material("models/ppm/partrender/eye_line_"..prefix.."1.png")
		render.SetMaterial(material)
		render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),modelscale*512*irissize,modelscale*512*irissize,Color(colorl1.x*255,colorl1.y*255,colorl1.z*255,255),-90)--position of the rect
		--direction to face in
		--size of the rect
		--color
		--rotate 90 degrees
	end
	--hole
	if isR then
		material=PPM.m_eye_pupils[pony.eye_type_r]
		if material and type(material)!="IMaterial"then
			PPM.m_eye_pupils[pony.eye_type_r]=nil
			material=nil
		end
	else
		material=PPM.m_eye_pupils[pony.eye_type]
		if material and type(material)!="IMaterial"then
			PPM.m_eye_pupils[pony.eye_type]=nil
			material=nil
		end
	end
	if material then
		render.SetMaterial(material)
		render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),modelscale*512*irissize,modelscale*512*irissize,Color(holecol.x*255,holecol.y*255,holecol.z*255),-90)--position of the rect
	end
	material=Material("models/ppm/partrender/eye_oval.png")
	render.SetMaterial(material)
	render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),modelscale*512*holesize*holewidth,modelscale*512*holesize,Color(holecol.x*255,holecol.y*255,holecol.z*255),-90)--position of the rect
	--direction to face in
	--size of the rect
	--color
	--rotate 90 degrees
	local material=Material("models/ppm/partrender/eye_effect.png")
	if isR then
		material:SetVector("$color2",pony.eye_effect_color_r or Vector(1,1,1))
		material:SetFloat("$alpha",pony.eye_effect_alpha_r)
	else
		material:SetVector("$color2",pony.effect_color or Vector(1,1,1))
		material:SetFloat("$alpha",pony.eye_effect_alpha)
	end
	render.SetMaterial(material)
	render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),modelscale*512*irissize,modelscale*512*irissize,Color(255,255,255),-90)--position of the rect
	--direction to face in
	--size of the rect
	--color
	--rotate 90 degrees
	local material=PPM.m_eye_reflections[1]
	if isR then
		material=PPM.m_eye_reflections[pony.eye_reflect_type_r]or material
		material:SetVector("$color2",pony.eye_reflect_color_r)
		material:SetFloat("$alpha",pony.eye_reflect_alpha_r)
	else
		material=PPM.m_eye_reflections[pony.eye_reflect_type]or material
		material:SetVector("$color2",pony.eye_reflect_color)
		material:SetFloat("$alpha",pony.eye_reflect_alpha)
	end
	--]=]
	render.SetMaterial(material)
	render.DrawQuadEasy(Vector(256,256,0),Vector(0,0,-1),modelscale*512*irissize,modelscale*512*irissize,Color(255,255,255,127),-90)--position of the rect
	--direction to face in
	--size of the rect
	--color
	--rotate 90 degrees
	--]]
	PPM.currt_success=true
end
PPM.hairrenderOp=function(UPDN,TAIL,hairnum)
	if TAIL then
		if PPM.manerender["tl"..hairnum]then
			PPM.currt_success=true
		end
	else
		if PPM.manerender[UPDN..hairnum]then
			PPM.currt_success=true
		end
	end
end
--/PPM.currt_success=true
--MsgN(UPDN,TAIL,hairnum,"=",PPM.currt_success)
PPM.manerender={
	up5={0,1},
	up6={0,1},
	up8={0,2},
	up9={0,3},
	up10={0,1},
	up11={0,3},
	up12={0,1},
	up13={0,1},
	up14={0,1},
	up15={0,1},
	dn5={0,1},
	dn8={3,2},
	dn9={3,2},
	dn10={0,3},
	dn11={0,2},
	dn12={0,1},
	tl5={0,1},
	tl8={0,5},
	tl10={0,1},
	tl11={0,3},
	tl12={0,2},
	tl13={0,1},
	tl14={0,1},
}
PPM.manecolorcounts={
	1,
	1,
	1,
	1,
	1,
	1,
}
PPM.defaultHairColors={
	Vector(0.984375,0.359375,0.3203125),
	Vector(0.9921875,0.5234375,0.234375),
	Vector(0.9921875,0.94140625,0.625),
	Vector(0.3828125,0.734375,0.3125),
	Vector(0.1484375,0.64453125,0.95703125),
	Vector(0.484375,0.3125,0.625),
}
