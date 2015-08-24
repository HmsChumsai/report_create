require "ocs"

local cmdln = require "cmdline"
local fo = require "fo"
local tim = require "tim"
local maps = require "maps"
local mandator = require "mandator"
local dubi = require "dubi"
local yalb = require("yalb")
local maps = require("maps")
local pd = require "pd"
local accpos = require "accpos"
local easygetter = require "easygetter"
local utils = require "utils"

local log_file = ""
local db_file = ""

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

  local confirmreport = require "confirmreport"
  local common = require "common"
  local debug_mode = false

-- =============================================================================
-- Insert Process code here (Create DB File).
-- =============================================================================

  local CallForceMapping = {["Call"]="Call", ["Force"]="Force", ["None"]=""}

  local sql_column_text = ' TEXT DEFAULT "" '
  local sql_column_integer = ' INTEGER DEFAULT 0'
  local sql_column_real = ' REAL DEFAULT 0.0'
  local table_name_deposit = "decide_deposit"
  local table_name_position = "decide_position"
  local table_name_port = "decide_port"

  local database_tables = {
  {table_name_deposit,{
  'broker' .. sql_column_text,
  'deposit_id' .. sql_column_text,
  'deposit_name' .. sql_column_text,
  'trader_id' .. sql_column_text,
  'trader_name' .. sql_column_text,
  'cust_type' .. sql_column_text,

  }},
  {table_name_position, {
  'deposit_id' .. sql_column_text,
  's' .. sql_column_text,
  'series' .. sql_column_text,
  'sellable_qty' .. sql_column_real,
  'mark_avg' .. sql_column_real,
  'last' .. sql_column_real,
  'unreal' .. sql_column_real,
  'total_upl' .. sql_column_real,
  }},
  {table_name_port, {
  'deposit_id' .. sql_column_text,
  'margin_balance' .. sql_column_real,
  'cash_balance' .. sql_column_real,
  'unreal_margin_balnace' .. sql_column_real,
  'ee_balance' .. sql_column_real,
  'equity_balance' .. sql_column_real,
  'before_cash' .. sql_column_real,
  'after_cash' .. sql_column_real
  }}
  }
  local context = {}
  local cache = {}
  local deposits = getAllDeposit()
  local portList={}
  local positionList={}
  local depositList={}
  proc(deposits,depositList,portList,positionList,context)  -- Process All records
  common.CreateTables(db_file, log_file,  database_tables, debug_mode)
  common.InsertRecords(db_file, log_file, table_name_port, portList, debug_mode)
  common.InsertRecords(db_file, log_file, table_name_deposit, depositList, debug_mode)
  common.InsertRecords(db_file, log_file, table_name_position, positionList, debug_mode)

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

function proc(deposits,depositList,portList,positionList,context)

  for _,deposit in pairs(deposits) do

    local depositItem = {}
    local DEPOSIT_obj = fo.Deposit(deposit)
    context['DEPOSIT_obj']=DEPOSIT_obj
    local client = DEPOSIT_obj:getClient()
    local client_name =tostring(client)
    if string.sub(client_name,1,1)=='D' then
      depositItem = getDepositItem(DEPOSIT_obj,client,client_name)
      table.insert(depositList,depositItem)
      local positions = DEPOSIT_obj:getAccPositions()
      getPositionList(positions,context,positionList)
      local portfolio = DEPOSIT_obj:getPortfolioId()
      if portfolio ~= nil then getPortList(DEPOSIT_obj:getNumber(),portList,portfolio) end
    end
  end  
end

function getPortList(deposit_id,portList,portfolio)
  --local portList = {}
  local portItem = {}
  local orderVolumeLimit, orderVolumeRisk = getOVL(portfolio)
  --local orderVolLimit = easygetter.GetFirstActiveOVL(depositId)
  if ( orderVolumeLimit ~= nil ) then
    -- Source : accountinfomationextended 
    --local orderVolumeRisk = orderVolLimit:getUniqueRisk()
    local margin_balance = orderVolumeRisk:getPositionMargin()
    local cash_balance = easygetter.EvenAmountToDouble(orderVolumeRisk:getCashBalance())
    local unreal_margin_balnace = easygetter.EvenAmountToDouble(orderVolumeRisk:getExpectedMargin())
    local ee_balance = easygetter.EvenAmountToDouble(orderVolumeRisk:getExcessEquityBalance())
    local equity_balance = easygetter.EvenAmountToDouble(orderVolumeRisk:getEquityBalance())
    
    local cf = orderVolumeRisk:getCallForce()

    local callForceFlagPrev = maps.CallForceToGui(orderVolumeLimit:getPreviousCallForce())
    local callForceFlagCurr = maps.CallForceToGui(cf)
    
    local callAmountCurr = ""
    if cf == "Call" then
      callAmountCurr = easygetter.EvenAmountToDouble(orderVolumeRisk:getCallAmount())--val(orderVolumeRisk:getCallAmount())
    elseif cf == "Force" then
      callAmountCurr = easygetter.EvenAmountToDouble(orderVolumeRisk:getForceAmount())--val(orderVolumeRisk:getForceAmount())
    end
    local before_cash = callForceFlagPrev.."/"..easygetter.EvenAmountToDouble(orderVolumeLimit:getPreviousCallAmount())--val(orderVolumeLimit:getPreviousCallAmount())
    local after_cash = callForceFlagCurr.."/"..callAmountCurr
    table.insert (portItem, {'deposit_id',deposit_id })
    table.insert (portItem, {'cash_balance',cash_balance })
    table.insert (portItem, {'margin_balance',cash_balance })
    table.insert (portItem, {'unreal_margin_balnace',unreal_margin_balnace })
    table.insert (portItem, {'ee_balance',ee_balance })
    table.insert (portItem, {'equity_balance',equity_balance })
    table.insert (portItem, {'before_cash',before_cash })
    table.insert (portItem, {'after_cash',after_cash })
		print(utils.prettystr(portItem))
    table.insert(portList,portItem)
  end
