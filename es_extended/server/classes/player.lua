local SetTimeout = SetTimeout
local GetPlayerPed = GetPlayerPed
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading

function CreateExtendedPlayer(playerId, identifier, group, accounts, inventory, weight, job, job2,  job3, loadout, name, coords)
	local targetOverrides = Config.PlayerFunctionOverride and Core.PlayerFunctionOverrides[Config.PlayerFunctionOverride] or {}
	
	local self = {}

	self.accounts = accounts
	self.coords = coords
	self.group = group
	self.identifier = identifier
	self.inventory = inventory
	self.job = job
	self.job2 = job2
	self.job3 = job3
	self.loadout = loadout
	self.name = name
	self.playerId = playerId
	self.source = playerId
	self.variables = {}
	self.weight = weight
	self.maxWeight = Config.MaxWeight
	if Config.Multichar then self.license = 'license'.. identifier:sub(identifier:find(':'), identifier:len()) else self.license = 'license:'..identifier end

	ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.license, self.group))
	
	local stateBag = Player(self.source).state
	stateBag:set("identifier", self.identifier, true)
	stateBag:set("license", self.license, true)
	stateBag:set("job", self.job, true)
	stateBag:set("job2", self.job2, true)
	stateBag:set("job3", self.job3, true)
	stateBag:set("group", self.group, true)
	stateBag:set("name", self.name, true)

	function self.triggerEvent(eventName, ...)
		TriggerClientEvent(eventName, self.source, ...)
	end

	function self.setCoords(coords)
		local Ped = GetPlayerPed(self.source)
		local vector = type(coords) == "vector4" and coords or type(coords) == "vector3" and vector4(coords, 0.0) or
		vec(coords.x, coords.y, coords.z, coords.heading or 0.0)
		SetEntityCoords(Ped, vector.xyz, false, false, false, false)
		SetEntityHeading(Ped, vector.w)
	end

	function self.updateCoords()
		SetTimeout(1000,function()
			local Ped = GetPlayerPed(self.source)
			if DoesEntityExist(Ped) then
				local coords = GetEntityCoords(Ped)
				local distance = #(coords - vector3(self.coords.x, self.coords.y, self.coords.z))
				if distance > 1.5 then
					local heading = GetEntityHeading(Ped)
					self.coords = {
						x = coords.x,
						y = coords.y, 
						z = coords.z, 
						heading = heading or 0.0
					}
				end
			end
			self.updateCoords()
		end)
	end

	function self.getCoords(vector)
		if vector then
			return vector3(self.coords.x, self.coords.y, self.coords.z)
		else
			return self.coords
		end
	end

	function self.kick(reason)
		DropPlayer(self.source, reason)
	end

	function self.setMoney(money)
		money = ESX.Math.Round(money)
		self.setAccountMoney('money', money)
	end

	function self.getMoney()
		return self.getAccount('money').money
	end

	function self.addMoney(money, reason)
		money = ESX.Math.Round(money)
		self.addAccountMoney('money', money, reason)
	end

	function self.removeMoney(money, reason)
		money = ESX.Math.Round(money)
		self.removeAccountMoney('money', money, reason)
	end

	function self.getIdentifier()
		return self.identifier
	end

	function self.setGroup(newGroup)
		ExecuteCommand(('remove_principal identifier.%s group.%s'):format(self.license, self.group))
		self.group = newGroup
		Player(self.source).state:set("group", self.group, true)
		ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.license, self.group))
	end

	function self.getGroup()
		return self.group
	end

	function self.set(k, v)
		self.variables[k] = v
		Player(self.source).state:set(k, v, true)
	end

	function self.get(k)
		return self.variables[k]
	end

	function self.getAccounts(minimal)
		if not minimal then
			return self.accounts
		end

		local minimalAccounts = {}

		for i=1, #self.accounts do
			minimalAccounts[self.accounts[i].name] = self.accounts[i].money
		end

		return minimalAccounts
	end

	function self.getAccount(account)
		for i=1, #self.accounts do
			if self.accounts[i].name == account then
				return self.accounts[i]
			end
		end
	end

	function self.getInventory(minimal)
		local Inventory = exports['qs-core']:GetInventory(self.source)
		return Inventory
	end

	function self.getJob()
		return self.job
	end

	function self.getJob2()
		return self.job2
	end
	
	function self.getJob3()
		return self.job3
	end

	function self.getLoadout(minimal)
		if not minimal then
			return self.loadout
		end
		local minimalLoadout = {}

		for k,v in ipairs(self.loadout) do
			minimalLoadout[v.name] = {ammo = v.ammo}
			if v.tintIndex > 0 then minimalLoadout[v.name].tintIndex = v.tintIndex end

			if #v.components > 0 then
				local components = {}

				for k2,component in ipairs(v.components) do
					if component ~= 'clip_default' then
						components[#components + 1] = component
					end
				end

				if #components > 0 then
					minimalLoadout[v.name].components = components
				end
			end
		end

		return minimalLoadout
	end

	function self.getName()
		return self.name
	end

	function self.setName(newName)
		self.name = newName
		Player(self.source).state:set("name", self.name, true)
	end

	function self.setAccountMoney (accountName, money)
		if money >= 0 then
			local account = self.getAccount(accountName)
			if account then
				local newMoney = ESX.Math.Round(money)
				if newMoney ~= account.money then
					account.money = newMoney
					if accountName == 'money' then
						local prevMoney = self.getInventoryItem('cash').count
						if prevMoney and newMoney > prevMoney then
							self.addAccountMoney('money', newMoney - prevMoney)
						elseif prevMoney and newMoney < prevMoney then 
							self.removeAccountMoney('money', prevMoney - newMoney)
						end
						self.triggerEvent('esx:setAccountMoney', account)
					elseif accountName == 'black_money' then
						local prevMoney = self.getInventoryItem('black_money').count
						if prevMoney and newMoney > prevMoney then 
							self.addAccountMoney('black_money', newMoney - prevMoney)
						elseif prevMoney and newMoney < prevMoney then 
							self.removeAccountMoney('black_money', prevMoney - newMoney)
						end
						self.triggerEvent('esx:setAccountMoney', account)
					else
						self.triggerEvent('esx:setAccountMoney', account)
					end
				end
			end
		end
	end

	function self.addAccountMoney(accountName, money)
		if money > 0 then
			local money = ESX.Math.Round(money)
			if accountName == 'money' then
				local cash = self.getInventoryItem('cash').count
				if cash then
					self.addInventoryItem("cash", money)
					self.setAccountMoney('money', cash + money)
				end
			elseif accountName == 'black_money' then
				local black_money = self.getInventoryItem('black_money').count
				if black_money then
					self.addInventoryItem("black_money", money)
					self.setAccountMoney('black_money', black_money + money)
				end
			else
				local account = self.getAccount(accountName)
				if account and account.money then
					local newMoney = account.money + money
					self.setAccountMoney(accountName, newMoney)
				end
			end
		end
	end

	function self.removeAccountMoney(accountName, money)
		if money > 0 then
			local money = ESX.Math.Round(money)
			if accountName == 'money' then
				local cash = self.getInventoryItem('cash').count
				if cash then
					self.removeInventoryItem("cash", money)
					local newMoney = cash - money
					if newMoney >= 0 then
						self.setAccountMoney('money', newMoney)
					else 
						self.setAccountMoney('money', 0)
					end
				end
			elseif accountName == 'black_money' then
				local black_money = self.getInventoryItem('black_money').count
				if black_money then 
					self.removeInventoryItem("black_money", money)
					local newMoney = black_money - money
					if newMoney >= 0 then
						self.setAccountMoney('black_money', newMoney)
					else 
						self.setAccountMoney('black_money', 0)
					end
				end
			else
				local account = self.getAccount(accountName)
				if account and account.money then
					local newMoney = account.money - money
					if newMoney >= 0 then 
						self.setAccountMoney(accountName, newMoney)
					else 
						self.setAccountMoney(accountName, 0)
					end
				end
			end
		end
	end

	function self.getInventoryItem(name)
		local Item = exports['qs-core']:GetItem(self.source, name)
		return Item
	end

	function self.addInventoryItem(name, count)
		TriggerEvent('inventory:server:addItem', self.source, name, count)
	end

function self.removeInventoryItem(name, count)
    TriggerEvent('inventory:server:removeItem', self.source, name, count)
end

function self.setInventoryItem(name, count)
    return true
end

	function self.getWeight()
		return self.weight
	end

	function self.getMaxWeight()
		return self.maxWeight
	end

function self.canCarryItem(name, count)
    local canCarry = exports['qs-core']:CanCarry(self.source, name, count)
    if canCarry then 
        return true
    else 
        return false
    end
end

	function self.canSwapItem(firstItem, firstItemCount, testItem, testItemCount)
		local firstItemObject = self.getInventoryItem(firstItem)
		local testItemObject = self.getInventoryItem(testItem)

		if firstItemObject.count >= firstItemCount then
			local weightWithoutFirstItem = ESX.Math.Round(self.weight - (firstItemObject.weight * firstItemCount))
			local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))

			return weightWithTestItem <= self.maxWeight
		end

		return false
	end

	function self.setMaxWeight(newWeight)
		self.maxWeight = newWeight
		self.triggerEvent('esx:setMaxWeight', self.maxWeight)
	end

	function self.setJob(job, grade)
		grade = tostring(grade)
		local lastJob = json.decode(json.encode(self.job))

		if ESX.DoesJobExist(job, grade) then
			local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

			self.job.id    = jobObject.id
			self.job.name  = jobObject.name
			self.job.label = jobObject.label

			self.job.grade        = tonumber(grade)
			self.job.grade_name   = gradeObject.name
			self.job.grade_label  = gradeObject.label
			self.job.grade_salary = gradeObject.salary

			if gradeObject.skin_male then
				self.job.skin_male = json.decode(gradeObject.skin_male)
			else
				self.job.skin_male = {}
			end

			if gradeObject.skin_female then
				self.job.skin_female = json.decode(gradeObject.skin_female)
			else
				self.job.skin_female = {}
			end

			TriggerEvent('esx:setJob', self.source, self.job, lastJob)
			self.triggerEvent('esx:setJob', self.job, lastJob)
			Player(self.source).state:set("job", self.job, true)
		else
			print(('[es_extended] [^3WARNING^7] Ignoring invalid ^5.setJob()^7 usage for ID: ^5%s^7, Job: ^5%s^7'):format(self.source, job))
		end
	end
