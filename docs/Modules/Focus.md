---
tags:
  - Modules
---

# Focus

Focus manages keyboard and gamepad focus. The components use it, and you can use it for your own. See [Accessibility](../Guides/Accessibility.md) for what it gives the player.

## How it works

A control that takes focus is registered with `manage`. The module then watches `GuiService.SelectedObject`: when it is a registered control, a ring is drawn around it. Tab moves `SelectedObject` between the registered controls that are showing.

Enter and Space need the handler of the control's `Activated` event, and a script cannot fire an event. When the module starts, it wraps the `Activated` key of Fusion's `OnEvent` once, and remembers the handler given to each instance. This is why `manage` works with any control that connects `Activated` through `OnEvent`.

## Functions

| Name | Description |
| ---- | ----------- |
| `manage: (gui: GuiObject, theme: Theme, textBox: boolean?) -> ()` | Makes `gui` a control that can take focus. `Selectable` is turned on and Roblox's own selection box is hidden. Set `textBox` for an input, so Tab focuses its text. `Interaction.wire`, which most components call, does this for you. |
| `select: (gui: GuiObject?) -> ()` | Moves focus to `gui`, or clears it for `nil`. A `TextBox` also captures the keyboard. |
| `onKey: (gui: GuiObject, handler: (input: InputObject) -> boolean) -> ()` | Calls `handler` for key presses while `gui` has focus. Return `true` for a key you used. The arrow keys of a slider are done this way. |
| `trap: (scope: Scope, root: GuiObject, open: UsedAs<boolean>) -> ()` | While `open` is true, Tab stays inside `root`. Focus moves to the first control in it, and goes back to where it was when `open` turns false. |
| `escape: (scope: Scope, open: UsedAs<boolean>, close: () -> ()) -> ()` | While `open` is true, Escape and the gamepad B button call `close`. When several are open, the one opened last closes. |
| `closer: (props: { OnClose: (() -> ())?, Open: any }) -> (() -> ())` | A function that closes an overlay: it calls `OnClose`, or sets a `Value` passed as `Open` to `false`. |

## Example

```luau
local button = scope:TextButton({
	Text = "Run",
	[Fusion.OnEvent("Activated")] = run,
})
Pantheon.Focus.manage(button, theme) -- Tab reaches it, Enter and Space call `run`

local open = scope:Value(false)
Pantheon.Focus.trap(scope, panel, open)
Pantheon.Focus.escape(scope, open, function()
	open:set(false)
end)
```
