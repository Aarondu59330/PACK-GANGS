ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_phone:registerNumber', 'sinaloa', 'alerte sinaloa', true, true)

TriggerEvent('esx_society:registerSociety', 'sinaloa', 'sinaloa', 'society_sinaloa', 'society_sinaloa', 'society_sinaloa', {type = 'public'})


------------------------ Coffre

RegisterServerEvent('esx_sinaloajob:prendreitems')
AddEventHandler('esx_sinaloajob:prendreitems', function(itemName, count)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local sourceItem = xPlayer.getInventoryItem(itemName)

    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_sinaloa', function(inventory)
        local inventoryItem = inventory.getItem(itemName)

        -- is there enough in the society?
        if count > 0 and inventoryItem.count >= count then

            -- can the player carry the said amount of x item?
            if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
                TriggerClientEvent('esx:showNotification', _source, "quantité invalide")
            else
                inventory.removeItem(itemName, count)
                xPlayer.addInventoryItem(itemName, count)
                TriggerClientEvent('esx:showNotification', _source, 'objet retiré', count, inventoryItem.label)
            end
        else
            TriggerClientEvent('esx:showNotification', _source, "quantité invalide")
        end
    end)
end)


RegisterNetEvent('esx_sinaloajob:stockitem')
AddEventHandler('esx_sinaloajob:stockitem', function(itemName, count)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local sourceItem = xPlayer.getInventoryItem(itemName)

    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_sinaloa', function(inventory)
        local inventoryItem = inventory.getItem(itemName)

        -- does the player have enough of the item?
        if sourceItem.count >= count and count > 0 then
            xPlayer.removeInventoryItem(itemName, count)
            inventory.addItem(itemName, count)
            TriggerClientEvent('esx:showNotification', _source, "objet déposé "..count..""..inventoryItem.label.."")
        else
            TriggerClientEvent('esx:showNotification', _source, "quantité invalide")
        end
    end)
end)


ESX.RegisterServerCallback('esx_sinaloajob:inventairejoueur', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local items   = xPlayer.inventory

    cb({items = items})
end)

ESX.RegisterServerCallback('esx_sinaloajob:prendreitem', function(source, cb)
    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_sinaloa', function(inventory)
        cb(inventory.items)
    end)
end)

ESX.RegisterServerCallback('esx_sinaloajob:getArmoryWeapons', function(source, cb)
	TriggerEvent('esx_datastore:getSharedDataStore', 'society_sinaloa', function(store)
		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end

		cb(weapons)
	end)
end)

ESX.RegisterServerCallback('esx_sinaloajob:addArmoryWeapon', function(source, cb, weaponName, removeWeapon)
	local xPlayer = ESX.GetPlayerFromId(source)

	if removeWeapon then
		xPlayer.removeWeapon(weaponName)
	end

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_sinaloa', function(store)
		local weapons = store.get('weapons') or {}
		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = weapons[i].count + 1
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name  = weaponName,
				count = 1
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)

ESX.RegisterServerCallback('esx_sinaloajob:removeArmoryWeapon', function(source, cb, weaponName)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addWeapon(weaponName, 500)

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_sinaloa', function(store)
		local weapons = store.get('weapons') or {}

		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = (weapons[i].count > 0 and weapons[i].count - 1 or 0)
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name = weaponName,
				count = 0
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)

------------------------------------------------ Intéraction


RegisterServerEvent('esx_sinaloajob:handcuff')
AddEventHandler('esx_sinaloajob:handcuff', function(target)
  TriggerClientEvent('esx_sinaloajob:handcuff', target)
end)

RegisterServerEvent('esx_sinaloajob:drag')
AddEventHandler('esx_sinaloajob:drag', function(target)
  local _source = source
  TriggerClientEvent('esx_sinaloajob:drag', target, _source)
end)

