local F = {}

F.clamp = function(x, min, max)
   return x < min and min or (x > max and max or x)
end

F.round = function(x, increment)
   if increment then
      return M.round(x / increment) * increment
   end
   return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

F.split = function(inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t = {}
   for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
      table.insert(t, str)
   end
   return t
end


return M
