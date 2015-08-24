require "ocs"

local cmdln = require "cmdline"
fo = require "fo"
local tim = require "tim"
local maps = require "maps"
local accpos = require "accpos"
local mandator = require "mandator"
local rtutils = require "rtutils"

local depositId = ""
local entryFrom = ""
local entryTo = ""
local log_file = ""
local db_file = ""
local format = "PDF"

cmdln.add{ name="--logFile", descr="", func=function(x) log_file=x end }
cmdln.add{ name="--dbFile", descr="", func=function(x) db_file=x end }
cmdln.add{ name="--depositid", descr="", func=function(x) depositId=x end }
--cmdln.add{ name="--format", descr="", func=function(x) format=x end }
cmdln.add{ name="--from", descr="", func=function(x) entryFrom=x end }
cmdln.add{ name="--to", descr="",  func=function(x) entryTo=x end }

cmdln.parse( arg, true )
print("depositId: " .. depositId)
print("entryFrom: " .. entryFrom)
print("entryTo: " .. entryTo)
print("log_file: " .. log_file)
print("db_file: " .. db_file)
print("format: " .. format)

ocs.createInstance( "LUA" )

function process()
  
  local dubi = require "dubi"
  local common = require "common"
  local easygetter = require "easygetter"
  local confirmreport = require "confirmreport"
  local debug_mode = false
  local orderMatchStatusToMLMapping = {[true]="M", [false]="P"}
  local TSCReportUtil= require "TSCReportUtil"
  --local table_name_deposit = "deposit"
  --local table_name_order = "DECIDE_order"

  common.CheckValidTimeRange(entryFrom, entryTo)

  local database_tables = {}
  table_name_deposit = "deposit"
  table_name_order = "DECIDE_order"
  table_name_total = "DECIDE_total"
	table_name_port = "DECIDE_port"
	table_name_set = "DECIDE_set"
	table_name_set50 = "DECIDE_set50"
	local depositList = {}
	local orderList = {}
	local totalList = {}
	local portList = {}
	local setList={}
	local set50List={}
	entryFrom = TSCReportUtil.checkBusDate(entryFrom)
	local handleAfc = true
	local orders = TSCReportUtil.GetOrders( depositId, entryFrom, entryTo ,handleAfc )
	--local orders = easygetter.GetOrders( depositId, entryFrom, entryTo )
	local setItem=getMarketData('SET')
	local set50Item=getMarketData('SET50')
	
	table.insert(setList,setItem)
	table.insert(set50List,set50Item)

  DECIDE_deposit_obj = fo.Deposit( tonumber(depositId) )
	depositList = getDeposit(depositId)
  orderList,totalList = TSCReportUtil.getOrderList(orders)
	portList = getPortList()
	database_tables = CreateSchema()
	common.CreateTables(db_file, log_file,  database_tables, debug_mode)
	common.InsertRecords(db_file, log_file, table_name_total, totalList, debug_mode)
	common.InsertRecords(db_file, log_file, table_name_deposit, depositList, debug_mode)
	common.InsertRecords(db_file, log_file, table_name_order, orderList, debug_mode)
	common.InsertRecords(db_file, log_file, table_name_port, portList, debug_mode)
	common.InsertRecords(db_file, log_file, table_name_set,setList,debug_mode)
	common.InsertRecords(db_file, log_file, table_name_set50,set50List,debug_mode)
end

function CreateSchema()
	print('--------------Start CreateSchema() -------------- ')
	local sql_column_text = ' TEXT DEFAULT "" '
  local sql_column_integer = ' INTEGER DEFAULT 0'
  local sql_column_real = ' REAL DEFAULT 0.0'
  local database_tables = {
  {table_name_deposit,{'account_no' .. sql_column_text,
	'account_name' .. sql_column_text,
	'account_type' .. sql_column_text,
  'trader_name' .. sql_column_text,
	'date' .. sql_column_text,
	'settlement' .. sql_column_text,
	}},
  {table_name_order,{
	'seq' .. sql_column_integer,
  'order_no' .. sql_column_integer,
	'side' .. sql_column_text,
  'stock' .. sql_column_text,
  'vol' .. sql_column_integer,
  'price' .. sql_column_real,
  'gross_amt' .. sql_column_real,
  'comm_fee' .. sql_column_real,
  'vat' .. sql_column_real,
  'amount_due' .. sql_column_real,
	'ttf' .. sql_column_text,
  }},
	{table_name_port,{
	'seq' .. sql_column_integer,
  	'stock' .. sql_column_text,
	'tff' .. sql_column_text,
	'pos' .. sql_column_integer,
	'avg_price' .. sql_column_real,
	'mkt_price' .. sql_column_real,
	'amount' .. sql_column_real,
	'mkt_value' .. sql_column_real,
	'pl' .. sql_column_real,
	'ttf' .. sql_column_text,
	}},
  {table_name_total,{'comm' ..sql_column_real,
  'total_amount_due' .. sql_column_real,
  'total_gross' .. sql_column_real,
  'vat' ..sql_column_real,
  'net' .. sql_column_real,
  'paid_received' .. sql_column_text
  }},
	{table_name_set,{'SET_close' .. sql_column_real,
	'SET_change' .. sql_column_real,
	'SET_val' .. sql_column_real

	}},
	{table_name_set50,{'SET50_close' .. sql_column_real,
	'SET50_change' .. sql_column_real,
	'SET50_val' .. sql_column_real
	}},
	}
	print ('----------------- End CreateSchema ---------------') 
  return database_tables
