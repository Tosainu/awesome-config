local filesystem    = require("gears.filesystem")
local theme_assets  = require("beautiful.theme_assets")
local xresources    = require("beautiful.xresources")

-- inherit default theme
local theme = dofile(filesystem.get_themes_dir() .. "default/theme.lua")

-- fonts
theme.font = "Sans Medium 10"

theme.notification_font = "Sans Medium 9"
theme.notification_width = 448
theme.notification_icon_size = 64

theme.menu_font = "Sans Medium 9"
theme.menu_height = 18
theme.wibar_height = 20

-- colors
theme.bg_normal     = "#212121"
theme.bg_focus      = "#616161"
theme.bg_urgent     = "#f44336"
theme.bg_minimize   = "#424242"
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = "#fafafa"
theme.fg_focus      = theme.fg_normal
theme.fg_urgent     = theme.fg_normal
theme.fg_minimize   = theme.fg_normal

theme.border_normal = theme.bg_normal
theme.border_focus  = "#757575"
theme.border_marked = theme.border_focus

-- Generate taglist squares:
local taglist_square_size = xresources.apply_dpi(5)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
  taglist_square_size, theme.fg_normal
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
  taglist_square_size, theme.fg_normal
)

theme.systray_icon_spacing = xresources.apply_dpi(2)

local wallpaper = os.getenv("HOME") .. "/Pictures/wall.png"
if filesystem.file_readable(wallpaper) then
  theme.wallpaper = wallpaper
end

return theme
-- vim:set foldmethod=marker:
