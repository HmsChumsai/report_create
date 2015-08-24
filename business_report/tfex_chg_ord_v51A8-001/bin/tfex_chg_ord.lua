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

  --common.CheckValidTimeRange(entryFrom, entryTo)

  local CallForceMapping = {["Call"]="Call", ["Force"]="Force", ["None"]=""}
  local debug_mode = false

  local sql_column_text = ' TEXT DEFAULT "" '
  local sql_column_integer = ' INTEGER DEFAULT 0'
  local sql_column_real = ' REAL DEFAULT 0.0'
  local table_name_order = "ExportedOrders"
  local table_name_deposit = "Decide_deposit"
  local database_tables = {

    {table_name_order, { 'TIME'..sql_column_text,
         'CHGTIME'..sql_column_text,
         'Transactions_status'..sql_column_text,
         'TRADERID'..sql_column_text,
         'CHGTRADERID'..sql_column_text,
         'TRADE'..sql_column_text,
         'ORDERID'..sql_column_text,
         'TFEXORDERNO'..sql_column_text,
         'SIDE'..sql_column_text,
         'POSITION'..sql_column_text,
         'SERIES'..sql_column_text,
         'QTY'..sql_column_integer,
         'OLD_QTY'..sql_column_integer,
         'OLD_PUB'..sql_column_integer,
         'NEW_PUB'..sql_column_integer,
         'NEWPUB'..sql_column_integer,
         'MATCHED_QTY'..sql_column_integer,
         'OLD_PRICE'..sql_column_real,
         'PRICE'..sql_column_real,
         'DEPOSIT'..sql_column_text,
         'mandator'..sql_column_text,
         'CANCELTRADER'..sql_column_text,
         'CANCELTIME'..sql_column_text,
         'NEW_DEPOSIT'..sql_column_text,
         'OLD_DEPOSIT'..sql_column_text,
         'ORDER_STATUS'..sql_column_real,
         'ORDER_STATUS_NEW'..sql_column_real,
         'ORDER_DATE_TIME'..sql_column_text,
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
         'unmatched_qty'..sql_column_integer,
         'Status'..sql_column_real,
         'service_type'..sql_column_real,
         'published'..sql_column_real}}
  }


  common.CreateTables(db_file, log_file,  database_tables, debug_mode)
--------------------------------------------------------------------------------------------------------------------------
  local businesscenter = fo.BusinessCenter("THAILAND")
  local tradingCalendar = businesscenter:getTradingCalendar()
  local entryTo = tradingCalendar:addActiveDays( tim.Date.current(),0, isNONE ):toString("%Y-%m-%dT17:00:00")
  local prevday = tradingCalendar:addActiveDays( tim.Date.current(), -1, isNONE ):toString("%Y-%m-%dT19:30:00")
  local orders = easygetter.GetOrdersByDate( prevday, entryTo )
  
  
  local orderList = {}
  local orderItem = {}

  print("----------------------------------------------------")
  print("-                   Begin Lua                      -")
  print("----------------------------------------------------")
  print("- Mandator : "..mandator.current():getShortName())
 -- print("- Mandatorconfig: "..mand_config) 
  print("- Entry from: "..entryFrom) 
  print("- Entry to: "..entryTo) 
  
  for _,no in pairs( orders ) do
    local order = fo.Order( no )
	 -- print("-* Order no. = "..order:getOrderId())
    for _,opj in pairs( order:getOrderOperations() ) do
    
    
    local Mandator_obj = mandator.current():getShortName()
       table.insert(orderItem,{'mandator',Mandator_obj})
       


      if( order:hasExchange() == true ) then
      local orderExchange = order:getExchange():getName()

      if (opj:getTransactionType() == "Change"  and orderExchange == 'Thailand Future Exchange') then
      local orderlegs = order:getOrderLegs()
      local operationLegs = opj:getOrderOperationLegs()
      local service_type = order:hasTradingChannel()
      if (service_type == true ) then
        table.insert (orderItem, {'service_type',order:getTradingChannel():getName()})
      end

      for i = 1, order:getNumberLegs() do
        orderItem = {}
        local orderLeg = orderlegs[i]
        local orderLeg_op = operationLegs[i]

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
          table.insert(orderItem,{'TFEXORDERNO',order:getExchangeOrderid()})------------*** NEW
          -------------**** NEW

          
          
        local date_local =  order:getEntryTime():getDateInUtcOffset(common.offsetTimeZoneSecs)
        

