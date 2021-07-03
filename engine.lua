local json = require('dkjson')
local anim8 = require('anim8')
require('helpers')
require('pathfinding')
require('map')

engine = {}
engine.players = {}
engine.map = {}

-- Map variables
local mapDec = {}

function engine.decodeJson(filename)
  assert(filename, "Filename is nil!")
  if not love.filesystem.isFile(filename)
    then error("Given filename is not a file! Is it a directory? Does it exist?")
  end

  --Reads file
  mapJson = love.filesystem.read(filename)

  --Attempts to decode file
  mapDec = json.decode(mapJson)
end


function engine.generatePlayField()
    engine.map = parseMap(engine, mapDec)
    -- engine.players = engine.map.players
end

function engine.getMouseTarget(xOff, yOff, zoom)
    local x, y = love.mouse.getPosition()
    local mapX, mapY = engine.screenToMap(x, y, zoom)
    x = x / zoom
    y = y / zoom
    -- x = x * zoom
    -- y = y * zoom
    xOff = xOff / zoom
    yOff = yOff / zoom
    local mapX, mapY = engine.screenToMap(x - xOff, y - yOff, zoom)

    -- if (mapX + 1) == j and (mapY + 1) == i then
    --   print('mouseTarget:', mapX, mapY, i, j,  x, y )
    -- end
    engine.mouseTarget = {mapY + 1, mapX + 1}
    return engine.mouseTarget
end

local bloodTexture = love.graphics.newImage("props/blood.png")


local function getPosition(x, y)
  if y < 1 or y > #engine.map.positions then return nil end
  if x < 1 or x > #engine.map.positions[y] then return nil end

  return engine.map.positions[y][x][1]
end

engine.getPosition = getPosition

