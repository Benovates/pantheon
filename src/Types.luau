--!strict
--[[
	Public types for estuary-ui (Cadence/Tithe design system).
]]

export type Scope = any
export type UsedAs<T> = T | any

export type ThemeMode = "Light" | "Dark"

export type ThemeColors = {
	Primary: Color3,
	OnPrimary: Color3,
	PrimaryContainer: Color3,
	OnPrimaryContainer: Color3,
	Background: Color3,
	Surface: Color3,
	SurfaceDim: Color3,
	SurfaceBright: Color3,
	OnSurface: Color3,
	OnSurfaceVariant: Color3,
	SurfaceContainer: Color3,
	SurfaceContainerHigh: Color3,
	Outline: Color3,
	OutlineVariant: Color3,
	Error: Color3,
	OnError: Color3,
	Success: Color3,
	OnSuccess: Color3,
	Warning: Color3,
	OnWarning: Color3,
	Scrim: Color3,
	Info: Color3,
	OnInfo: Color3,
}

export type ThemeFonts = {
	Heading: Font,
	Body: Font,
	Mono: Font,
}

export type ThemeMetrics = {
	Space2xs: number,
	SpaceXs: number,
	SpaceSm: number,
	SpaceMd: number,
	SpaceLg: number,
	SpaceXl: number,
	--- Corner radius scale (px)
	RadiusNone: number,
	Radius2xs: number,
	RadiusXs: number,
	RadiusSm: number,
	RadiusMd: number,
	RadiusLg: number,
	RadiusXl: number,
	Radius2xl: number,
	Radius3xl: number,
	--- Semantic: cards / panels / sheets (typically = RadiusLg)
	RadiusPanel: number,
	--- Fully rounded (pills, avatars, switches)
	RadiusPill: number,
	AppBarHeight: number,
	DrawerWidth: number,
	RailWidth: number,
	ButtonPadX: number,
	ButtonPadY: number,
}


export type TypeScale = {
	Font: Font,
	Size: number,
	LineHeight: number,
}

export type ThemeTypography = {
	Display: TypeScale,
	Headline: TypeScale,
	Title: TypeScale,
	Button: TypeScale,
	Body: TypeScale,
	Label: TypeScale,
	Mono: TypeScale,
	[string]: TypeScale,
}

export type ThemeColorRole = {
	Base: Color3,
	OnBase: Color3,
	Container: Color3,
	OnContainer: Color3,
}

--- Extensible palette; defaults use Material-ish names (primary, secondary, …).
export type ThemePalette = { [string]: ThemeColorRole }

--- Color3 | hex | RGB {r,g,b} | palette name | Material swatch ("Blue 500") | { Blue = 500 } | role
export type ColorInput = Color3 | string | { number } | { [string]: number | string } | ThemeColorRole

export type ThemeMotion = {
	SpringSpeed: number,
	SpringDamping: number,
	PressScale: number,
}

export type PreferredTextSizeName = "Medium" | "Large" | "Larger" | "Largest"

export type AccessibilityPrefs = {
	ReduceMotion: boolean?,
	PreferredTransparency: number?,
	HighContrast: boolean?,
	PreferredTextSize: PreferredTextSizeName?,
}

--- Control chrome defaults (iOS-style switch I/O labels, etc.)
export type ThemeControls = {
	--- Show I / O glyphs on Switch tracks (iOS “Show On/Off Labels”).
	SwitchIcons: boolean?,
}

export type ThemeIcons = { [string]: string }
export type ThemeAudio = { [string]: string }

export type Theme = {
	Mode: ThemeMode,
	Colors: ThemeColors,
	--- Named colors for Color= props (primary, secondary, error, custom, …)
	Palette: ThemePalette,
	Fonts: ThemeFonts,
	Typography: ThemeTypography,
	Metrics: ThemeMetrics,
	Motion: ThemeMotion,
	Icons: ThemeIcons,
	Audio: ThemeAudio,
	Controls: ThemeControls,
	Accessibility: AccessibilityPrefs?,
}

export type ThemeRef = UsedAs<Theme>

--- Style only (Vuetify-like). Legacy names still accepted on Button.
export type ButtonVariant =
	"Filled"
	| "Tonal"
	| "Outlined"
	| "Text"
	| "Primary"
	| "Destructive"

