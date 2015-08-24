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
  local M = require "customOrderData"

--  common.CheckValidTimeRange(entryFrom, entryTo)

  local CallForceMapping = {["Call"]="Call", ["Force"]="Force", ["None"]=""}
  local debug_mode = false

  local sql_column_text = ' TEXT DEFAULT "" '
  local sql_column_integer = ' INTEGER DEFAULT 0'
  local sql_column_real = ' REAL DEFAULT 0.0'
  local table_name_order = "ExportedOrders"
  local table_name_deposit = "Decide_deposit"
  local database_tables = {

    {table_name_deposit, { 'TRADENAME'..sql_column_text,
        'Mandator'..sql_column_text,
        'TRADERID'..sql_column_text,
        'DEPOSITID'..sql_column_text,
        'TYPE'..sql_column_text,
        'CASH'..sql_column_integer,
        'FLOATING'..sql_column_integer,
        'EEBALANCE'..sql_column_integer,
        'MARGINBALANCE'..sql_column_integer,
        'UNREALIZED'..sql_column_integer,
        'EQUITYBALANCE'..sql_column_integer,
        'TOTALMM'..sql_column_integer,
        'CALLAMOUNT'..sql_column_integer,
        'FORCEAMOUNT'..sql_column_integer
        }}
  }


  common.CreateTables(db_file, log_file,  database_tables, debug_mode)

-------------------------------------------------------------------------------------
  
  --local orders = easygetter.GetOrders( entryFrom, entryTo )
  
  local deposits = {}
  local depositList = {}
  local depositItem = {}
  local options = {}
  
  local function processDeposits (deposit)
         deposits[deposit] = deposit
  end

  dubi.getDeposits(options,processDeposits)
   --local deposits =  dubi.getDeposits(options)
  print("----------------------------------------------------")
  print("-                   Begin Lua                      -")
  print("----------------------------------------------------")
  print("- Mandator : "..mandator.current():getShortName())
  --print("- Mandatorconfig: "..mand_config) 
  print("- Entry from: "..entryFrom) 
  print("- Entry to: "..entryTo) 
  
  
   
  for _,deposit in pairs( deposits ) do
    local Deposit = fo.Deposit(deposit)
    
    if(Deposit:hasTradingProfile()) then
    
        local profile = Deposit:getTradingProfile()
        local profilePreFix = ""
    if( profile ~= nil) then
        profilePreFix = string.sub(profile:getName(), 1, 2)
        if( string.find("F=;O=;A=;N=;G=;E=;X=;", profilePreFix) ~= nil) then

          local t = dubi.getOrderVolumeTotalTurnoverLimits(deposit)

          for _, lim in ipairs( t ) do
          local ordVolLim = fo.OrderVolumeLimit( lim.lim_ordvolnr )
           OrderVolumerisk = ordVolLim:getUniqueRisk()
          if ( OrderVolumerisk ~= nil )then
          
          
          if (OrderVolumerisk:getCallForce() == "Force") then
          local depositItem = {}
          
          local client_obj = Deposit:getClient()
              if( client_obj:hasAccountManager() ) then
          local account_manager = client_obj:getAccountManager()
          local trader_id = dubi.getSETTraderId( account_manager:getShortName())
              if( trader_id ~= nill) then
                table.insert (depositItem, {'TRADERID', trader_id })
          end
          table.insert(depositItem,{'TRADENAME',account_manager:getName()})
          end
          
          
          table.insert(depositItem,{'Mandator',mandator.current():getShortName()})
          depositId = Deposit:getNumber()
          
          table.insert (depositItem, {'DEPOSITID',depositId})
          table.insert (depositItem, {'TYPE',ordVolLim:getUniqueRisk():getCallForce()})
          table.insert (depositItem, {'CASH',easygetter.EvenAmountToDouble(OrderVolumerisk:getCashBalance())})
          table.insert (depositItem, {'FLOATING',easygetter.EvenAmountToDouble(OrderVolumerisk:getTotalFutureUPLGross())})
          table.insert (depositItem, {'EEBALANCE',easygetter.EvenAmountToDouble(OrderVolumerisk:getExcessEquityBalance())})
          table.insert (depositItem, {'MARGINBALANCE',easygetter.EvenAmountToDouble(OrderVolumerisk:getPositionMargin())})
          table.insert (depositItem, {'UNREALIZED',easygetter.EvenAmountToDouble(OrderVolumerisk:getPositionMargin())-easygetter.EvenAmountToDouble(OrderVolumerisk:getDailyFutureUPLGross())})
          table.insert (depositItem, {'EQUITYBALANCE',easygetter.EvenAmountToDouble(OrderVolumerisk:getEquityBalance())})
          table.insert (depositItem, {'TOTALMM',easygetter.EvenAmountToDouble(OrderVolumerisk:getMaintenanceMargin())})
          table.insert (depositItem, {'CALLAMOUNT',easygetter.EvenAmountToDouble(OrderVolumerisk:getCallAmount())})
          table.insert (depositItem, {'FORCEAMOUNT',easygetter.EvenAmountToDouble(OrderVolumerisk:getForceAmount())})
          
          table.insert (depositList, depositItem)
          end
          
      end

      end

        end
        
    end

   end

      end

  common.InsertRecords(db_file, log_file, table_name_deposit, depositList, debug_mode)
  print("----------------------------------------------------")
  print("-*                  End Lua                       *-")
  print("----------------------------------------------------")

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
