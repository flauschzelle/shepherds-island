local scene = {} 

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white
    love.graphics.printf("Thanks for playing! <3", 0, CANVAS_HEIGHT*1/4, CANVAS_WIDTH, "center")

    love.graphics.printf("If you enjoyed this game, say hi on Twitter or check out our other games! :)\n\n@flauschzelle   @blinry\n\nflauschzelle.de   blinry.org", CANVAS_WIDTH/4, CANVAS_HEIGHT*1.5/4, CANVAS_WIDTH/2, "center")
end

function scene:handleInput()
    if input:isPressed("quit") then
        roomy:enter(scenes.gameplay)
        roomy:push(scenes.menu)
    end
end

return scene
