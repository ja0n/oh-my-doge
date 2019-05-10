local json = require('dkjson')
local anim8 = require('anim8')
require('helpers')
require('pathfinding')

engine = {}
mapDec = {}
local mapTextures = {}
mapPositions = {}
mapProps = {}
local mapLighting = {}
mapPropsfield = {}
local tileWidth = 0
local tileHeight = 0
engine.players = {}

local mapPlayfieldWidthInTiles = 0
local mapPlayfieldHeightInTiles = 0

local objectListSize = 0

local zoomLevel = 1

function split(value)
  return string.split_(value, "|")
end

function fmap(func, array)
  local new_array = {}
  for i,v in ipairs(array) do
    new_array[i] = func(v)
  end
  return new_array
end

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
  --TODO: Maps will be packed as renamed ZIP file extensios and will be able to be installed in users machines. So, textures and props have to be loaded from this directory.
  --Currently, the mapDecoder will look for textures in folder named textures in the root of the project, and props in a props folder.

  print("Current map information:")
  print("General information: =-=-=-=-=-=-=")
  if mapDec.general ~= nil then
    print("Map name: "..mapDec.general[1].name)
    print("Map version: "..mapDec.general[1].version)
    print("Map lighting: "..mapDec.general[1].lighting)
    if mapDec.general[1].lighting ~= nil then
      mapLighting = string.split_(mapDec.general[1].lighting, "|")
    end
    print("----")
  end

  print("Ground textures: =-=-=-=-=-=-=-=")
  for i, texture in ipairs(mapDec.textures) do
    --Print table contents for now
    print(texture.file)
    print(texture.mnemonic)
    print("---")

    table.insert(mapTextures, {
      file = texture.file,
     mnemonic = texture.mnemonic,
     offset = texture.offset,
     image = love.graphics.newImage("textures/"..texture.file)
    })

  end

  --Get ground texture dimensions
  mainTexture = mapTextures[1]
  offsets = string.split_(mainTexture.offset, "|")
  tileWidth = (mainTexture.image:getWidth() - offsets[1])/2
  tileHeight = (mainTexture.image:getHeight() - offsets[2])/2

  print("Playfield props: =-=-=-=-=-=-=-=")
  if mapDec.props ~= nil then
    for i, props in ipairs(mapDec.props) do
      print(props.file)
      print(props.mnemonic)
      print(props.origin)
      print("----")
      image = love.graphics.newImage("props/"..props.file)
   origins = split(props.origin)
   occupy = fmap(split, props.occupy or {})
      table.insert(mapProps, {
    file = props.file,
    mnemonic = props.mnemonic,
    image = image,
    origins = origins,
    occupy = occupy,
   })
    end
  else
    print("No props found on current map!")
  end


  --Add each ground tile to a table according to their texture
  --TODO: the following should be done on a separate thread. I have not tested the performance of the following lines on a colossal engine.
  timerStart = love.timer.getTime()
  for i, groundTexture in ipairs(mapTextures) do
    for colunas in ipairs(mapDec.data) do
      for linhas in ipairs(mapDec.data[colunas]) do
        for i, properties in ipairs(mapDec.data[colunas][linhas]) do

          --Add ground texture if mnemonic is found
          if properties == groundTexture.mnemonic then
            local xPos = linhas
            local yPos = colunas
            if mapPositions[colunas] == nil then
              mapPositions[colunas] = {}
            end
            if mapPositions[colunas][linhas] == nil then
              mapPositions[colunas][linhas] = {}
            end
            local mapPosition = {
              texture = groundTexture.image,
              x=xPos,
              y=yPos,
              objects={}
            }
            table.insert(mapPositions[colunas][linhas], mapPosition)
          end

        end
      end
    end
  end

  --TODO: Merge these loops, since both save stuff to the same table?
  --Add object to map accordingly
  for i, props in ipairs(mapProps) do --For each object

    --Loop through map terrain information
    for colunas in ipairs(mapDec.data) do
      for linhas in ipairs(mapDec.data[colunas]) do

        --Iterate over the objects in a given 2D position
        for i, objects in ipairs(mapDec.data[colunas][linhas]) do
          if objects == props.mnemonic then
            --table.insert(mapPositions[colunas][linhas], {texture=props.image, x=linhas, y=colunas, offX=props.origins[1], offY=props.origins[2]})

            --VERY IMPORTANT NOTE ABOUT THE FOLLOWING LINES
            --these control the ZBuffer in some *dark manner*. IT WORKS. I **really** have to figure out why.
            pX, pY = engine.toIso(linhas, colunas)

            colX = linhas * (tileWidth*zoomLevel)
            colY = colunas * (tileWidth*zoomLevel)
            colX, colY = engine.toIso(colX, colY)
            local propField = {
              mnemonic=props.mnemonic,
              texture=props.image,
              x=linhas,
              y=colunas,
              offX=props.origins[1],
              offY=props.origins[2],
              mapY = pY,
              mapX = pX,
              colX = colX,
              colY = colY,
              width = props.image:getWidth(),
              height = props.image:getHeight(),
              alpha = false
            }
            -- local propField = [];
            table.insert(mapPropsfield, propField)

      table.insert(mapPositions[colunas][linhas][1].objects, propField)

      for i,v in ipairs(props.occupy or {}) do
       local x = colunas + v[2]
       local y = linhas + v[1]
       print('occupy', x, y)
       if x < 8 and y < 8 then
        table.insert(mapPositions[x][y][1].objects, propField)
       end
      end
            --Add to occupy positions
          end
        end

      end
    end

  end

  print("Player props: =-=-=-=-=-=-=-=")
  if mapDec.players ~= nil then
    local props = nil
    for i,props in ipairs(mapDec.players) do
      -- local props = mapDec.players[1]
      print(props.mnemonic)
      local image = love.graphics.newImage("props/"..props.file)
      local origins = string.split_(props.origin, "|")
      local position = string.split_(props.position, "|")
      local final = string.split_(props.position, "|")
      local sprite = nil
      local animations = {}
      props.velocity = 0.9
      if props.sprite and props.sprite == 'dog.png' then
        props.velocity = 0.9
        sprite = love.graphics.newImage("sprites/"..props.sprite)
        local g = anim8.newGrid(154, 100, sprite:getWidth(), sprite:getHeight())
        local animation_left = anim8.newAnimation(g('1-5',2), 0.2)
        local animation_up = animation_left:clone()
        animation_up:flipH()
        local animation_down = anim8.newAnimation(g('1-5',1), 0.2)
        local animation_right = animation_down:clone()
        animation_right:flipH()
        animations["up"] = animation_up
        animations["down"] = animation_down
        animations["left"] = animation_left
        animations["right"] = animation_right
      end
      if props.sprite and props.sprite == 'zombie.png' then
        props.velocity = 0.3
        sprite = love.graphics.newImage("sprites/"..props.sprite)
        local g = anim8.newGrid(129, 110, sprite:getWidth(), sprite:getHeight())
        local animation_right = anim8.newAnimation(g('1-5',1), 0.2)
        local animation_down = animation_right:clone()
        animation_down:flipH()
        local animation_left = anim8.newAnimation(g('1-5',2), 0.2)
        local animation_up = animation_left:clone()
        animation_up:flipH()
        animations["up"] = animation_up
        animations["down"] = animation_down
        animations["left"] = animation_left
        animations["right"] = animation_right
      end
      print(props.file)
      print(props.mnemonic)
      print(props.origin)
      print("----")
      table.insert(engine.players, {
        texture = props.file,
        velocity = props.velocity,
        mnemonic = props.mnemonic,
        sprite = sprite,
        animations = animations,
        currentAnimation=nil,
        image = image,
        origins = origins,
        position = position,
        final = final,
        action = nil,
        action_queue = {},
      })
    end
    print(engine.players[1].final[1])
    print('---333')
  else
    print("No players found on current map!")
  end
  --Calculate map dimensions
  mapPlayfieldWidthInTiles = #mapPositions
  mapPlayfieldHeightInTiles = #mapPositions[1]

  --Store map original object list size without any extra dynamic objects
  objectListSize = #mapPropsfield

  timerEnd = love.timer.getTime()
  print("Decode loop took "..((timerEnd-timerStart)*100).."ms")

