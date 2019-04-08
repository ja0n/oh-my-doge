
-- Load some default values for our rectangle.
function love.load()
   tile_width = 74
   tile_height = 42

   ground = love.graphics.newImage( "ground_tile.bmp" )
   block_width = ground:getWidth()
   block_height = ground:getHeight() - 1
  --  block_depth = block_height / 2
   block_depth = block_height / 2

   grid_size = 8 
   grid = {}
   for x = 1,grid_size do
      grid[x] = {}
      for y = 1,grid_size do
         grid[x][y] = 1
      end
   end

    grid_x = (grid_size - 1) * block_width/2
    grid_y = (grid_size - 1) * block_height/4
    x, y, w, h = 20, 20, 60, 20

  canvas = love.graphics.newCanvas(1024, 1024)
  canvas:setFilter("nearest", "nearest")

  -- love.graphics.setDefaultFilter("nearest", "nearest")
  -- love.graphics.setDefaultFilter("linear", "nearest")
  -- image:setFilter("linear", "nearest")
end
 
-- Increase the size of the rectangle every frame.
function love.update(dt)
    w = w + 1
    h = h + 1
end
 
-- Draw a coloured rectangle.
function love.draw()
  -- love.graphics.scale(2, 2)
    draw_map()
    -- love.graphics.rectangle("fill", x, y, w, h)
end

function normalizePixel(x)
  return math.floor(x)*16
end

function draw_map()
    love.graphics.setCanvas(canvas) --This sets the draw target to the canvas

    for x = 1,grid_size do
        for y = 1,grid_size do

          if grid[x][y] == 1 then
              love.graphics.draw(ground,
                 grid_x + ((y-x) * (block_width / 2)) - x,
                 grid_y + ((x+y) * (block_depth / 2)) - (block_depth * (grid_size / 2))-x)
           end
        end
     end
     love.graphics.setCanvas() --This sets the target back to the screen

     love.graphics.draw(canvas, 0, 0, 0, 2, 2)

end