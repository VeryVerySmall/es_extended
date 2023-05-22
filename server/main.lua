RegisterNetEvent('esx:onPlayerJoined')
AddEventHandler('esx:onPlayerJoined', function()
	if not ESX.Players[source] then
		onPlayerJoined(source)
	end
end)

function onPlayerJoined(playerId)
	local identifier
	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.sub(v, 1, string.len("steam:")) == "steam:" then
			identifier = v
			break
		end
	end
	if identifier then
		if ESX.GetPlayerFromIdentifier(identifier) then
			DropPlayer(playerId, ('There Was An Error Loading Your Character!\nError Code: identifier-active-ingame\n\nThis Error Is Caused By A Player On This Server Who Has The Same Identifier As You Have. Make Sure You Are Not Playing On The Same Steam Account.\n\nYour Steam Identifier: %s'):format(identifier))
		else
			MySQL.Async.fetchScalar('SELECT 1 FROM users WHERE identifier = @identifier', {
				['@identifier'] = identifier
			}, function(result)
				if result then
					loadESXPlayer(identifier, playerId)
				else
					local accounts = {}
					for account,money in pairs(Config['StartingAccountMoney']) do
						accounts[account] = money
					end
					MySQL.Async.execute('INSERT INTO users (accounts, identifier) VALUES (@accounts, @identifier)', {
						['@accounts'] = json.encode(accounts),
						['@identifier'] = identifier
					}, function(rowsChanged)
						loadESXPlayer(identifier, playerId)
					end)
				end
			end)
		end
	else
		DropPlayer(playerId, 'There Was An Error Loading Your Character!\nError Code: identifier-missing-ingame\n\nThe Cause Of This Error Is Not Known, Your Identifier Could Not Be Found.')
	end
end

function loadESXPlayer(identifier, playerId)
	local tasks = {}
	local userData = {
		accounts = {},
		inventory = {},
		job = {},
		loadout = {},
		playerName = GetPlayerName(playerId),
	}
	table.insert(tasks, function(cb)
		MySQL.Async.fetchAll('SELECT accounts, job, job_grade, `group`, loadout, position, inventory FROM users WHERE identifier = @identifier', {
			['@identifier'] = identifier
		}, function(result)
			local job, grade, jobObject, gradeObject = result[1].job, tostring(result[1].job_grade)
			local foundAccounts, foundItems = {}, {}
			-- Accounts
			if result[1].accounts and result[1].accounts ~= '' then
				local accounts = json.decode(result[1].accounts)
				for account,money in pairs(accounts) do
					foundAccounts[account] = money
				end
			end
			for account,label in pairs(Config['Accounts']) do
				table.insert(userData.accounts, {
					name = account,
					money = foundAccounts[account] or Config['StartingAccountMoney'][account] or 0,
					label = label
				})
			end
			-- Job
			if ESX.DoesJobExist(job, grade) then
				jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
			else
				print(('[^4Luciano Base^7] [^3Warning^7] Invalid Job For ^4%s^7 [Job: ^4%s^7, Grade: ^4%s^7]'):format(identifier, job, grade))
				job, grade = 'unemployed', '0'
				jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
			end
			userData.job.id = jobObject.id
			userData.job.name = jobObject.name
			userData.job.label = jobObject.label
			userData.job.grade = tonumber(grade)
			userData.job.grade_name = gradeObject.name
			userData.job.grade_label = gradeObject.label
			userData.job.grade_salary = gradeObject.salary
			userData.job.skin_male = {}
			userData.job.skin_female = {}
			if gradeObject.skin_male then userData.job.skin_male = json.decode(gradeObject.skin_male) end
			if gradeObject.skin_female then userData.job.skin_female = json.decode(gradeObject.skin_female) end
			-- Inventory
			if result[1].inventory and result[1].inventory ~= '' then
				local inventory = json.decode(result[1].inventory)
				for name,count in pairs(inventory) do
					local item = ESX.Items[name]
					if item then
						foundItems[name] = count
					else
						print(('[^4Luciano Base^7] [^3Warning^7] Invalid Item %4%s%7 For ^4%s'):format(name, identifier))
					end
				end
			end
			for name,item in pairs(ESX.Items) do
				local count = foundItems[name] or 0
				table.insert(userData.inventory, {
					name = name,
					count = count,
					label = item.label,
					limit = item.limit,
					usable = ESX.UsableItemsCallbacks[name] ~= nil,
					rare = item.rare,
					canRemove = item.canRemove
				})
			end
			table.sort(userData.inventory, function(a, b)
				return a.label < b.label
			end)
			-- Group
			if result[1].group then
				userData.group = result[1].group
			else
				userData.group = 'user'
			end
			-- Loadout
			if result[1].loadout and result[1].loadout ~= '' then
				local loadout = json.decode(result[1].loadout)
				for name,weapon in pairs(loadout) do
					local label = ESX.GetWeaponLabel(name)
					if label then
						if not weapon.components then weapon.components = {} end
						if not weapon.tintIndex then weapon.tintIndex = 0 end
						table.insert(userData.loadout, {
							name = name,
							ammo = weapon.ammo,
							label = label,
							components = weapon.components,
							tintIndex = weapon.tintIndex
						})
					end
				end
			end
			-- Position
			if result[1].position and result[1].position ~= '' then
				userData.coords = json.decode(result[1].position)
			else
				print('[^4Luciano Base^7] [^3Warning^7] Column ^4position^7 In Table ^4users^7 Is Missing.')
				userData.coords = {x = -269.4, y = -955.3, z = 31.2, heading = 205.8}
			end
			cb()
		end)
	end)
	Async.parallel(tasks, function(results)
		local xPlayer = CreateExtendedPlayer(playerId, identifier, userData.group, userData.accounts, userData.inventory, userData.job, userData.loadout, userData.playerName, userData.coords)
		ESX.Players[playerId] = xPlayer
		TriggerEvent('esx:playerLoaded', playerId, xPlayer)
		xPlayer.triggerEvent('esx:playerLoaded', {
			accounts = xPlayer.getAccounts(),
			coords = xPlayer.getCoords(),
			identifier = xPlayer.getIdentifier(),
			inventory = xPlayer.getInventory(),
			job = xPlayer.getJob(),
			loadout = xPlayer.getLoadout(),
			money = xPlayer.getMoney()
		})
		xPlayer.updateCoords()
		xPlayer.triggerEvent('esx:registerSuggestions', ESX.RegisteredCommands)
		print(('[^4Luciano Base^7] [^2Info^7] Player ^4%s^7 Connected To The Server [ID: ^4%s^7]'):format(xPlayer.getName(), playerId))
	end)
