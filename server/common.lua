ESX = {}
ESX.Players = {}
ESX.UsableItemsCallbacks = {}
ESX.Items = {}
ESX.ServerCallbacks = {}
ESX.TimeoutCount = -1
ESX.CancelledTimeouts = {}
ESX.Pickups = {}
ESX.PickupId = 0
ESX.Jobs = {}
ESX.RegisteredCommands = {}

AddEventHandler('esx:getSharedObject', function(cb)
	cb(ESX)
end)

function getSharedObject()
	return ESX
end

MySQL.ready(function()
	MySQL.Async.fetchAll('SELECT * FROM items', {}, function(result)
		for k,v in ipairs(result) do
			ESX.Items[v.name] = {
				label = v.label,
				limit = v.limit,
				rare = v.rare,
				canRemove = v.can_remove
			}
		end
	end)
	MySQL.Async.fetchAll('SELECT * FROM jobs', {}, function(jobs)
		for k,v in ipairs(jobs) do
			ESX.Jobs[v.name] = v
			ESX.Jobs[v.name].grades = {}
		end
		MySQL.Async.fetchAll('SELECT * FROM job_grades', {}, function(jobGrades)
			for k,v in ipairs(jobGrades) do
				if ESX.Jobs[v.job_name] then
					ESX.Jobs[v.job_name].grades[tostring(v.grade)] = v
				else
					print(('[^4Luciano Base^7] [^3Warning^7] Job Grade ^4%s^7 Not Found.'):format(v.job_name))
				end
			end
			for k2,v2 in pairs(ESX.Jobs) do
				if ESX.Table.SizeOf(v2.grades) == 0 then
					ESX.Jobs[v2.name] = nil
					print(('[^4Luciano Base^7] [^3Warning^7] Job ^4%s^7 Not Found.'):format(v2.name))
				end
			end
		end)
	end)
end)

RegisterServerEvent('esx:clientLog')
AddEventHandler('esx:clientLog', function(msg)
	if Config['EnableDebug'] then
		print(('[^4Luciano Base^7] [^2TRACE^7] %s^7'):format(msg))
	end
end)

RegisterServerEvent('esx:triggerServerCallback')
AddEventHandler('esx:triggerServerCallback', function(name, requestId, ...)
	local playerId = source
	ESX.TriggerServerCallback(name, requestId, playerId, function(...)
		TriggerClientEvent('esx:serverCallback', playerId, requestId, ...)
	end, ...)
end)