end

function getDepositItem(deposit,client,client_name)
  -- body

  --print("-----------get Deposititem-------------------")
  local depositItem= {}
  local client = deposit:getClient()
  local client_name =tostring(client)

  local deposit_id = deposit:getNumber()
  local deposit_name = deposit:getName()
  if client:hasClientType() then 
    local client_type = client:getClientType()
    local cust_type = client_type:getName()
    table.insert(depositItem,{'cust_type',cust_type})
  end
  local broker = mandator.current():getShortName()
  local trader_id = '-'
  local trader_name = '-'

  if client:hasAccountManager() == true then

    local user = client:getAccountManager()
    local person = user:getPerson()
    trader_id = person:getShortName()
    trader_name = user:getName()
  end

  table.insert(depositItem,{'broker',broker})
  table.insert(depositItem,{'deposit_id',deposit_id})
  table.insert(depositItem,{'deposit_name',deposit_name})
  table.insert(depositItem,{'trader_id',trader_id})
  table.insert(depositItem,{'trader_name',trader_name})


  return depositItem
end

function getPositionList(positions,context,positionList)
  --print("-----------getPositionList-------------------")
  --print(utils.prettystr(positions))
  --local positionList = {}
  local getGeneralLedgerCurrencyType =  context['DEPOSIT_obj']:getGeneralLedgerCurrencyType()
  for _,position in pairs(positions) do
    
    local positionItem = {}
    local contract=position:getContract()
    local series = contract:getContractCode()
    local s=position:getShortLong()
    local ok, pe = pcall( fo.PositionEvaluation, { position=position, plview="latest" } )
 
    if ok then

      local ce = pe:getContractEvaluation()
      local instrument = ce:getContract():getInstrument()
      local exchange = instrument:getPrimaryExchange():getShortName()
      --print("Enchange :",exchange)
      if exchange ~='TFEX' then return end
      --print("Continue ")
      local last =ce:getLastUnchecked()
      --local last = easygetter.EvenAmountToDouble(data.LastUnchecked)
      local mark_avg = pe:getAvgePrice()
      local sellable_qty = pe:getAvailableQuantity()
      local unreal = getUPL(pe)
      local total_upl = pe:getTplGrossMZ()
      local deposit_id = context['DEPOSIT_obj']:getNumber()
      --print('deposit_id',deposit_id)
      table.insert(positionItem,{'deposit_id',deposit_id})
      table.insert(positionItem,{'series',series})
      table.insert(positionItem,{'s',s})
      table.insert(positionItem,{'last',last})
      table.insert(positionItem,{'mark_avg',mark_avg})
      table.insert(positionItem,{'sellable_qty',sellable_qty})
      table.insert(positionItem,{'unreal',unreal})
      table.insert(positionItem,{'total_upl',total_upl})
      --print("positionItem",utils.prettystr(positionItem))
    end

    table.insert(positionList,positionItem)
  end
  --print(utils.prettystr(positionList))
  --return positionList
end
function getAllDeposit()
  local deposits =  dubi.getDeposits(options)
  return deposits
end
function getUPL(pe)

  local ok, peUPL = pcall(pe.getUplGrossMZ,pe )
  --print('upl ok :',ok)
  return ok and pe:getUplGrossMZ() or nil
end

function val(val)
  if type(val) == "evenQuantity" or type(val) == "amount::EvenQuantity" or type(val) == "evenAmount" or type(val) == "amount::EvenAmount" then
    return val:isValid() and val:asDouble() or yalb.Error
  else
    return val or yalb.Error
  end
end

function getOVL(portfolio)
  local orderVolumeLimit, orderVolumeRisk
  local sqlLim = string.format("lim_ordvol where ordvollimtype='TotalTurnover' and sw_lim_ap='Active'" .. " and portfolionr=%s", portfolio)
  local lim = pd.get(sqlLim)[1]
  if not lim then
  else
    orderVolumeLimit = fo.OrderVolumeLimit(lim.lim_ordvolnr)
    local sqlRisk = string.format("risk_ordvol where lim_ordvolnr=%s", lim.lim_ordvolnr)
    local risk = pd.get(sqlRisk)[1]
    if not risk then
    else
      orderVolumeRisk = fo.OrderVolumeRisk(risk.risk_ordvolnr)
    end
  end
  return orderVolumeLimit,orderVolumeRisk
end

local inst = os.getenv( "RPT_BROKER" )
local mand = mandator.Mandator( inst)
mandator.changeTo( mand, process )
