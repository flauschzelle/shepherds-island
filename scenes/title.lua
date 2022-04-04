local scene = {} 

name = "Title"
map = [[




 w
ww
ww       p a
www   a ggggg a
www   ggggggggg h
wwwwwggggggggggwwww
]]
local backgroundLevel = Level:new(name, map)

function scene:enter()
    --love.mouse.setRelativeMode(false)
end

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white

    backgroundLevel:draw(false)

    --love.graphics.printf("Pistachio Studios presents:", 0, CANVAS_HEIGHT/4, CANVAS_WIDTH, "center")
    love.graphics.setFont(hugefont)
    love.graphics.printf("Shepherd's Island", 0, CANVAS_HEIGHT*0.15, CANVAS_WIDTH, "center")
    love.graphics.setFont(bigfont)
    love.graphics.printf("made in 72 hours for Ludum Dare 50", 0, CANVAS_HEIGHT*0.35, CANVAS_WIDTH, "center")
    love.graphics.printf("by flauschzelle and blinry", 0, CANVAS_HEIGHT*0.45, CANVAS_WIDTH, "center")
    love.graphics.printf("Press Enter to start!", 0, CANVAS_HEIGHT*0.85, CANVAS_WIDTH, "center")
end

--function scene:mousepressed(x, y, button)
--    roomy:enter(scenes.gameplay)
--end

function scene:handleInput()
    if input:isPressed("quit") then
        love.event.quit()
    end
    if input:isPressed("click") then
        roomy:enter(scenes.gameplay)
        --roomy:push(scenes.menu)
    end
end

return scene
