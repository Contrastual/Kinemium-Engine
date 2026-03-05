--!strict
--!optimize 2
--!native

local ffi = zune.ffi

local _GtkAccessibleInterface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ get_at_context = ffi.types.pointer },
	{ get_platform_state = ffi.types.pointer },
	{ get_accessible_parent = ffi.types.pointer },
	{ get_first_accessible_child = ffi.types.pointer },
	{ get_next_accessible_sibling = ffi.types.pointer },
	{ get_bounds = ffi.types.pointer },
})
export type _GtkAccessibleInterface = typeof(_GtkAccessibleInterface:new({}))

local _GtkAccessibleRangeInterface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ set_current_value = ffi.types.pointer },
})
export type _GtkAccessibleRangeInterface = typeof(_GtkAccessibleRangeInterface:new({}))

local GtkAccessibleTextRange = ffi.struct({
	{ start = ffi.types.pointer },
	{ length = ffi.types.pointer },
})
export type GtkAccessibleTextRange = typeof(GtkAccessibleTextRange:new({}))

local _GtkAccessibleTextInterface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ get_contents = ffi.types.pointer },
	{ get_contents_at = ffi.types.pointer },
	{ get_caret_position = ffi.types.pointer },
	{ get_selection = ffi.types.pointer },
	{ get_attributes = ffi.types.pointer },
	{ get_default_attributes = ffi.types.pointer },
	{ get_extents = ffi.types.pointer },
	{ get_offset = ffi.types.pointer },
})
export type _GtkAccessibleTextInterface = typeof(_GtkAccessibleTextInterface:new({}))

local _GtkActionableInterface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ get_action_name = ffi.types.pointer },
	{ set_action_name = ffi.types.pointer },
	{ get_action_target_value = ffi.types.pointer },
	{ set_action_target_value = ffi.types.pointer },
})
export type _GtkActionableInterface = typeof(_GtkActionableInterface:new({}))

local _GtkAdjustment = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkAdjustment = typeof(_GtkAdjustment:new({}))

local _GtkAdjustmentClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ changed = ffi.types.pointer },
	{ value_changed = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
})
export type _GtkAdjustmentClass = typeof(_GtkAdjustmentClass:new({}))

local _GtkApplication = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkApplication = typeof(_GtkApplication:new({}))

local _GtkApplicationClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ window_added = ffi.types.pointer },
	{ window_removed = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkApplicationClass = typeof(_GtkApplicationClass:new({}))

local _GtkApplicationWindow = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkApplicationWindow = typeof(_GtkApplicationWindow:new({}))

local _GtkApplicationWindowClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkApplicationWindowClass = typeof(_GtkApplicationWindowClass:new({}))

local _GtkBitsetIter = ffi.struct({
	{ private_data = ffi.types.pointer:array(10) },
})
export type _GtkBitsetIter = typeof(_GtkBitsetIter:new({}))

local _GtkBorder = ffi.struct({
	{ left = ffi.types.pointer },
	{ right = ffi.types.pointer },
	{ top = ffi.types.pointer },
	{ bottom = ffi.types.pointer },
})
export type _GtkBorder = typeof(_GtkBorder:new({}))

local _GtkBox = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkBox = typeof(_GtkBox:new({}))

local _GtkBoxClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkBoxClass = typeof(_GtkBoxClass:new({}))

local _GtkBuildableParser = ffi.struct({
	{ start_element = ffi.types.pointer },
	{ end_element = ffi.types.pointer },
	{ text = ffi.types.pointer },
	{ error = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(4) },
})
export type _GtkBuildableParser = typeof(_GtkBuildableParser:new({}))

local _GtkBuildableIface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ set_id = ffi.types.pointer },
	{ get_id = ffi.types.pointer },
	{ add_child = ffi.types.pointer },
	{ set_buildable_property = ffi.types.pointer },
	{ construct_child = ffi.types.pointer },
	{ custom_tag_start = ffi.types.pointer },
	{ custom_tag_end = ffi.types.pointer },
	{ custom_finished = ffi.types.pointer },
	{ parser_finished = ffi.types.pointer },
	{ get_internal_child = ffi.types.pointer },
})
export type _GtkBuildableIface = typeof(_GtkBuildableIface:new({}))

