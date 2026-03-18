c = {}
c.paths = {}
c.appearance = {}
c.features = {}
c.advanced = {}

c.paths.yabai = "/opt/homebrew/bin/yabai"

c.appearance.color = { white = 0.90 }
c.appearance.alpha = 1
c.appearance.dimmer = 2.5
c.appearance.iconDimmer = 1.1
c.appearance.showIcons = true
c.appearance.size = 32
c.appearance.radius = 3
c.appearance.iconPadding = 4
c.appearance.pillThinness = 6
c.appearance.vertSpacing = 1.2

c.appearance.offset = {}
c.appearance.offset.y = 2
c.appearance.offset.x = 4

c.appearance.shouldFade = true
c.appearance.fadeDuration = 0.2

c.features.clickToFocus = true
c.features.hsBugWorkaround = true

c.features.fzyFrameDetect = {}
c.features.fzyFrameDetect.enabled = true
c.features.fzyFrameDetect.fuzzFactor = 30

c.features.winTitles = "not_implemented"
c.features.dynamicLuminosity = "not_implemented"

c.advanced.maxRefreshRate = 0.5

return c
