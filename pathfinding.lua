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
        for col in line:gmatch"." do
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

    return mapData[y][x]
end

function getNeighbors(position, mapData)
    if not mapData then error("no mapData passed") end
    if not position then return {} end
    local x = position['x']
    local y = position['y']

    return table.filter(
        {
            -- { ['direction'] = 'top', getPosition(x, y - 1, mapData),
            getPosition(x, y - 1, mapData),
            getPosition(x + 1, y, mapData),
            getPosition(x, y + 1, mapData),
            getPosition(x - 1, y, mapData),
        },
        function (v) return v ~= nil and v['value'] ~= 'x' end
    )
end

function findPath(mapData, source, getNeighbors, target)
    local queue = {source}
    local came_from = {}

    while #queue ~= 0 do
        local current = table.remove(queue)

        if target(current) then
            local path = {}
            while current ~= source do
                table.insert(path, 1, current)
                current = came_from[current]
            end
            return path
        end

        local neighbors = getNeighbors(current, mapData)
        for index, neighbor in ipairs(neighbors) do
            if not came_from[neighbor] then
                table.insert(queue, neighbor)
                came_from[neighbor] = current 
            end
        end
    end
end


map = [[
.........
xxxxxxx..
....0.x..
......x..
.........
]]
mapData = parseMap(map)
source = getPosition(1, 1, mapData)
print('getPosition', source['value'])
-- print('getPosdddddition', getPosition(-1, -1, mapData))
path = findPath(
    mapData,
    source,
    getNeighbors,
    function (current) return current['value'] == '0' end
)

print(map)

for index, position in ipairs(path) do
    print('findPath (x, y)', position['x'], position['y'])
end