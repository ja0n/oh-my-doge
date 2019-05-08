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

  return {}
end