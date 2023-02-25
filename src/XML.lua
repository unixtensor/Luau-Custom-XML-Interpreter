--[[
	The XML scripting structure:
	"
<?xml version="1" author="author name" description="UI purposes"?> <!--This is optional-->	
<xml>
	<!--With var just like in HTML, data-anyname will be a named variable that can be used-->
	<var data-FrameColor=Color3.new(1,0,1)>
	<var data-AnchorVector=Vector2.new(.5,.5)>

	<ScreenGui Parent=game:GetService("StarterGui") ResetOnSpawn=false>
		<Frame BackgroundColor3=data-FrameColor AnchorPoint=data-AnchorVector>
			<!--A comment about anything-->
			<TextLabel>This Is Funny And Gonna Be Real</TextLabel>
			<TextButton>
				<!--Maybe some custom's too? mine as well get creative with our custom XML lang-->
				<b>Im Bold and bright</b>
			</TextButton>
			<!--Pushing Limits already?-->
			<script type="server/local/module">
				print("Hello World From XML Lua.")
			</script>
		</Frame>
	</ScreenGui>
</xml>
	"
	
	The XML data structure:

]]

local XML = {}
XML.__index = XML
XML.__cache = {}


local Valid_Insts = {
	["ScreenGui"] = true,
	["Frame"] = true
}

local function RBLXCreate(Inst, Props)
	local C = Instance.new(Inst)
	for n,v in Props do
		local s,e = pcall(function() C[n] = v end)
		if not s then warn(e, '\n', debug.traceback()) end
	end
end

local function Get_XML_special()

end

local function Get_XML_props(attrs)
	local props = {}
	for i = 1, #attrs do
		local ind = attrs[i]:split('=')
		for p = 1, #ind do
			local last_data = p-1
			props[ind[last_data ~= 0 and last_data or 1]] = ind[p]
		end
	end
	return props
end

local function IsAServicePath(potential_S)
	--Imagine a world where ":FindService" would return false and not an error...
	local S_exist, S = pcall(game.GetService, game, potential_S)
	return S_exist and S
end

local function Wrap_data_props(XML_props)
	local Wrap = {}
	for prop, val in XML_props do
		if prop == "Parent" then
			--Convert strings to service
			if val == "workspace" then
				val = "Workspace" 
			end
			local Service = IsAServicePath(val)
			if Service then
				Wrap[prop] = Service
			end
		elseif prop == "true" or prop == "false" then
			--Convert strings to bool
			--Idk.. this is pure prediction that this will be an actual bool and not a string as a bool
			Wrap[prop] = val == "true" and true
		elseif tonumber(val) then
			--Convert strings to number(s)
			Wrap[prop] = tonumber(val)
		else
			Wrap[prop] = val
		end
	end
	return Wrap
end

-- Support for pascal casing and snake casing
function XML.new(from_argSource)
	return setmetatable({XML_Source = from_argSource}, XML)
end
XML.New = XML.new

function XML:Interpreter()
	local S = self.XML_Source
	local Xpat = "<([%s%S]+)(.-)>(.-)</(%1)>"
	for Tag,RawAT,Value,_ in S:gmatch(Xpat) do
		local raw_data = {
			Tag = Tag, 
			Value = Value,
			Attr = RawAT:split(' ')
		}
		if raw_data.Attr[1] == "" then --Clear a possible empty block
			table.remove(raw_data.Attr, 1)
		end
		table.insert(self.__cache, raw_data)
	end
	for i = 1, #self.__cache do
		local v = self.__cache[i]
		if Valid_Insts[v.Tag] then
			local Converted_data = Wrap_data_props(Get_XML_props(v.Attr))
			RBLXCreate(v.Tag, Converted_data)
		else
			--Handle specials
		end
	end
	
	local stashed_cache = self.__cache
	self.__cache = {}
	XML.__cache = {}
	return stashed_cache
end
function XML:interpreter(...) return XML:Interpreter(...) end

return XML