--job2
	function self.setJob2(job2, grade2)
		grade2 = tostring(grade2)
		local lastJob2 = json.decode(json.encode(self.job2))

		if ESX.DoesJobExist(job2, grade2) then
			local job2Object, grade2Object = ESX.Jobs[job2], ESX.Jobs[job2].grades[grade2]

			self.job2.id    = job2Object.id
			self.job2.name  = job2Object.name
			self.job2.label = job2Object.label

			self.job2.grade        = tonumber(grade2)
			self.job2.grade_name   = grade2Object.name
			self.job2.grade_label  = grade2Object.label
			self.job2.grade_salary = grade2Object.salary

			if grade2Object.skin_male then
				self.job2.skin_male = json.decode(grade2Object.skin_male)
			else
				self.job2.skin_male = {}
			end

			if grade2Object.skin_female then
				self.job2.skin_female = json.decode(grade2Object.skin_female)
			else
				self.job2.skin_female = {}
			end

			TriggerEvent('esx:setJob2', self.source, self.job2, lastJob2)
			self.triggerEvent('esx:setJob2', self.job2, lastJob2)
			Player(self.source).state:set("job2", self.job2, true)
		else
			print(('[es_extended] [^3WARNING^7] Ignoring invalid ^5.setJob2()^7 usage for ID: ^5%s^7, Jo2b: ^5%s^7'):format(self.source, job2))
		end
	end

