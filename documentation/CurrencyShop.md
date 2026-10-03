# Currency Shop Guide

Players buy Greenbacks with Robux from the CurrencyShop screen. Each purchase button is tied to a Developer Product. The button says which product to prompt. A separate list says how much currency that product pays.

## Where things go in Studio

**StarterGui > CurrencyShop**  
The shop screen. Restyle it however you want: size, colour, images, layout, extra frames, and labels. The scripts only care about the purchase buttons and the back button.

**Purchase button**  
Any TextButton inside CurrencyShop can be a purchase button. It must have an Attribute:

- Name: `DevProductId`
- Type: Number
- Value: the Developer Product id from the Creator Dashboard

Buttons without that attribute are ignored. Decoration buttons are fine.

The frame around the button can have a `UIScale` named `UIScale` if you want the hover grow. That is optional. The purchase still works without it.

**Back**  
`Back` is an ImageLabel and a direct child of CurrencyShop. Inside it, a button named `Button` closes the shop. Hover brightens the Back image. Leave those names as they are.

**EconomyServer > CurrencyProducts**  
This module is the payout list. The number in brackets is the same Developer Product id. The number on the right is how many Greenbacks they receive.

```lua
local CurrencyProducts = {
    [3716162853] = 0.50,
    [3716162888] = 3.00,
    [3716162915] = 7.50,
    [3716162952] = 20.00,
}
```

`3716162853` charges the Robux price you set on that product in the dashboard, then gives `0.50` Greenbacks. The Robux price is not in this file. Only the in-game payout is.

## Adding a currency button

1. Create the Developer Product on the Creator Dashboard and copy its id.
2. Duplicate an existing purchase frame in CurrencyShop, or build a new one.
3. On the TextButton, set `DevProductId` to that id. The attribute type must be Number, not String.
4. In `CurrencyProducts`, add a line with the same id and the Greenbacks amount:

```lua
[1234567890] = 50,
```

5. Put a comma between lines. Change the label text on the frame yourself so players can see the amount. The script does not write that text.

The id on the button and the id in `CurrencyProducts` must match. If the button id is missing from that list, the purchase prompt does not open.

## Editing an existing button

Change the picture, size, and text freely. To change how much currency it gives, edit the number on the right in `CurrencyProducts`. To point the button at a different product, change `DevProductId` and add or update that id in `CurrencyProducts`.

Do not rename `DevProductId`. Do not store the id as text in the button's name. The attribute is what the game reads.

## If something does not work

- `DevProductId` must be a Number attribute, and it must match a line in `CurrencyProducts`.
- The product must exist on the game's Creator Dashboard. Studio test purchases need the game to be published with those products.
- `Back > Button` must keep those names or the shop will not close.
- Currency is saved after Roblox confirms the purchase. If the player leaves before that confirm finishes, Roblox asks the server again later.