export type TextVariant = string
export type AlertTone = "Info" | "Success" | "Warning" | "Error"
export type ProgressVariant = "Linear" | "Circular"
export type ProgressMode = "Determinate" | "Indeterminate" | "Buffering"

-- Shared base
export type BaseProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	--- Top-level UI frame for overlays (dialogs, menus, toasts, drawers).
	--- Prefer providing this so overlays do not shift content layout.
	Layer: Instance?,
	[string]: any,
}

export type ButtonProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Text: UsedAs<string>?,
	--- Style: Filled | Tonal | Outlined | Text (legacy Primary/Destructive still work)
	Variant: (ButtonVariant | string)?,
	--- Palette name, Color3, hex, RGB table, or ThemeColorRole
	Color: UsedAs<ColorInput>?,
	OnClick: (() -> ())?,
	Disabled: UsedAs<boolean>?,
	Icon: string?,
	--- Lucide icon before label
	LeadingIcon: string?,
	--- Lucide icon after label
	TrailingIcon: string?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	CornerRadius: number?,
	Padding: { number }?,
	[string]: any,
}

export type TextFieldResize = "None" | "Y" | "X" | "Both"

export type Validator = (value: any) -> (boolean, string?)

export type TextFieldProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Text: UsedAs<string>?,
	Placeholder: UsedAs<string>?,
	Label: UsedAs<string>?,
	Helper: UsedAs<string>?,
	Error: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	Multiline: boolean?,
	MinLines: number?,
	MaxLines: number?,
	--- Corner grip resize (Material-style). Default `Y` when Multiline.
	Resize: TextFieldResize?,
	Disabled: UsedAs<boolean>?,
	LeadingIcon: string?,
	TrailingIcon: string?,
	Validators: { Validator }?,
	--- Validate on focus lost (default true when Validators set)
	ValidateOnBlur: boolean?,
	[string]: any,
}

export type TextProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Text: UsedAs<string>,
	Variant: TextVariant?,
	Color: UsedAs<Color3>?,
	TextXAlignment: Enum.TextXAlignment?,
	TextWrapped: boolean?,
	[string]: any,
}

export type ListItemProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Title: UsedAs<string>,
	Subtitle: UsedAs<string>?,
	OnClick: (() -> ())?,
	Leading: Instance?,
	Trailing: Instance?,
	Disabled: UsedAs<boolean>?,
	[string]: any,
}

export type ChipProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Text: UsedAs<string>,
	Selected: UsedAs<boolean>?,
	OnClick: (() -> ())?,
	Disabled: UsedAs<boolean>?,
	LeadingIcon: string?,
	TrailingIcon: string?,
	[string]: any,
}

export type DialogAction = {
	Text: string,
	Variant: (ButtonVariant | string)?,
	Color: ColorInput?,
	OnClick: (() -> ())?,
}

export type DialogProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Title: UsedAs<string>,
	Body: UsedAs<string>?,
	Actions: { DialogAction }?,
	OnClose: (() -> ())?,
	Open: UsedAs<boolean>?,
	--- Optional custom body content (forms, etc.)
	Children: any?,
	--- Optional Lucide icon above the title (alerts / confirms).
	Icon: string?,
	IconColor: UsedAs<Color3>?,
	IconSize: number?,
	[string]: any,
}


export type PromptProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Title: UsedAs<string>,
	Body: UsedAs<string>?,
	Actions: { DialogAction }?,
	OnClose: (() -> ())?,
	Open: UsedAs<boolean>?,
	Children: any?,
	Icon: string?,
	IconColor: UsedAs<Color3>?,
	IconSize: number?,
	OnConfirm: (() -> ())?,
	ConfirmText: string?,
	CancelText: string?,
	Destructive: boolean?,
	[string]: any,
}

export type ConfirmDialogProps = PromptProps

export type SurfaceProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Name: string?,
	Elevated: boolean?,
	[string]: any,
}

export type OverlayProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	OnClick: (() -> ())?,
	[string]: any,
}

export type IconProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Name: string?, -- Lucide icon id
	Image: string?,
	Color: UsedAs<Color3>?,
	IconSize: number?,
	AssetSize: number?,
	[string]: any,
}

export type IconButtonProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Name: string?,
	Image: string?,
	OnClick: (() -> ())?,
	Disabled: UsedAs<boolean>?,
	[string]: any,
}

