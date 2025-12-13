-- RPE/Data/Export.lua
-- Utility to export a Lua table to the clipboard window, fully formatted

_G.RPE = _G.RPE or {}
_G.RPE.Data = _G.RPE.Data or {}

local Export = {}

---Exports a Lua table to the clipboard window, formatted for copy-paste
---@param tbl table The Lua table to export
---@param opts table|nil Optional table. If opts.format == "compact", output is single-line. If opts.key is set, outputs [key]=... (not wrapped in a table)
function Export.ToClipboard(tbl, opts)
    local cb = _G and _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.Clipboard
    if not cb or not cb.serialize_lua_table then
        print("Clipboard or serialization function not found.")
        return
    end
    local str
    if opts and opts.key then
        local function compact_serialize(val)
            local t = type(val)
            if t == "table" then
                local s = "{"
                local first = true
                for k, v in pairs(val) do
                    if not first then s = s .. "," else first = false end
                    local key
                    if type(k) == "string" and k:match("^%a[%w_]*$") then
                        key = k
                    else
                        key = "[" .. compact_serialize(k) .. "]"
                    end
                    s = s .. key .. "=" .. compact_serialize(v)
                end
                return s .. "}"
            elseif t == "string" then
                return string.format("%q", val)
            else
                return tostring(val)
            end
        end
        if opts.format == "compact" then
            str = "[" .. opts.key .. "]=" .. compact_serialize(tbl)
        else
            str = "[" .. opts.key .. "] = " .. cb.serialize_lua_table(tbl)
        end
    else
        if opts and opts.format == "compact" then
            local function compact_serialize(val)
                local t = type(val)
                if t == "table" then
                    local s = "{"
                    local first = true
                    for k, v in pairs(val) do
                        if not first then s = s .. "," else first = false end
                        local key
                        if type(k) == "string" and k:match("^%a[%w_]*$") then
                            key = k
                        else
                            key = "[" .. compact_serialize(k) .. "]"
                        end
                        s = s .. key .. "=" .. compact_serialize(v)
                    end
                    return s .. "}"
                elseif t == "string" then
                    return string.format("%q", val)
                else
                    return tostring(val)
                end
            end
            str = compact_serialize(tbl)
        else
            str = cb.serialize_lua_table(tbl)
        end
    end
    cb:SetContent(str)
    cb:Show()
end

_G.RPE.Data.Export = Export
return Export
