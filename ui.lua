CreateThread(function()
    while true do
        Wait(0)
        if IsNuiFocused() then
            if IsControlJustReleased(0, 322) or IsControlJustReleased(0, 194) then
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'closeGarage' })
            end
        end
    end
end)
