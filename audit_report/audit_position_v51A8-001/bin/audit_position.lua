require "ocs"

local cmdln = require "cmdline"
local mandator = require "mandator"
local fo = require "fo"
local tim = require "tim"
local maps = require "maps"
local easygetter = require "easygetter"
local mandator = require "mandator"
local log_file = ""
local db_file = ""
local entryFrom = ""
local entryTo = ""
-- =============================================================================
-- Read Configuration
-- =============================================================================

cmdln.add{ name="--logFile", descr="", func=function(x) log_file=x end }
cmdln.add{ name="--dbFile", descr="", func=function(x) db_file=x end }

-- =============================================================================


cmdln.parse( arg, true )

print("Start!!!!: " )
print("DB File is "..db_file)
print("Log File :"..log_file)

ocs.createInstance( "LUA" )


local function process()

  print("begin process")

  local common = require "common"
  local debug_mode = false

-- =============================================================================
-- Insert Process code here (Create DB File).
-- =============================================================================
  local dubi = require "dubi"
  --self defined common module
  local common = require "common"
  local confirmreport = require "confirmreport"
  local otp = require "otp"
--common.CheckValidTimeRange(entryFrom, entryTo)

  local CallForceMapping = {["Call"]="Call", ["Force"]="Force", ["None"]=""}
  local debug_mode = false

  local sql_column_text = ' TEXT DEFAULT "" '
  local sql_column_integer = ' INTEGER DEFAULT 0'
  local sql_column_real = ' REAL DEFAULT 0.0'
  local table_name_order = "positionTable"
  local database_tables = {
     {table_name_order, {
               'Medium'..sql_column_text,
               'TA_NUM'..sql_column_text,
               'STOCK'..sql_column_text,
               'CLIENT'..sql_column_text,
               'Price'..sql_column_integer,
               'TRADER_obj'..sql_column_text,
               'OLD_obj'..sql_column_integer,
               'NEW_obj'..sql_column_integer,
               'TIME'..sql_column_text,
               'TTF'..sql_column_text,
              }},
}

  common.CreateTables(db_file, log_file,  database_tables, debug_mode)
 local report_transaction_path = os.getenv("RPT_TRANSACTION")
 local report_date=os.date("%Y-%m-%d")
 local file  = io.open ( report_transaction_path.."/"..report_date.."/Audit_Transaction_Report_TSC.csv", "r" )


    function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end


function printCSV(line)
  for word in string.gmatch(line, '([^,]+)') do
      print(word)
  end
end



local i=0

local orderList = {}
    for line in io.lines(report_transaction_path.."/"..report_date.."/Audit_Transaction_Report_TSC.csv") do
    i=i+1
    

    
    if i>9 then
       local log = {}
       
        local depositItem ={}
       local stock = 0
       local qty = 0
      -- print("lines : " ,line)
       for word in (line .. ","):gmatch("([^,]*),") do 
       --for word in string.gmatch(line,'([^,]+),') do
        log[#log + 1] = word
        --print("-"..word)
      end
      
      --local Portfolio =log[3]
      local stock =log[5]
      local price =log[9]
      local qty =log[7]
      local Ta =log[11]
      local Client =log[1]
      local Transaction =log[2]
      local CG =log[4]
      local Time =log[12]
      local Trader =log[13]
      local Medium =log[14]

      if (Ta ~= nil and Ta ~="" ) then
       
       local Ta_number = tonumber(Ta)
       local spv
       local spv = otp.getPositionStateForTA(Ta_number,true,"Customer")--new
       local spv2 = otp.getPositionStateForTA(Ta_number,false,"Customer")--old
        print("=========================================================")
        print("")
        print("STOCK : "..stock)
        table.insert(depositItem,{'STOCK',stock})
        print("TA Number : "..Ta_number)
        table.insert(depositItem,{'TA_NUM',Ta_number})
        print("Client : "..Client)
        table.insert(depositItem,{'CLIENT',Client})
        print("Trader : "..Trader)
        table.insert(depositItem,{'TRADER_obj',Trader})
        
        table.insert(depositItem,{'Price',price})
        
        local Time_obj = tostring(Time)
        local Time_sub = string.sub(Time_obj,12)
        print("Time : "..Time_sub)
        table.insert(depositItem,{'TIME',Time_sub})
        
        print("Medium : "..Medium)
        table.insert(depositItem,{'Medium',Medium})
        
        -- local find_string = string.find(stock,"-R")
        -- if (find_string ~= nil) then
        -- local find_number = 2
        -- table.insert(depositItem,{'TTF',find_number})
        -- print("TTF : "..find_number)
        -- end 
        
        -- local find_string = string.find(stock,"-U")
        -- if (find_string ~= nil) then
        -- local find_number = 1
        -- table.insert(depositItem,{'TTF',find_number})
        -- print("TTF : "..find_number)
        -- end 
        local find_string = string.match(stock,"-R" or"-U")
        if (find_string == "-R")then
        local num = 2
        table.insert(depositItem,{'TTF',num})
        end
        if(find_string == "-U")then
        local num = 3
        table.inser(depositItem,{'TTF',num})
        end

        local old_qty = tostring(spv2.quantity)
        local new_qty = tostring(spv.quantity)
        print("Quantity Old : "..old_qty)
        table.insert(depositItem,{'OLD_obj',old_qty})
        
        print("Quantity New : "..new_qty)
        table.insert(depositItem,{'NEW_obj',new_qty})
        
        
        
        local bookValNet = tostring(spv2.bookValueNet)
        print("bookValueNet"..bookValNet)
        print("")
        print("=========================================================")
        table.insert (orderList, depositItem) 
       end
       
       end
       
    end

common.InsertRecords(db_file, log_file, table_name_order, orderList, debug_mode)

-- =============================================================================

end

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end


local inst = os.getenv( "RPT_BROKER" )
local mand = mandator.Mandator( inst)
mandator.changeTo( mand, process )
