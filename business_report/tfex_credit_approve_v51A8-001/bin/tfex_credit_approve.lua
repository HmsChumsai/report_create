require "ocs"

local cmdln = require "cmdline"
local mandator = require "mandator"

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

  local common = require "common"
  local debug_mode = false
	local sql_column_text = ' TEXT DEFAULT "" '
-- =============================================================================
-- Insert Process code here (Create DB File).
-- =============================================================================
	local table_name_dummy = 'dummy'
	local database_tables = {
	{table_name_dummy,{
	'dummy_field' ..sql_column_text,
	}},
	}
	local dummy = {}
  table.insert(dummy,{'dummy_field',''}) 
  local dummyList={}
  table.insert(dummyList,dummy)
	common.CreateTables(db_file, log_file,  database_tables, debug_mode)
	common.InsertRecords(db_file, log_file, table_name_dummy, dummyList, debug_mode)



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
