* Demo
--------- test.lua -------------
require 'PHPSerialize'

P=PHPSerialize:new()
print(P:serialize_key(1))
print(P:serialize_key('AS'))
print(P:serialize_key(nil))
a={1,2,3,4, 'five', six='six' , seven={1,2}}
ll=P:serialize(a)
print (ll)
x=P:unserialize(ll)
print('X='..type(x))
for k,v in pairs(x) do print(k,v) end



* source link

http://lua-users.org/lists/lua-l/2007-09/msg00421.html