local _GtkBuilderScopeInterface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ get_type_from_name = ffi.types.pointer },
	{ get_type_from_function = ffi.types.pointer },
	{ create_closure = ffi.types.pointer },
})
export type _GtkBuilderScopeInterface = typeof(_GtkBuilderScopeInterface:new({}))

local _GtkBuilderCScopeClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
})
export type _GtkBuilderCScopeClass = typeof(_GtkBuilderCScopeClass:new({}))

local _GtkButton = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkButton = typeof(_GtkButton:new({}))

local _GtkButtonClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ clicked = ffi.types.pointer },
	{ activate = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkButtonClass = typeof(_GtkButtonClass:new({}))

local _GtkCheckButton = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkCheckButton = typeof(_GtkCheckButton:new({}))

local _GtkCheckButtonClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ toggled = ffi.types.pointer },
	{ activate = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(7) },
})
export type _GtkCheckButtonClass = typeof(_GtkCheckButtonClass:new({}))

local _GtkCssProvider = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkCssProvider = typeof(_GtkCssProvider:new({}))

local _GtkDrawingArea = ffi.struct({
	{ widget = ffi.types.pointer },
})
export type _GtkDrawingArea = typeof(_GtkDrawingArea:new({}))

local _GtkDrawingAreaClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ resize = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkDrawingAreaClass = typeof(_GtkDrawingAreaClass:new({}))

local _GtkEditableInterface = ffi.struct({
	{ base_iface = ffi.types.pointer },
	{ insert_text = ffi.types.pointer },
	{ delete_text = ffi.types.pointer },
	{ changed = ffi.types.pointer },
	{ get_text = ffi.types.pointer },
	{ do_insert_text = ffi.types.pointer },
	{ do_delete_text = ffi.types.pointer },
	{ get_selection_bounds = ffi.types.pointer },
	{ set_selection_bounds = ffi.types.pointer },
	{ get_delegate = ffi.types.pointer },
})
export type _GtkEditableInterface = typeof(_GtkEditableInterface:new({}))

local _GtkEntry = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkEntry = typeof(_GtkEntry:new({}))

local _GtkEntryClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ activate = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkEntryClass = typeof(_GtkEntryClass:new({}))

local _GtkEntryBuffer = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkEntryBuffer = typeof(_GtkEntryBuffer:new({}))

local _GtkEntryBufferClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ inserted_text = ffi.types.pointer },
	{ deleted_text = ffi.types.pointer },
	{ get_text = ffi.types.pointer },
	{ get_length = ffi.types.pointer },
	{ insert_text = ffi.types.pointer },
	{ delete_text = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
	{ _gtk_reserved5 = ffi.types.pointer },
	{ _gtk_reserved6 = ffi.types.pointer },
	{ _gtk_reserved7 = ffi.types.pointer },
	{ _gtk_reserved8 = ffi.types.pointer },
})
export type _GtkEntryBufferClass = typeof(_GtkEntryBufferClass:new({}))

local GtkParamSpecExpression = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type GtkParamSpecExpression = typeof(GtkParamSpecExpression:new({}))

local _GtkFilterClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ match = ffi.types.pointer },
	{ get_strictness = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
	{ _gtk_reserved5 = ffi.types.pointer },
	{ _gtk_reserved6 = ffi.types.pointer },
	{ _gtk_reserved7 = ffi.types.pointer },
	{ _gtk_reserved8 = ffi.types.pointer },
})
export type _GtkFilterClass = typeof(_GtkFilterClass:new({}))

local _GtkFixed = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkFixed = typeof(_GtkFixed:new({}))

local _GtkFixedClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkFixedClass = typeof(_GtkFixedClass:new({}))

