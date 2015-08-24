local orderConfirmUtil={}
local fo = require "fo"
local tim = require "tim"
local easygetter = require "easygetter"
function getStopCond(order)
	local stopTypes = {
		StopMarket = true,
		StopLimit = true,
		StopIceberg = true,
		StopSpecialMarket = true,
		StopMarketToLimit = true
	}
	local type = order:getOrderLimitType()
	if stopTypes[type] then
		return order:getStopCondition()
	else
		return ''
	end
end

function getValid(order)
	local orderRest = order:getOrderRestrictionType()
  if orderRest == "None" then
		return order:getValidityType()
  else
	  return orderRest
  end
end

function getPrevDay ()
	local businesscenter = fo.BusinessCenter("THAILAND")
	local tradingCalendar = businesscenter:getTradingCalendar()
	local prevday=tradingCalendar:addActiveDays( tim.Date.current(), -1, isNONE ):toString("%Y-%m-%dT19:30:00")
	return prevday
end

function test()
	return "test"
end

function orderConfirmUtil.getHeader()


end


function orderConfirmUtil.getAllOrders(headerList)
  local headerItem = {}
	print("============= GET ALL ORDERS ==========")
	local businesscenter = fo.BusinessCenter("THAILAND")
	local tradingCalendar = businesscenter:getTradingCalendar()
	local prevday = tradingCalendar:addActiveDays( tim.Date.current(), -1, isNONE )
	local orders = easygetter.GetOrdersByDate( prevday:toString("%Y-%m-%dT19:30:00"), entryTo )
	print("============= End GET ALL ORDERS ==========")
	table.insert(headerItem,{'trade_date',prevday:toString("%d/%m/%Y")})
  table.insert(headerItem,{'broker',mandator.current():getShortName()})
  table.insert(headerList,headerItem)

  return orders

end



