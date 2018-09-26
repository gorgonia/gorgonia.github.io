---
title: "Improvements"
date: 2018-09-24T21:32:15+02:00
draft: false
weight: 170
alwaysopen: true
---


In a trivial benchmark, careful use of CUDA (in this case, used to call `sigmoid`) shows impressive improvements over non-CUDA code (bearing in mind the CUDA kernel is extremely naive and not optimized):

```
BenchmarkOneMilCUDA-8   	     300	   3348711 ns/op
BenchmarkOneMil-8       	      50	  33169036 ns/op
```



