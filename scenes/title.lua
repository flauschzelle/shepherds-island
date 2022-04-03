local scene = {} 

function scene:enter()
    love.mouse.setRelativeMode(false)
end

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white
    love.graphics.printf("Pistachio Studios presents:", 0, CANVAS_HEIGHT/4, CANVAS_WIDTH, "center")
    love.graphics.printf("[Insert Game Title]", 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
    love.graphics.printf("made in 72 hours for [Game Jam]", 0, CANVAS_HEIGHT*0.75, CANVAS_WIDTH, "center")
    love.graphics.printf("by [names]", 0, CANVAS_HEIGHT*0.85, CANVAS_WIDTH, "center")
end

function scene:mousepressed(x, y, button)
    roomy:enter(scenes.gameplay)
end

function scene:handleInput()
    if input:isPressed("menu") then
        roomy:enter(scenes.gameplay)
        roomy:push(scenes.menu)
    end
end

return scene
