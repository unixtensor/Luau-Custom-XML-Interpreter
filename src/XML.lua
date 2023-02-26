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
XML.__cache = {variables = {}}

local function RBLXCreate(Inst, Props)
	local C = Instance.new(Inst)
	for n,v in Props do
		local s,e = pcall(function() C[n] = v end)
		if not s then warn(e, '\n', debug.traceback()) end
	end
end

local function Wrap_data_props(XML_props)
	local Wrap = {}
	local IsAServicePath = function(potential_S)
		--Imagine a world where ":FindService" would return false and not an error...
		local S_exist, S = pcall(game.GetService, game, potential_S)
		return S_exist and S
	end
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
			Wrap[prop] = val == "true"
		elseif tonumber(val) then
			--Convert strings to number(s)
			Wrap[prop] = tonumber(val)
		else
			Wrap[prop] = val
		end
	end
	return Wrap
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

local function New_XML_var(self, Query_var)
	local Query_var_sub, Query_var_state = Query_var:sub(1,5), Query_var:sub(6,#Query_var)
	local Query_var_val = Query_var_sub == "data-" or Query_var_sub == "DATA-"
	if Query_var_val then
		local var_value = Query_var_state:split('=')[2]
		if var_value then
			self.__cache.variables[Query_var_state] = var_value
		end
	end
end

local Base_Instances = {
	["ScreenGui"] = true,
	["Frame"] = true
}
local Special_cases = {
	Small = { --Small form <Tag Attr=Value>
		["var"] = New_XML_var
	},
	Full = { --Full form <Tag Attr=Value>Inner</Tag>
	}
}
local function make(self)
	local function AnalizeFull()
		local Query_ana_full = self.XML_Source:gmatch("<([%s%S]+)(.-)>(.-)</(%1)>")
		for XML_Tag,XML_RawAT,XML_Value,_ in Query_ana_full do
			local Xraw_data = {
				XML_Tag = XML_Tag,
				XML_Value = XML_Value,
				XML_Attribute = XML_RawAT:gsub(' ',''):split(' ')
			}
			local Syntax_Base = Base_Instances[XML_Tag]
			if Syntax_Base then
				RBLXCreate(XML_Tag, Wrap_data_props(Get_XML_props(Xraw_data.XML_Attribute)))
			else
				--Syntax is incorrect
				warn("Unknown XML Tag: \""..XML_Tag.."\".")
			end
			table.insert(self.__cache, Xraw_data)
		end
	end

	local Query_ana_part = self.XML_Source:gmatch("<([%s%S]+)(.-)(%1)>")
	for XML_Tag,XML_RawAT in Query_ana_part do
		local S_caseF = Special_cases.Small[XML_Tag]
		if S_caseF then
			S_caseF(self, {
				XML_Tag = XML_Tag,
				XML_Attribute = XML_RawAT:gsub(' ',''):split(' ')
			})
		else
			AnalizeFull()
			break
		end
	end

	local stashed_metadata = self.__cache
	self.__cache = {variables = {}}
	XML.__cache = {}
	return stashed_metadata
end

-- Support for pascal casing and snake casing
function XML.new(from_argSource)
	return setmetatable({XML_Source = from_argSource}, XML)
end
XML.New = XML.new

function XML:Make()
	return make(self)
end
function XML:make(...) return XML:Make(...) end

return XML