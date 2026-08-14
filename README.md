# Estuary UI / Pantheon

A modern and slick Fusion 0.3+ components library for Roblox, with a focus on accessibility, theming, and performance.

## Installation

Pantheon is still in development and is not published to Wally yet. To install, clone the repository and run the following commands in your project directory to get started:
```bash
rokit install
wally install
rojo serve demo.project.json
```

## Example Usage

```luau
local EstuaryUI = require(Packages.EstuaryUI)
local scope = EstuaryUI.scoped()
local theme = EstuaryUI.Theme.create("Light") -- Montserrat typography

EstuaryUI.Theme.Provide(theme, function()
  EstuaryUI.Components.Button(scope, { Text = "Run", Variant = "Outlined" })
  EstuaryUI.Components.Icon(scope, { Name = "search", IconSize = 24 })
end)
```

Brief API docs available in the [docs folder](./docs). Soon will be more comprehensive and covers all components and their properties.

## License
This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

For contributions, please make sure to follow the coding style and write tests for any new features or bug fixes. Create components in the `src/Components` folder and add example usage in the `stories` folder. Follow the existing structure, naming conventions, design styleguide for consistency. Always use the Iona-based system to create new instances for components, and avoid using Roblox's built-in instances directly.

Ensure to add types for all new components and their properties in the `src/Types.luau` file. This will help with type checking and improve the developer experience.

## Version
0.0.1 - Initial release.