function orderConfirmUtil.getDetailList(orders)
	print("============= GET ORDER Details ==========")
	local orderList={}
	local dealList={}
	for _,no in pairs(orders) do
		
		local order = fo.Order(no)
		local orderHandlingType = order:getHandlingType()
		
		if (orderHandlingType == 'TradingOrder') then
			local dealItem={}
			local orderOperations = order:getOrderOperations()
			getDealInfo(orderOperations,dealList,no)
			local orderlegs = order:getOrderLegs()
			--print("Order No. : ",no)
			--print("No . of orderlegs : ",#order:getOrderLegs())
			for i=1,order:getNumberLegs() do
				local trade_no = ''
        local deal_no=''
        local deal_qty = 0
        local deal_price = 0.0
        local deal_time = ''	
				local stop_series = ''
				local stop_condition= ''
				local stop_price = 0
        local valid_date=''
        local orderLeg=orderlegs[i]
				local orderItem={}
				local side=common.BuySellToBSMapping[orderLeg:getOrderKind()]
				local position_obj = orderLeg:getOpenClose()
				local position = orderLeg:getOpenClose()
				
				if (position_obj == 'Open') then
					position='O'
				else 
					position='C'
				end
				
				local contract = orderLeg:getContract()--fo.Contract(series)
				local series= contract:getContractCode()--orderLeg:getContract():getContractCode()
				
				local ce = fo.ContractEvaluation{ contract=contract }
				local price = ce:getLastUnchecked()
				local deposit = order:getDeposit()
				--local deposit = tostring(order:getDeposit())
				local ord_st = order:getStatus()

				local qty = orderLeg:getTotalQty()
				local matched = orderLeg:getExecQty()
				local trader_id = order:getApprovalUser()
				local ord_time = order:getEntryTime():toString("%T")
				local valid = getValid(order)
				
				
        if order:hasStopContract() then
				  stop_series = order:getStopContract():getContractCode()
				  stop_condition=getStopCondition(order)
				  stop_price = orderLeg:getStopLimit()
			  end
        
				table.insert(orderItem,{'order_no',no})
				table.insert(orderItem,{'side',side})
				table.insert(orderItem,{'position',position})
				table.insert(orderItem,{'series',series})
				table.insert(orderItem,{'qty',qty})
				table.insert(orderItem,{'mathced',matched})
				table.insert(orderItem,{'price',price})
				table.insert(orderItem,{'ord_time',ord_time})
				table.insert(orderItem,{'trader_id',trader_id})
				table.insert(orderItem,{'deposit',tostring(deposit)})
				table.insert(orderItem,{'ord_st',ord_st})
				table.insert(orderItem,{'trade_no',trade_no})
				table.insert(orderItem,{'valid',valid})
				table.insert(orderItem,{'valid_date',valid_date})
				table.insert(orderItem,{'stop_series',stop_series})
				table.insert(orderItem,{'stop_price',stop_price})
				table.insert(orderItem,{'stop_condition',stop_condition})
        
        ---------------------------------------------------------
        ---- Account inquiry optimization needed----------------
        getAccountDetail(deposit,orderItem)
        
        table.insert(orderList,orderItem)
			end
		end
	end
	return orderList,dealList
end

function getAccountDetail(deposit,orderItem)
  
  local DECIDE_deposit_obj = deposit 
  if DECIDE_deposit_obj:hasAccountType() then

    local acc_type = DECIDE_deposit_obj:getAccountType():getName()
    table.insert(orderItem,{'account_type',acc_type})
  
  end

  local acc_name = DECIDE_deposit_obj:getName()
  table.insert(orderItem,{'account_name',acc_name})
  
  local client = DECIDE_deposit_obj:getClient()
  if client:hasClientType() then
    client_type = client:getClientType():getName()
    table.insert(orderItem,{'client_type',client_type})
  end
  if (client:hasAccountManager()) then
    local user = client:getAccountManager()
    local trader_id = user:getShortName()
    local person = user:getPerson()
    local trader_name = person:getName()
    table.insert(orderItem,{'trader_name',trader_name})    
    table.insert(orderItem,{'trader_id',trader_id})
  end
  
end

function getDealInfo(orderOperations,dealList,orderNo)
	local deal_seq=0
	for _,op in pairs( orderOperations ) do
		if op:getTransactionType() ~= "Entry" then 
			--print("Deal operation type () : ",op:getTransactionType())
			local opLegs=op:getOrderOperationLegs()
			for _,opLeg in pairs (opLegs) do
				deal_seq=deal_seq+1
				local dealItem = {}
				local order_no = orderNo
				local deal_qty = opLeg:getExecQty()
				local deal_price = opLeg:getPrice()
				local deal_time = op:getEntryTime():addHours(7):toString("%T")
				if opLeg:hasTransaction() then
					local ta_no = opLeg:getEffectiveTransaction():getTaNrExchange() -- eg. TN-2-1431578607208-1;DN_76_2015-05-14_10630_119
					local i,j = string.find(ta_no,";")
          local deal_no = string.sub(ta_no,j+1)
          ta_no = string.sub(ta_no,1,i-1)
          table.insert(dealItem,{'trade_no',ta_no})
          table.insert(dealItem,{'deal_no',deal_no})
				end
				table.insert(dealItem ,{'order_no',order_no})	
				table.insert(dealItem ,{'deal_price',deal_price})
				table.insert(dealItem ,{'deal_qty',deal_qty})
				table.insert(dealItem ,{'deal_time',deal_time})
				table.insert(dealList,dealItem)
			
			end
		end
	end
end

function getDeposit(depositId)
	local DECIDE_deposit_obj = fo.Deposit( tonumber(depositId) )
	local depositList,depositItem={}
	
--	table.insert(depositItem,{'credit_type',
	table.insert(depositItem,{'customer_type',DECIDE_deposit_obj:getAccountType():getName()})
	table.insert(depositList,depositItem)
	return depositList
end

return orderConfirmUtil
