table.filter = function(t, filterIter)
    local out = {}
  
    for k, v in pairs(t) do
      if filterIter(v, k, t) then table.insert(out, v) end
    end
  
    return out
end

function parseMap(map)
    local data = {}

    for line in map:gmatch"[^\r\n]+" do
        local lineData = {}
            print('y', line)
        for col in line:gmatch"." do
            print('x', col)
            local position = {
                ['x'] = #lineData + 1,
                ['y'] = #data + 1,
                ['value'] = col,
            }
            table.insert(lineData, position) 
        end
        table.insert(data, lineData)
    end

    return data
end

function getPosition(x, y, mapData)
    if y < 1 or y > #mapData then return nil end
    if x < 1 or x > #mapData[y] then return nil end

    print('getPosition', x, y)
    return mapData[y][x]
end

function getNeighbors(position, mapData)
    if not mapData then error("no mapData passed") end
    if not position then return {} end
    local x = position['x']
    local y = position['y']

    print('getNeighbors', x, y)

    return table.filter(
        {
            -- { ['direction'] = 'top', getPosition(x, y - 1, mapData),
            getPosition(x, y - 1, mapData),
            getPosition(x + 1, y, mapData),
            getPosition(x, y + 1, mapData),
            getPosition(x - 1, y, mapData),
        },
        function (v) return v ~= nil end
    )
end

function findPath(mapData, source, getNeighbors, target)
    local queue = {source}
    local visited = {}

    while #queue ~= 0 do
        local current = table.remove(queue)

        if target(current) then
            return {current}
        end


        local neighbors = getNeighbors(current, mapData)
        for index, neighbor in ipairs(neighbors) do
            if not visited[neighbor] then
                table.insert(queue, neighbor)
                visited[neighbor] = true
            end
        end
    end
end


map = [[
aaaaaaaaa
aaaa1aaaa
aaa402aaa
aaaa3aaaa
aaaaaaaaa
]]
mapData = parseMap(map)
position = getPosition(1, 1, mapData)
print('getPosition', position['value'])
print('getPosdddddition', getPosition(-1, -1, mapData))
print('mapp', mapData)
path = findPath(
    mapData,
    position,
    getNeighbors,
    function (current) return current['value'] == '0' end
)

path = path[1]
print('findPath (x, y)', path['x'], path['y'])