-------------------------------------------------------------------------------------------------------------------
          for _,op in pairs( order:getOrderOperations() ) do
            if (op:getEntryUserId() ~= nill) then
              table.insert(orderItem,{'CANCELTRADER',op:getEntryUserId()})
            end

          local time_local =  op:getEntryTime():addHours(7)
          table.insert (orderItem, {'ORDER_DATE_TIME',time_local:toString("%T")})
          
          
          
          
          
          local chg_trader_op = op:getEntryUserId()
          table.insert(orderItem,{'TRADE',chg_trader_op})

          if op:getTransactionType() == "Change" then
          
          
          local orderlegs_obj = op:getOrderOperationLegs()
          for i = 1, order:getNumberLegs() do
          local orderLeg_obj = orderlegs_obj[i]
          local chg_time = op:getEntryTime():addHours(7):toString("%T")
                table.insert(orderItem,{'CHGTIME',chg_time})
                table.insert(orderItem,{'NEW_PUB',orderLeg_obj:getPeakQty()})
                local chg_trader = op:getEntryUserId()
                table.insert(orderItem,{'CHGTRADERID',chg_trader})
                if(order:getOrderId() ~= nil )then
                table.insert (orderItem, {'ORDER_STATUS_NEW', order:getCustomStatus()})
                end
                local order_id = order:getOrderId()
            -- if not order_id and (not order or not order:getOrderId()) then
            -- local orderId = order:getOrderId()
            -- table.insert (orderItem, {'ORDER_STATUS_NEW',order:getCustomStatus()})
            print("NEW PUB >>>>>>"..orderLeg_obj:getPeakQty())
       
      -- end
                table.insert(orderItem,{'NEW_DEPOSIT',op:getDeposit():getNumber()})
          end
          end
            
             
             
          if op:getTransactionType() == "Entry" then
             
            
              local orderlegs_obj = op:getOrderOperationLegs()
             for i = 1, order:getNumberLegs() do
             orderItem = {}
             local orderLeg_obj = orderlegs_obj[i]
             local qty_obj = orderLeg_obj:getOpenQty()
             table.insert (orderItem, {'OLD_QTY', qty_obj})
             local price_obj = orderLeg_obj:getPriceLimit()
             table.insert(orderItem,{'OLD_PRICE',price_obj})
             table.insert(orderItem,{'OLD_DEPOSIT',op:getDeposit():getNumber()})
             table.insert(orderItem,{'OLD_PUB',orderLeg_obj:getPeakQty()})
             print("OLD PUB >>>>>>"..orderLeg_obj:getPeakQty())
             table.insert (orderItem, {'ORDER_STATUS', M.getStatus(order:getOrderId())})
             end
          end
            
            
            
            
            
          local order_status = order:getStatus()
          if(order_status == "Closed" or order_status == "Rejected") then
                 local order_Operationtype = order:getLastOperationType()
                   if (order_Operationtype == "Cancel") then
                    local get_time = order:getStatusChangeTime():addHours(7):toString("%T")
                       table.insert(orderItem,{'CANCELTIME',get_time})
              end
              end
          end

          local STLCon_obj = order:hasStopContract()
          if( STLCon_obj == true ) then
              table.insert(orderItem,{'STOP_CONTRACT',order:getStopContract():getContractCode()})
          end
          
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
        ---------------------------------------------------------------------------------------------------------------
        local date_local =  order:getEntryTime():getDateInUtcOffset(common.offsetTimeZoneSecs)
        local time_local =  order:getEntryTime():addHours(7)
        table.insert (orderItem, {'TIME',time_local:toString("%T")})
        
        local order_id = order:getOrderId()
        table.insert (orderItem, {'ORDERID', order_id})
        local order_deposit = order:getDeposit():getNumber()
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
         
         
         table.insert(orderItem,{'Transactions_status',opj:getTransactionType()})
         
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
        table.insert(orderItem,{'TRADERID',order:getEntryUserId()})
        -- local trader_id = dubi.getSETTraderId( account_manager:getShortName())
        -- if( trader_id ~= nill) then
          -- table.insert (orderItem, {'TRADERID', trader_id })
        -- end
        end
        print("Order number"..order:getOrderId())
        
        local order_price_limit = tostring(orderLeg:getPriceLimit() or '')
        local order_limit_type = tostring(order:getOrderLimitType() or '')
          table.insert (orderItem, {'PRICE', order_price_limit})
        local tradeDate = order:getEntryTime():getDateInUtcOffset(offsetTimeZoneSecs):toString("%d/%m/%Y")
          table.insert (orderItem, {'trade_date', tradeDate})



        table.insert (orderList, orderItem)
      end
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