local _GtkFlowBoxChild = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkFlowBoxChild = typeof(_GtkFlowBoxChild:new({}))

local _GtkFlowBoxChildClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ activate = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkFlowBoxChildClass = typeof(_GtkFlowBoxChildClass:new({}))

local _GtkFrame = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkFrame = typeof(_GtkFrame:new({}))

local _GtkFrameClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ compute_child_allocation = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkFrameClass = typeof(_GtkFrameClass:new({}))

local _GtkGLArea = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkGLArea = typeof(_GtkGLArea:new({}))

local _GtkGLAreaClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ render = ffi.types.pointer },
	{ resize = ffi.types.pointer },
	{ create_context = ffi.types.pointer },
	{ _padding = ffi.types.pointer:array(8) },
})
export type _GtkGLAreaClass = typeof(_GtkGLAreaClass:new({}))

local _GtkGrid = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkGrid = typeof(_GtkGrid:new({}))

local _GtkGridClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkGridClass = typeof(_GtkGridClass:new({}))

local _GtkIMContext = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkIMContext = typeof(_GtkIMContext:new({}))

local _GtkIMContextClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ preedit_start = ffi.types.pointer },
	{ preedit_end = ffi.types.pointer },
	{ preedit_changed = ffi.types.pointer },
	{ commit = ffi.types.pointer },
	{ retrieve_surrounding = ffi.types.pointer },
	{ delete_surrounding = ffi.types.pointer },
	{ set_client_widget = ffi.types.pointer },
	{ get_preedit_string = ffi.types.pointer },
	{ filter_keypress = ffi.types.pointer },
	{ focus_in = ffi.types.pointer },
	{ focus_out = ffi.types.pointer },
	{ reset = ffi.types.pointer },
	{ set_cursor_location = ffi.types.pointer },
	{ set_use_preedit = ffi.types.pointer },
	{ set_surrounding = ffi.types.pointer },
	{ get_surrounding = ffi.types.pointer },
	{ set_surrounding_with_selection = ffi.types.pointer },
	{ get_surrounding_with_selection = ffi.types.pointer },
	{ activate_osk = ffi.types.pointer },
	{ activate_osk_with_event = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
})
export type _GtkIMContextClass = typeof(_GtkIMContextClass:new({}))

local _GtkIMContextSimple = ffi.struct({
	{ object = ffi.types.pointer },
	{ priv = ffi.types.pointer },
})
export type _GtkIMContextSimple = typeof(_GtkIMContextSimple:new({}))

local _GtkIMContextSimpleClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
})
export type _GtkIMContextSimpleClass = typeof(_GtkIMContextSimpleClass:new({}))

local _GtkIMMulticontext = ffi.struct({
	{ object = ffi.types.pointer },
	{ priv = ffi.types.pointer },
})
export type _GtkIMMulticontext = typeof(_GtkIMMulticontext:new({}))

local _GtkIMMulticontextClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
})
export type _GtkIMMulticontextClass = typeof(_GtkIMMulticontextClass:new({}))

local _GtkLayoutChildClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
})
export type _GtkLayoutChildClass = typeof(_GtkLayoutChildClass:new({}))

local _GtkLayoutManagerClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ get_request_mode = ffi.types.pointer },
	{ measure = ffi.types.pointer },
	{ allocate = ffi.types.pointer },
	{ layout_child_type = ffi.types.pointer },
	{ create_layout_child = ffi.types.pointer },
	{ root = ffi.types.pointer },
	{ unroot = ffi.types.pointer },
	{ _padding = ffi.types.pointer:array(16) },
})
export type _GtkLayoutManagerClass = typeof(_GtkLayoutManagerClass:new({}))

local _GtkListBoxRow = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkListBoxRow = typeof(_GtkListBoxRow:new({}))

local _GtkListBoxRowClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ activate = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkListBoxRowClass = typeof(_GtkListBoxRowClass:new({}))

