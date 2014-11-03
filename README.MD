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