RegisterServerEvent('esx_sinaloajob:putInVehicle')
AddEventHandler('esx_sinaloajob:putInVehicle', function(target)
  TriggerClientEvent('esx_sinaloajob:putInVehicle', target)
end)

RegisterServerEvent('esx_sinaloajob:OutVehicle')
AddEventHandler('esx_sinaloajob:OutVehicle', function(target)
    TriggerClientEvent('esx_sinaloajob:OutVehicle', target)
end)

-------------------------------- Fouiller

RegisterNetEvent('esx_sinaloajob:confiscatePlayerItem')
AddEventHandler('esx_sinaloajob:confiscatePlayerItem', function(target, itemType, itemName, amount)
	local _source = source
	local sourceXPlayer = ESX.GetPlayerFromId(_source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if itemType == 'item_standard' then
		local targetItem = targetXPlayer.getInventoryItem(itemName)
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)

		-- does the target player have enough in their inventory?
		if targetItem.count > 0 and targetItem.count <= amount then

			-- can the player carry the said amount of x item?
			if sourceXPlayer.canCarryItem(itemName, sourceItem.count) then
				targetXPlayer.removeInventoryItem(itemName, amount)
				sourceXPlayer.addInventoryItem   (itemName, amount)
				sourceXPlayer.showNotification(_U('you_confiscated', amount, sourceItem.label, targetXPlayer.name))
				targetXPlayer.showNotification(_U('got_confiscated', amount, sourceItem.label, sourceXPlayer.name))
			else
				sourceXPlayer.showNotification(_U('quantity_invalid'))
			end
		else
			sourceXPlayer.showNotification(_U('quantity_invalid'))
		end

	elseif itemType == 'item_account' then
		local targetAccount = targetXPlayer.getAccount(itemName)

		-- does the target player have enough money?
		if targetAccount.money >= amount then
			targetXPlayer.removeAccountMoney(itemName, amount)
			sourceXPlayer.addAccountMoney   (itemName, amount)

			sourceXPlayer.showNotification(_U('you_confiscated_account', amount, itemName, targetXPlayer.name))
			targetXPlayer.showNotification(_U('got_confiscated_account', amount, itemName, sourceXPlayer.name))
		else
			sourceXPlayer.showNotification(_U('quantity_invalid'))
		end

	elseif itemType == 'item_weapon' then
		if amount == nil then amount = 0 end

		-- does the target player have weapon?
		if targetXPlayer.hasWeapon(itemName) then
			targetXPlayer.removeWeapon(itemName, amount)
			sourceXPlayer.addWeapon   (itemName, amount)

			sourceXPlayer.showNotification(_U('you_confiscated_weapon', ESX.GetWeaponLabel(itemName), targetXPlayer.name, amount))
			targetXPlayer.showNotification(_U('got_confiscated_weapon', ESX.GetWeaponLabel(itemName), amount, sourceXPlayer.name))
		else
			sourceXPlayer.showNotification(_U('quantity_invalid'))
		end
	end
end)

ESX.RegisterServerCallback('esx_sinaloajob:getOtherPlayerData', function(source, cb, target, notify)
	local xPlayer = ESX.GetPlayerFromId(target)

	if notify then
		xPlayer.showNotification('being_searched')
	end

	if xPlayer then
		local data = {
			name = xPlayer.getName(),
			job = xPlayer.job.label,
			grade = xPlayer.job.grade_label,
			inventory = xPlayer.getInventory(),
			accounts = xPlayer.getAccounts(),
			weapons = xPlayer.getLoadout()
		}

		
			data.dob = xPlayer.get('dateofbirth')
			data.height = xPlayer.get('height')

			if xPlayer.get('sex') == 'm' then data.sex = 'male' else data.sex = 'female' end
		

		TriggerEvent('esx_status:getStatus', target, 'drunk', function(status)
			if status then
				data.drunk = ESX.Math.Round(status.percent)
			end
		end)

		
			cb(data)
		
	end
end)