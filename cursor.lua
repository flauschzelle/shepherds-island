-- a class for objects that can be moved directly 
-- by player input (mouse/keyboard/joystick), 
-- like a player characters or a cursor in menu
local Cursor = class("Cursor")

function Cursor:initialize(graphicType, borderMode, pos_x, pos_y, speed, grid_x, grid_y, grid_margins, grid_align_x, grid_align_y)

    -- image or geometry (default: geometry)
    if graphicType == "image" then
        self.graphicType = "image"
    else
        self.graphicType = "geometry"
    end

    -- behaviour at the border of the canvas (default: stop)
    if borderMode == "free" then
        self.borderMode = "free"
    elseif borderMode == "wrap" then
        self.borderMode = "wrap"
    else
        self.borderMode = "stop"
    end
    
    -- starting position
    if pos_x ~= nil then
        self.pos_x = pos_x
    else
        self.pos_x = CANVAS_WIDTH/2
    end

    if pos_y ~= nil then
        self.pos_y = pos_y
    else
        self.pos_y = CANVAS_HEIGHT/2
    end

    -- default rotation and scaling for image cursors
    self.rotation = 0
    self.scale_x = 1
    self.scale_y = 1

    -- speed
    if speed ~= nil then
        self.speed = speed
    else
        self.speed = 30 -- default
    end

    -- for grid-bound cursors
    if grid_x ~= nil then
        self.grid_x = grid_x
        self.grid_bound = true

        if grid_y ~= nil then
            self.grid_y = grid_y
        else
            self.grid_y = grid_x
        end

        if grid_margins ~= nil then
            self.grid_margins = grid_margins
        else
            self.grid_margins = {top = 0, bottom = 0, left = 0, right = 0,}
        end

        if (grid_align_x == "left") or (grid_align_x == "right") then
            self.grid_align_x = grid_align_x
        else
            self.grid_align_x = "center"
        end

        if (grid_align_y == "top") or (grid_align_y == "bottom") then
            self.grid_align_y = grid_align_y
        else
            self.grid_align_y = "center"
        end

        self.grid_col_width = (CANVAS_WIDTH - (self.grid_margins.left + self.grid_margins.right))/grid_x
        self.grid_row_height = (CANVAS_HEIGHT - (self.grid_margins.top + self.grid_margins.bottom))/grid_y

        self.draw_pos_x = self.pos_x
        self.draw_pos_y = self.pos_y

        self.grid_col = 1
        self.grid_row = 1

    else
        self.grid_bound = false
    end

end

-- setters for image cursors only: --

function Cursor:setImage(image, rotation, scale_x, scale_y, origin_offset_x, origin_offset_y)
    -- image parameter must always be provided
    self.image = image

    if rotation ~= nil then
        self.rotation = rotation
    end

    if scale_x ~= nil then
        self.scale_x = scale_x
    end

    if scale_y ~= nil then
        self.scale_y = scale_y
    end

    -- default origin will be in the middle of the image:
    if origin_offset_x ~= nil then
        self.origin_offset_x = origin_offset_x
    else
        self.origin_offset_x = (self.image:getWidth()/2)
    end

    if origin_offset_y ~= nil then
        self.origin_offset_y = origin_offset_y
    else
        self.origin_offset_y = (self.image:getHeight()/2)
    end

end

function Cursor:setImageRotation(rotation)
    self.rotation = rotation
end

function Cursor:setImageScale(scale_x, scale_y)
    self.scale_x = scale_x
    self.scale_y = scale_y
end

-- setters for geometry cursors only: --

function Cursor:setGeometry(object)
    -- object must be something that has a "draw" function 
    -- that takes the x and y position as first arguments!
    self.geometry = object
end

-- setters for all cursors: --

function Cursor:setSpeed(speed)
    self.speed = speed
end

function Cursor:move()
    x = self.pos_x + input:getX() * self.speed
    y = self.pos_y + input:getY() * self.speed
    self:setPosition(x, y)
end

function Cursor:setPosition(pos_x, pos_y)
    self.pos_x = pos_x
    self.pos_y = pos_y

    -- correction for stopping at canvas borders
    if self.borderMode == "stop" then

        if self.pos_x < 0 then
            self.pos_x = 0
        elseif self.pos_x > CANVAS_WIDTH then
            self.pos_x = CANVAS_WIDTH
        end

        if self.pos_y < 0 then
            self.pos_y = 0
        elseif self.pos_y > CANVAS_HEIGHT then
            self.pos_y = CANVAS_HEIGHT
        end

    -- correction for wrapping around canvas borders
    elseif self.borderMode == "wrap" then
        
        if self.pos_x < 0 then
            self.pos_x = (CANVAS_WIDTH + self.pos_x)
        elseif self.pos_x > CANVAS_WIDTH then
            self.pos_x = (self.pos_x - CANVAS_WIDTH)
        end

        if self.pos_y < 0 then
            self.pos_y = (CANVAS_HEIGHT + self.pos_y)
        elseif self.pos_y > CANVAS_HEIGHT then
            self.pos_y = (self.pos_y - CANVAS_HEIGHT)
        end

    end
    -- correction for grid bound cursors
    if self.grid_bound then
        --set x position:
        --TODO: correct for cursor size
        local align_x = 0
        if self.grid_align_x == "right" then
            align_x = self.grid_col_width 
        elseif self.grid_align_x == "center" then
            align_x = (self.grid_col_width)/2
        end

        if self.pos_x < self.grid_margins.left then
            self.draw_pos_x = self.grid_margins.left + align_x
            self.grid_col = 1
        elseif self.pos_x > (CANVAS_WIDTH - self.grid_margins.right) then
            self.draw_pos_x = CANVAS_WIDTH - self.grid_margins.right - self.grid_col_width + align_x
            self.grid_col = self.grid_x
        else
            self.grid_col = math.ceil((self.pos_x - self.grid_margins.left)/self.grid_col_width)
            self.draw_pos_x = self.grid_margins.left + (self.grid_col-1)*self.grid_col_width + align_x
        end

        --set y position:
        local align_y = 0
        if self.grid_align_y == "bottom" then
            align_y = self.grid_row_height
        elseif self.grid_align_y == "center" then
            align_y = self.grid_row_height/2
        end
        
        if self.pos_y < self.grid_margins.top then
            self.draw_pos_y = self.grid_margins.top + align_y
            self.grid_row = 1
        elseif self.pos_y > (CANVAS_HEIGHT - self.grid_margins.bottom) then
            self.draw_pos_y = CANVAS_HEIGHT - self.grid_margins.bottom - self.grid_row_height + align_y
            self.grid_row = self.grid_y
        else
            self.grid_row = math.ceil((self.pos_y - self.grid_margins.top)/self.grid_row_height)
            self.draw_pos_y = self.grid_margins.top + (self.grid_row-1)*self.grid_row_height + align_y
        end


    end
end


function Cursor:draw()

    local x = self.pos_x
    local y = self.pos_y

    -- correction for grid-bound cursors:
    if self.grid_bound then
        x = self.draw_pos_x
        y = self.draw_pos_y
    end

    if self.graphicType == "image" then
        -- draw image
        love.graphics.draw(self.image, x, y, self.rotation, self.scale_x, self.scale_y, self.origin_offset_x, self.origin_offset_y)
    else
        -- draw geometry
        self.geometry:draw(x, y)
    end

end

return Cursor