end

function getDeposit(depositId)
	print('----------- Start getDeposit --------')
	local depositItem = {}
	local depositList={}
	local clientName = TSCReportUtil.getClientName(DECIDE_deposit_obj)
  table.insert (depositItem, {'account_no', DECIDE_deposit_obj:getNumber()})
  table.insert (depositItem, {'account_name', clientName})
  if (DECIDE_deposit_obj:hasAccountType()) then
  	table.insert (depositItem, {'account_type', DECIDE_deposit_obj:getAccountType():getName() })
	end

	local trader_name = TSCReportUtil.getTraderName(DECIDE_deposit_obj)
  table.insert(depositItem,{'trader_name',trader_name})
	--local am = rtutils.getAccountManager(DECIDE_deposit_obj) 
  --if am then
  --	table.insert(depositItem,{'trader_name',am:getName()})
	--end
	
 	local reportDate = tim.TimeStamp(entryFrom):toString("%d.%m.%y")
	--reportDate = time.Date(reportDate)
	--tim.Date(entryFrom)
	local nextDate,settlement = getNextBusDate(tim.Date(reportDate))
	table.insert(depositItem,{'date',nextDate})
	table.insert(depositItem,{'settlement',settlement})
	table.insert(depositList,depositItem)


	
  print('----------- End getDeposit ---------')
	return depositList
end

function getPortList()
	local global_seq = 0
	local port_seq = {}
	local ttfMapping={}
	ttfMapping['TTF']=1
	ttfMapping['NVDR']=2
	print("----------------- Start getPortList ------------------")
	local portList = {}
	local position_list = DECIDE_deposit_obj:getAccPositions()
	for _,position in pairs ( position_list ) do
		--local data = accpos.getPositionValues( position, tim.TimeStamp.current() , tim.TimeStamp.current(), DECIDE_deposit_obj:getGeneralLedgerCurrencyType() )
	  --print("data.effective : ",data.effective)	
		--if ( data.effective == "Yes" ) then 
    	--local pos = fo.Position(position)
      local portItem = {}
      local ok, pe = pcall(fo.PositionEvaluation, {
        position = position,
        plview = plview,plrefdate = plref
        })
      local ce = pe:getContractEvaluation()  
      local symbol=ce:getContract():getSymbol()
			local ttf = ce:getContract():getInstrument():getProductCategory()
      --fo.getOrderContract(order):getSymbol() 
      local contract = position:getContract()
			local stock = contract:getContractCode()
			--local ce = fo.ContractEvaluation{ contract=contract }
			local mkt_price = ce:getLastUnchecked()
			local pos = pe:getQuantity() 
			local avg_price = pe:getAvgePriceNet() 
			local amount=pe:getPosBookValue()
			print("amount",amount)
			local ok, mkt_value = pcall( pe.getLiqMarketValue, pe )
			mkt_value = ok and mkt_value or 0
      local pl = ok and mkt_value-amount or 0
			
			print("mkt_value",mkt_value)
				
			if pos > 0 then  -- Filters data 
				local seq = ''
				if type(port_seq[symbol]) == 'nil' then
					global_seq =global_seq + 1
					seq=global_seq
					port_seq[symbol]='existed'
				end
	  			table.insert(portItem,{'pos',pos})
	        	table.insert(portItem,{'stock',symbol})
	  			table.insert(portItem,{'amount',amount})
	  			table.insert(portItem,{'mkt_price',mkt_price})
	        	table.insert(portItem,{'mkt_value',mkt_value})
	        	table.insert(portItem,{'avg_price',avg_price})
	        	table.insert(portItem,{'pl',pl})
	        	table.insert(portItem,{'ttf',ttfMapping[ttf]} or '')
	  			table.insert(portList,portItem)
      end
			--end
		end
	print("----------------- End getPortList ------------------")
  return portList
end

function getPrevDay()
	local businesscenter = fo.BusinessCenter("THAILAND")
	local tradingCalendar = businesscenter:getTradingCalendar()
	local prevday = tradingCalendar:addActiveDays( tim.Date.current(), -1, isNONE ):toString("%d.%m.%Y")
	return prevday

end

function getMarketData(index)
	local market = {}
	local contract = fo.Contract(index)
	--local ce = fo.ContractEvaluation{contract="SET" }
	local ce = fo.ContractEvaluation{ contract=contract,"Period Date" }
	local close = ce:getLastUnchecked()
	local val = ce:getTotalTurnover()
	local close  = ce:getLast()
	--local change= ce:getChangeNet()

	local ok,change= pcall(ce.getChangeNet,ce)
	change = ok and change or 0
	table.insert(market,{index..'_close',close}) -- append index name to Avoid data collide
	table.insert(market,{index..'_val',val})
	table.insert(market,{index..'_change',change})
	return market
end

--function getFee(order, orderLeg, ut)
--  local fee = 0
--	for _, execution in ipairs(order:getEffectiveExecutions(ut)) do
--    local leg = execution:getOrderLeg(ut)
--    if leg:getOrder() == order and leg:getLegIndex() == orderLeg:getLegIndex() then
--      local data = execution:getData(ut)
--      fee = fee + math.abs(data.amountp:asDouble() - data.netAmountP:asDouble())
--		end
--  end
--  return fee
--end

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
local inst = os.getenv( "OCSINST" )
local mand = mandator.Mandator( inst )
mandator.changeTo( mand, process )
