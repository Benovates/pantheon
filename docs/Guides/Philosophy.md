# Philosophy

Some parts of Pantheon work in a way you might not expect. This page explains why.

## A plain value is a starting value

Many properties accept a plain value or a Fusion state. For the value of a control, a plain value is only where the control starts.

- Give the control a `Value` and it stays in step with it both ways. When the user changes the control, the `Value` changes. When you set the `Value`, the control changes.
- Give it a `Computed` and it follows the `Computed`. The user's changes do not write back.

Every control works like this. See [Common properties](CommonProperties.md).

## Components read the theme once

A component reads its colours, fonts and spacing when you build it. That keeps components small, but it means a theme change normally needs a rebuild of the interface.

A rebuild would lose what the user typed, so Pantheon has [Persist](PersistingState.md). It keeps the state of controls between rebuilds.

## Components handle focus and motion

Each component that takes input draws its own focus ring. It works with a keyboard and a gamepad. It also follows the player's settings for reduced motion and transparency. You do not need to add any of this. See [Accessibility](Accessibility.md).

## Game components are separate

The [Game](../Game/Hotbar.md) components are styled for a HUD and do not use the app theme. Most games do not want the inventory bar to turn white when the player picks the light theme. Keeping the two sets apart means a change to one does not affect the other.

## Components are ordinary instances

A component returns a normal Roblox instance. You can pass other Fusion properties to it with `Apply`. If Pantheon does not have the component you need, build it from instances and place it next to the others.
