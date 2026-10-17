# Pantheon

A modern and slick Fusion 0.3+ components library for Roblox, with a focus on accessibility, theming, and performance.

## Installation

Add Pantheon to your `wally.toml`, then run `wally install`:

```toml
[dependencies]
Pantheon = "koterahq/pantheon@0.1.0"
```

To work on Pantheon itself, clone the repository and run:

```bash
rokit install
wally install
rojo serve demo.project.json
```

## Example Usage

```luau
local Pantheon = require(Packages.Pantheon)
local scope = Pantheon.scoped()
local theme = Pantheon.Theme.create("Light") -- Montserrat typography

Pantheon.Theme.Provide(theme, function()
  Pantheon.Components.Button(scope, { Text = "Run", Variant = "Outlined" })
  Pantheon.Components.Icon(scope, { Name = "search", IconSize = 24 })
end)
```

The documentation is in the [docs folder](./docs), written for MkDocs Material. Run `mkdocs serve` to read it in a browser. It covers every component and its properties, the theme, and the in-game components.

## License
This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

For contributions, please make sure to follow the coding style and write tests for any new features or bug fixes. Create components in the `src/Components` folder and add example usage in the `stories` folder. Follow the existing structure, naming conventions, design styleguide for consistency. Always use the Iona-based system to create new instances for components, and avoid using Roblox's built-in instances directly.

Ensure to add types for all new components and their properties in the `src/Types.luau` file. This will help with type checking and improve the developer experience.

## Version
0.1.0 - Initial release.