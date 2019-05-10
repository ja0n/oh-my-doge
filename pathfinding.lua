table.filter = function(t, filterIter)
  local out = {}

  for k, v in pairs(t) do
   if filterIter(v, k, t) then table.insert(out, v) end
  end

  return out
end

function findPath(mapData, source, getNeighbors, target)
  local queue = {source}
  local came_from = {}
  local direction_from = {}

  while #queue ~= 0 do
    local current = table.remove(queue)

    if target(current) then
      local path = {}
      while current ~= source do
        direction = direction_from[current]
        table.insert(path, 1, { direction = direction, position = current })
        current = came_from[current]
      end
      return path
    end

    local neighbors = getNeighbors(current, mapData)
    for index, neighbor in ipairs(neighbors) do
      if not came_from[neighbor.position] then
        table.insert(queue, neighbor.position)
        came_from[neighbor.position] = current
        direction_from[neighbor.position] = neighbor.direction
      end
    end
  end

  return {}
end