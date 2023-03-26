local XML = [[
<var data-test=newvar>
<var data-test2=newvar2>
]]

local XML_Module = require(path.XML)

local XML_Wrapper = XML_Module.New(XML)
local XML_metadata = XML_Wrapper:Make()

--Optionally log the metadata for debug purposes
print(XML_metadata)

--  ["variables"] =  ▼  {
--    ["test=new"] = "test"
-- }