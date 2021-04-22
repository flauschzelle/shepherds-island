local scene = {} 

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white
    love.graphics.printf("PAUSED", 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
end

function scene:keypressed(key)
    if key == "p" then
        roomy:pop()
    end
end

return scene