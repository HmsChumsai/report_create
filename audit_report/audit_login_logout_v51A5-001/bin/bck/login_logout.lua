require "ocs"

local cmdln = require "cmdline"
local mandator = require "mandator"
local tim = require "tim"
local maps = require "maps"

local log_file = ""
local db_file = ""

-- =============================================================================
-- Read Configuration
-- =============================================================================

cmdln.add{ name="--logFile", descr="", func=function(x) log_file=x end }
cmdln.add{ name="--dbFile", descr="", func=function(x) db_file=x end }

-- =============================================================================
local infile=os.getenv("LOGINLOGOUT_CSV_FILE")


cmdln.parse( arg, true )

print("Start!!!!: " )
print("DB File is "..db_file)
print("Log File :"..log_file)

ocs.createInstance( "LUA" )


local function process()

  print("begin process")

  local common = require "common"
  local confirmreport = require "confirmreport"
  local utils = require "CSVUtil"

  local debug_mode = false

-- =============================================================================
-- Insert Process code here (Create DB File).
-- =============================================================================
  local sql_column_text = ' TEXT DEFAULT "" '
  
  local table_name_logs = "DECIDE_logs"
  local database_tables = {
    {table_name_logs, {'USER_ID'..sql_column_text,
    'CHANNEL'..sql_column_text,
    'USER_NAME'..sql_column_text,
    'SET_ID'..sql_column_text,
    'TIME'..sql_column_text,
    'STATUS'..sql_column_text,
    'SERVER_IP'..sql_column_text,
    'CLIENT_IP'..sql_column_text,
    }}
  }

  print("Before Create TB")
  --common.CreateTables(db_file,log_file,database_tables,debug_mode)
  common.CreateTables(db_file, log_file,  database_tables, debug_mode)

  print("After Create TB")
  local logList={}
  local file = infile
  if not file_exists(file) then return {} end
  for line in io.lines(file) do 
    local log ={}
    local logItem={}
    for word in string.gmatch(line,'([^,]+)') do
      log[#log+1]=word
    end
    table.insert(logItem,{'USER_ID',log[1]})
    table.insert(logItem,{'CHANNEL',log[2]})
    table.insert(logItem,{'USER_NAME',log[3]})
    table.insert(logItem,{'SET_ID',log[4]})
    table.insert(logItem,{'TIME',log[5]})
    table.insert(logItem,{'STATUS',log[6]})
    table.insert(logItem,{'SERVER_IP',log[7]})
    table.insert(logItem,{'CLIENT_IP',log[8]})
    table.insert(logList,logItem)
  end
  print("logListi :",dump(logList))
  common.InsertRecords(db_file, log_file, table_name_logs, logList, debug_mode)
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
