name = "A Flight of Sheep"
map = [[

                  bb 
        ba       gggggh
        ggg      gggggw
        ggg p a  gggggw
        ggggggggggggggw
        ggggggggggggggw
        ggggggggggggggw
        ggggggggggggggw
wwww    ggggggggggggggw
wwwwwwwwggggggggggggggw
]]

intro = nil
outro = "Well done! You saved all your sheep!\n\nLet's hope that the next flood won't come too soon.\n\nBut in the end, you just delayed the inevitable."

level = Level:new(name, map, intro, outro)

return level