export type CheckboxProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Checked: UsedAs<boolean>?,
	Label: UsedAs<string>?,
	OnChanged: ((boolean) -> ())?,
	Disabled: UsedAs<boolean>?,
	[string]: any,
}

export type SwitchProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Checked: UsedAs<boolean>?,
	Label: UsedAs<string>?,
	OnChanged: ((boolean) -> ())?,
	Disabled: UsedAs<boolean>?,
	--- Override Theme.Controls.SwitchIcons for this switch.
	Icons: boolean?,
	[string]: any,
}

export type RadioOption = {
	Value: string,
	Label: string,
}

export type RadioProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Checked: UsedAs<boolean>,
	Label: UsedAs<string>?,
	OnActivated: (() -> ())?,
	Disabled: UsedAs<boolean>?,
	[string]: any,
}

export type RadioGroupProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Options: { RadioOption },
	Value: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	Disabled: UsedAs<boolean>?,
	[string]: any,
}

export type SelectOption = {
	Value: string,
	Label: string,
}

export type SelectProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Options: { SelectOption },
	Value: UsedAs<string>?,
	Placeholder: UsedAs<string>?,
	Label: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	Disabled: UsedAs<boolean>?,
	Filterable: boolean?,
	Validators: { Validator }?,
	[string]: any,
}

export type MultiSelectProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Options: { SelectOption },
	Value: UsedAs<{ string }>?,
	Placeholder: UsedAs<string>?,
	Label: UsedAs<string>?,
	OnChanged: (({ string }) -> ())?,
	Disabled: UsedAs<boolean>?,
	Validators: { Validator }?,
	--- `Chips` (default) shows a chip per selection; `Count` shows "N selected".
	Display: ("Chips" | "Count")?,
	[string]: any,
}

export type SpinnerProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	SizePx: number?,
	[string]: any,
}

export type SliderProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Value: UsedAs<number>?,
	Min: number?,
	Max: number?,
	Step: number?,
	OnChanged: ((number) -> ())?,
	Disabled: UsedAs<boolean>?,
	Label: UsedAs<string>?,
	[string]: any,
}

export type RangeSliderProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Value: UsedAs<NumberRange>?,
	Min: number?,
	Max: number?,
	OnChanged: ((NumberRange) -> ())?,
	Disabled: UsedAs<boolean>?,
	[string]: any,
}

export type AlertProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Title: UsedAs<string>?,
	Text: UsedAs<string>,
	Tone: AlertTone?,
	[string]: any,
}

export type SnackbarProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Message: UsedAs<string>,
	ActionText: string?,
	OnAction: (() -> ())?,
	[string]: any,
}

export type SnackbarHostProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	-- Host manages queue via returned API; see Components.SnackbarHost
	[string]: any,
}

export type ProgressProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Value: UsedAs<number>?,
	Buffer: UsedAs<number>?,
	Variant: ProgressVariant?,
	Mode: ProgressMode?,
	[string]: any,
}

export type BadgeProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Content: Instance,
	Count: UsedAs<number>?,
	Dot: boolean?,
	[string]: any,
}

export type TabItem = {
	Id: string,
	Label: string,
}

export type TabsProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Items: { TabItem },
	Selected: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	[string]: any,
}

export type DividerProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Vertical: boolean?,
	[string]: any,
}

export type CardProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Title: UsedAs<string>?,
	Subtitle: UsedAs<string>?,
	Children: any?,
	[string]: any,
}

export type AppBarProps = {
	Radius: any?,
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Title: UsedAs<string>?,
	Leading: Instance?,
	Actions: { Instance }?,
	[string]: any,
}

export type NavigationDrawerProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Open: UsedAs<boolean>?,
	Title: UsedAs<string>?,
	Subtitle: UsedAs<string>?,
	AvatarImage: string?,
	AvatarInitials: string?,
	--- Flat actions (Menu-style). Prefer `Sections` for categories.
	Items: { any }?,
	Sections: { MenuSectionProps }?,
	OnClose: (() -> ())?,
	Children: any?,
	--- Gap (px) from the parent edges — use `4` inside Window.
	Inset: number?,
	--- Panel corner radius (px). Window drawers typically use `RadiusPanel + 4`.
	CornerRadius: number?,
	--- First MenuPage id when composing `Children`.
	InitialPage: string?,
	Page: UsedAs<string>?,
	OnPageChanged: ((string) -> ())?,
	--- Cap embedded menu height (px). Omit to fill.
	MaxHeight: number?,
	[string]: any,
}

