export type Padding = {
	left: number?,
	right: number?,
	top: number?,
	bottom: number?,
}

export type Components =
	"badge"
	| "button"
	| "card"
	| "checkbox"
	| "colorPicker"
	| "divider"
	| "githistory"
	| "poll"
	| "dropdown"
	| "pie"
	| "frame"
	| "graph"
	| "iconButton"
	| "image"
	| "imageButton"
	| "textButton"
	| "label"
	| "menu"
	| "apibrowser"
	| "itemcard"
	| "imageTextButton"
	| "progressBar"
	| "prompt"
	| "navigation"
	| "radioButton"
	| "slider"
	| "spinner"
	| "stepper"
	| "switch"
	| "tabs"
	| "textInput"
	| "toggle"
	| "tooltip"
	| "fileSearch"
	| "toast"
	| "commandPalette"
	| "projectCard"
	| "hstack"
	| "vstack"
	| "flex"
	| "textbox"
	| "keyboard"

export type ComponentConfig = {
	comp: Components,

	-- Base Properties
	x: number?,
	y: number?,
	width: number?,
	height: number?,

	-- Text Properties
	text: string?,
	font: any?,
	fontSize: number?,
	textColor: any?,

	-- Styling Properties
	class: string?,
	backgroundColor: any?,
	backgroundTransparency: number?,
	hoverColor: any?,
	pressColor: any?,
	rounded: { any }?, -- { radius, segments }

	-- Image Properties
	icon: any?,
	image: any?,
	imageColor: any?,
	imageTransparency: number?,

	-- Layout & Flexbox Properties
	direction: string?,
	justifyContent: string?,
	alignItems: string?,
	flexWrap: string?,
	gap: number?,
	padding: Padding?,

	layoutOrder: number?,
	flexGrow: number?,
	flexShrink: number?,
	aspectRatio: number?,
	minWidth: number?,
	minHeight: number?,
	maxWidth: number?,
	maxHeight: number?,

	-- Interactions
	onClick: (() -> ())?,

	[string]: any,
}

export type CreationOutput = {
	render: (dt: number) -> (),
	get: (object: string) -> (),
}

export type CreationStructure = {
	[string]: ComponentConfig,
}

return {}