--JOB3

	function self.setJob3(job3, grade3)
		grade3 = tostring(grade3)
		local lastJob3 = json.decode(json.encode(self.job3))

		if ESX.DoesJobExist(job3, grade3) then
			local job3Object, grade3Object = ESX.Jobs[job3], ESX.Jobs[job3].grades[grade3]

			self.job3.id    = job3Object.id
			self.job3.name  = job3Object.name
			self.job3.label = job3Object.label

			self.job3.grade        = tonumber(grade3)
			self.job3.grade_name   = grade3Object.name
			self.job3.grade_label  = grade3Object.label
			self.job3.grade_salary = grade3Object.salary

			if grade3Object.skin_male then
				self.job3.skin_male = json.decode(grade3Object.skin_male)
			else
				self.job3.skin_male = {}
			end

			if grade3Object.skin_female then
				self.job3.skin_female = json.decode(grade3Object.skin_female)
			else
				self.job3.skin_female = {}
			end

			TriggerEvent('esx:setJob3', self.source, self.job3, lastJob3)
			self.triggerEvent('esx:setJob3', self.job3, lastJob3)
			Player(self.source).state:set("job3", self.job3, true)
		else
			print(('[es_extended] [^3WARNING^7] Ignoring invalid ^5.setJob3()^7 usage for ID: ^5%s^7, Jo3b: ^5%s^7'):format(self.source, job3))
		end
	end



