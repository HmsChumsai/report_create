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

    {table_name_order, { 'ORDERID'..sql_column_text,
         'SIDE'..sql_column_text,
         'POSITION'..sql_column_text,
         'SERIES'..sql_column_text,
         'QTY'..sql_column_integer,
         'MATCHED_QTY'..sql_column_integer,
         'PRICE'..sql_column_text,
        'DEPOSIT'..sql_column_text,
        'TRADERID'..sql_column_text,
        'ORDER_STATUS'..sql_column_real,
        'ORDER_DATE_TIME'..sql_column_text,
        'ORDER_DATE'..sql_column_text,
        'VALID'..sql_column_text,
        'VDATE'..sql_column_text,
        'STOP_CONTRACT'..sql_column_text,
        'STOP_LIMIT'..sql_column_text,
        'STCOND'..sql_column_text,
        'CPM'..sql_column_text,
        'order_entry_time'..sql_column_text,
        'trade_date'..sql_column_text,
        'settlement_date'..sql_column_text,
        'match_price'..sql_column_real,
        'mandator'..sql_column_text,
        'unmatched_qty'..sql_column_integer,
        'Status'..sql_column_real,
        'service_type'..sql_column_real,
        'published'..sql_column_real}}
        
  }


  common.CreateTables(db_file, log_file,  database_tables, debug_mode)
  
  
  local businesscenter = fo.BusinessCenter("THAILAND")
  local tradingCalendar = businesscenter:getTradingCalendar()
  local entryTo = tradingCalendar:addActiveDays( tim.Date.current(),0, isNONE ):toString("%Y-%m-%dT17:00:00")
  local prevday = tradingCalendar:addActiveDays( tim.Date.current(), -1, isNONE ):toString("%Y-%m-%dT19:30:00")
