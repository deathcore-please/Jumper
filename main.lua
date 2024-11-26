function love.load()

    love.window.setMode(1000, 768)
    anim8 = require 'libraries/anim8/anim8'
    wf = require 'libraries/windfield/windfield'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'

    cam = cameraFile()
    background = love.graphics.newImage('sprites/background.png')

    sprites = {}
    platforms = {}
    animations = {}
    sounds = {}
    sounds.jump = love.audio.newSource("sounds/jump.wav", "static")
    sounds.music = love.audio.newSource("sounds/music.mp3", "stream")
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.2)

    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png')
    sprites.enemySheet = love.graphics.newImage('sprites/enemySheet.png')
    local grid = anim8.newGrid(614, 564, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())
    local enemyGrid = anim8.newGrid(100, 79, sprites.enemySheet:getWidth(), sprites.enemySheet:getHeight())

    animations.enemy = anim8.newAnimation(enemyGrid('1-2', 1), 0.03)
    animations.idle = anim8.newAnimation(grid('1-15', 1), 0.05)
    animations.jump = anim8.newAnimation(grid('1-7', 2), 0.05)
    animations.run = anim8.newAnimation(grid('1-15', 3), 0.038)

    world = wf.newWorld(0, 1500, false)
    world:addCollisionClass('Platform')
    world:addCollisionClass('Player')
    world:addCollisionClass('Danger')

    require('player')
    require('enemy')
    require('libraries/show')

    flagX = 0
    flagY = 0

    saveData = {}
    saveData.currentLevel = "level1"
    sounds.music:play()

    if love.filesystem.getInfo("data.lua") then 
        local data = love.filesystem.load("data.lua")
        data()
    end

    dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, {collision_class = "Danger"})
    dangerZone:setType('static')
    loadMap(saveData.currentLevel)
    --world:setQueryDebugDrawing(true)
end

function love.update(dt)
    world:update(dt)
    playerUpdate(dt)
    enemiesUpdate(dt)
    gameMap:update(dt)

    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
    
    cam:lookAt(player:getX(), love.graphics.getHeight()/2)

    local colliders = world:queryCircleArea(flagX, flagY, 10, {'Player'})
    if #colliders > 0 then
        if saveData.currentLevel == "level1" then
            loadMap("level2")
        elseif saveData.currentLevel == "level2" then
            loadMap("level1")
        end
    end
end

function love.draw()
    love.graphics.draw(background)
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        --world:draw()
        drawPlayer()
        drawEnemies()
    cam:detach()
end

function love.keypressed(key)
    if key == 'space' then
        if #colliders>0 then
            player:applyLinearImpulse(0, -6000)
            sounds.jump:play()
        end
    end
end

function loadMap(mapName)
    saveData.currentLevel = mapName
    love.filesystem.write("data.lua", table.show(saveData, "saveData"))
    destroyAll()
    --player:setPosition(playerStartX, playerStartY)
    gameMap = sti("maps/" .. mapName .. ".lua")
    for i, obj in pairs(gameMap.layers["Start"].objects) do
        playerStartX = obj.x
        playerStartY = obj.y
    end
    player:setPosition(playerStartX, playerStartY)

    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end
    for i, obj in pairs(gameMap.layers["Enemies"].objects) do
        spawnEnemies(obj.x, obj.y)
    end
    for i, obj in pairs(gameMap.layers["Flag"].objects) do
        flagX = obj.x
        flagY = obj.y
    end
end

function spawnPlatform(x, y, width, height)
    if width>0 and height>0 then
        local platform = world:newRectangleCollider(x, y, width, height, {collision_class = "Platform"})
        platform:setType('static')
        table.insert(platforms, platform)
    end
end

function destroyAll()
    local i = #platforms
    while i>-1 do
        if platforms[i] ~= nil then
            platforms[i]:destroy()
        end
        table.remove(platforms, i)
        i = i-1
    end

    local i = #enemies
    while i>-1 do
        if enemies[i] ~= nil then
            enemies[i]:destroy()
        end
        table.remove(enemies, i)
        i = i-1
    end
end