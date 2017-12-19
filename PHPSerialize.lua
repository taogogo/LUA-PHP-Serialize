
module("PHPSerialize", package.seeall)

local MT={__index=_M}

  function init(self)
  end

  function new()
    local o={}
    setmetatable(o, MT)
    return o
  end

  function serialize(self, data)
    return self:serialize_value(data)
  end

  function is_int(self, data)
    if tonumber(data) then
      return true
    else
      return false
    end
    --[[
    if type(data)=='number' and math.floor(data)==data then
      return true
    else
      return false
    end
    ]]--
  end

  function serialize_key(self, data)
    if type(data)=='number' then
      return 'i:'..data..';'
    end
    if type(data)=='boolean' then
      return 'i:1'
    end
    if type(data)=='string' then
      if self:is_int(data) then
        return 'i:'..tonumber(data)..';'
      else
        return 's:'..string.len(data)..':"'..data..'";'
      end
    end
    if type(data)=='nil' then
      return 's:0:"";'
    end
    error('Unknown/Unhandled key type! type='..type(data))
  end

  function serialize_value(self, data)
    if type(data)=='number' then
      if math.floor(data)==data or math.ceil(data)==data then
        return 'i:'..data..';'
      else
        return 'd:'..data..';'
      end
    end
    if type(data)=='string' then
      if self:is_int(data) then
        return 'i:'..tonumber(data)..';'
      else
        return 's:'..string.len(data)..':"'..data..'";'
      end
    end
    if type(data)=='nil' then
      return 'N;'
    end
    if type(data)=='table' then
      local out={}
      local i=0
      local len=0
      if #data>0 then
        for k,v in pairs(data) do
          if self:is_int(k) then
            table.insert(out, self:serialize_key(i))
          else
            table.insert(out, self:serialize_key(k))
            i=i-1
          end
          table.insert(out, self:serialize_value(v))
          i=i+1
          len=len+1
        end
      else
        for k,v in pairs(data) do
          table.insert(out, self:serialize_key(k))
          table.insert(out, self:serialize_value(v))
          len=len+1
        end
      end
      return 'a:'..len..':{'..table.concat(out)..'}'
    end
    if type(data)=='boolean' then
      if data then
        return 'b:1;'
      else
        return 'b:0;'
      end
    end
    error('Unknown / Unhandled data type! type='..type(data))
  end

  function unserialize(self, data)
    local a,b,c = self:_unserialize(data, 0)
    return c
  end

  function _unserialize(self, data, offset)
    if offset==nil then offset=0 end
    local buf={}
    local dtype=string.lower(string.sub(data,offset+1,offset+1))
    local dataoffset=offset+2
    local typeconvert=function(x) return x end
    local chars,datalength=0,0
    local readdata, stringlength=nil,nil

    local s1=offset-5
    if s1<1 then s1=1 end
    local s2=offset+5
    if s2>string.len(data) then s2=string.len(data) end
    local snip=string.sub(data, s1,s2)

    if dtype=='i' then
      typeconvert=function(x) return tonumber(x) end
      chars, readdata=self:read_until(data, dataoffset, ';')
      dataoffset=dataoffset+chars+1
    elseif dtype=='b' then
      typeconvert=function(x) return tonumber(x)==1 end
      chars, readdata=self:read_until(data, dataoffset, ';')
      dataoffset=dataoffset+chars+1
    elseif dtype=='d' then
      typeconvert=function(x) return tonumber(x) end
      chars, readdata=self:read_until(data, dataoffset, ';')
      dataoffset=dataoffset+chars+1
    elseif dtype=='n' then
      readdata=nil
    elseif dtype=='s' then
      chars, stringlength=self:read_until(data, dataoffset, ':')
      dataoffset=dataoffset+chars+2
      chars, readdata=self:read_chars(data, dataoffset+1,
tonumber(stringlength
))
      dataoffset=dataoffset+chars+2
      if chars~=tonumber(stringlength) or chars~=string.len(readdata) then
        error('String len mismatch!')
      end
    elseif dtype=='a' then
      readdata={}
      local keys=nil
      chars, keys=self:read_until(data, dataoffset, ':')
      dataoffset=dataoffset+chars+2
      for i=0,tonumber(keys)-1 do
        local ktype, kchars, key=self:_unserialize(data, dataoffset)
        dataoffset=dataoffset+kchars
        local vtype, vchars, value=self:_unserialize(data, dataoffset)
        dataoffset=dataoffset+vchars
        readdata[key]=value
      end
      dataoffset=dataoffset+1
    elseif dtype=='o' then
      chars, stringlength=self:read_until(data, dataoffset, ':')
      dataoffset=dataoffset+chars+2
      chars, readdata=self:read_chars(data, dataoffset+1,
tonumber(stringlength
))
      dataoffset=dataoffset+chars+2
      if chars~=tonumber(stringlength) or chars~=string.len(readdata) then
        error('String len mismatch!')
      end

      readdata=self:createClass(readdata) or {CLASSNAME=readdata} --new
class
      local keys=nil
      chars, keys=self:read_until(data, dataoffset, ':')
      dataoffset=dataoffset+chars+2
      for i=0,tonumber(keys)-1 do
        local ktype, kchars, key=self:_unserialize(data, dataoffset)
        dataoffset=dataoffset+kchars
        local vtype, vchars, value=self:_unserialize(data, dataoffset)
        dataoffset=dataoffset+vchars
        readdata[key]=value
      end
      dataoffset=dataoffset+1
    else
      error('"Unknown / Unhandled data type! type='..dtype)
    end
    return dtype, dataoffset-offset, assert(typeconvert)(readdata)
  end

  function read_until(self, data, offset, stopchar)
    local buf={}
    local char=string.sub(data, offset+1, offset+1)
    local i=2
    while char~=stopchar do
      if i+offset>string.len(data) then
        error('Invalid')
      end
      table.insert(buf, char)
      char=string.sub(data, offset+i, offset+i)
      i=i+1
    end
    return #buf, table.concat(buf)
  end

  function read_chars(self, data, offset, length)
    local buf={}
    for i=1,length do
      char=string.sub(data, offset+(i-1), offset+(i-1))
      table.insert(buf, char)
    end
    return #buf, table.concat(buf)
  end

  -- TODO: not implemented yet!
  function createClass(self, classname)
    return {DummyClass=classname}
  end
