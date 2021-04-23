local scene = {} 

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white
    love.graphics.printf("Thanks for playing!", 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
end

return scene