RegisterNetEvent('e-fuel:payMoney')
AddEventHandler('e-fuel:payMoney', function(amount, paymentType)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local account = paymentType == 'bank' and 'bank' or 'money'
    local balance = xPlayer.getAccount(account).money

    if balance >= amount then
        xPlayer.removeAccountMoney(account, amount)
        TriggerClientEvent('ox:notifyClient', source, {
            title = 'Payment Successful',
            description = 'Paid '..amount..'€ with '..(paymentType == 'bank' and 'a credit card' or 'cash')..'.',
            position = 'top',
            type = 'success'
        })
    else
        TriggerClientEvent('ox:notifyClient', source, {
            title = 'Payment Failed',
            description = 'Insufficient funds in '..(paymentType == 'bank' and 'your credit card' or 'your pockets')..'.',
            position = 'top',
            type = 'error'
        })
    end
end)

lib.callback.register('e-fuel:getBankBalance', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer.getAccount('bank').money
end)


lib.callback.register('e-fuel:useGasCan', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getInventoryItem('WEAPON_PETROLCAN').count > 0 then
        xPlayer.removeInventoryItem('WEAPON_PETROLCAN', 1)
        xPlayer.triggerEvent('ox_inventory:disarm')
        return true
    else
        return false
    end
end)

lib.callback.register('e-fuel:buyGasCan', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getAccount('money').money >= Config.GasCanPrice then
        xPlayer.addInventoryItem('WEAPON_PETROLCAN', 1, {
            ammo = 4500
        })
        return 'purchased'
    else
        return 'no_money'
    end
end)