function engine.getNeighbors(position)
  local source = position
  assert(source, "No position find for this source")
  local x = source.x
  local y = source.y

  return table.filter(
    {
      -- { ['direction'] = 'top', getPosition(x, y - 1, mapData),
      { direction = 'up', position = getPosition(x, y - 1) },
      { direction = 'right', position = getPosition(x + 1, y) },
      { direction = 'down', position = getPosition(x, y + 1) },
      { direction = 'left', position = getPosition(x - 1, y) },
    },
    function (neighbor)
      position = neighbor.position
      return position ~= nil and #position.objects == 0
    end
  )
end

function engine.getTargetPath(source, target)
  local targetX = target[1]
  local targetY = target[2]
  target = getPosition(targetY, targetX)

  local player = engine.players[1]

  if player.action then
    return {target}
  end

  local sourceX = source[1]
  local sourceY = source[2]
  source = getPosition(sourceX, sourceY)

	return findPath(
		engine.map.positions,
		source,
		engine.getNeighbors,
		function (current) return current == target end
	)
end


function engine.pushAction(player, action)
  table.insert(player.action_queue, action)
end

function engine.executeAction(player, action)
  -- local player = engine.players[1]
  local playerX = tonumber(player.position[1])
  local playerY = tonumber(player.position[2])
  local finalX = tonumber(player.final[1])
  local finalY = tonumber(player.final[2])

  if (player.action) then
    return nil
  end

  if action == "left" then
    finalX = math.floor(playerX) - 1
    finalY = math.floor(playerY)
    player.currentAnimation = player.animations["left"]
  end
  if action == "right" then
    finalX = math.floor(playerX + 1)
    finalY = math.floor(playerY)
    player.currentAnimation = player.animations["right"]
  end
  if action == "up" then
    finalX = math.floor(playerX)
    finalY = math.floor(playerY) - 1
    player.currentAnimation = player.animations["up"]
  end
  if action == "down" then
    finalX = math.floor(playerX)
    finalY = math.floor(playerY) + 1
    player.currentAnimation = player.animations["down"]
  end

  if (player.currentAnimation) then
    player.currentAnimation:pauseAtStart()
  end


  player.final[1] = finalX
  player.final[2] = finalY
  player.action = action
end

function engine.runAction(dt)
  -- local player = engine.players[1]
  local player = nil
  for i,player in ipairs(engine.players) do
    if not player.action then
      -- player.action = table.remove(player.action_queue, 1)
      local nextAction = table.remove(player.action_queue, 1)
      if nextAction then
        engine.executeAction(player, nextAction)
      end
    end
    if player.action then
      local playerX = tonumber(player.position[1])
      local playerY = tonumber(player.position[2])
      local finalX = tonumber(player.final[1])
      local finalY = tonumber(player.final[2])
      local currentAnimation = player.currentAnimation
      local velocity = player.velocity
      -- player.currentAnimation.gotoFrame(1)

      if player.currentAnimation then
        player.currentAnimation:resume()
        player.currentAnimation:update(dt)
      end

      local mapLength = 8
      local invalid = (finalX < 1 or finalX > mapLength) or (finalY < 1 or finalY > mapLength)
      local reachedFinalPosition = (playerX == finalX and playerY == finalY)
      -- local invalid = false
      if invalid or reachedFinalPosition then
        player.action = nil
        player.final[1] = playerX
        player.final[2] = playerY
        if player.currentAnimation then
          player.currentAnimation:pauseAtStart()
        end
        return false
      end
      local position = engine.map.positions[finalY][finalX]
      local blocked = table.getn(position[1].objects) > 0
      if blocked then
        player.action = nil
        player.final[1] = playerX
        player.final[2] = playerY
        if player.currentAnimation then
          player.currentAnimation:pauseAtStart()
        end
        return false
      end

      if playerX > finalX then
        player.position[1] = math.max(finalX, playerX - dt * velocity)
      else
        player.position[1] = math.min(finalX, playerX + dt * velocity)
      end

      if playerY > finalY then
        player.position[2] = math.max(finalY, playerY - dt * velocity)
      else
        player.position[2] = math.min(finalY, playerY + dt * velocity)
      end
    end
  end
end

function engine.getTile2DCoordinates(i, j)
  local xP = engine.map.positions[i][j][1].x * (engine.map.tileWidth*engine.map.zoomLevel)
  local yP = engine.map.positions[i][j][1].y * (engine.map.tileWidth*engine.map.zoomLevel)
  xP, yP = engine.toIso(xP, yP)
  return xP, yP
end


function engine.getPlayfieldWidth()
  return engine.map.widthInTiles
end

function engine.getPlayfieldHeight()
  return engine.map.heightInTiles
end

function engine.getGroundTileWidth()
  return engine.map.tileWidth
end

--Links used whilst searching for information on isometric maps:
--http://stackoverflow.com/questions/892811/drawing-isometric-game-worlds
--https://gamedevelopment.tutsplus.com/tutorials/creating-isometric-worlds-a-primer-for-game-developers--gamedev-6511
--Give it a good read if you don't understand whats happening over here.

function engine.toIso(x, y)
  assert(x, "Position X is nil!")
  assert(y, "Position Y is nil!")

  -- local xPos = (x - y) * tileWidth
  -- local yPos = (x + y) * tileHeight
  newX = x - y
  newY = (x + y)/2
  return newX, newY
end

function engine.getTileDimensions()
  tileWidth = engine.map.tileWidth
  tileHeight = engine.map.tileHeight
  return tileWidth, tileHeight
end

function engine.screenToMap(x, y, size)
  tileWidth, tileHeight = engine.getTileDimensions()
  tileWidth = tileWidth / size
  tileHeight = tileHeight / size
  mapX = (x / tileWidth + y / tileHeight)/2
  mapY = (y / tileHeight - x / tileWidth)/2
  mapX = math.floor(mapX)
  mapY = math.floor(mapY)

  return mapX, mapY
end

function engine.toCartesian(x, y)
  assert(x, "Position X is nil!")
  assert(y, "Position Y is nil!")
  x = (2 * y + x)/2
  y = (2 * y - x)/2
  return x, y
end

function engine.insertNewObject(textureI, isoX, isoY, offXR, offYR)
  --User checks
  if offXR == nil then offXR = 0 end
  if offYR == nil then offYR = 0 end
  assert(textureI, "Invalid texture file for object!")
  assert(isoX, "No X position for object! (Isometric coordinates)")
  assert(isoY, "No Y position for object! (Isometric coordinates)")
  assert(engine.map.widthInTiles>=isoX, "Insertion coordinates out of map bounds! (X)")
  assert(engine.map.widthInTiles>=isoY, "Insertion coordinates out of map bounds! (Y)")
  local rx, ry = engine.toIso(isoX, isoY)

  local colX = isoX * (engine.map.tileWidth*engine.map.zoomLevel)
  local colY = isoY * (engine.map.tileWidth*engine.map.zoomLevel)
  colX, colY = engine.toIso(colX, colY)
  --Insert object on map
  local propField = {
    texture=textureI,
    x=isoY,
    y=isoX+0.001,
    offX=offXR,
    offY = offYR,
    mapY = ry,
    mapX = rx,
    colX = colX,
    colY = colY,
    width = textureI:getWidth(),
    height = textureI:getHeight(),
    alpha = false,
  }
  table.insert(engine.map.propFields, propField)
  table.insert(engine.map.positions[isoX][isoY][1].objects, propField)
end

function engine.removeObject(x, y)
  if #engine.map.positions[x][y] > 1 then
    table.remove(engine.map.positions[x][y], #engine.map.positions[x][y])
  end
end

return engine
