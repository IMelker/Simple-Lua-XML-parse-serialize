local function ParseXMLArgs(s)
    local arg = {}
    string.gsub(s, "([%-%w_]+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
    end)
    return arg
end

local function ParseXML(s)
    local stack = {}
    local top = {}
    table.insert(stack, top)
    local ni,c,label,xarg, empty
    local i, j = 1, 1
    while true do
        ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
        if not ni then break end
            local text = string.sub(s, i, ni-1)
        if not string.find(text, "^%s*$") then
            table.insert(top, text)
        end
        if empty == "/" then         -- empty element tag
            table.insert(top, {label=label, xarg=ParseXMLArgs(xarg), empty=1})
        elseif c == "" then          -- start tag
            top = {label=label, xarg=ParseXMLArgs(xarg)}
            table.insert(stack, top)   -- new level
        else  -- end tag
            local toclose = table.remove(stack)  -- remove top
            top = stack[#stack]
            if #stack < 1 then
                assert("XML Parser: noting to close with " .. label)
            end
            if toclose.label ~= label then
                assert("XML Parser: trying to close "..toclose.label.." with "..label)
            end
            table.insert(top, toclose)
        end
    i = j+1
    end
    local text = string.sub(s, i)
    if not string.find(text, "^%s*$") then
        table.insert(stack[#stack], text)
    end
    if #stack > 1 then
        assert("XML Parser: unclosed "..stack[#stack].label)
    end
    return stack[1]
end


local xml = ""
local function ToStringXML(value)
    local t = type(value)
    if t == 'string' then
        xml = xml .. "<" .. value .. "/>\n"
    elseif t == 'table' then
        local label = value["label"]
        xml = xml .. '<' .. value["label"]
        if value["xarg"] then
            for key,value in pairs(value["xarg"]) do
                xml = xml .. ' ' .. key .. '=\"' .. value .. '\"'
            end
        end
        if value["empty"] then
            xml = xml .. '/>'
        else
            xml = xml .. '>'
            for name,data in pairs(value) do
                local ntype = type (name)
                if ntype == 'number' then
                    local dtype = type (data)
                    if dtype == 'table' then
                        ToStringXML(data)
                    elseif dtype == 'string' then
                         xml = xml .. data
                    end
                end
            end
            xml = xml .. '</' .. label .. '>'
        end
    end
end

local function SerialiseXML(xml_table)
    xml = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>"
    ToStringXML(xml_table[2])
    return xml
end

------------------------------------EXAMPLE-------------------------------------
local xml_text = "<?xml version=\"1.0\" encoding=\"utf-8\" ?><package><status><msg id=\"44324\" sms_id=\"1\" date_completed=\"2018-06-20 17:59:59\">102</msg>" .. 
"<msg id=\"44324\" sms_id=\"1\" date_completed=\"2018-06-20 17:59:59\">102</msg></status></package>"

local xml_table = ParseXML(xml_text)
local result = SerialiseXML(xml_table)
print(xml) 