export type NavigationRailProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Items: { { Id: string, Icon: string?, Label: string?, OnClick: (() -> ())? } },
	Selected: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	--- Default `Vertical` (side rail). `Horizontal` lays items in a row.
	Orientation: ("Vertical" | "Horizontal")?,
	[string]: any,
}

--- App chrome shell: elevated Sheet colors + optional AppBar / NavigationRail / content / overlays.
export type WindowProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Position: UsedAs<UDim2>?,
	AnchorPoint: UsedAs<Vector2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	AppBar: Instance?,
	NavigationRail: Instance?,
	--- Main content; fills space beside/above the rail.
	Children: any?,
	--- Drawers, menus, dialogs — reparented onto the window overlay layer.
	Overlays: { Instance }?,
	--- Layout for the rail slot. Defaults by inferring from `NavigationRail.Size`
	--- (horizontal rails use full-width × ~72px). Prefer setting explicitly when unsure.
	--- Also set `NavigationRail.Orientation` to match.
	RailOrientation: ("Vertical" | "Horizontal")?,
	--- Outer chrome radius (default `RadiusPanel`).
	CornerRadius: number?,
	--- Sheet elevation (default true).
	Elevated: boolean?,
	[string]: any,
}

export type BreadcrumbItem = {
	Label: string,
	OnClick: (() -> ())?,
}

export type BreadcrumbsProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Items: { BreadcrumbItem },
	[string]: any,
}

export type PaginationProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Page: UsedAs<number>?,
	PageCount: number,
	OnChanged: ((number) -> ())?,
	[string]: any,
}

export type ContainerProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	MaxWidth: number?,
	Children: any?,
	[string]: any,
}

export type MenuSlot = string | Instance

export type MenuItemProps = {
	Text: UsedAs<string>,
	OnClick: (() -> ())?,
	Disabled: UsedAs<boolean>?,
	--- Lucide icon or custom instance before the label.
	Leading: MenuSlot?,
	--- Lucide icon or custom instance after the label.
	Trailing: MenuSlot?,
	--- Alias for `Leading` when it is a Lucide icon name.
	LeadingIcon: string?,
	--- Alias for `Trailing` when it is a Lucide icon name.
	TrailingIcon: string?,
	--- Palette / Color3 tint for label + icons (e.g. `"error"`).
	Color: UsedAs<ColorInput>?,
	--- Push this MenuPage id (does not close the menu).
	Page: string?,
	[string]: any,
}

export type MenuButtonProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Text: UsedAs<string>,
	OnClick: (() -> ())?,
	Disabled: UsedAs<boolean>?,
	Leading: MenuSlot?,
	Trailing: MenuSlot?,
	LeadingIcon: string?,
	TrailingIcon: string?,
	Color: UsedAs<ColorInput>?,
	Page: string?,
	--- Compact row (40px). False uses the taller header-menu row (44px). Default true.
	Compact: boolean?,
	--- Invoked after `OnClick` (Menu wires this when building from Items/Sections).
	OnClose: (() -> ())?,
	Children: any?,
	[string]: any,
}

export type MenuSectionProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	--- Optional category label above this group of items.
	Title: UsedAs<string>?,
	--- Lucide icon before the category title (prepend only).
	Icon: string?,
	--- Data-driven rows (built as MenuButtons). Prefer `Children` when composing.
	Items: { any }?,
	--- Composed MenuButtons (or other content).
	Children: any?,
	--- Category header can collapse/expand its items.
	Collapsible: boolean?,
	--- Initial open state when collapsible (default true).
	DefaultExpanded: boolean?,
	--- Controlled expanded state.
	Expanded: UsedAs<boolean>?,
	OnExpandedChanged: ((boolean) -> ())?,
	Compact: boolean?,
	OnClose: (() -> ())?,
	[string]: any,
}

export type MenuPageProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Id: string,
	--- Subpage bar title; also enables the back control.
	Title: UsedAs<string>?,
	Children: any?,
	[string]: any,
}

