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

--- Color3 | hex | RGB {r,g,b} | palette name | full role
export type ColorInput = Color3 | string | { number } | ThemeColorRole

export type ThemeMotion = {
	SpringSpeed: number,
	SpringDamping: number,
	PressScale: number,
}

export type AccessibilityPrefs = {
	ReduceMotion: boolean?,
	PreferredTransparency: number?,
	HighContrast: boolean?,
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
	Layer: GuiObject?,
}

export type ButtonProps = BaseProps & {
	Text: UsedAs<string>?,
	--- Style: Filled | Tonal | Outlined | Text (legacy Primary/Destructive still work)
	Variant: ButtonVariant?,
	--- Palette name, Color3, hex, RGB table, or ThemeColorRole
	Color: UsedAs<ColorInput>?,
	OnClick: (() -> ())?,
	Disabled: UsedAs<boolean>?,
	Icon: string?,
	--- Lucide icon before label
	LeadingIcon: string?,
	--- Lucide icon after label
	TrailingIcon: string?,
}

export type TextFieldResize = "None" | "Y" | "X" | "Both"

export type Validator = (value: any) -> (boolean, string?)

export type TextFieldProps = BaseProps & {
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
}

export type TextProps = BaseProps & {
	Text: UsedAs<string>,
	Variant: TextVariant?,
	Color: UsedAs<Color3>?,
	TextXAlignment: Enum.TextXAlignment?,
	TextWrapped: boolean?,
}

export type ListItemProps = BaseProps & {
	Title: UsedAs<string>,
	Subtitle: UsedAs<string>?,
	OnClick: (() -> ())?,
	Leading: Instance?,
	Trailing: Instance?,
	Disabled: UsedAs<boolean>?,
}

export type ChipProps = BaseProps & {
	Text: UsedAs<string>,
	Selected: UsedAs<boolean>?,
	OnClick: (() -> ())?,
	Disabled: UsedAs<boolean>?,
	LeadingIcon: string?,
	TrailingIcon: string?,
}

export type DialogAction = {
	Text: string,
	Variant: ButtonVariant?,
	Color: ColorInput?,
	OnClick: (() -> ())?,
}

export type DialogProps = BaseProps & {
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
}

export type SurfaceProps = BaseProps & {
	Name: string?,
	Elevated: boolean?,
}

export type OverlayProps = BaseProps & {
	OnClick: (() -> ())?,
}

export type IconProps = BaseProps & {
	Name: string?, -- Lucide icon id
	Image: string?,
	Color: UsedAs<Color3>?,
	IconSize: number?,
	AssetSize: number?,
}

export type IconButtonProps = BaseProps & {
	Name: string?,
	Image: string?,
	OnClick: (() -> ())?,
	Disabled: UsedAs<boolean>?,
}

export type CheckboxProps = BaseProps & {
	Checked: UsedAs<boolean>?,
	Label: UsedAs<string>?,
	OnChanged: ((boolean) -> ())?,
	Disabled: UsedAs<boolean>?,
}

export type SwitchProps = BaseProps & {
	Checked: UsedAs<boolean>?,
	Label: UsedAs<string>?,
	OnChanged: ((boolean) -> ())?,
	Disabled: UsedAs<boolean>?,
	--- Override Theme.Controls.SwitchIcons for this switch.
	Icons: boolean?,
}

export type RadioOption = {
	Value: string,
	Label: string,
}

export type RadioProps = BaseProps & {
	Checked: UsedAs<boolean>,
	Label: UsedAs<string>?,
	OnActivated: (() -> ())?,
	Disabled: UsedAs<boolean>?,
}

export type RadioGroupProps = BaseProps & {
	Options: { RadioOption },
	Value: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	Disabled: UsedAs<boolean>?,
}

export type SelectOption = {
	Value: string,
	Label: string,
}

export type SelectProps = BaseProps & {
	Options: { SelectOption },
	Value: UsedAs<string>?,
	Placeholder: UsedAs<string>?,
	Label: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	Disabled: UsedAs<boolean>?,
	Filterable: boolean?,
	Validators: { Validator }?,
}

