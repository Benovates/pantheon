# Performance

Pantheon builds each component once. After that, Fusion states carry the changes. Your interface stays fast if you keep it that way. This page lists what costs time and what you can do about it.

## Measure first

Open [DevTools](../Modules/DevTools.md) and use the profiler to see which elements change every frame. Use the MicroProfiler in Studio to see what the scripts cost. Fix what you find there before you change anything else.

## Lifetime checks

Fusion can check that a scope lasts at least as long as the things that read from it. It runs the check on every `use` and scans the whole scope each time, so it is slow in a large interface. Pantheon turns it off.

Turn it on only when you are looking for a scope that is destroyed too early:

```luau
Pantheon.Flags.LifetimeChecks = true
```

See [Flags](../Modules/Flags.md).

## Long lists

A list builds one instance for every row. Use [VirtualList](../Components/Layout/VirtualList.md) when a list has more than about 100 rows. It builds only the rows you can see. The inventory panel of the [Hotbar](../Game/Hotbar.md) already does this.

## Changing theme

By default, a theme change rebuilds the interface. Use [Persist](PersistingState.md) so the user keeps what they entered.

`Flags.ReactiveTheme` is an experimental option. With it, components follow the theme as it changes and nothing is rebuilt. A few colours are still read once, so check your interface in both modes. See [Theming](Theming.md).

## Hidden interface

Do not keep hidden interface running. Build an overlay when it opens, or set `Visible` to `false` and stop any springs that drive it. A spring that has settled costs nothing. A spring that follows a value that keeps changing costs a step every frame.

## Fewer states

A `Computed` runs again each time something it reads changes. Put properties that change together in one `Computed`. Do not return a new table from a `Computed` each time, because Fusion counts that as a change.
