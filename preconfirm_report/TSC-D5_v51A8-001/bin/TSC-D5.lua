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
  local TSCReportUtil = require "TSCReportUtil"
  --local table_name_deposit = "deposit"
  --local table_name_order = "DECIDE_order"

  common.CheckValidTimeRange(entryFrom, entryTo)

  local database_tables = {}
	
  table_name_deposit = "deposit"
  table_name_order = "DECIDE_order"
  table_name_total = "DECIDE_total"
	local depositList = {}
	local orderList = {}
	local totalList = {}
	entryFrom = TSCReportUtil.checkBusDate(entryFrom)
	local handleAfc = true
	local orders = TSCReportUtil.GetOrders( depositId, entryFrom, entryTo ,handleAfc )
	depositList = getDeposit(depositId)
	--orderList,totalList = getOrderList(orders)
	orderList,totalList = TSCReportUtil.getOrderList(orders,0)
	database_tables = CreateSchema()
	common.CreateTables(db_file, log_file,  database_tables, debug_mode)
	common.InsertRecords(db_file, log_file, table_name_total, totalList, debug_mode)
	common.InsertRecords(db_file, log_file, table_name_deposit, depositList, debug_mode)
	common.InsertRecords(db_file, log_file, table_name_order, orderList, debug_mode)
  
  common.reportFinish()
  common.setNumRecord(#depositList)
	
end

function CreateSchema()
	print('--------------Start CreateSchema() -------------- ')
	local sql_column_text = ' TEXT DEFAULT "" '
  local sql_column_integer = ' INTEGER DEFAULT 0'
  local sql_column_real = ' REAL DEFAULT 0.0'
--  local table_name_deposit = "deposit"
--  local table_name_order = "DECIDE_order"
--  local table_name_total = "DECIDE_total"
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
	'ttf' .. sql_column_text,
  'vat' .. sql_column_real,
  'amount_due' .. sql_column_real
  }},
  {table_name_total,{'comm' ..sql_column_real,
  'total_amount_due' .. sql_column_real,
  'total_gross' .. sql_column_real,
  'vat' ..sql_column_real,
  'net' .. sql_column_real,
  'paid_received' .. sql_column_text
  }}
	}
  return database_tables
end

function getDeposit(depositId)
	print('----------- Start getDeposit --------')
	local depositItem = {}
	local depositList={}
  local DECIDE_deposit_obj = fo.Deposit( tonumber(depositId) )
  local clientName = TSCReportUtil.getClientName(DECIDE_deposit_obj)
  table.insert (depositItem, {'account_no', DECIDE_deposit_obj:getNumber()})
  table.insert (depositItem, {'account_name', clientName})
  if (DECIDE_deposit_obj:hasAccountType()) then
  	table.insert (depositItem, {'account_type', DECIDE_deposit_obj:getAccountType():getName() })
	end
	--local am = rtutils.getAccountManager(DECIDE_deposit_obj)
  --if am then
  --	table.insert(depositItem,{'trader_name',am:getName()})
	--end
	local trader_name = TSCReportUtil.getTraderName(DECIDE_deposit_obj)
  table.insert(depositItem,{'trader_name',trader_name})

	local reportDate = tim.TimeStamp(entryFrom):toString("%d.%m.%y")
	local nextDate,settlement = getNextBusDate(tim.Date(reportDate))
	--local settlement = getNextBusDate(nextDate)
	table.insert(depositItem,{'date',nextDate})
	table.insert(depositItem,{'settlement',settlement})
	table.insert(depositList,depositItem)
	
	return depositList
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
local inst = os.getenv( "RPT_BROKER" )
local mand = mandator.Mandator( inst )
mandator.changeTo( mand, process )
