local anim8 = require('anim8')

--[[
TODO: s will be packed as renamed ZIP file extensios and will be able to
be installed in users machines. So, textures and props have to be loaded from this directory.
Currently, the decoder will look for textures in folder named textures in the root of the project,
and props in a props folder.
--]]

function parseMap(engine, mapData)
  local textures = {}
  local positions = {}
  local props = {}
  local lighting = {}
  local propFields = {}
  local players = {}
  local tileWidth = 0
  local tileHeight = 0
  local zoomLevel = 1
  local widthInTiles = 0
  local heightInTiles = 0


  print("Current  information:")
  print("General information: =-=-=-=-=-=-=")
  if mapData.general ~= nil then
    print(" name: "..mapData.general[1].name)
    print(" version: "..mapData.general[1].version)
    print(" lighting: "..mapData.general[1].lighting)
    if mapData.general[1].lighting ~= nil then
      lighting = string.split_(mapData.general[1].lighting, "|")
    end
    print("----")
  end

  print("Ground textures: =-=-=-=-=-=-=-=")
  for i, texture in ipairs(mapData.textures) do
    --Print table contents for now
    print(texture.file)
    print(texture.mnemonic)
    print("---")

    table.insert(textures, {
      file = texture.file,
      mnemonic = texture.mnemonic,
      offset = texture.offset,
      image = love.graphics.newImage("textures/"..texture.file)
    })

  end

  --Get ground texture dimensions
  mainTexture = textures[1]
  offsets = string.split_(mainTexture.offset, "|")
  tileWidth = (mainTexture.image:getWidth() - offsets[1])/2
  tileHeight = (mainTexture.image:getHeight() - offsets[2])/2

  print("Playfield props: =-=-=-=-=-=-=-=")
  if mapData.props ~= nil then
    for i, prop in ipairs(mapData.props) do
      print(prop.file)
      print(prop.mnemonic)
      print(prop.origin)
      print("----")
      image = love.graphics.newImage("props/"..prop.file)
      origins = split(prop.origin)
      occupy = fmap(split, prop.occupy or {})

      table.insert(props, {
        file = prop.file,
        mnemonic = prop.mnemonic,
        image = image,
        origins = origins,
        occupy = occupy,
      })
    end
  else
    print("No prop found on current !")
  end


  --Add each ground tile to a table according to their texture
  --TODO: the following should be done on a separate thread. I have not tested the performance of the following lines on a colossal engine.
  timerStart = love.timer.getTime()
  for i, groundTexture in ipairs(textures) do
    for colunas in ipairs(mapData.data) do
      for linhas in ipairs(mapData.data[colunas]) do
        for i, properties in ipairs(mapData.data[colunas][linhas]) do

          --Add ground texture if mnemonic is found
          if properties == groundTexture.mnemonic then
            local xPos = linhas
            local yPos = colunas
            if positions[colunas] == nil then
              positions[colunas] = {}
            end
            if positions[colunas][linhas] == nil then
              positions[colunas][linhas] = {}
            end
            local position = {
              texture = groundTexture.image,
              x=xPos,
              y=yPos,
              objects={}
            }
            table.insert(positions[colunas][linhas], position)
          end

        end
      end
    end
  end

  --TODO: Merge these loops, since both save stuff to the same table?
  --Add object to  accordingly
  for i, prop in ipairs(props) do --For each object

    --Loop through  terrain information
    for colunas in ipairs(mapData.data) do
      for linhas in ipairs(mapData.data[colunas]) do

        --Iterate over the objects in a given 2D position
        for i, objects in ipairs(mapData.data[colunas][linhas]) do
          if objects == prop.mnemonic then
            --table.insert(positions[colunas][linhas], {texture=prop.image, x=linhas, y=colunas, offX=prop.origins[1], offY=prop.origins[2]})

            --VERY IMPORTANT NOTE ABOUT THE FOLLOWING LINES
            --these control the ZBuffer in some *dark manner*. IT WORKS. I **really** have to figure out why.
            pX, pY = engine.toIso(linhas, colunas)

            colX = linhas * (tileWidth*zoomLevel)
            colY = colunas * (tileWidth*zoomLevel)
            colX, colY = engine.toIso(colX, colY)
            local propField = {
              mnemonic=prop.mnemonic,
              texture=prop.image,
              x=linhas,
              y=colunas,
              offX=prop.origins[1],
              offY=prop.origins[2],
              mapY = pY,
              mapX = pX,
              colX = colX,
              colY = colY,
              width = prop.image:getWidth(),
              height = prop.image:getHeight(),
              alpha = false
            }
            -- local propField = [];
            table.insert(propFields, propField)

      table.insert(positions[colunas][linhas][1].objects, propField)

      for i,v in ipairs(prop.occupy or {}) do
        local x = colunas + v[2]
        local y = linhas + v[1]
        if x < 8 and y < 8 then
          table.insert(positions[x][y][1].objects, propField)
        end
      end
      --Add to occupy positions
    end
  end

end
    end

  end

  print("Player props: =-=-=-=-=-=-=-=")
  if mapData.players ~= nil then
    local props = nil
    for i,player in ipairs(mapData.players) do
      -- local player = mapData.players[1]
      local image = love.graphics.newImage("props/"..player.file)
      local origins = string.split_(player.origin, "|")
      local position = string.split_(player.position, "|")
      local final = string.split_(player.position, "|")
      local sprite = nil
      local animations = {}
      player.velocity = 0.9
      if player.sprite and player.sprite == 'dog.png' then
        player.velocity = 0.9
        sprite = love.graphics.newImage("sprites/"..player.sprite)
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
      if player.sprite and player.sprite == 'zombie.png' then
        player.velocity = 0.3
        sprite = love.graphics.newImage("sprites/"..player.sprite)
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
      print(player.file)
      print(player.mnemonic)
      print(player.origin)
      print("----")
      table.insert(engine.players, {
        texture = player.file,
        velocity = player.velocity,
        mnemonic = player.mnemonic,
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
  else
    print("No players found on current !")
  end
  --Calculate  dimensions
  local widthInTiles = #positions
  local heightInTiles = #positions[1]

  --Store  original object list size without any extra dynamic objects
  objectListSize = #propFields

  timerEnd = love.timer.getTime()
  print("Decode loop took "..((timerEnd-timerStart)*100).."ms")


	return {
		textures = textures,
		positions = positions,
		props = props,
		lighting = lighting,
		propFields = propFields,
    objectListSize = objectListSize,
    players = players,
    tileWidth = tileWidth,
    tileHeight = tileHeight,
    zoomLevel = zoomLevel,
    widthInTiles = widthInTiles,
    heightInTiles = heightInTiles,
	}
end