end

function engine.drawGround(xOff, yOff, size)
  assert(xOff)
  assert(yOff)
  assert(size)
  zoomLevel = size
  --Apply lighting
  love.graphics.setColor(tonumber(mapLighting[1]), tonumber(mapLighting[2]), tonumber(mapLighting[3]), 255)

  love.graphics.print("X: "..math.floor(x).." Y: "..math.floor(y), 0, 64)
  love.graphics.print("TileWidth: "..tileWidth.."TileHeight"..tileHeight, 200, 164)
  --Draw the flat ground layer for the map, without elevation or props.
  engine.mouseTarget = nil
  for i in ipairs(mapPositions) do
    for j=1,#mapPositions[i], 1 do
      local xPos = mapPositions[i][j][1].x * (tileWidth*zoomLevel) + i
      local yPos = mapPositions[i][j][1].y * (tileWidth*zoomLevel) + j
      local xPos, yPos = engine.toIso(xPos, yPos)

      local texture = mapPositions[i][j][1].texture
      love.graphics.draw(texture,xPos+xOff, yPos+yOff, 0, size, size, texture:getWidth()/2, texture:getHeight()/2 )

      local x, y = love.mouse.getPosition()

      xPos = xPos + xOff - texture:getWidth()/2 * size
      yPos = yPos + yOff - texture:getHeight()/2 * size

      local isTarget = (x >= xPos and x <= xPos + texture:getWidth() * size )
        and (y >= yPos and y <= yPos + texture:getHeight() * size)
      if isTarget then
        engine.mouseTarget = {i, j}
      end
    end
  end

