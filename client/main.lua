local isDead = false

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)
		if NetworkIsPlayerActive(PlayerId()) then
			exports.spawnmanager:setAutoSpawn(false)
			DoScreenFadeOut(0)
			TriggerServerEvent('esx:onPlayerJoined')
			break
		end
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.PlayerLoaded = true
	ESX.PlayerData = playerData
	if GetEntityModel(PlayerPedId()) == GetHashKey('PLAYER_ZERO') then
		local defaultModel = GetHashKey('a_m_y_stbla_02')
		RequestModel(defaultModel)
		while not HasModelLoaded(defaultModel) do
			Citizen.Wait(10)
		end
		SetPlayerModel(PlayerId(), defaultModel)
		SetPedDefaultComponentVariation(PlayerPedId())
		SetPedRandomComponentVariation(PlayerPedId(), true)
		SetModelAsNoLongerNeeded(defaultModel)
	end
	FreezeEntityPosition(PlayerPedId(), true)
	SetCanAttackFriendly(PlayerPedId(), true, false)
	NetworkSetFriendlyFireOption(true)
	ClearPlayerWantedLevel(PlayerId())
	SetMaxWantedLevel(0)
	ESX.Game.Teleport(PlayerPedId(), {
		x = playerData.coords.x,
		y = playerData.coords.y,
		z = playerData.coords.z + 0.25,
		heading = playerData.coords.heading
	}, function()
		TriggerServerEvent('esx:onPlayerSpawn')
		TriggerEvent('esx:onPlayerSpawn')
		TriggerEvent('playerSpawned')
		TriggerEvent('esx:restoreLoadout')
		ShutdownLoadingScreen()
		ShutdownLoadingScreenNui()
		DoScreenFadeIn(3000)
		StartServerSyncLoops()
	end)
	TriggerEvent('esx:loadingScreenOff')
	local elements = {
		{label = "ยืนยัน <strong class='blue-text'>ตัวละคร</strong> โหลดเสร็จแล้ว", value = 'submit'}
	}
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'protect', {
		title    = 'ระบบ [ ยืนยันเพื่อเข้าเกมส์ ]',
		align    = 'center',
		elements = elements
	}, function(data,menu)
		if data.current.value == 'submit' then
			menu.close()
			FreezeEntityPosition(PlayerPedId(),false)
		end
	end, function(data,menu)
		menu.close()
		FreezeEntityPosition(PlayerPedId(),false)
	end)
end)

AddEventHandler('esx:onPlayerSpawn', function() 
	isDead = false 
end)

AddEventHandler('esx:onPlayerDeath', function() 
	isDead = true 
end)

AddEventHandler('skinchanger:modelLoaded', function()
	while not ESX.PlayerLoaded do
		Citizen.Wait(100)
	end
	TriggerEvent('esx:restoreLoadout')
end)