export type MultiSelectProps = BaseProps & {
	Options: { SelectOption },
	Value: UsedAs<{ string }>?,
	Placeholder: UsedAs<string>?,
	Label: UsedAs<string>?,
	OnChanged: (({ string }) -> ())?,
	Disabled: UsedAs<boolean>?,
	Validators: { Validator }?,
	--- `Chips` (default) shows a chip per selection; `Count` shows "N selected".
	Display: ("Chips" | "Count")?,
}

export type SpinnerProps = BaseProps & {
	SizePx: number?,
}

export type SliderProps = BaseProps & {
	Value: UsedAs<number>?,
	Min: number?,
	Max: number?,
	Step: number?,
	OnChanged: ((number) -> ())?,
	Disabled: UsedAs<boolean>?,
	Label: UsedAs<string>?,
}

export type RangeSliderProps = BaseProps & {
	Value: UsedAs<NumberRange>?,
	Min: number?,
	Max: number?,
	OnChanged: ((NumberRange) -> ())?,
	Disabled: UsedAs<boolean>?,
}

export type AlertProps = BaseProps & {
	Title: UsedAs<string>?,
	Text: UsedAs<string>,
	Tone: AlertTone?,
}

export type SnackbarProps = BaseProps & {
	Message: UsedAs<string>,
	ActionText: string?,
	OnAction: (() -> ())?,
}

export type SnackbarHostProps = BaseProps & {
	-- Host manages queue via returned API; see Components.SnackbarHost
}

export type ProgressProps = BaseProps & {
	Value: UsedAs<number>?,
	Buffer: UsedAs<number>?,
	Variant: ProgressVariant?,
	Mode: ProgressMode?,
}

export type BadgeProps = BaseProps & {
	Content: Instance,
	Count: UsedAs<number>?,
	Dot: boolean?,
}

export type TabItem = {
	Id: string,
	Label: string,
}

export type TabsProps = BaseProps & {
	Items: { TabItem },
	Selected: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
}

export type DividerProps = BaseProps & {
	Vertical: boolean?,
}

export type CardProps = BaseProps & {
	Title: UsedAs<string>?,
	Subtitle: UsedAs<string>?,
	Children: any?,
}

export type AppBarProps = BaseProps & {
	Title: UsedAs<string>?,
	Leading: Instance?,
	Actions: { Instance }?,
}

export type NavigationDrawerProps = BaseProps & {
	Open: UsedAs<boolean>?,
	Title: UsedAs<string>?,
	Subtitle: UsedAs<string>?,
	AvatarImage: string?,
	AvatarInitials: string?,
	Items: { ListItemProps }?,
	OnClose: (() -> ())?,
	Children: any?,
}

export type NavigationRailProps = BaseProps & {
	Items: { { Id: string, Icon: string?, Label: string?, OnClick: (() -> ())? } },
	Selected: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	--- Default `Vertical` (side rail). `Horizontal` lays items in a row.
	Orientation: ("Vertical" | "Horizontal")?,
}

export type BreadcrumbItem = {
	Label: string,
	OnClick: (() -> ())?,
}

export type BreadcrumbsProps = BaseProps & {
	Items: { BreadcrumbItem },
}

export type PaginationProps = BaseProps & {
	Page: UsedAs<number>?,
	PageCount: number,
	OnChanged: ((number) -> ())?,
}

export type ContainerProps = BaseProps & {
	MaxWidth: number?,
	Children: any?,
}

export type MenuItemProps = {
	Text: string,
	OnClick: (() -> ())?,
	Disabled: boolean?,
}

export type MenuProps = BaseProps & {
	Items: { MenuItemProps },
	Open: UsedAs<boolean>?,
	OnClose: (() -> ())?,
}

export type PopoverProps = BaseProps & {
	Open: UsedAs<boolean>?,
	OnClose: (() -> ())?,
	--- Anchor to position relative to (screen space).
	Target: GuiObject?,
	--- Preferred placement relative to Target.
	Placement: ("Bottom" | "Top" | "Left" | "Right")?,
	Items: { MenuItemProps }?,
	Children: any?,
	Width: number?,
}

export type AvatarMenuProps = BaseProps & {
	Open: UsedAs<boolean>?,
	OnClose: (() -> ())?,
	Target: GuiObject?,
	Image: string?,
	Initials: string?,
	Name: UsedAs<string>?,
	Subtitle: UsedAs<string>?,
	Items: { MenuItemProps }?,
}

export type TooltipPlacement = "Top" | "Bottom" | "Left" | "Right" | "Auto"