end

AddEventHandler('chatMessage', function(playerId, author, message)
	if message:sub(1, 1) == '/' and playerId > 0 then
		CancelEvent()
		local commandName = message:sub(1):gmatch("%w+")()
		TriggerClientEvent('chat:addMessage', playerId, {args = {'^1SYSTEM', _U('commanderror_invalidcommand', commandName)}})
	end
end)

AddEventHandler('playerDropped', function(reason)
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(playerId)
	if xPlayer then
		TriggerEvent('esx:playerDropped', playerId, reason)
		ESX.SavePlayer(xPlayer, function()
			ESX.Players[playerId] = nil
		end)
	end
end)

RegisterNetEvent('esx:updateCoords')
AddEventHandler('esx:updateCoords', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer then
		xPlayer.updateCoords()
	end
end)

RegisterNetEvent('esx:updateWeaponAmmo')
AddEventHandler('esx:updateWeaponAmmo', function(weaponName, ammoCount)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer then
		xPlayer.updateWeaponAmmo(weaponName, ammoCount)
	end
end)

RegisterNetEvent('esx:giveInventoryItem')
AddEventHandler('esx:giveInventoryItem', function(target, type, itemName, itemCount)
	local playerId = source
	local sourceXPlayer = ESX.GetPlayerFromId(playerId)
	local targetXPlayer = ESX.GetPlayerFromId(target)
	if type == 'item_standard' then
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)
		local targetItem = targetXPlayer.getInventoryItem(itemName)
		if itemCount > 0 and sourceItem.count >= itemCount then
			if targetItem.limit ~= -1 and (targetItem.count + itemCount) > targetItem.limit then
				sourceXPlayer.triggerEvent('mythic_notify:client:SendAlert',{
					text = itemName.label..' ของ '..targetXPlayer.name..' เกินขีดตำกัด.',
					type = 'error',
					length = 5000,
				})
			else
				sourceXPlayer.removeInventoryItem(itemName, itemCount)
                targetXPlayer.addInventoryItem(itemName, itemCount)
			end
		else
			sourceXPlayer.triggerEvent('mythic_notify:client:SendAlert',{
				text = 'ปริมาณไม่ถูกต้อง.',
				type = 'error',
				length = 5000,
			})
		end
	elseif type == 'item_account' then
		if itemCount > 0 and sourceXPlayer.getAccount(itemName).money >= itemCount then
			sourceXPlayer.removeAccountMoney(itemName, itemCount)
			targetXPlayer.addAccountMoney   (itemName, itemCount)
		else
			sourceXPlayer.showNotification(_U('imp_invalid_amount'))
		end
	elseif type == 'item_weapon' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponLabel = ESX.GetWeaponLabel(itemName)
			if not targetXPlayer.hasWeapon(itemName) then
				local _, weapon = sourceXPlayer.getWeapon(itemName)
				local _, weaponObject = ESX.GetWeapon(itemName)
				itemCount = weapon.ammo
				sourceXPlayer.removeWeapon(itemName)
				targetXPlayer.addWeapon(itemName, itemCount)
				if weaponObject.ammo and itemCount > 0 then
					local ammoLabel = weaponObject.ammo.label
					sourceXPlayer.showNotification(_U('gave_weapon_withammo', weaponLabel, itemCount, ammoLabel, targetXPlayer.name))
					targetXPlayer.showNotification(_U('received_weapon_withammo', weaponLabel, itemCount, ammoLabel, sourceXPlayer.name))
				else
					sourceXPlayer.showNotification(_U('gave_weapon', weaponLabel, targetXPlayer.name))
					targetXPlayer.showNotification(_U('received_weapon', weaponLabel, sourceXPlayer.name))
				end
			else
				sourceXPlayer.showNotification(_U('gave_weapon_hasalready', targetXPlayer.name, weaponLabel))
				targetXPlayer.showNotification(_U('received_weapon_hasalready', sourceXPlayer.name, weaponLabel))
			end
		end
	elseif type == 'item_ammo' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponNum, weapon = sourceXPlayer.getWeapon(itemName)
			if targetXPlayer.hasWeapon(itemName) then
				local _, weaponObject = ESX.GetWeapon(itemName)
				if weaponObject.ammo then
					local ammoLabel = weaponObject.ammo.label
					if weapon.ammo >= itemCount then
						sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
						targetXPlayer.addWeaponAmmo(itemName, itemCount)
						sourceXPlayer.showNotification(_U('gave_weapon_ammo', itemCount, ammoLabel, weapon.label, targetXPlayer.name))
						targetXPlayer.showNotification(_U('received_weapon_ammo', itemCount, ammoLabel, weapon.label, sourceXPlayer.name))
					end
				end
			else
				sourceXPlayer.showNotification(_U('gave_weapon_noweapon', targetXPlayer.name))
				targetXPlayer.showNotification(_U('received_weapon_noweapon', sourceXPlayer.name, weapon.label))
			end
		end
	end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(type, itemName, itemCount)
	local playerId = source
	local xPlayer = ESX.GetPlayerFromId(source)
	if type == 'item_standard' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification(_U('imp_invalid_quantity'))
		else
			local xItem = xPlayer.getInventoryItem(itemName)
			if (itemCount > xItem.count or xItem.count < 1) then
				xPlayer.showNotification(_U('imp_invalid_quantity'))
			else
				xPlayer.removeInventoryItem(itemName, itemCount)
			end
		end
	elseif type == 'item_account' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification(_U('imp_invalid_amount'))
		else
			local account = xPlayer.getAccount(itemName)
			if (itemCount > account.money or account.money < 1) then
				xPlayer.showNotification(_U('imp_invalid_amount'))
			else
				xPlayer.removeAccountMoney(itemName, itemCount)
			end
		end
	elseif type == 'item_weapon' then
		itemName = string.upper(itemName)
		if xPlayer.hasWeapon(itemName) then
			local _, weapon = xPlayer.getWeapon(itemName)
			local _, weaponObject = ESX.GetWeapon(itemName)
			local components, pickupLabel = ESX.Table.Clone(weapon.components)
			xPlayer.removeWeapon(itemName)
			if weaponObject.ammo and weapon.ammo > 0 then
				local ammoLabel = weaponObject.ammo.label
				pickupLabel = ('~y~%s~s~ [~g~%s~s~ %s]'):format(weapon.label, weapon.ammo, ammoLabel)
				xPlayer.showNotification(_U('threw_weapon_ammo', weapon.label, weapon.ammo, ammoLabel))
			else
				pickupLabel = ('~y~%s~s~'):format(weapon.label)
				xPlayer.showNotification(_U('threw_weapon', weapon.label))
			end
		end
	end
end)

RegisterNetEvent('esx:useItem')
AddEventHandler('esx:useItem', function(itemName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local count = xPlayer.getInventoryItem(itemName).count
	if count > 0 then
		ESX.UseItem(source, itemName)
	end
end)

ESX.RegisterServerCallback('esx:getPlayerData', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		loadout      = xPlayer.getLoadout(),
		money        = xPlayer.getMoney()
	})
end)

ESX.RegisterServerCallback('esx:getOtherPlayerData', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)
	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		loadout      = xPlayer.getLoadout(),
		money        = xPlayer.getMoney()
	})
end)

ESX.RegisterServerCallback('esx:getPlayerNames', function(source, cb, players)
	players[source] = nil
	for playerId,v in pairs(players) do
		local xPlayer = ESX.GetPlayerFromId(playerId)

		if xPlayer then
			players[playerId] = xPlayer.getName()
		else
			players[playerId] = nil
		end
	end
	cb(players)
end)

ESX.StartDBSync()
ESX.StartPayCheck()