function self.addWeapon(weaponName, ammo)
    TriggerEvent('inventory:server:addWeapon', self.source, weaponName, ammo)
end

	function self.addWeaponComponent(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				if not self.hasWeaponComponent(weaponName, weaponComponent) then
					self.loadout[loadoutNum].components[#self.loadout[loadoutNum].components + 1] = weaponComponent
					local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash
					GiveWeaponComponentToPed(GetPlayerPed(self.source), joaat(weaponName), componentHash)
					self.triggerEvent('esx:addInventoryItem', component.label, false, true)
				end
			end
		end
	end

	function self.addWeaponAmmo(weaponName, ammoCount)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo + ammoCount
			SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)
		end
	end

	function self.updateWeaponAmmo(weaponName, ammoCount)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = ammoCount
		end
	end

	function self.setWeaponTint(weaponName, weaponTintIndex)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local weaponNum, weaponObject = ESX.GetWeapon(weaponName)

			if weaponObject.tints and weaponObject.tints[weaponTintIndex] then
				self.loadout[loadoutNum].tintIndex = weaponTintIndex
				self.triggerEvent('esx:setWeaponTint', weaponName, weaponTintIndex)
				self.triggerEvent('esx:addInventoryItem', weaponObject.tints[weaponTintIndex], false, true)
			end
		end
	end

	function self.getWeaponTint(weaponName)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			return weapon.tintIndex
		end

		return 0
	end

	function self.removeWeapon(weaponName)
		local weaponLabel

		for k,v in ipairs(self.loadout) do
			if v.name == weaponName then
				weaponLabel = v.label

				for k2,v2 in ipairs(v.components) do
					self.removeWeaponComponent(weaponName, v2)
				end

				table.remove(self.loadout, k)
				break
			end
		end

		if weaponLabel then
			self.triggerEvent('esx:removeWeapon', weaponName)
			self.triggerEvent('esx:removeInventoryItem', weaponLabel, false, true)
		end
	end

	function self.removeWeaponComponent(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				if self.hasWeaponComponent(weaponName, weaponComponent) then
					for k,v in ipairs(self.loadout[loadoutNum].components) do
						if v == weaponComponent then
							table.remove(self.loadout[loadoutNum].components, k)
							break
						end
					end

					self.triggerEvent('esx:removeWeaponComponent', weaponName, weaponComponent)
					self.triggerEvent('esx:removeInventoryItem', component.label, false, true)
				end
			end
		end
	end

	function self.removeWeaponAmmo(weaponName, ammoCount)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo - ammoCount
			self.triggerEvent('esx:setWeaponAmmo', weaponName, weapon.ammo)
		end
	end

	function self.hasWeaponComponent(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			for k,v in ipairs(weapon.components) do
				if v == weaponComponent then
					return true
				end
			end

			return false
		else
			return false
		end
	end

	function self.hasWeapon(weaponName)
		for k,v in ipairs(self.loadout) do
			if v.name == weaponName then
				return true
			end
		end

		return false
	end

	function self.hasItem(item, metadata)
		for k,v in ipairs(self.inventory) do
			if (v.name == item) and (v.count >= 1) then
				return v, v.count
			end
		end

		return false
	end

	function self.getWeapon(weaponName)
		for k,v in ipairs(self.loadout) do
			if v.name == weaponName then
				return k, v
			end
		end
	end

	function self.showNotification(msg)
		self.triggerEvent('esx:showNotification', msg)
	end

	function self.showHelpNotification(msg, thisFrame, beep, duration)
		self.triggerEvent('esx:showHelpNotification', msg, thisFrame, beep, duration)
	end

	for fnName,fn in pairs(targetOverrides) do
		self[fnName] = fn(self)
	end

	return self
end