export type TooltipProps = BaseProps & {
	Text: UsedAs<string>,
	Target: GuiObject?,
	--- Preferred side of the target. `Auto` picks the side with most room.
	Placement: TooltipPlacement?,
	Gap: number?,
}

export type DatePickerProps = BaseProps & {
	Value: UsedAs<string>?, -- YYYY-MM-DD
	OnChanged: ((string) -> ())?,
}

export type TimePickerProps = BaseProps & {
	Value: UsedAs<number>?, -- seconds from midnight
	OnChanged: ((number) -> ())?,
}

export type ColorPickerProps = BaseProps & {
	Value: UsedAs<Color3>?,
	OnChanged: ((Color3) -> ())?,
}

export type VirtualListProps = BaseProps & {
	ItemCount: UsedAs<number>,
	ItemHeight: number,
	RenderItem: (scope: Scope, index: number) -> Instance,
	Padding: number?,
}

export type DataTableColumn = {
	Id: string,
	Title: string,
	Width: number?,
	Sortable: boolean?,
}

export type DataTableProps = BaseProps & {
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

export type AvatarProps = BaseProps & {
	Image: string?,
	Initials: string?,
	AvatarSize: number?,
}

export type EmptyStateProps = BaseProps & {
	Title: UsedAs<string>,
	Subtitle: UsedAs<string>?,
	Action: ButtonProps?,
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
}

export type SettingsListProps = BaseProps & {
	--- Hub rows (iOS Settings style cards)
	Items: { SettingsListItem }?,
	--- Section title above the card group
	Header: UsedAs<string>?,
	Footer: UsedAs<string>?,
	Children: any?,
	InsetGrouped: boolean?,
}

export type AppSheetProps = BaseProps & {
	Open: UsedAs<boolean>?,
	Title: UsedAs<string>?,
	OnClose: (() -> ())?,
	Children: any?,
	--- Detent height scale 0–1 of host. Default 0.92
	Detent: number?,
	ShowGrabber: boolean?,
}

export type StarRatingProps = BaseProps & {
	Value: UsedAs<number>?,
	Max: number?,
	OnChanged: ((number) -> ())?,
	ReadOnly: boolean?,
	IconSize: number?,
}

export type SegmentedControlProps = BaseProps & {
	Items: { { Id: string, Label: string, Icon: string? } },
	Selected: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	Disabled: UsedAs<boolean>?,
}

export type TreeNode = {
	Id: string,
	Label: string,
	Icon: string?,
	Children: { TreeNode }?,
}

export type TreeViewProps = BaseProps & {
	Nodes: { TreeNode },
	Expanded: UsedAs<{ [string]: boolean }>?,
	Selected: UsedAs<string>?,
	OnSelect: ((id: string) -> ())?,
	OnToggle: ((id: string, expanded: boolean) -> ())?,
}

export type CollapsibleProps = BaseProps & {
	Title: UsedAs<string>,
	Open: UsedAs<boolean>?,
	OnChanged: ((boolean) -> ())?,
	Children: any?,
}

export type ChoiceGroupOption = {
	Value: string,
	Label: string,
	Disabled: boolean?,
}

export type ChoiceGroupProps = BaseProps & {
	Options: { ChoiceGroupOption },
	Value: UsedAs<string>?,
	OnChanged: ((string) -> ())?,
	Disabled: UsedAs<boolean>?,
	--- "Radio" | "Segmented"
	Variant: ("Radio" | "Segmented")?,
	Validators: { Validator }?,
	Label: UsedAs<string>?,
}

export type ScrollAreaProps = BaseProps & {
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
	--- Rubber-band overscroll. Default true when Inertia.
	Overscroll: boolean?,
	--- Pull-to-refresh callback (fires after pull threshold). Vertical only.
	OnRefresh: (() -> ())?,
	RefreshThreshold: number?,
	--- Drag anywhere to scroll (touch/mouse). Default true.
	DragToScroll: boolean?,
	--- "List" (default) stacks children; "None" for absolute/virtual content.
	ContentLayout: ("List" | "None")?,
	--- Padding around list content. Default theme SpaceMd. Use 0 for virtual lists.
	ContentPadding: number?,
	--- Gap between list children. Default theme SpaceLg.
	ListPadding: number?,
}

return nil