local _GtkMediaFileClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ open = ffi.types.pointer },
	{ close = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
})
export type _GtkMediaFileClass = typeof(_GtkMediaFileClass:new({}))

local _GtkMediaStreamClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ play = ffi.types.pointer },
	{ pause = ffi.types.pointer },
	{ seek = ffi.types.pointer },
	{ update_audio = ffi.types.pointer },
	{ realize = ffi.types.pointer },
	{ unrealize = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
	{ _gtk_reserved5 = ffi.types.pointer },
	{ _gtk_reserved6 = ffi.types.pointer },
	{ _gtk_reserved7 = ffi.types.pointer },
	{ _gtk_reserved8 = ffi.types.pointer },
})
export type _GtkMediaStreamClass = typeof(_GtkMediaStreamClass:new({}))

local _GtkMountOperation = ffi.struct({
	{ parent_instance = ffi.types.pointer },
	{ priv = ffi.types.pointer },
})
export type _GtkMountOperation = typeof(_GtkMountOperation:new({}))

local _GtkMountOperationClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
})
export type _GtkMountOperationClass = typeof(_GtkMountOperationClass:new({}))

local _GtkNativeDialogClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ response = ffi.types.pointer },
	{ show = ffi.types.pointer },
	{ hide = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
})
export type _GtkNativeDialogClass = typeof(_GtkNativeDialogClass:new({}))

local _GtkOrientableIface = ffi.struct({
	{ base_iface = ffi.types.pointer },
})
export type _GtkOrientableIface = typeof(_GtkOrientableIface:new({}))

local _GtkPadActionEntry = ffi.struct({
	{ type = ffi.types.pointer },
	{ index = ffi.types.i32 },
	{ mode = ffi.types.i32 },
	{ label = ffi.types.pointer },
	{ action_name = ffi.types.pointer },
})
export type _GtkPadActionEntry = typeof(_GtkPadActionEntry:new({}))

local _GtkPopover = ffi.struct({
	{ parent = ffi.types.pointer },
})
export type _GtkPopover = typeof(_GtkPopover:new({}))

local _GtkPopoverClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ closed = ffi.types.pointer },
	{ activate_default = ffi.types.pointer },
	{ reserved = ffi.types.pointer:array(8) },
})
export type _GtkPopoverClass = typeof(_GtkPopoverClass:new({}))

local _GtkRange = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkRange = typeof(_GtkRange:new({}))

local _GtkRangeClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ value_changed = ffi.types.pointer },
	{ adjust_bounds = ffi.types.pointer },
	{ move_slider = ffi.types.pointer },
	{ get_range_border = ffi.types.pointer },
	{ change_value = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkRangeClass = typeof(_GtkRangeClass:new({}))

local _GtkRecentData = ffi.struct({
	{ display_name = ffi.types.pointer },
	{ description = ffi.types.pointer },
	{ mime_type = ffi.types.pointer },
	{ app_name = ffi.types.pointer },
	{ app_exec = ffi.types.pointer },
	{ groups = ffi.types.pointer },
	{ is_private = ffi.types.pointer },
})
export type _GtkRecentData = typeof(_GtkRecentData:new({}))

local _GtkRecentManager = ffi.struct({
	{ parent_instance = ffi.types.pointer },
	{ priv = ffi.types.pointer },
})
export type _GtkRecentManager = typeof(_GtkRecentManager:new({}))

local _GtkRecentManagerClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ changed = ffi.types.pointer },
	{ _gtk_recent1 = ffi.types.pointer },
	{ _gtk_recent2 = ffi.types.pointer },
	{ _gtk_recent3 = ffi.types.pointer },
	{ _gtk_recent4 = ffi.types.pointer },
})
export type _GtkRecentManagerClass = typeof(_GtkRecentManagerClass:new({}))

local _GtkScale = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkScale = typeof(_GtkScale:new({}))

local _GtkScaleClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ get_layout_offsets = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkScaleClass = typeof(_GtkScaleClass:new({}))

local _GtkScaleButton = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkScaleButton = typeof(_GtkScaleButton:new({}))

