```
------------------------------------------------
-- test
MemLeak:init([[memleak.log]]) -- init MemLeak op
MemLeak:cacheMemory()    -- cache memory1

local aaaaaaaaa = {}
bbbbbbbbbb = {}

MemLeak:cacheMemory()    -- cache memory2
MemLeak:differCache()    -- differ memory cache
---------------------------------------------------------
```
中文说明：
http://radiotail.github.io/2014/11/03/%E6%9F%A5%E6%89%BElua%E5%B1%82%E7%9A%84%E5%86%85%E5%AD%98%E6%B3%84%E6%BC%8F%E9%97%AE%E9%A2%98/
