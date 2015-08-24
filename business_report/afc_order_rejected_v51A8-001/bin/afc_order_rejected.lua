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
local afcUtil = require "afcUtil"
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
  local M = require "customOrderData"
--common.CheckValidTimeRange(entryFrom, entryTo)

  local CallForceMapping = {["Call"]="Call", ["Force"]="Force", ["None"]=""}
  local debug_mode = false

  local sql_column_text = ' TEXT DEFAULT "" '
  local sql_column_integer = ' INTEGER DEFAULT 0'
  local sql_column_real = ' REAL DEFAULT 0.0'
  local table_name_order = "ExportedTable"
   local database_tables = {
     {table_name_order, {
              'Status'..sql_column_text,
              'Order_Status'..sql_column_text,
              'AFC_ORDER'..sql_column_text,
              'STOCK'..sql_column_text,
              'B_S'..sql_column_text,
              'Volume'..sql_column_text,
              'Price'..sql_column_real,
              'Limit_Type'..sql_column_text,
              'Deposit'..sql_column_text,
              'Account_Type'..sql_column_text,
              'Entry_ID'..sql_column_text,
              'TTF'..sql_column_text,
              'Channel'..sql_column_text,
              'Entry_date'..sql_column_text,
              'Entry_time'..sql_column_text,
              'Text_Error'..sql_column_text,
              }},
}

   common.CreateTables(db_file, log_file,  database_tables, debug_mode)


  local businesscenter = fo.BusinessCenter("THAILAND")
  local tradingCalendar = businesscenter:getTradingCalendar()
  local entryTo = tradingCalendar:addActiveDays( tim.Date.current(),0, isNONE ):toString("%Y-%m-%dT17:00") ---"%Y-%m-%dT%H:%M"
  local entryFrom = tradingCalendar:addActiveDays( tim.Date.current(),-1, isNONE ):toString("%Y-%m-%dT17:00")
  print("Prevday : "..entryFrom)
  print("EntryTo : "..entryTo)
  
  local handleAfc = true
  local orders = afcUtil.GetOrders( entryFrom, entryTo, handleAfc )
  local depositItem = {}
  local depositList = {}
  



  for _,no in pairs( orders ) do
    local order = fo.Order( no )
    local orderHandlingType = order:getHandlingType()

    local orderlegs = order:getOrderLegs()
    
    
    for i = 1, order:getNumberLegs() do
    local orderLeg = orderlegs[i]
    
    local order_limit_type = tostring(order:getOrderLimitType())
    
    
    if( order:getAfterCloseOrder() == "Triggered")then
    print("===============================================================================================")
    
     local depositItem = {}
    print("AFC_ORDER : "..order:getOrderId())
    table.insert (depositItem, {'Status',order:getAfterCloseOrder()})
    table.insert (depositItem, {'Order_Status',order:getCustomStatus()})
    table.insert (depositItem, {'AFC_ORDER',order:getOrderId()})
    print("Stock : "..order:getInstrument():getShortName())
    table.insert (depositItem, {'STOCK',order:getInstrument():getShortName()})
    --"::::::::BUYSell:::::::"
    local buy_sell = common.BuySellToBSMapping[orderLeg:getOrderKind()]
    if (buy_sell == "B") then
    local buy_sell = "Buy"
    print("B/S : "..buy_sell)
    table.insert (depositItem, {'B_S',buy_sell})
    end
    if (buy_sell == "S") then
    local buy_sell = "Sell"
    print("B/S : "..buy_sell)
    table.insert (depositItem, {'B_S',buy_sell})
    end


   local Text_error = fo.OrderOperation( order, order:getLastOrderOperationIndex() ):getErrorText()
   local sub_string = string.gsub(Text_error,"'"," ")
   if( Text_error ~= '' ) then
   table.insert(depositItem,{'Text_Error',sub_string})
    end
   
    print("Text_error : "..sub_string)
    print("Status : "..order:getStatus())
    print("AFC : "..order:getAfterCloseOrder())
    print("Volume : "..orderLeg:getTotalQty())
    table.insert (depositItem, {'Volume',orderLeg:getTotalQty()})
    
    print("Price : "..orderLeg:getPriceLimit())
    table.insert (depositItem, {'Price',orderLeg:getPriceLimit()})
    
    if(order:getTradeRestrictionType() == "None")then 
    table.insert (depositItem, {'Limit_Type',order:getOrderLimitType()})
    else
    
    local ATO_ATC = order:getTradeRestrictionType()
    if(ATO_ATC == "ClosingAuction") then
    table.insert (depositItem, {'Limit_Type',"ATC"})
    end
    if(ATO_ATC == "OpeningAuction") then
    table.insert (depositItem, {'Limit_Type',"ATO"})
    end
    end
    
    print("Deposit : "..order:getDeposit():getNumber())
    table.insert (depositItem, {'Deposit',order:getDeposit():getNumber()})
    
    if(order:getDeposit():hasAccountType())then
    print("Account Type : "..order:getDeposit():getAccountType():getName())
    table.insert (depositItem, {'Account_Type',order:getDeposit():getAccountType():getName()})
    else
    print("Account Type : ".." ")
    local blank = " "
    table.insert (depositItem, {'Account_Type',blank})
    end
    
    print("Entry ID : "..order:getEntryUserId())
    table.insert(depositItem,{'Entry_ID',order:getEntryUserId()})
    
    
     -- for _,op in pairs( order:getOrderOperations() ) do
    
    -- if (op:getTransactionType() == "Cancel") then
    -- print("Cancel Date : "..order:getEntryTime():getDateInUtcOffset(common.offsetTimeZoneSecs):toString("%d/%m/%Y"))
    -- table.insert (depositItem,{'Entry_date',op:getEntryTime():getDateInUtcOffset(common.offsetTimeZoneSecs):toString("%d/%m/%Y")})
    
    -- print("Cancle Time : "..order:getEntryTime():addHours(7):toString("%T"))
    -- table.insert (depositItem,{'Entry_time',op:getEntryTime():addHours(7):toString("%T")})
    
    
    -- end 
    -- end
    

    local stock = order:getInstrument():getShortName()
    local find_string = string.match(stock,"-R" or"-U")
    if (find_string == "-R")then
    local num = 2
    table.insert(depositItem,{'TTF',num})
    end
    if(find_string == "-U")then
    local num = 3
    table.inser(depositItem,{'TTF',num})
    end
    
    if(order:hasTradingChannel()) then
          --table.insert (orderItem, {'market',order:getExchange():getName()})
          print("Trading Channel : "..order:getTradingChannel():getName())
          table.insert (depositItem,{'Channel',order:getTradingChannel():getName()})
    end
    
    
    print("Entry Date : "..order:getEntryTime():getDateInUtcOffset(common.offsetTimeZoneSecs):toString("%d/%m/%Y"))
    table.insert (depositItem,{'Entry_date',order:getEntryTime():getDateInUtcOffset(common.offsetTimeZoneSecs):toString("%d/%m/%Y")})
    
    print("Entry Time : "..order:getEntryTime():addHours(7):toString("%T"))
    table.insert (depositItem,{'Entry_time',order:getStatusChangeTime():addHours(7):toString("%T")})
    
    print("===============================================================================================")
    table.insert (depositList, depositItem)
    end
    end
end
 common.InsertRecords(db_file, log_file, table_name_order, depositList, debug_mode)
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