AddEventHandler('esx:restoreLoadout', function()
	local playerPed = PlayerPedId()
	local ammoTypes = {}
	RemoveAllPedWeapons(playerPed, true)
	for k,v in ipairs(ESX.PlayerData.loadout) do
		local weaponName = v.name
		local weaponHash = GetHashKey(weaponName)
		GiveWeaponToPed(playerPed, weaponHash, 0, false, false)
		SetPedWeaponTintIndex(playerPed, weaponHash, v.tintIndex)
		local ammoType = GetPedAmmoTypeFromWeapon(playerPed, weaponHash)
		for k2,v2 in ipairs(v.components) do
			local componentHash = ESX.GetWeaponComponent(weaponName, v2).hash
			GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
		end
		if not ammoTypes[ammoType] then
			AddAmmoToPed(playerPed, weaponHash, v.ammo)
			ammoTypes[ammoType] = true
		end
	end
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
	for k,v in ipairs(ESX.PlayerData.accounts) do
		if v.name == account.name then
			ESX.PlayerData.accounts[k] = account
			break
		end
	end
end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(item, count, showNotification)
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			ESX.UI.ShowInventoryItemNotification(true, v.label, count - v.count)
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(item, count, showNotification)
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			ESX.UI.ShowInventoryItemNotification(false, v.label, v.count - count)
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

RegisterNetEvent('esx:addWeapon')
AddEventHandler('esx:addWeapon', function(weaponName, ammo)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	GiveWeaponToPed(playerPed, weaponHash, ammo, false, false)
end)

RegisterNetEvent('esx:addWeaponComponent')
AddEventHandler('esx:addWeaponComponent', function(weaponName, weaponComponent)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash
	GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
end)

RegisterNetEvent('esx:setWeaponAmmo')
AddEventHandler('esx:setWeaponAmmo', function(weaponName, weaponAmmo)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	SetPedAmmo(playerPed, weaponHash, weaponAmmo)
end)

RegisterNetEvent('esx:setWeaponTint')
AddEventHandler('esx:setWeaponTint', function(weaponName, weaponTintIndex)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	SetPedWeaponTintIndex(playerPed, weaponHash, weaponTintIndex)
end)

RegisterNetEvent('esx:removeWeapon')
AddEventHandler('esx:removeWeapon', function(weaponName)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	RemoveWeaponFromPed(playerPed, weaponHash)
	SetPedAmmo(playerPed, weaponHash, 0)
end)

RegisterNetEvent('esx:removeWeaponComponent')
AddEventHandler('esx:removeWeaponComponent', function(weaponName, weaponComponent)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash
	RemoveWeaponComponentFromPed(playerPed, weaponHash, componentHash)
end)

RegisterNetEvent('esx:teleport')
AddEventHandler('esx:teleport', function(coords)
	local playerPed = PlayerPedId()
	coords.x = coords.x + 0.0
	coords.y = coords.y + 0.0
	coords.z = coords.z + 0.0
	ESX.Game.Teleport(playerPed, coords)
end)

RegisterNetEvent('esx:spawnVehicle')
AddEventHandler('esx:spawnVehicle', function(vehicleName)
	local model = (type(vehicleName) == 'number' and vehicleName or GetHashKey(vehicleName))
	if IsModelInCdimage(model) then
		local playerPed = PlayerPedId()
		local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)
		ESX.Game.SpawnVehicle(model, playerCoords, playerHeading, function(vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		end)
	else
		exports['mythic_notify']:SendAlert('error', 'Invalid Vehicle Model.', 5000)
	end
end)

RegisterNetEvent('esx:registerSuggestions')
AddEventHandler('esx:registerSuggestions', function(registeredCommands)
	for name,command in pairs(registeredCommands) do
		if command.suggestion then
			TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
		end
	end
end)

RegisterNetEvent('esx:deleteVehicle')
AddEventHandler('esx:deleteVehicle', function(radius)
	local playerPed = PlayerPedId()
	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(playerPed), radius)
		for k,entity in ipairs(vehicles) do
			local attempt = 0
			while not NetworkHasControlOfEntity(entity) and attempt < 100 and DoesEntityExist(entity) do
				Citizen.Wait(100)
				NetworkRequestControlOfEntity(entity)
				attempt = attempt + 1
			end
			if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
				ESX.Game.DeleteVehicle(entity)
			end
		end
	else
		local vehicle, attempt = ESX.Game.GetVehicleInDirection(), 0
		if IsPedInAnyVehicle(playerPed, true) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		end
		while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
			Citizen.Wait(100)
			NetworkRequestControlOfEntity(vehicle)
			attempt = attempt + 1
		end
		if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
			ESX.Game.DeleteVehicle(vehicle)
		end
	end
end)

function StartServerSyncLoops()
	if Config['SyncAmmo'] then
		Citizen.CreateThread(function()
			local currentWeapon = { Ammo = 0 }
			while ESX.PlayerLoaded do
				local sleep = 1500
				if GetSelectedPedWeapon(ESX.PlayerData.ped) ~= -1569615261 then
					sleep = 1000
					local _, weaponHash = GetCurrentPedWeapon(ESX.PlayerData.ped, true)
					local weapon = ESX.GetWeaponFromHash(weaponHash)
					if weapon then
						local ammoCount = GetAmmoInPedWeapon(ESX.PlayerData.ped, weaponHash)
						if weapon.name ~= currentWeapon.name then
							currentWeapon.Ammo = ammoCount
							currentWeapon.name = weapon.name
						else
							if ammoCount ~= currentWeapon.Ammo then
								currentWeapon.Ammo = ammoCount
								TriggerServerEvent('esx:updateWeaponAmmo', weapon.name, ammoCount)
							end
						end
					end
				end
				Citizen.Wait(sleep)
			end
		end)
	end
end