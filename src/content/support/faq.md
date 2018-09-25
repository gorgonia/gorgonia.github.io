---
title: "FAQ"
date: 2018-09-24T21:32:15+02:00
draft: false
weight: 10
alwaysopen: false
---

### Why are there seemingly random `runtime.GC()` calls in the tests? ###

The answer to this is simple - the design of the package uses CUDA in a particular way: specifically, a CUDA device and context is tied to a `VM`, instead of at the package level. This means for every `VM` created, a different CUDA context is created per device per `VM`. This way all the operations will play nicely with other applications that may be using CUDA (this needs to be stress-tested, however). 

The CUDA contexts are only destroyed when the `VM` gets garbage collected (with the help of a finalizer function). In the tests, about 100 `VM`s get created, and garbage collection for the most part can be considered random. This leads to cases where the GPU runs out of memory as there are too many contexts being used. 

Therefore at the end of any tests that may use GPU, a `runtime.GC()` call is made to force garbage collection, freeing GPU memories.

In production, one is unlikely to start that many `VM`s, therefore it's not really a problem. If there is, open a ticket on Github, and we'll look into adding a `Finish()` method for the `VM`s.


