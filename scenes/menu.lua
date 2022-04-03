local scene = {} 

MARGIN = 50
LINES = 6

function draw_level_list()
    local lvls = levelManager.level_count
    local colWidth = (CANVAS_WIDTH - 2*MARGIN)/(math.ceil(lvls/LINES))
    local lineHeight = (CANVAS_HEIGHT - 4*MARGIN)/LINES
    local i = 1
    while i <= lvls do
        local number = i..". "
        if i <= 9 then
            number = "0"..i..". "
        end
        local name = number..levels[i].name
        love.graphics.printf(name, MARGIN + ((math.ceil(i/LINES)-1)*colWidth), 3*MARGIN + (((i-1)%LINES) * lineHeight), colWidth, "left")
        i = i +1
    end
end

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white
    love.graphics.printf("-- MENU --", 0, 20, CANVAS_WIDTH, "center")
    love.graphics.printf("Press Q to return to the game or choose a level and click.", 0, 70, CANVAS_WIDTH, "center")
    draw_level_list()
    self.mouse:draw()
end

function scene:update(dt)
    --update cursor
    self.mouse:move()
end

function scene:handleInput()
    if input:isPressed("menu") then
        roomy:pop()
    end

    if input:isPressed("click") then
        -- TODO: open the level that was clicked on
        local col = self.mouse.grid_col
        local row = self.mouse.grid_row
        local newlevelno = row + (LINES*(col-1))
        if newlevelno <= levelManager.level_count then
            -- reset current level state
            if levelManager.current ~= newlevelno then
                levelManager:currentLevel().won = false
                if levelManager:currentLevel().intro ~= nil then
                    levelManager:currentLevel().started = false
                end
            end
            -- switch to new level
            levelManager.current = newlevelno
            -- leave menu
            roomy:pop()
        end

    end
end

function scene:enter()
    local lvls = levelManager.level_count
    local cols = math.ceil(lvls / 6)

    -- initialize cursor
    -- TODO: optimise speed for grid-bound cursor
    self.mouse = Cursor:new("geometry", "stop", nil, nil, 70, cols, LINES, {top = MARGIN*3, bottom = MARGIN, left = MARGIN, right = MARGIN}, "left", "top")
    self.mouse:setGeometry(arrow)
end

-- some geometric shapes to use as cursors: --

circle = {} --initialize geometry object with draw function
function circle:draw(x, y)
    love.graphics.setColor(1,0,0)
    love.graphics.circle("line", x, y, 20)
    love.graphics.setColor(1,1,1)
end

box = {} --initialize geometry object with draw function
function box:draw(x, y)
    love.graphics.setColor(1,0,0)
    love.graphics.rectangle("line", x, y, 70, 50)
    love.graphics.setColor(1,1,1)
end

arrow = {} --initialize geometry object with draw function
function arrow:draw(x, y)
    local size = 25
    local vertices = {x-size, y, x, y+size, x-size, y+(2*size)}
    love.graphics.setColor(1,0,0)
    love.graphics.polygon("fill", vertices)
    love.graphics.setColor(1,1,1)
end

-- end of cursor templates list --

return scene