end

local texture = love.graphics.newImage("props/highlight.png")
function engine.drawMouseTarget(xOff, yOff, size)
  local mouseTarget = engine.mouseTarget
  zoomLevel = size

  if not mouseTarget then
    return nil
  end

  local player = engine.players[1]
  local path = engine.getTargetPath(player.final, mouseTarget)

  for i, node in ipairs(path) do
    local mapPosition = node.position
    if mapPosition then
      local xPos = mapPosition.x * (tileWidth*zoomLevel)
      local yPos = mapPosition.y * (tileWidth*zoomLevel)
      local xPos, yPos = engine.toIso(xPos, yPos)
      engine.drawTexture(texture, xPos, yPos, xOff, yOff, size)
    end
  end
end

function engine.drawTexture(texture, xPos, yPos, xOff, yOff, size)
  love.graphics.draw(texture,xPos+xOff, yPos+yOff, 0, size, size, texture:getWidth()/2, texture:getHeight()/2 )
end

local function getPosition(x, y)
  if y < 1 or y > #mapPositions then return nil end
  if x < 1 or x > #mapPositions[y] then return nil end

  return mapPositions[y][x][1]
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
		mapPositions,
		source,
		engine.getNeighbors,
		function (current) return current == target end
	)
end

function engine.drawPlayers(xOff, yOff, size)
  assert(xOff)
  assert(yOff)
  assert(size)
  zoomLevel = size

  xOff = xOff
  local player = nil
  for i,player in ipairs(engine.players) do
    local x = player.position[1]
    local y = player.position[2]
    local xPos = x * (tileWidth*zoomLevel) + x
    local yPos = y * (tileWidth*zoomLevel) + y
    local xPos, yPos = engine.toIso(xPos, yPos)
    if player.currentAnimation then
      player.currentAnimation:draw(player.sprite,xPos+xOff, yPos+yOff, 0, size, size, player.image:getWidth()/2, player.image:getHeight()/2 )
    else
      love.graphics.draw(player.image,xPos+xOff, yPos+yOff, 0, size, size, player.image:getWidth()/2, player.image:getHeight()/2 )
    end
  end
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
      local position = mapPositions[finalY][finalX]
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

