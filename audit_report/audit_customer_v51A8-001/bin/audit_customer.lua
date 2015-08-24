require "ocs"

local cmdln = require "cmdline"
local fo = require "fo"
local tim = require "tim"
local maps = require "maps"
local mandator = require "mandator"
local utils = require "utils"
local depositId = ""
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

local infile=os.getenv("LOGINLOGOUT_CSV_FILE") -- Config here

cmdln.parse( arg, true )

print("Start!!!!: " )
print("DB File is "..db_file)
print("Log File :"..log_file)

ocs.createInstance( "LUA" )


local function process()

  print("begin process")

  local dubi = require "dubi"
  local common = require "common"
  local confirmreport = require "confirmreport"
  local customerAuditUtils = require "customerAuditUtils"
  local debug_mode = false

-- =============================================================================
-- Insert Process code here (Create DB File).
-- =============================================================================

  local sql_column_text = ' TEXT DEFAULT "" '
  
  local table_name_client= "DECIDE_client"
  local table_name_deposit = "DECIDE_deposit"
  local table_name_ovl = "DECIDE_ovl"
  local database_tables = {
    {table_name_client, {

    'field' .. sql_column_text,
    'value_old' .. sql_column_text,
    'value_new' .. sql_column_text,
    'client_id'..sql_column_text,
    'client_number' .. sql_column_text,
    'client_name' .. sql_column_text,
    --'deposit_id' .. sql_column_text,
    'user_id' .. sql_column_text,
    'time' .. sql_column_text,
    }},
  }
 client_name_cache = {}

  customerAuditUtils.query() 
  local audit_table = customerAuditUtils.audit_table
  local clients = customerAuditUtils.getTable(audit_table,'clients')
  local deposits = customerAuditUtils.getTable(audit_table,'deposits')  
  local ovls = customerAuditUtils.getTable(audit_table,'lim_ordvol')  
  --local ovlList = getOvlDb(ovls)
  --local clientList = getClientDb(clients)
  local clientList={}
  getClientDb(clients,clientList)
  getDepositDb(deposits,clientList)
  getOvlDb(ovls,clientList)
  print("Before Create TB")
  common.CreateTables(db_file,log_file,database_tables,debug_mode)
  common.InsertRecords(db_file, log_file, table_name_client, clientList, debug_mode)
  --common.reportFinish()
  --common.setNumRecord(#clientList)






-- =============================================================================

end
function getDepositDb(deposits,clientList)
  local table_deposit_mapping = {}
-- table_deposit_mapping['accntmasternr']='
  table_deposit_mapping['accountmanager']={'Account Manager',getAccountManager}
  table_deposit_mapping['accountstatus']='Account Status'
  table_deposit_mapping['accounttype']='Responsibility'
-- table_deposit_mapping['accounttypenr']='
-- table_deposit_mapping['aenderungsdatlo']='
-- table_deposit_mapping['approve_credit']='
-- table_deposit_mapping['asset_category']='
-- table_deposit_mapping['balitemnr']='
-- table_deposit_mapping['banknummer']='
-- table_deposit_mapping['buch_methode']='
  table_deposit_mapping['calc_mon_yn']='Money Calculation'
-- table_deposit_mapping['clearingktotype']='
-- table_deposit_mapping['clearingnr']=''
-- table_deposit_mapping['client_routing']='
  table_deposit_mapping['clientfeecat2']={'Client Fee Category 2',getClientFeeDesc}
  table_deposit_mapping['clientfeecat3']={'Client Fee Category 3',getClientFeeDesc}
  table_deposit_mapping['clientfeecat4']={'Client Fee Category 4',getClientFeeDesc}
  table_deposit_mapping['clientfeecat5']={'Client Fee Category 5',getClientFeeDesc}
  table_deposit_mapping['clientfeecatnr']={'Client Fee Category 1',getClientFeeDesc}
-- table_deposit_mapping['clientnummer']=/'
  table_deposit_mapping['clienttypenr']='Client Type'
-- table_deposit_mapping['cnt_alloc_quantity']='
-- table_deposit_mapping['cnt_order_quantity']='
-- table_deposit_mapping['date_prereq']='
-- table_deposit_mapping['dep_yn']='
-- table_deposit_mapping['depositclass']='
-- table_deposit_mapping['depotkey']='
-- table_deposit_mapping['depotkey_m']='
  table_deposit_mapping['depotname']='Name'
-- table_deposit_mapping['depotnummer']='
  table_deposit_mapping['description']='Description'
-- table_deposit_mapping['editcomment']='
-- table_deposit_mapping['editstatus']='
  table_deposit_mapping['feecalcbase']='Order Commission on'
-- table_deposit_mapping['flat_tax_deposit']='
-- table_deposit_mapping['genled_waeart']='
  table_deposit_mapping['keep_positions']='Keep Positions'
-- table_deposit_mapping['lastedit_person']='
-- table_deposit_mapping['lasteditor']='
-- table_deposit_mapping['mandatornr']='
  table_deposit_mapping['net_settlement']='Net Settlement'
-- table_deposit_mapping['portfolionr']='
  table_deposit_mapping['remark']='Remark'
-- table_deposit_mapping['settlement_curr']='
-- table_deposit_mapping['sw_active']='
  table_deposit_mapping['sw_balancecheck']='Balance Check'
  table_deposit_mapping['sw_best_abgl']='Reconciliation'
-- table_deposit_mapping['sw_exec_market']='
-- table_deposit_mapping['sw_force_settlecurr']='
-- table_deposit_mapping['sw_inet_trading']='
  table_deposit_mapping['sw_ordscreen']='Order/Screening'
-- table_deposit_mapping['sw_pflicht_portf']='
  table_deposit_mapping['sw_poslimcheck']='Check Pos.Limits'
-- table_deposit_mapping['sw_prereq']='
  table_deposit_mapping['sw_sl_netting']='Short/Long position netting'
  table_deposit_mapping['trdprofilenr']={'Trading Profile',getTradingProfile}
-- table_deposit_mapping['userid']='


  for _,deposit in pairs(deposits) do
    local client_id= deposit['clientnummer']
    local client_obj= fo.Client(tonumber(client_id))
    local user_id = deposit['userid'][2] or deposit['userid']
    local log_time = deposit['aenderungsdatlo'][2] or deposit['aenderungsdatlo']
    local time = tim.TimeStamp(log_time):addHours(7):toString("%T")
    local client_name =''
   	print("client_obj:getName()",client_obj:getName())
    if type(client_name_cache[client_id]) ~= 'string' then
      client_name = client_obj:getName()
      client_name_cache[client_id]=client_name
    else 
      client_name=client_name_cache[client_id]
    end
    
    for field,data in pairs(deposit) do
      if type(data) == 'table' then
        local clientItem = {}
        table.insert(clientItem,{'client_number',client_id})
        table.insert(clientItem,{'client_id',tostring(client_obj)})
        table.insert(clientItem,{'client_name',client_name})
        table.insert(clientItem,{'time',time})
        table.insert(clientItem,{'user_id',user_id})
        if type(table_deposit_mapping[field]) == 'string' then
          table.insert(clientItem,{'field',table_deposit_mapping[field]})
          table.insert(clientItem,{'value_old',data[1]})
          table.insert(clientItem,{'value_new',data[2]})
          table.insert(clientList,clientItem)
        -- value store as code,need mapping
        elseif type(table_deposit_mapping[field]) == 'table' then
          local func = table_deposit_mapping[field][2]
          table.insert(clientItem,{'field',table_deposit_mapping[field][1]})
          table.insert(clientItem,{'value_old',func(data[1])})
          table.insert(clientItem,{'value_new',func(data[2])})
          table.insert(clientList,clientItem)
        end
      end
    end
  end
end
function getClientDb(clients,clientList)
  --print("mapping ",name)
  local table_client_mapping = {}
  table_client_mapping['clientanrede']='Salutation'
  table_client_mapping['clienttitel']='Title'
  table_client_mapping['clientname']='Name'
  table_client_mapping['clientvnamie']='First Name'
  table_client_mapping['alternative_name']='Alternative Name'
  table_client_mapping['landnr']='Country'
  table_client_mapping['clientstrasse']='Street'
  table_client_mapping['clientplz']='ZIP Code / City'
  table_client_mapping['clienttelefon']='Phone/Fax'
  table_client_mapping['remark']='Remark'
  table_client_mapping['clienttypenr']='Type'
  table_client_mapping['accountmanager']={'Account Manager',getAccountManager}
  table_client_mapping['clientfeecat2']={'Client Fee Category 2',getClientFeeDesc}
  table_client_mapping['clientfeecat3']={'Client Fee Category 3',getClientFeeDesc}
  table_client_mapping['clientfeecat4']={'Client Fee Category 4',getClientFeeDesc}
  table_client_mapping['clientfeecat5']={'Client Fee Category 5',getClientFeeDesc}
  table_client_mapping['clientfeecatnr']={'Client Fee Category 1',getClientFeeDesc}
  table_client_mapping['marginlimit']='Margin Limit'
  table_client_mapping['marginmult']='Factor'
  table_client_mapping['marginmult2']='Factor 2'
  table_client_mapping['nostrojn']='Prop'
  table_client_mapping['accntcalc']='Money Calculation'
  table_client_mapping['mpcjn']='Market Price Check'

  for _,client in pairs(clients) do
    local modified_flag = false
    local temp ={}
    local client_id = client['clientnummer']
    local client_obj = fo.Client(tonumber(client_id))
    local user_id = client['userid'][2] or client['userid']
    local log_time = client['aenderungsdatlo'][2] or client['aenderungsdatlo']
    local time = tim.TimeStamp(log_time):addHours(7):toString("%T")
    local client_name = ''
		if type(client_name_cache[client_id]) ~= 'string' then
      client_name = client_obj:getName()
      client_name_cache[client_id]=client_name
    else
			print("Cache! : ,",client_name)
      client_name=client_name_cache[client_id]
    end

    local deposit_id = client_obj:getDeposits()
    for field,data in pairs(client) do
      --local field = ''
      local label = ''
			local value_old = ''
      local value_new = ''
      if type(data) == 'table' then --for modified record
        modified_flag=true
        insertClientItem(clientList,table_client_mapping)
       
      elseif modified_flag~=true then -- for newly created record
				
        local clientItem = {}
				if type(table_client_mapping[field])=="string" then
						table.insert(clientItem,{'client_number',client_id})
						table.insert(clientItem,{'client_id',tostring(client_obj)})
						table.insert(clientItem,{'client_name',client_name})
						table.insert(clientItem,{'time',time})
						table.insert(clientItem,{'user_id',user_id})
						table.insert(clientItem,{'field',table_client_mapping[field]})
						table.insert(clientItem,{'value_old',data})
						table.insert(temp,clientItem)
				end
			end
			--if modified_flag == false then print(utils.prettystr(temp)) end
    end
		if modified_flag~=true then
			for _,seq in pairs(temp) do
				print("seq")
				print(utils.prettystr(seq))
				table.insert(clientList,seq)
				--table.insert(clientList,seq)			
			end
		end--print(utils.prettystr(temp))
  end
end
function getOvlDb(ovls,clientList)
  local table_ovl_mapping = {}
--    table_ovl_mapping['aenderungsdatlo=
  table_ovl_mapping['alert_percentage']='Threshold'
  table_ovl_mapping['buysell']='Buy/Sell'
--    table_ovl_mapping['ca_calc=
--    table_ovl_mapping['calculation=
--    table_ovl_mapping['call_amount_prev=
--    table_ovl_mapping['call_force_prev=
--    table_ovl_mapping['check_ca=
--    table_ovl_mapping['check_ee=
--    table_ovl_mapping['clientnummer=
  table_ovl_mapping['credit_line']='Credit Line'
  table_ovl_mapping['cutoff_fee_buy']='Cutoff Fee Buy'
  table_ovl_mapping['cutoff_fee_sell']='Cutoff Fee Sell'
--    table_ovl_mapping['cutoff_vol_buy=
--    table_ovl_mapping['cutoff_vol_sell=
--    table_ovl_mapping['dec_sectype=
--    table_ovl_mapping['deletetime=
--    table_ovl_mapping['deleteuser=
--    table_ovl_mapping['depotkey=
--    table_ovl_mapping['entrydatlo=
--    table_ovl_mapping['entrydattz=
--    table_ovl_mapping['entryuserid=
--    table_ovl_mapping['eq_bal_prev=
--    table_ovl_mapping['ex_eq_bal_prev=
  table_ovl_mapping['extravalue']='Deposit/Withdrawal'
--    table_ovl_mapping['fmr_prev=
--    table_ovl_mapping['foreign_coll=
--    table_ovl_mapping['handlingtype=
--    table_ovl_mapping['imr_prev=
--    table_ovl_mapping['include_fees=
--    table_ovl_mapping['include_upl=
  table_ovl_mapping['instruclusternr']='Instrument Cluster'
--    table_ovl_mapping['instrumentnr
  table_ovl_mapping['kommentar']='Remark'
--    table_ovl_mapping['lim_ordvolnr=
  table_ovl_mapping['limit']='Limit'
--    table_ovl_mapping['limitclass=
--    table_ovl_mapping['mandatornr=
--    table_ovl_mapping['margintaskname=
--    table_ovl_mapping['margintasknr=
--    table_ovl_mapping['misc_long=
--    table_ovl_mapping['misc_short=
--    table_ovl_mapping['mmr_prev=
--    table_ovl_mapping['mtm_fut_prev=
--    table_ovl_mapping['non_cash_coll=
--    table_ovl_mapping['ordvollimtype=
--    table_ovl_mapping['portfolionr=
--    table_ovl_mapping['reftimedatlo=
--    table_ovl_mapping['reftimedattz=
  table_ovl_mapping['reject_action']='Reject Action'
  table_ovl_mapping['sw_lim_ap']='Status'
--    table_ovl_mapping['tradenr=
--    table_ovl_mapping['upl_gr_opt_prev=
--    table_ovl_mapping['userid=
--    table_ovl_mapping['withheld_adjust=

  for _,ovl in pairs(ovls) do
    
    local client_id = ovl['clientnummer']
    local client_obj = fo.Client(tonumber(client_id))
    local log_time = ovl['aenderungsdatlo'][2] or ovl['aenderungsdatlo']
    local time = tim.TimeStamp(log_time):addHours(7):toString("%T")
    local user_id = ovl['userid'][2] or ovl['userid']
    if client_name_cache[client_id] == 'nil' then
      client_name = client_obj:getName()
      client_name_cache[client_id]=client_name
    else 
      client_name=client_name_cache[client_id]
    end
    
    for field,data in pairs(ovl) do
      if type(data) == 'table' then
        if type(table_ovl_mapping[field]) == 'string' then
          local clientItem = {}
          table.insert(clientItem,{'client_number',client_id})
          table.insert(clientItem,{'client_id',tostring(client_obj)})
          table.insert(clientItem,{'client_name',client_name})
          --table.insert(clientItem,{'deposit_id',tostring(deposit_id)})
          table.insert(clientItem,{'time',time})
          table.insert(clientItem,{'user_id',user_id})
          table.insert(clientItem,{'field',table_ovl_mapping[field]})
          table.insert(clientItem,{'value_old',data[1]})
          table.insert(clientItem,{'value_new',data[2]})
          table.insert(clientList,clientItem)
        end
      end
    end 
  end
end

function insertClientItem(clientList,table_client_mapping)

  local clientItem = {}
  table.insert(clientItem,{'client_number',client_id})
  table.insert(clientItem,{'client_id',tostring(client_obj)})
  table.insert(clientItem,{'client_name',client_name})
  table.insert(clientItem,{'time',time})
  table.insert(clientItem,{'user_id',user_id})
  if type(table_client_mapping[field]) == 'string' then
    table.insert(clientItem,{'field',table_client_mapping[field]})
    table.insert(clientItem,{'value_old',data[1]})
    table.insert(clientItem,{'value_new',data[2]})
    table.insert(clientList,clientItem)
    -- value store as code,need mapping
  elseif type(table_client_mapping[field]) == 'table' then
    local func = table_client_mapping[field][2]
    table.insert(clientItem,{'field',table_client_mapping[field][1]})
    table.insert(clientItem,{'value_old',func(data[1])})
    table.insert(clientItem,{'value_new',func(data[2])})
    table.insert(clientList,clientItem)
  end
end

function getClientFeeDesc(clientFeeCat)
  return clientFeeCat
  --local feeDesc = ''
  --local fee= fo.ClientFeeCategory(tonumber(clientFeeCat))
  --if type(fee) ~= 'nil' then
  --  feeDesc=fee:getName()
  --end
  --return feeDesc
end

function getAccountManager(userid)
  local user = fo.User(tonumber(userid))
  if type(user) == 'nil' then return userid end
  local person = user:getPerson()
    local trader_name = person:getName()
    return trader_name or userid
end

function getTradingProfile(id)
  local desc = ''
  local tradingProfile = fo.TradingProfile(tonumber(id))
  if type(tradingProfile) == 'nil' then return '' end
  desc = tradingProfile:getName()
  print('tradingProfile' .. desc)
  return desc
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
