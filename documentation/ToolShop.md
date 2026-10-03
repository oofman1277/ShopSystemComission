# Tool Shop Guide

Players buy tools from the ToolShop screen. The list of tools, prices, and whether a tool is permanent lives in `ShopItems` (ShopService). The actual Tool objects live under that same ShopItems module in Studio.

## Two kinds of tools

**Permanent**  
The player can buy it once. It is saved to their data. The shop shows "Owned" after that, and they cannot put it in the cart again. They still receive one copy of the tool in their backpack when they buy it.

**Replenishable**  
Nothing is saved. Each purchase puts that many copies in the backpack. They can buy the same tool again later, including several in one checkout. The shop lets them stack a quantity up to 100.

## Where things go in Studio

**ShopService > ShopItems**  
Open this module. The catalog (names, prices, and so on) is the list near the top. Also parent your Tool instances directly under this module. Do not put them in a subfolder. The game clones whatever Tool is named the same as `ToolName`.

**StarterGui > ToolShop**  
The shop screen. You can restyle frames, fonts, and layout here. Keep these names or the scripts will not find them:

- `Container > Content > PermanentContainer`
- `Container > Content > ReplenishableContainer`
- `TotalTab > Total`
- `Back` (ImageLabel, direct child of ToolShop)
- `Back > Button`
- `Checkout` (ImageLabel, direct child of ToolShop)
- `Checkout > Button`

**StarterGui > ToolShop > Scripts**  
`PermanentTemplate` and `ReplenishableTemplate` live here. Both stay `Visible = false`. The game clones them.

Each template needs:

- `ToolName` — TextLabel
- `Price` — TextLabel
- `Icon` — ImageLabel
- `Button` — the invisible button over the card
- `UIScale` — on the card, Scale = 1

`ReplenishableTemplate` also needs:

- `Quantity` — TextButton (shows how many are in the cart)

**ReplicatedStorage > EconomyShared > Events**  
`FetchToolData` and `PurchaseTools` must both exist as RemoteEvents. Do not rename them.

## Adding a tool

1. Build the Tool in Studio (handle, mesh, scripts, whatever it needs).
2. Name the Tool exactly, capitals included. Example: `Medkit`.
3. Parent that Tool under ShopItems. It is the template. Players never use this copy. Checkout clones it into their backpack.
4. In ShopItems, copy an existing block inside `ShopItems.Tools` and edit it. Permanent tools go in the same list as replenishable ones. The shop splits them on screen from the `Permanent` field.

Permanent example:

```lua
{
    Id = "Medkit",
    Name = "Medkit",
    Price = 12,
    Permanent = true,
    IconId = "rbxassetid://0",
    ToolName = "Medkit",
    Description = "A saved medical kit.",
},
```

Replenishable example:

```lua
{
    Id = "Coffee",
    Name = "Coffee",
    Price = 1,
    Permanent = false,
    IconId = "rbxassetid://0",
    ToolName = "Coffee",
    Description = "One drink. Buy as many as you want.",
},
```

A comma is required between blocks. The last block in the list does not need one after it, but a comma there is fine too.

## What each field does

**Id**  
The save name for a permanent tool. Must be unique across the whole list. Changing this later makes the game treat it as a new item, so players who already bought the old Id will not count as owning the new one.

**Name**  
Text on the card (the ToolName label). This can have spaces. It does not have to match the Tool instance name.

**Price**  
Cost in Greenbacks for one copy. A replenishable total is price times quantity. Use a number such as `5` or `1.5`, not `"$5"`.

**Permanent**  
`true` means buy once, saved, and the card shows Owned afterwards. `false` means replenishable, not saved, and the quantity button is used.

**IconId**  
The picture on the card. In Studio, copy the image id from the Toolbox or from an ImageLabel's Image property. It should look like `rbxassetid://123456789`. `rbxassetid://0` shows a blank icon until you replace it.

**ToolName**  
Must match the Name of the Tool parented under ShopItems. Capitals matter. `Medkit` will not find a tool named `medkit`.

**Description**  
Optional. Stored with the item for your own notes or future UI. The current cards do not display this text.

## How a purchase works

Click a card to put it in the cart.

- Permanent: one click adds it, a second click removes it.
- Replenishable: each click adds one. The Quantity button removes one.
- Owned permanent tools do not go into the cart.

The card turns green while any amount of that tool is in the cart. `TotalTab > Total` shows the cart cost with a dollar sign.

Checkout buys the whole cart or nothing. If they cannot afford the total, nothing is taken and nothing is given. Tools they already own are skipped and not charged. Money is taken from their saved Greenbacks.

Back closes the shop and clears the cart, including replenishable quantities.

Permanent ownership is loaded when they join and again when the shop opens, so "Owned" stays correct after a rejoin.

## Customising the look

Safe to change on the templates and shop frame: size, position, colours, fonts, corner radius, padding, and icon size.

The default card colour used when a tool leaves the cart is `111, 111, 83`. If you want a different resting colour, that number also needs to change in `ToolShopUI` (`Scripts > ToolShopUI`), or the card will tween back to the old brown when removed from the cart.

Hover grows the card slightly (`UIScale`). Leave a UIScale named `UIScale` on the card. Back and Checkout brighten on hover. Those ImageLabels should start around ImageColor3 `40, 40, 40`.

Do not rename the labels and buttons listed above. Do not delete `Button`. Clicks are on that button, not on the whole card.

## If something does not work

- `ToolName` must match the Tool's Name under ShopItems, and the Tool must be a direct child of ShopItems, not inside a folder.
- `Id` must be unique. Two cards with the same Id will fight each other.
- `Permanent` must be `true` or `false`, not the words "yes" or "no".
- `Price` must be a number.
- `FetchToolData` and `PurchaseTools` must exist under `EconomyShared.Events`.
- Output warnings that mention a missing tool template mean `ToolName` does not match a Tool under ShopItems.
- After editing ShopItems, sync with Rojo. Tools you placed under ShopItems in Studio are kept. Rojo will not delete them.
