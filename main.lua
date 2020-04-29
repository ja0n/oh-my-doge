engine = require ('engine')
render = require('render')
require('helpers')
isGrabbing = false
math.randomseed( os.time() )

x = 0
y = 0
vx = 0
vy = 0

local player = nil
local player2 = nil
local player3 = nil
local actions = {'up', 'down', 'left', 'right'}

function resetCamera()
  x = 0
  y = 0
  vx = 0
  vy = 0
end

function love.load()
  --Variables
  x = 330
  y = 180
  vx = 330
  vy = 180
  zoomL = 1
  zoom = 1

  resetCamera()

  love.window.setTitle('Where is my Friend')

  love.graphics.setBackgroundColor(0, 0, 0)
  love.graphics.setDefaultFilter("linear", "linear", 8)


  --Decode JSON map file
  engine.decodeJson("map.json")

  --Generate map from JSON file (loads assets and creates tables)
  engine.generatePlayField()
  player = engine.players[1]
  engine.pushAction(player, 'right')
end

function love.update(dt)
  engine.runAction(dt)
  -- require("lovebird").update()

  local i = 2
  repeat
    local player = engine.players[i]
    if player.action == nil then
      engine.pushAction(player, actions[math.random(#actions)])
    end
    i = i + 1
  until i > #engine.players

  zoomL = lerp(zoomL, zoom, 0.05*(dt*300))

  if isGrabbing then
    local currentX = love.mouse.getX()
    local currentY = love.mouse.getY()
    vx = x + (currentX - lastPosX)
    vy = y + (currentY - lastPosY)
  end
end

function love.draw()
  render.update(vx, vy, zoomL)

  printDebug(vx, vy)
end

function love.keypressed(key)
  -- player
  local player = engine.players[1]
  if key == 'w' then
     engine.pushAction(player, 'up')
  end
  if key == 's' then
     engine.pushAction(player, 'down')
  end
  if key == 'a' then
     engine.pushAction(player, 'left')
  end
  if key == 'd' then
     engine.pushAction(player, 'right')
  end

end


function love.wheelmoved(x, y)
    if y > 0 then
      zoom = zoom + 0.1
    elseif y < 0 then
      zoom = zoom - 0.1
    end

  if zoom < 0.1 then zoom = 0.1 end
end

local texture = love.graphics.newImage("props/blood.png")
function love.mousepressed(currentX, currentY, button, istouch, presses)
  if button == 1 then
    lastPosX = currentX
    lastPosY = currentY
    isGrabbing = true
    love.mouse.setGrabbed(true)
  end
  if button == 1 then
    if love.keyboard.isDown('lshift') then
      engine.insertNewObject(texture, engine.mouseTarget[1], engine.mouseTarget[2], 108, 59)
      print('mouseTarget:', engine.mouseTarget[2], engine.mouseTarget[1])
    end
  end
end

function love.mousereleased(currentX, currentY, button, istouch, presses)
  if isGrabbing and button == 1 then
    x = x + (currentX - lastPosX)
    y = y + (currentY - lastPosY)

    love.graphics.print("vX: "..x.." vY: "..y, 150, 78)
    isGrabbing = false
    love.mouse.setGrabbed(false)
  end

  if not isGrabbing and button == 2 then
    if not engine.mouseTarget then return nil end

    local path = engine.getTargetPath(player.position, engine.mouseTarget)
    local player = engine.players[1]
    for index, node in ipairs(path) do
      print('direction', direction)
      engine.pushAction(player, node.direction)
    end
  end
end

function printDebug(vx, vy)
  local player = engine.players[1]
  info = love.graphics.getStats()
  love.graphics.print("FPS: "..love.timer.getFPS())
  love.graphics.print("Draw calls: "..info.drawcalls, 0, 12)
  love.graphics.print(string.format("Texture memory: %.2f mb", ((info.texturememory/1024)/1024)), 0, 24)
  love.graphics.print("Zoom level: "..zoom, 0, 36)
  love.graphics.print("Is grabbing: "..tostring(isGrabbing), 0, 48)
  love.graphics.print("X: "..math.floor(x).." Y: "..math.floor(y), 0, 64)
  love.graphics.print("vX: "..math.floor(vx).." vY: "..math.floor(vy), 0, 78)

  love.graphics.print("posX: "..player.position[1], 0, 100)
  love.graphics.print("posY: "..player.position[2], 0, 120)
  love.graphics.print("finX: "..player.final[1], 0, 140)
  love.graphics.print("finY: "..player.final[2], 0, 160)
  love.graphics.print("action: "..tostring(player.action), 0, 180)
  love.graphics.print("X: "..math.floor(x).." Y: "..math.floor(y), 0, 64)
  love.graphics.print("tileWidth: "..engine.map.tileWidth, 0, 200)
  love.graphics.print("tileHeight: "..engine.map.tileHeight, 0, 220)
end
