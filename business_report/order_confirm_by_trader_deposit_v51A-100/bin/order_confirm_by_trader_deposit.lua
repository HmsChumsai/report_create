require "ocs"

local cmdln = require "cmdline"
fo = require "fo"
local tim = require "tim"
local maps = require "maps"
local easygetter = require "easygetter"
mandator = require "mandator"
local utils = require "utils"
local cmdln = require "cmdline"
local mandator = require "mandator"

local mand_config = ""
local entryFrom = ""
local entryTo = ""
local log_file = ""
local db_file = ""
local format = "PDF"

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
  local dubi = require "dubi"
  local common = require "common"
  local debug_mode = false

-- =============================================================================
-- Insert Process code here (Create DB File).
-- =============================================================================
 local M = require "customOrderData"
  local orderConfirmUtil= require "orderConfirmUtil"
  print("orderConfirmUtil",orderConfirmUtil)
  local CallForceMapping = {["Call"]="Call", ["Force"]="Force", ["None"]=""}
  local debug_mode = false

  local sql_column_text = ' TEXT DEFAULT "" '
  local sql_column_integer = ' INTEGER DEFAULT 0'
  local sql_column_real = ' REAL DEFAULT 0.0'
  local table_name_order = "ExportedOrders"
  local table_name_deposit = "Decide_deposit"
  local table_name_deal = "Decide_deal"
  local table_name_header = "Decide_header"
  local database_tables = {
    {table_name_order, { 'order_no'..sql_column_text,
    'side'..sql_column_text,
    'position'..sql_column_text,
    'series'..sql_column_text,
    'qty'..sql_column_integer,
    'mathced'..sql_column_real,
    'price'..sql_column_real,
    'ord_time'..sql_column_text,
    'trader_id'..sql_column_text,
    'deposit'..sql_column_text,
    'ord_st'..sql_column_text,
    'trade_no'..sql_column_text,
    'valid'..sql_column_text,
    'valid_date'..sql_column_text,
    'stop_series'..sql_column_text,
    'stop_price'..sql_column_real,
    'stop_condition'..sql_column_text,
    -------------------------- Not required by OrderConfirmReport ------------------
    'account_name' .. sql_column_text,
    'account_type' .. sql_column_text,
    'client_type' .. sql_column_text,
    'trader_name' .. sql_column_text,
    }},
    {table_name_deal,{
    'order_no'..sql_column_text,    
    'deal_no'..sql_column_integer,
    'deal_qty'..sql_column_integer,
    'deal_price'..sql_column_real,
    'deal_time'..sql_column_text,
    'trade_no'..sql_column_text,

    }},
    {table_name_header,{
    'broker' .. sql_column_text,
    'trade_date'..sql_column_text,
    }},
  }
  local headerList = {}
  local orders = orderConfirmUtil.getAllOrders(headerList)
  --easygetter.GetOrdersByDate( prevday, entryTo )
  local orderList,dealList= orderConfirmUtil.getDetailList(orders)
  --print("database_tables : ",utils.prettystr(database_tables))
  print("Header List : ",utils.prettystr(headerList))
  common.CreateTables(db_file, log_file,  database_tables, debug_mode)
  common.InsertRecords(db_file, log_file, table_name_order, orderList, debug_mode)
  common.InsertRecords(db_file, log_file, table_name_deal, dealList, debug_mode)
  common.InsertRecords(db_file, log_file, table_name_header, headerList, debug_mode)
  




















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