local _GtkScaleButtonClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ value_changed = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkScaleButtonClass = typeof(_GtkScaleButtonClass:new({}))

local _GtkScrollableInterface = ffi.struct({
	{ base_iface = ffi.types.pointer },
	{ get_border = ffi.types.pointer },
})
export type _GtkScrollableInterface = typeof(_GtkScrollableInterface:new({}))

local _GtkSectionModelInterface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ get_section = ffi.types.pointer },
})
export type _GtkSectionModelInterface = typeof(_GtkSectionModelInterface:new({}))

local _GtkSelectionModelInterface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ is_selected = ffi.types.pointer },
	{ get_selection_in_range = ffi.types.pointer },
	{ select_item = ffi.types.pointer },
	{ unselect_item = ffi.types.pointer },
	{ select_range = ffi.types.pointer },
	{ unselect_range = ffi.types.pointer },
	{ select_all = ffi.types.pointer },
	{ unselect_all = ffi.types.pointer },
	{ set_selection = ffi.types.pointer },
})
export type _GtkSelectionModelInterface = typeof(_GtkSelectionModelInterface:new({}))

local _GtkShortcutManagerInterface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ add_controller = ffi.types.pointer },
	{ remove_controller = ffi.types.pointer },
})
export type _GtkShortcutManagerInterface = typeof(_GtkShortcutManagerInterface:new({}))

local _GtkSizeGroup = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkSizeGroup = typeof(_GtkSizeGroup:new({}))

local _GtkRequestedSize = ffi.struct({
	{ data = ffi.types.pointer },
	{ minimum_size = ffi.types.i32 },
	{ natural_size = ffi.types.i32 },
})
export type _GtkRequestedSize = typeof(_GtkRequestedSize:new({}))

local _GtkSorterClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ compare = ffi.types.pointer },
	{ get_order = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
	{ _gtk_reserved5 = ffi.types.pointer },
	{ _gtk_reserved6 = ffi.types.pointer },
	{ _gtk_reserved7 = ffi.types.pointer },
	{ _gtk_reserved8 = ffi.types.pointer },
})
export type _GtkSorterClass = typeof(_GtkSorterClass:new({}))

local _GtkSymbolicPaintableInterface = ffi.struct({
	{ g_iface = ffi.types.pointer },
	{ snapshot_symbolic = ffi.types.pointer },
})
export type _GtkSymbolicPaintableInterface = typeof(_GtkSymbolicPaintableInterface:new({}))

local _GtkText = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkText = typeof(_GtkText:new({}))

local _GtkTextBuffer = ffi.struct({
	{ parent_instance = ffi.types.pointer },
	{ priv = ffi.types.pointer },
})
export type _GtkTextBuffer = typeof(_GtkTextBuffer:new({}))

local _GtkTextBufferClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ insert_text = ffi.types.pointer },
	{ insert_paintable = ffi.types.pointer },
	{ insert_child_anchor = ffi.types.pointer },
	{ delete_range = ffi.types.pointer },
	{ changed = ffi.types.pointer },
	{ modified_changed = ffi.types.pointer },
	{ mark_set = ffi.types.pointer },
	{ mark_deleted = ffi.types.pointer },
	{ apply_tag = ffi.types.pointer },
	{ remove_tag = ffi.types.pointer },
	{ begin_user_action = ffi.types.pointer },
	{ end_user_action = ffi.types.pointer },
	{ paste_done = ffi.types.pointer },
	{ undo = ffi.types.pointer },
	{ redo = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
})
export type _GtkTextBufferClass = typeof(_GtkTextBufferClass:new({}))

local _GtkTextChildAnchor = ffi.struct({
	{ parent_instance = ffi.types.pointer },
	{ segment = ffi.types.pointer },
})
export type _GtkTextChildAnchor = typeof(_GtkTextChildAnchor:new({}))

local _GtkTextChildAnchorClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
})
export type _GtkTextChildAnchorClass = typeof(_GtkTextChildAnchorClass:new({}))

