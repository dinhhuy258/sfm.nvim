function table.extend(dest, src)
  for _, v in pairs(src) do
    table.insert(dest, v)
  end

  return dest
end

function table.first(items)
  return items[1]
end

function table.last(items)
  return items[#items]
end

function table.remove_key(items, key)
  items[key] = nil
end

function table.contains_key(items, key)
  return items[key] and true or false
end

function table.is_empty(items)
  return next(items) == nil
end