export type MenuProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	--- Flat item list (used when `Sections` is nil). Prefer composing MenuButton.
	Items: { any }?,
	--- Grouped items with optional category titles. Prefer composing MenuSection.
	Sections: { MenuSectionProps }?,
	Open: UsedAs<boolean>?,
	OnClose: (() -> ())?,
	--- Optional content above the item list (e.g. AvatarMenu profile header).
	Header: any?,
	--- Composed MenuSection / MenuButton / MenuPage (also appended after Items/Sections).
	Children: any?,
	--- Cap list height; scrolls when content exceeds this (px).
	MaxHeight: number?,
	--- When true, list fills remaining height and scrolls (fixed `Size` required).
	Fill: boolean?,
	--- Override panel corner radius (default `RadiusPanel`).
	CornerRadius: number?,
	--- Outer padding (default 4).
	Padding: number?,
	--- When true, skip Layer.mount — parent owns overlay / layering (AvatarMenu, Popover).
	Embedded: boolean?,
	--- First MenuPage id (default: first page child).
	InitialPage: string?,
	--- Controlled page id; Menu pushes/pops to match.
	Page: UsedAs<string>?,
	OnPageChanged: ((string) -> ())?,
	[string]: any,
}

export type PopoverProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Open: UsedAs<boolean>?,
	OnClose: (() -> ())?,
	--- Anchor to position relative to (screen space).
	Target: Instance?,
	--- Preferred placement relative to Target.
	Placement: ("Bottom" | "Top" | "Left" | "Right")?,
	Items: { any }?,
	Sections: { MenuSectionProps }?,
	MaxHeight: number?,
	Children: any?,
	Width: number?,
	[string]: any,
}

export type AvatarMenuProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Open: UsedAs<boolean>?,
	OnClose: (() -> ())?,
	Target: Instance?,
	Sections: { MenuSectionProps }?,
	MaxHeight: number?,
	Image: string?,
	Initials: string?,
	Name: UsedAs<string>?,
	Subtitle: UsedAs<string>?,
	Items: { any }?,
	[string]: any,
}

export type TooltipPlacement = "Top" | "Bottom" | "Left" | "Right" | "Auto"

export type TooltipProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Text: UsedAs<string>,
	Target: Instance?,
	--- Preferred side of the target. `Auto` picks the side with most room.
	Placement: TooltipPlacement?,
	Gap: number?,
	[string]: any,
}

export type DatePickerProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Value: UsedAs<string>?, -- YYYY-MM-DD
	OnChanged: ((string) -> ())?,
	[string]: any,
}

export type TimePickerProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Value: UsedAs<number>?, -- seconds from midnight
	OnChanged: ((number) -> ())?,
	[string]: any,
}

export type ColorPickerProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Value: UsedAs<Color3>?,
	OnChanged: ((Color3) -> ())?,
	[string]: any,
}

export type VirtualListProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	ItemCount: UsedAs<number>,
	ItemHeight: number,
	RenderItem: (scope: Scope, index: number) -> Instance,
	Padding: number?,
	[string]: any,
}

export type DataTableColumn = {
	Id: string,
	Title: string,
	Width: number?,
	Sortable: boolean?,
}

export type DataTableProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Columns: { DataTableColumn },
	Rows: UsedAs<{ { [string]: any } }>,
	RowHeight: number?,
	SortColumn: UsedAs<string>?,
	SortAscending: UsedAs<boolean>?,
	OnSort: ((columnId: string, ascending: boolean) -> ())?,
	Selected: UsedAs<{ [number]: boolean }>?,
	OnSelect: ((index: number, selected: boolean) -> ())?,
	Filter: UsedAs<string>?,
}

export type AvatarProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Image: string?,
	Initials: string?,
	AvatarSize: number?,
	[string]: any,
}

export type EmptyStateProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Title: UsedAs<string>,
	Subtitle: UsedAs<string>?,
	Action: ButtonProps?,
	[string]: any,
}

export type SettingsListItem = {
	Id: string?,
	Title: UsedAs<string>,
	Subtitle: UsedAs<string>?,
	Icon: string?,
	OnClick: (() -> ())?,
	Trailing: Instance?,
	ShowChevron: boolean?,
	Disabled: boolean?,
	[string]: any,
}

export type SettingsListProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	--- Hub rows (iOS Settings style cards)
	Items: { any }?,
	--- Section title above the card group
	Header: UsedAs<string>?,
	Footer: UsedAs<string>?,
	Children: any?,
	InsetGrouped: boolean?,
	[string]: any,
}

