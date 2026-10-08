<p align="center">
  <img src="assets/banner.svg" alt="Valheim Solo Toolkit — Your world. Your rules." width="100%">
</p>

<p align="center">
  A dark, easy-to-use Cheat Engine toolkit for your solo Valheim world.<br>
  Manage your inventory, tune your skills and make the next adventure your own.
</p>

<p align="center">
  <a href="ValheimInventory.CT"><strong>Download the table</strong></a>
  &nbsp; · &nbsp;
  <a href="#quick-start">Quick start</a>
  &nbsp; · &nbsp;
  <a href="#watch-it-in-action">Watch it in action</a>
  &nbsp; · &nbsp;
  <a href="#a-few-useful-details">Useful details</a>
</p>

<br>

## Quick start

**You need:** Windows, Cheat Engine 7.6 and Valheim running with Mono support.

1. Download **[ValheimInventory.CT](ValheimInventory.CT)**. On GitHub's file page, use **Download raw file**.
2. Start Valheim and load your world.
3. Open the table in Cheat Engine and allow its Lua script to run.
4. The toolkit finds Valheim and loads your inventory automatically.

Not in your world yet? It quietly retries every **3 seconds** until the first load succeeds. There is no need to choose the process manually.

The **green Refresh inventory** button reloads your items whenever you need it. Hover over any action for a quick explanation, or open **Help & tips** for the full guide.

<br>

## Watch it in action

> 🎬 **YouTube walkthrough — coming soon**  
> A tour of the interface, inventory tools and everything you can do in your world.

<!-- When the video is ready, replace the callout above with:
[![Watch the Valheim Solo Toolkit walkthrough](https://img.youtube.com/vi/VIDEO_ID/hqdefault.jpg)](https://www.youtube.com/watch?v=VIDEO_ID)
Replace both instances of VIDEO_ID with the actual YouTube video ID.
-->

<br>

## 🟢 Make inventory management effortless

Select an item, choose an action and get back to playing.

| Tool | What it does |
| :--- | :--- |
| **Edit quantity** | Set a stack to the amount you want, including above its normal limit. |
| **Clone an item** | Copy a selected item into your inventory. Leave an empty slot available. |
| **Max all stacks** | Fill existing stacks to their normal limits. Overstacks are reduced to those limits. |
| **Freeze quantities** | Hold one stack or all current stacks at their chosen quantities. An **X** shows what is frozen. |
| **Auto refill** | Ctrl + left-click a stack into an open chest. A copy transfers while the original stays in your slot. |
| **Delete items** | Enable the bottom-left in-game menu, drag a full stack from your inventory, then destroy and confirm. |
| **Item flags** | Clear a selected item's cheated flag once, or keep carried-item flags off automatically. |

Freezing captures the stacks you have now. New items and newly split stacks start unfrozen. Use **Auto refill** when you want to deposit an entire stack and keep the original.

<br>

## 🟡 Build freely. Carry more. Keep going.

| Player tool | What it does |
| :--- | :--- |
| **God mode** | Blocks damage to your local player. |
| **Unlimited stamina** | Replenishes stamina while enabled. |
| **Free crafting** | Bypasses crafting and building material requirements. |
| **Unlimited carry** | Prevents encumbrance, even when you exceed the normal weight limit. |
| **Bow beam** | Hold attack with a bow to unleash an energy beam with swirling particles, wind ribbons and bright impact effects. |

The bow beam damages hostile monsters along its path. Players, pets and buildings are excluded from its damage targets.

> [!IMPORTANT]
> **God mode and Free crafting can affect item flags.**  
> Killing monsters with an item while God mode is enabled can flag that item as cheated. Crafted or upgraded items can also receive the flag when using Free crafting.  
> Select the affected item and use **Item flags → Clear selected flag**, then **drop it and pick it up again**. Use the normal drop action, not Inventory delete.  
> **Keep item flags off** continuously clears flags on carried items.

<br>

## 🔵 Choose your skills. Change how you move.

**Set custom skill level** opens a dedicated skill window. See current levels, check individual skills—or **Select all**—enter a level and click **Apply level**.

- **Max skills to 100** brings all existing skill entries to the normal maximum.
- **Custom levels** let you go above 100. Unchecked skills stay unchanged.
- **Movement speed** adjusts how fast you walk, run, crouch and swim.
- **Jump force** gives your jumps more height.
- **Flight** lets you rise with **Space**, descend with **Left Ctrl** and move faster with **Shift**.
- **Reset speed and jump** restores the original movement values.

Changing a skill level resets that skill's progress toward the next level. Higher-than-normal levels may still be limited by the game's own calculations. Flight does not disable collisions.

<br>

## 🟣 Turn your map into a travel menu

Open **Teleport tools** to choose where you want to go next.

| Destination | How to use it |
| :--- | :--- |
| **Map marker** | Create a named marker on Valheim's map. Click **Refresh locations**, select it and **Teleport selected**. |
| **Map ping** | Ping a location in the game, then refresh while the ping is visible. Select its **Ping** row and teleport. |
| **Saved location** | Stand still and click **Save current position**. Name the spot and return whenever you like. |
| **Coordinates** | Enter **X Y Z**. **Y** is height. |
| **Another player** | They must enable **Visible to other players** on their map. Click **Refresh players**, select them and teleport. |

Saved locations are local bookmarks for each world; they do not create markers on the in-game map. Map and ping destinations use the coordinates captured when you refresh. Player destinations use the latest shared position when clicked, with a small sideways offset.

Return to the game and unpause after queuing a teleport. Give the destination time to load. **Cancel queued** cancels a waiting request; it does not undo an accepted teleport.

<br>

## A few useful details

<details>
<summary><strong>What do the inventory indicators mean?</strong></summary>

**X** means the stack quantity is frozen. In the flag column, **Y** means marked as cheated, **–** means clear and **?** means unreadable. The item-flag tools manage these flags; they do not erase every record of cheat use.

</details>

<details>
<summary><strong>Can I delete part of a stack?</strong></summary>

Split the amount you want to remove into its own slot first, then delete that full stack. The delete menu blocks equipped items, quest items, chest items and partial-stack drags. Confirmed deletion is permanent.

</details>

<details>
<summary><strong>Does Free crafting also fill machines?</strong></summary>

No. It bypasses crafting and building requirements. Machines and other objects that consume fuel still need their fuel items.

</details>

<details>
<summary><strong>Does Unlimited carry add inventory slots?</strong></summary>

No. It removes encumbrance. Slot count, displayed weight and the normal weight limit remain unchanged.

</details>

<details>
<summary><strong>What happens when I close the toolkit?</strong></summary>

Closing the toolkit stops its active toggles and quantity freezes. It does not undo quantity edits, skill edits, cloned or deleted items, or saved bookmarks.

</details>

<details>
<summary><strong>Do I need the separate DLL files?</strong></summary>

The table contains its Lua script and embedded helpers. Use **ValheimInventory.CT** to run the toolkit. The separate Lua and C# files are available for reviewing or modifying its implementation.

</details>

<br>

---

<p align="center">
  <strong>Explore a little further. Build something bigger. Have fun.</strong><br>
  <sub>An unofficial community toolkit for solo play. Not affiliated with Valheim's developers.</sub>
</p>
