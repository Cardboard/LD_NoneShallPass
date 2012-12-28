function love.conf(t)
	t.title = "NONE SHALL PASS"
	t.author = "cardboard"
	t.version = "0.8.0"
	-- set up window variables so they can be accessed whenever needed
	window = {}
	window.width = 960
	window.height = 640
	t.screen.width = window.width
	t.screen.height = window.height
	-- random crap
	t.screen.fullscreen = false
	t.fsaa = 0
	t.verticalsync = true
	-- console
	t.console = true

end