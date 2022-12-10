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
