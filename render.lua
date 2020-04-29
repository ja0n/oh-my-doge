local engine = require('engine')
local textures = require('textures')

render = {}


function render.update(vx, vy, zoomL)
  render.drawGround(vx, vy, zoomL)
  render.drawMouseTarget(vx, vy, zoomL)
  render.drawPlayers(vx, vy, zoomL)
  render.drawObjects(vx, vy, zoomL)
end


function render.drawGround(xOff, yOff, zoom)
  assert(xOff)
  assert(yOff)
  assert(zoom)

  --Apply lighting
  -- Rename backgroundColor
  love.graphics.setColor(
    tonumber(engine.map.lighting[1]),
    tonumber(engine.map.lighting[2]),
    tonumber(engine.map.lighting[3]),
    255
  )

  --Draw the flat ground layer for the map, without elevation or props.
  engine.mouseTarget = nil
  engine.map.zoomLevel = zoom

  for y, column in ipairs(engine.map.positions) do
    for x, line  in ipairs(column) do
      local position = engine.map.positions[y][x][1]
      local position = line[1]
      local texture = position.texture

      render.drawTextureToPosition(xOff, yOff, zoom, x, y, texture)
      engine.getMouseTarget(xOff, yOff, zoom)

    end
  end
end


function render.drawPlayers(xOff, yOff, size)
  assert(xOff)
  assert(yOff)
  assert(size)
  engine.map.zoomLevel = size

  for i,player in ipairs(engine.players) do
    local x = player.position[1]
    local y = player.position[2]
    local tileWidth = engine.map.tileWidth * size
    local tileHeight = engine.map.tileHeight * size
    x = x - 1
    y = y - 1
    local xPos = (x - y) * tileWidth
    local yPos = (x + y) * tileHeight
    xOff = xOff * size
    yOff = yOff * size

    if player.currentAnimation then
      player.currentAnimation:draw(player.sprite, xPos+xOff, yPos+yOff, 0, size, size, tileWidth, 0)
    else
    end
  end
end


function render.drawMouseTarget(xOff, yOff, zoom)
  local mouseTarget = engine.mouseTarget
  engine.map.zoomLevel = zoom

  if not mouseTarget then
    return nil
  end

  if love.keyboard.isDown('lshift') then
    local texture = bloodTexture
    local y = mouseTarget[1]
    local x = mouseTarget[2]
    print('mouseTarget:', y, x)
  else
    local player = engine.players[1]
    render.drawPath(xOff, yOff, zoom, player.final, mouseTarget)
  end

end


function render.drawPath(xOff, yOff, zoom, from, to)
  local path = engine.getTargetPath(from, to)
  local texture = textures.highlightGround

  for i, node in ipairs(path) do
    local mapPosition = node.position
    if mapPosition then
      local x = mapPosition.x
      local y = mapPosition.y
      render.drawTextureToPosition(xOff, yOff, zoom, x, y, texture)
    end
  end

end

function render.updateDynamicObjectOcclusion ()
  --Figure out dynamic object occlusion
  if #engine.map.propFields > engine.map.objectListSize then
    for i=engine.map.objectListSize + 1, #engine.map.propFields do
      for j=1, engine.map.objectListSize do
        if engine.map.propFields[i].y < engine.map.propFields[j].y and
          engine.map.propFields[i].x < engine.map.propFields[j].x and
          CheckCollision(
            engine.map.propFields[j].colX,
            engine.map.propFields[j].colY,
            engine.map.propFields[j].width,
            engine.map.propFields[j].height,
            engine.map.propFields[i].colX,
            engine.map.propFields[i].colY,
            engine.map.propFields[i].width,
            engine.map.propFields[i].height
          )
          then
          engine.map.propFields[j].alpha = true
        end
      end
    end
  end
end


function render.drawObjects(xOff, yOff, size)
  render.updateDynamicObjectOcclusion()
  --Sort ZBuffer
  local sorteredPropFields = spairs(engine.map.propFields, function(t,a,b) return t[b].mapY > t[a].mapY end)
  -- local sorteredPropFields = engine.map.propFields

  -- Draw objects.
  for k,v in sorteredPropFields do
    render.drawObject(v, xOff, yOff, size)
  end
end


function render.drawObject (v, xOff, yOff, size)
    local x = v.x - 1
    local y = v.y - 1
    local xPos = x * (engine.map.tileWidth * size)
    local yPos = y * (engine.map.tileWidth * size)
    local xPos, yPos = engine.toIso(xPos, yPos)

    if v.alpha then
      love.graphics.setColor(255, 255, 255, 0.35)
    else
      love.graphics.setColor(255, 255, 255, 1.0)
    end

    vOffX, vOffY = engine.toIso(v.offX, v.offY)
    render.drawTextureToPosition(
      xOff + vOffX,
      yOff + vOffY,
      size,
      v.x,
      v.y,
      v.texture
    )

    --Update values in order to minimize for loops

    v.alpha = false
    v.colX = xPos-v.offX
    v.colY = yPos-v.offY
    v.mapX, v.mapY = engine.toIso(v.x, v.y)
    love.graphics.setColor(255, 255, 255, 1.0)
end


function render.drawTextureToPosition(xOff, yOff, zoom, x, y, texture)
  -- local mapPosition = engine.map.positions[y][x][1]
  local tileWidth = engine.map.tileWidth * zoom
  local tileHeight = engine.map.tileHeight * zoom
  x = x - 1
  y = y - 1
  local xPos = (x - y) * tileWidth
  local yPos = (x + y) * tileHeight
  -- local xPos, yPos = engine.toIso(xPos, yPos)
  love.graphics.draw(
    texture,
    xPos + (xOff * zoom),
    yPos + (yOff * zoom),
    0,
    zoom,
    zoom,
    tileWidth,
    0
  )
end


function render.drawTexture(texture, xPos, yPos, xOff, yOff, size)
  love.graphics.draw(texture, xPos+xOff, yPos+yOff, 0, size, size, engine.map.tileWidth, engine.map.tileHeight)
end


return render
