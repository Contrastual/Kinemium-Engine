local ok, err = pcall(function()
    print("Testing Humanoid IK...")
    local hum = Instance.new("Humanoid")
    print("Humanoid ClassName:", hum.ClassName)

    -- Define a basic rig if possible
    if hum.CreateDefaultRig then
        print("Creating default rig...")
        hum:CreateDefaultRig()
    else
        print("CreateDefaultRig not found, skipping rig build.")
    end

    -- Test SetIKCallback
    local ikTicks = 0
    hum:SetIKCallback(function(source, dt, pose)
        ikTicks = ikTicks + 1
        if ikTicks % 30 == 0 then
            print("IK Callback Active, Tick:", ikTicks)
        end
        return {
            Head = CFrame.Angles(0, math.sin(os.clock() * 2) * 0.5, 0)
        }
    end)
    print("IK Callback registered.")

    for i = 1, 100 do
        task.wait(1/60)
    end
    print("IK Test Finished.")
end)

if not ok then
    print("IK TEST CRASHED:", tostring(err))
end