local _GtkTextIter = ffi.struct({
	{ dummy1 = ffi.types.pointer },
	{ dummy2 = ffi.types.pointer },
	{ dummy3 = ffi.types.i32 },
	{ dummy4 = ffi.types.i32 },
	{ dummy5 = ffi.types.i32 },
	{ dummy6 = ffi.types.i32 },
	{ dummy7 = ffi.types.i32 },
	{ dummy8 = ffi.types.i32 },
	{ dummy9 = ffi.types.pointer },
	{ dummy10 = ffi.types.pointer },
	{ dummy11 = ffi.types.i32 },
	{ dummy12 = ffi.types.i32 },
	{ dummy13 = ffi.types.i32 },
	{ dummy14 = ffi.types.pointer },
})
export type _GtkTextIter = typeof(_GtkTextIter:new({}))

local _GtkTextMark = ffi.struct({
	{ parent_instance = ffi.types.pointer },
	{ segment = ffi.types.pointer },
})
export type _GtkTextMark = typeof(_GtkTextMark:new({}))

local _GtkTextMarkClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkTextMarkClass = typeof(_GtkTextMarkClass:new({}))

local _GtkTextTag = ffi.struct({
	{ parent_instance = ffi.types.pointer },
	{ priv = ffi.types.pointer },
})
export type _GtkTextTag = typeof(_GtkTextTag:new({}))

local _GtkTextTagClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkTextTagClass = typeof(_GtkTextTagClass:new({}))

local _GtkTextView = ffi.struct({
	{ parent_instance = ffi.types.pointer },
	{ priv = ffi.types.pointer },
})
export type _GtkTextView = typeof(_GtkTextView:new({}))

local _GtkTextViewClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ move_cursor = ffi.types.pointer },
	{ set_anchor = ffi.types.pointer },
	{ insert_at_cursor = ffi.types.pointer },
	{ delete_from_cursor = ffi.types.pointer },
	{ backspace = ffi.types.pointer },
	{ cut_clipboard = ffi.types.pointer },
	{ copy_clipboard = ffi.types.pointer },
	{ paste_clipboard = ffi.types.pointer },
	{ toggle_overwrite = ffi.types.pointer },
	{ create_buffer = ffi.types.pointer },
	{ snapshot_layer = ffi.types.pointer },
	{ extend_selection = ffi.types.pointer },
	{ insert_emoji = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkTextViewClass = typeof(_GtkTextViewClass:new({}))

local _GtkToggleButton = ffi.struct({
	{ button = ffi.types.pointer },
})
export type _GtkToggleButton = typeof(_GtkToggleButton:new({}))

local _GtkToggleButtonClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ toggled = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkToggleButtonClass = typeof(_GtkToggleButtonClass:new({}))

local _GtkRequisition = ffi.struct({
	{ width = ffi.types.i32 },
	{ height = ffi.types.i32 },
})
export type _GtkRequisition = typeof(_GtkRequisition:new({}))

local _GtkWidget = ffi.struct({
	{ parent_instance = ffi.types.pointer },
	{ priv = ffi.types.pointer },
})
export type _GtkWidget = typeof(_GtkWidget:new({}))

local _GtkWidgetClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ show = ffi.types.pointer },
	{ hide = ffi.types.pointer },
	{ map = ffi.types.pointer },
	{ unmap = ffi.types.pointer },
	{ realize = ffi.types.pointer },
	{ unrealize = ffi.types.pointer },
	{ root = ffi.types.pointer },
	{ unroot = ffi.types.pointer },
	{ size_allocate = ffi.types.pointer },
	{ state_flags_changed = ffi.types.pointer },
	{ direction_changed = ffi.types.pointer },
	{ get_request_mode = ffi.types.pointer },
	{ measure = ffi.types.pointer },
	{ mnemonic_activate = ffi.types.pointer },
	{ grab_focus = ffi.types.pointer },
	{ focus = ffi.types.pointer },
	{ set_focus_child = ffi.types.pointer },
	{ move_focus = ffi.types.pointer },
	{ keynav_failed = ffi.types.pointer },
	{ query_tooltip = ffi.types.pointer },
	{ compute_expand = ffi.types.pointer },
	{ css_changed = ffi.types.pointer },
	{ system_setting_changed = ffi.types.pointer },
	{ snapshot = ffi.types.pointer },
	{ contains = ffi.types.pointer },
	{ priv = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkWidgetClass = typeof(_GtkWidgetClass:new({}))

local _GtkWindow = ffi.struct({
	{ parent_instance = ffi.types.pointer },
})
export type _GtkWindow = typeof(_GtkWindow:new({}))

local _GtkWindowClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ activate_focus = ffi.types.pointer },
	{ activate_default = ffi.types.pointer },
	{ keys_changed = ffi.types.pointer },
	{ enable_debugging = ffi.types.pointer },
	{ close_request = ffi.types.pointer },
	{ padding = ffi.types.pointer:array(8) },
})
export type _GtkWindowClass = typeof(_GtkWindowClass:new({}))

