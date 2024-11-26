playerStartX = 180
playerStartY = 100

player = world:newRectangleCollider(playerStartX, playerStartY, 40, 100, {collision_class = "Player"})
player:setFixedRotation(true)
player.speed = 300
player.animation = animations.idle
player.direction = 1
player.grounded = true

function playerUpdate(dt)
    player.animation:update(dt)

    colliders = world:queryRectangleArea(player:getX()-20, player:getY()+50, 40, 2, {'Platform'})
    if #colliders>0 then
        player.grounded = true
    else
        player.grounded = false
    end

    if #colliders<1 then
        player.animation = animations.jump
    else
        player.animation = animations.idle
    end
    
    if player.body then
        local px, py = player:getPosition()
        if love.keyboard.isDown("a") then
            if #colliders>0 then
                player.animation = animations.run
            end
            player.direction = -1
            player:setX(px-player.speed*dt)
        elseif love.keyboard.isDown("d") then
            if #colliders>0 then
                player.animation = animations.run
            end
            player.direction = 1
            player:setX(px+player.speed*dt)
        end
    end

    if player:enter('Danger') then
        player:setPosition(playerStartX, playerStartY)
    end
end

function drawPlayer()
    player.animation:draw(sprites.playerSheet, player:getX(), player:getY(), nil, 0.25*player.direction, 0.25, 130, 300)
end