function engine.drawObjects(xOff, yOff, size)

  --Figure out dynamic object occlusion
  if #mapPropsfield > objectListSize then
    for i=objectListSize+1, #mapPropsfield do
      for j=1, objectListSize do
        if mapPropsfield[i].y < mapPropsfield[j].y and
          mapPropsfield[i].x < mapPropsfield[j].x and
          CheckCollision(
            mapPropsfield[j].colX,
            mapPropsfield[j].colY,
            mapPropsfield[j].width,
            mapPropsfield[j].height,
            mapPropsfield[i].colX,
            mapPropsfield[i].colY,
            mapPropsfield[i].width,
            mapPropsfield[i].height
          )
          then
          mapPropsfield[j].alpha = true
        end
      end
    end
  end

  --Sort ZBuffer and draw objects.
  for k,v in spairs(mapPropsfield, function(t,a,b) return t[b].mapY > t[a].mapY end) do
    local xPos = v.x * (tileWidth*zoomLevel)
    local yPos = v.y * (tileWidth*zoomLevel)
    local xPos, yPos = engine.toIso(xPos, yPos)

    if v.alpha then
      love.graphics.setColor(255, 255, 255, 90)
    else
      love.graphics.setColor(255, 255, 255, 255)
    end
    love.graphics.draw(v.texture, xPos+xOff, yPos+yOff, 0, size, size, v.offX, v.offY)

    --Update values in order to minimize for loops
    v.alpha = false
    v.colX = xPos-v.offX
    v.colY = yPos-v.offY
    v.mapX, v.mapY = engine.toIso(v.x, v.y)
  end
end


function engine.getTile2DCoordinates(i, j)
  local xP = mapPositions[i][j][1].x * (tileWidth*zoomLevel)
  local yP = mapPositions[i][j][1].y * (tileWidth*zoomLevel)
  xP, yP = engine.toIso(xP, yP)
  return xP, yP
end


function engine.getPlayfieldWidth()
  return mapPlayfieldWidthInTiles
end

function engine.getPlayfieldHeight()
  return mapPlayfieldHeightInTiles
end

function engine.getGroundTileWidth()
  return tileWidth
end

--Links used whilst searching for information on isometric maps:
--http://stackoverflow.com/questions/892811/drawing-isometric-game-worlds
--https://gamedevelopment.tutsplus.com/tutorials/creating-isometric-worlds-a-primer-for-game-developers--gamedev-6511
--Give it a good read if you don't understand whats happening over here.

function engine.toIso(x, y)
  assert(x, "Position X is nil!")
  assert(y, "Position Y is nil!")

  newX = x - y
  newY = (x + y)/2
  return newX, newY
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
  assert(mapPlayfieldWidthInTiles>=isoX, "Insertion coordinates out of map bounds! (X)")
  assert(mapPlayfieldWidthInTiles>=isoY, "Insertion coordinates out of map bounds! (Y)")
  local rx, ry = engine.toIso(isoX, isoY)

  local colX = isoX * (tileWidth*zoomLevel)
  local colY = isoY * (tileWidth*zoomLevel)
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
  table.insert(mapPropsfield, propField)
  table.insert(mapPositions[isoX][isoY][1].objects, propField)
end

function engine.removeObject(x, y)
  if #mapPositions[x][y] > 1 then
    table.remove(mapPositions[x][y], #mapPositions[x][y])
  end
end

return engine 