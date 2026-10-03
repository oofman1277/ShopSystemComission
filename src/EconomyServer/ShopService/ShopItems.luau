local ShopItems = {}

export type ShopItem = {
    Id: string,
    Name: string,
    Price: number,
    Permanent: boolean,
    IconId: string,
    ToolName: string,
    Description: string?,
}

--/ SHOP CATALOG /--
ShopItems.Tools = {
    {
        Id = "TestShovel",
        Name = "Test Shovel",
        Price = 5,
        Permanent = true,
        IconId = "rbxassetid://0",
        ToolName = "TestShovel",
        Description = "Permanent test tool.",
    },
    {
        Id = "TestHammer",
        Name = "Test Hammer",
        Price = 8,
        Permanent = true,
        IconId = "rbxassetid://0",
        ToolName = "TestHammer",
        Description = "Permanent test tool.",
    },
    {
        Id = "TestCoffee",
        Name = "Coffee",
        Price = 1,
        Permanent = false,
        IconId = "rbxassetid://0",
        ToolName = "TestCoffee",
        Description = "Replenishable test tool.",
    },
    {
        Id = "TestBandage",
        Name = "Bandage",
        Price = 2,
        Permanent = false,
        IconId = "rbxassetid://0",
        ToolName = "TestBandage",
        Description = "Replenishable test tool.",
    },
}

--/ CORE /--
function ShopItems.Get(id: string): ShopItem?
    for _, item in ShopItems.Tools do
        if item.Id == id then
            return item
        end
    end

    return nil
end

function ShopItems.GetTemplate(toolName: string): Tool?
    local template = script:FindFirstChild(toolName)
    if template and template:IsA("Tool") then
        return template
    end

    return nil
end

return ShopItems