-------------------------------------------------------------------------------------
  local orders = easygetter.GetOrdersByDate( prevday, entryTo )
  local orderList = {}
  local orderItem = {}
  
  print("----------------------------------------------------")
  print("-                   Begin Lua                      -")
  print("----------------------------------------------------")
  print("- Mandator : "..mandator.current():getShortName())
  --print("- Mandatorconfig: "..mand_config) 
  print("- Entry from: "..entryFrom) 
  print("- Entry to: "..entryTo) 
  
  for _,no in pairs( orders ) do
    local order = fo.Order( no )
	--print("-* Order no. = "..order:getOrderId())
    local orderHandlingType = order:getHandlingType()
    
    
    if( order:hasExchange() == true ) then
    local orderExchange = order:getExchange():getName()
    if (orderHandlingType == 'BlockTrade'  and orderExchange == 'Thailand Future Exchange' ) then
      local orderlegs = order:getOrderLegs()
      
      local Mandator_obj = mandator.current():getShortName()
       table.insert(orderItem,{'mandator',Mandator_obj})
       
      local service_type = order:hasTradingChannel()
      if (service_type == true ) then
        table.insert (orderItem, {'service_type',order:getTradingChannel():getName()})
      end
      
      for i = 1, order:getNumberLegs() do
        orderItem = {}
        local orderLeg = orderlegs[i]
         ----------------------------------------------------------------------------------------------------------------
        local STCOND_obj = order:getStopCondition()
          if ( STCOND_obj == "Standard") then
              table.insert(orderItem,{'STCOND'," "})
              
          elseif( STCOND_obj == "LastGEStop")then
              table.insert(orderItem,{'STCOND',"Last>=Stop"})
              
          elseif( STCOND_obj == "LastLEStop")then
              table.insert(orderItem,{'STCOND',"Last<=Stop"})
              
          elseif( STCOND_obj == "BidGEStop")then
              table.insert(orderItem,{'STCOND',"Bid>=Stop"})
              
          elseif( STCOND_obj == "BidLEStop")then
              table.insert(orderItem,{'STCOND',"Bid<=Stop"})
              
          elseif( STCOND_obj == "AskGEStop")then
              table.insert(orderItem,{'STCOND',"Ask>=Stop"})
          
          elseif( STCOND_obj == "AskLEStop")then
              table.insert(orderItem,{'STCOND',"Ask<=Stop"})
          end
        table.insert (orderItem, {'TRADERID',order:getEntryUserId()})
        local STLCon_obj = order:hasStopContract()
          if( STLCon_obj == true ) then
            table.insert(orderItem,{'STOP_CONTRACT',order:getStopContract():getContractCode()})
          end
        table.insert (orderItem, {'ORDER_STATUS', M.getStatus(order:getOrderId())})
        local order_vdate = order:getValidTime():toString("%d/%m/%Y")
          if ( order_vdate == "UNUSED") then
            table.insert ( orderItem,{'VDATE'," "})
          else
            table.insert (orderItem, {'VDATE', order_vdate})
          end

        local order_restriction = tostring(order:getOrderRestrictionType())
          if (order_restriction == "None") then
            table.insert (orderItem, {'VALID',"Day"})
          else
            table.insert (orderItem, {'VALID', order_restriction})
          end

        local date_local =  order:getEntryTime():getDateInUtcOffset(common.offsetTimeZoneSecs)
        local time_local =  order:getEntryTime():addHours(7)
          table.insert (orderItem, {'ORDER_DATE_TIME',time_local:toString("%T")})
          table.insert (orderItem, {'ORDER_DATE',date_local:toString("%d/%m/%Y")})

        local order_id = order:getOrderId()
          table.insert (orderItem, {'ORDERID', order_id})
        local order_deposit = order:getDeposit():getName()
        print("-* Order deposit = "..order_deposit)
          table.insert (orderItem,{'DEPOSIT',order_deposit})
        
        local position_obj = orderLeg:getOpenClose()
        if position_obj == 'Open' then
            table.insert(orderItem,{'POSITION',"O"})
          elseif position_obj == 'Close' then
            table.insert(orderItem,{'POSITION',"C"})
        end
        
        local buy_sell = common.BuySellToBSMapping[orderLeg:getOrderKind()]
          table.insert (orderItem, {'SIDE', buy_sell})
        local qty_obj = orderLeg:getTotalQty()
          table.insert (orderItem, {'QTY', qty_obj})
        local match_qty = orderLeg:getExecQty()
          table.insert (orderItem, {'MATCHED_QTY', match_qty})
        local instrument = orderLeg:getContract():getContractCode()
          table.insert (orderItem, {'SERIES', instrument})
        local StPrice = tostring(orderLeg:getStopLimit())
        local set_zero = nil
          if (StPrice ~= "0") then
            local stringformat = string.format("%.2f",StPrice)
            table.insert(orderItem,{'STOP_LIMIT',stringformat})
          else
            table.insert(orderItem,{'STOP_LIMIT',set_zero})
          end
        
        local client_obj = order:getClient()
        if( client_obj:hasAccountManager() ) then
        local account_manager = client_obj:getAccountManager()
        
        end
        print("Order number"..order:getOrderId())
        local order_price_limit = tostring(orderLeg:getPriceLimit() or '')
        local order_limit_type = tostring(order:getOrderLimitType() or '')
          table.insert (orderItem, {'PRICE', string.format("%.2f",order_price_limit)})
        local tradeDate = order:getEntryTime():getDateInUtcOffset(offsetTimeZoneSecs):toString("%d/%m/%Y")
          table.insert (orderItem, {'trade_date', tradeDate})
        
        local cpm_obj = order:getCounterparty():getName()
        
        --local cpm_obj = order:getCounterparty():getInterfaceLogin()
        --local cpm_obj = order:getCounterparty():getExchange():getName()
        --local cpm_obj = order:getCounterparty():getInterfaceLoginGroup()
        table.insert(orderItem,{'CPM',cpm_obj})


        table.insert (orderList, orderItem)
      end
    end
   end
   end
  common.InsertRecords(db_file, log_file, table_name_order, orderList, debug_mode)
  print("----------------------------------------------------")
  print("-*                  End Lua                       *-")
  print("----------------------------------------------------")
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