export type AppSheetProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Open: UsedAs<boolean>?,
	Title: UsedAs<string>?,
	OnClose: (() -> ())?,
	Children: any?,
	--- Detent height scale 0–1 of host. Default 0.92
	Detent: number?,
	ShowGrabber: boolean?,
	[string]: any,
}

export type StarRatingProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Value: UsedAs<number>?,
	Max: number?,
	OnChanged: ((number) -> ())?,
	ReadOnly: boolean?,
	IconSize: number?,
	[string]: any,
}

export type SegmentedControlProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Items: { { Id: string, Label: string, Icon: string? } },
	Selected: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	Disabled: UsedAs<boolean>?,
	[string]: any,
}

export type TreeNode = {
	Id: string,
	Label: string,
	Icon: string?,
	Children: { TreeNode }?,
}

export type TreeViewProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Nodes: { TreeNode },
	Expanded: UsedAs<{ [string]: boolean }>?,
	Selected: UsedAs<string>?,
	OnSelect: ((id: string) -> ())?,
	OnToggle: ((id: string, expanded: boolean) -> ())?,
	[string]: any,
}

export type CollapsibleProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Title: UsedAs<string>,
	Open: UsedAs<boolean>?,
	OnChanged: ((boolean) -> ())?,
	Children: any?,
	[string]: any,
}

export type ChoiceGroupOption = {
	Value: string,
	Label: string,
	Disabled: boolean?,
}

export type ChoiceGroupProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Options: { ChoiceGroupOption },
	Value: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	Disabled: UsedAs<boolean>?,
	--- "Radio" | "Segmented"
	Variant: ("Radio" | "Segmented")?,
	Validators: { Validator }?,
	Label: UsedAs<string>?,
	[string]: any,
}

export type ScrollAreaProps = {
	Theme: ThemeRef?,
	LayoutOrder: UsedAs<number>?,
	Size: UsedAs<UDim2>?,
	Visible: UsedAs<boolean>?,
	ZIndex: UsedAs<number>?,
	Layer: Instance?,
	Children: any?,
	--- Scroll axis. Default "Vertical".
	Orientation: ("Vertical" | "Horizontal")?,
	ScrollBarThickness: number?,
	ScrollBarColor: Color3?,
	ScrollBarActiveColor: Color3?,
	ScrollBarRailThickness: number?,
	ScrollBarRailBackground: boolean?,
	ScrollBarRailColor: Color3?,
	ScrollBarPadding: number?,
	Smooth: boolean?,
	Inertia: boolean?,
	Keyboard: boolean?,
	AutoCanvas: boolean?,
	CanvasSize: UsedAs<UDim2>?,
	ScrollBarRail: boolean?,
	AutoHideScrollBar: boolean?,
	AutoHideDelay: number?,
	ScrollButtons: boolean?,
	ScrollButtonStep: number?,
	ScrollOffset: UsedAs<number>?,
	OnScroll: ((offset: number) -> ())?,
	--- Rubber-band overscroll for drag / top-edge wheel pull (when OnRefresh is set).
	--- Mid-list and bottom edges hard-clamp on wheel/trackpad. Default true when Inertia.
	Overscroll: boolean?,
	--- Pull action (fires on release past threshold). Vertical only. Not limited to refresh.
	OnRefresh: (() -> ())?,
	--- Called when pull is cancelled (released below threshold after pulling).
	OnPullCancel: (() -> ())?,
	RefreshThreshold: number?,
	--- Show built-in pull hint. Default true when OnRefresh is set.
	PullIndicator: boolean?,
	--- Below threshold while pulling.
	PullHint: string?,
	--- Past threshold — release finger/mouse to confirm.
	ReleaseHint: string?,
	--- Shown under ReleaseHint while armed.
	CancelHint: string?,
	--- Drag anywhere to scroll (touch/mouse). Default: touch, or mouse when OnRefresh is set.
	DragToScroll: boolean?,
	--- "List" (default) stacks children; "None" for absolute/virtual content.
	ContentLayout: ("List" | "None")?,
	--- Padding around list content. Default theme SpaceMd. Use 0 for virtual lists.
	ContentPadding: number?,
	--- Gap between list children. Default theme SpaceLg.
	ListPadding: number?,
	[string]: any,
}

return nil

