-- a class for objects that can be moved directly 
-- by player input (mouse/keyboard/joystick), 
-- like a player characters or a cursor in menu
local Cursor = class("Cursor")

function Cursor:initialize(graphicType, borderMode, pos_x, pos_y, speed)

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
end


function Cursor:draw()
    if self.graphicType == "image" then
        -- draw image
        love.graphics.draw(self.image, self.pos_x, self.pos_y, self.rotation, self.scale_x, self.scale_y, self.origin_offset_x, self.origin_offset_y)
    else
        -- draw geometry
        self.geometry:draw(self.pos_x, self.pos_y)
    end

end

return Cursor