-- ********************************************************************************** --
-- **   Serialize table to string                                                  ** --
-- **                                                                              ** --
-- ********************************************************************************** --
 
 -- declare local variables
 --// exportstring( string )
 --// returns a "Lua" portable version of the string
 local function exportstring( s )
    return string.format("%q", s)
 end
 
 local insert  = table.insert
 local tostring= tostring
 local ipairs  = ipairs
 local pairs   = pairs
 local type    = type

 --// The Save Function
 function table.toString(tbl)
    local charS,charE = "   ","\n"
    local s_tbl = {}
    
    -- initiate variables for save procedure
    local tables,lookup = { tbl },{ [tbl] = 1 }
    insert(s_tbl, "return {"..charE )

    for idx,t in ipairs( tables ) do
       insert(s_tbl, "-- Table: {"..idx.."}"..charE )
       insert(s_tbl, "{"..charE )
       local thandled = {}

       for i,v in ipairs( t ) do
          thandled[i] = true
          local stype = type( v )
          -- only handle value
          if stype == "table" then
             if not lookup[v] then
                insert( tables, v )
                lookup[v] = #tables
             end
             insert(s_tbl, charS.."{"..lookup[v].."},"..charE )
          elseif stype == "string" then
             insert(s_tbl,  charS..exportstring( v )..","..charE )
          elseif stype == "number" or stype == "boolean" then
             insert(s_tbl,  charS..tostring( v )..","..charE )
          end
       end

       for i,v in pairs( t ) do
          -- escape handled values
          if (not thandled[i]) then
          
             local str = ""
             local stype = type( i )
             -- handle index
             if stype == "table" then
                if not lookup[i] then
                   insert( tables,i )
                   lookup[i] = #tables
                end
                str = charS.."[{"..lookup[i].."}]="
             elseif stype == "string" then
                str = charS.."["..exportstring( i ).."]="
             elseif stype == "number" or stype == "boolean" then
                str = charS.."["..tostring( i ).."]="
             end
          
             if str ~= "" then
                stype = type( v )
                -- handle value
                if stype == "table" then
                   if not lookup[v] then
                      insert( tables,v )
                      lookup[v] = #tables
                   end
                   insert(s_tbl, str.."{"..lookup[v].."},"..charE )
                elseif stype == "string" then
                   insert(s_tbl, str..exportstring( v )..","..charE )
                elseif stype == "number" or stype == "boolean" then
                   insert(s_tbl, str..tostring( v )..","..charE )
                end
             end
          end
       end
       insert(s_tbl, "},"..charE )
    end
    insert(s_tbl, "}" )
    
    return table.concat(s_tbl)
 end
 
 --// The Load Function
 function table.fromString(s)
    local ftables = loadstring(s)
    local tables = ftables()
    for idx = 1,#tables do
       local tolinki = {}
       for i,v in pairs( tables[idx] ) do
          if type( v ) == "table" then
             tables[idx][i] = tables[v[1]]
          end
          if type( i ) == "table" and tables[i[1]] then
             insert( tolinki,{ i,tables[i[1]] } )
          end
       end
       -- link indices
       for _,v in ipairs( tolinki ) do
          tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
       end
    end
    return tables[1]
 end