local _GtkWindowGroup = ffi.struct({
	{ parent_instance = ffi.types.pointer },
	{ priv = ffi.types.pointer },
})
export type _GtkWindowGroup = typeof(_GtkWindowGroup:new({}))

local _GtkWindowGroupClass = ffi.struct({
	{ parent_class = ffi.types.pointer },
	{ _gtk_reserved1 = ffi.types.pointer },
	{ _gtk_reserved2 = ffi.types.pointer },
	{ _gtk_reserved3 = ffi.types.pointer },
	{ _gtk_reserved4 = ffi.types.pointer },
})
export type _GtkWindowGroupClass = typeof(_GtkWindowGroupClass:new({}))

local structs = {
	_GtkAccessibleInterface = _GtkAccessibleInterface,
	_GtkAccessibleRangeInterface = _GtkAccessibleRangeInterface,
	GtkAccessibleTextRange = GtkAccessibleTextRange,
	_GtkAccessibleTextInterface = _GtkAccessibleTextInterface,
	_GtkActionableInterface = _GtkActionableInterface,
	_GtkAdjustment = _GtkAdjustment,
	_GtkAdjustmentClass = _GtkAdjustmentClass,
	_GtkApplication = _GtkApplication,
	_GtkApplicationClass = _GtkApplicationClass,
	_GtkApplicationWindow = _GtkApplicationWindow,
	_GtkApplicationWindowClass = _GtkApplicationWindowClass,
	_GtkBitsetIter = _GtkBitsetIter,
	_GtkBorder = _GtkBorder,
	_GtkBox = _GtkBox,
	_GtkBoxClass = _GtkBoxClass,
	_GtkBuildableParser = _GtkBuildableParser,
	_GtkBuildableIface = _GtkBuildableIface,
	_GtkBuilderScopeInterface = _GtkBuilderScopeInterface,
	_GtkBuilderCScopeClass = _GtkBuilderCScopeClass,
	_GtkButton = _GtkButton,
	_GtkButtonClass = _GtkButtonClass,
	_GtkCheckButton = _GtkCheckButton,
	_GtkCheckButtonClass = _GtkCheckButtonClass,
	_GtkCssProvider = _GtkCssProvider,
	_GtkDrawingArea = _GtkDrawingArea,
	_GtkDrawingAreaClass = _GtkDrawingAreaClass,
	_GtkEditableInterface = _GtkEditableInterface,
	_GtkEntry = _GtkEntry,
	_GtkEntryClass = _GtkEntryClass,
	_GtkEntryBuffer = _GtkEntryBuffer,
	_GtkEntryBufferClass = _GtkEntryBufferClass,
	GtkParamSpecExpression = GtkParamSpecExpression,
	_GtkFilterClass = _GtkFilterClass,
	_GtkFixed = _GtkFixed,
	_GtkFixedClass = _GtkFixedClass,
	_GtkFlowBoxChild = _GtkFlowBoxChild,
	_GtkFlowBoxChildClass = _GtkFlowBoxChildClass,
	_GtkFrame = _GtkFrame,
	_GtkFrameClass = _GtkFrameClass,
	_GtkGLArea = _GtkGLArea,
	_GtkGLAreaClass = _GtkGLAreaClass,
	_GtkGrid = _GtkGrid,
	_GtkGridClass = _GtkGridClass,
	_GtkIMContext = _GtkIMContext,
	_GtkIMContextClass = _GtkIMContextClass,
	_GtkIMContextSimple = _GtkIMContextSimple,
	_GtkIMContextSimpleClass = _GtkIMContextSimpleClass,
	_GtkIMMulticontext = _GtkIMMulticontext,
	_GtkIMMulticontextClass = _GtkIMMulticontextClass,
	_GtkLayoutChildClass = _GtkLayoutChildClass,
	_GtkLayoutManagerClass = _GtkLayoutManagerClass,
	_GtkListBoxRow = _GtkListBoxRow,
	_GtkListBoxRowClass = _GtkListBoxRowClass,
	_GtkMediaFileClass = _GtkMediaFileClass,
	_GtkMediaStreamClass = _GtkMediaStreamClass,
	_GtkMountOperation = _GtkMountOperation,
	_GtkMountOperationClass = _GtkMountOperationClass,
	_GtkNativeDialogClass = _GtkNativeDialogClass,
	_GtkOrientableIface = _GtkOrientableIface,
	_GtkPadActionEntry = _GtkPadActionEntry,
	_GtkPopover = _GtkPopover,
	_GtkPopoverClass = _GtkPopoverClass,
	_GtkRange = _GtkRange,
	_GtkRangeClass = _GtkRangeClass,
	_GtkRecentData = _GtkRecentData,
	_GtkRecentManager = _GtkRecentManager,
	_GtkRecentManagerClass = _GtkRecentManagerClass,
	_GtkScale = _GtkScale,
	_GtkScaleClass = _GtkScaleClass,
	_GtkScaleButton = _GtkScaleButton,
	_GtkScaleButtonClass = _GtkScaleButtonClass,
	_GtkScrollableInterface = _GtkScrollableInterface,
	_GtkSectionModelInterface = _GtkSectionModelInterface,
	_GtkSelectionModelInterface = _GtkSelectionModelInterface,
	_GtkShortcutManagerInterface = _GtkShortcutManagerInterface,
	_GtkSizeGroup = _GtkSizeGroup,
	_GtkRequestedSize = _GtkRequestedSize,
	_GtkSorterClass = _GtkSorterClass,
	_GtkSymbolicPaintableInterface = _GtkSymbolicPaintableInterface,
	_GtkText = _GtkText,
	_GtkTextBuffer = _GtkTextBuffer,
	_GtkTextBufferClass = _GtkTextBufferClass,
	_GtkTextChildAnchor = _GtkTextChildAnchor,
	_GtkTextChildAnchorClass = _GtkTextChildAnchorClass,
	_GtkTextIter = _GtkTextIter,
	_GtkTextMark = _GtkTextMark,
	_GtkTextMarkClass = _GtkTextMarkClass,
	_GtkTextTag = _GtkTextTag,
	_GtkTextTagClass = _GtkTextTagClass,
	_GtkTextView = _GtkTextView,
	_GtkTextViewClass = _GtkTextViewClass,
	_GtkToggleButton = _GtkToggleButton,
	_GtkToggleButtonClass = _GtkToggleButtonClass,
	_GtkRequisition = _GtkRequisition,
	_GtkWidget = _GtkWidget,
	_GtkWidgetClass = _GtkWidgetClass,
	_GtkWindow = _GtkWindow,
	_GtkWindowClass = _GtkWindowClass,
	_GtkWindowGroup = _GtkWindowGroup,
	_GtkWindowGroupClass = _GtkWindowGroupClass,
}

return structs
