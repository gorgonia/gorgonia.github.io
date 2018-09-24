---
title: "CUDA  "
date: 2018-09-24T21:32:15+02:00
draft: false
weight: 150
alwaysopen: false
---

Gorgonia comes with CUDA support out of the box. However, usage is specialized. To use CUDA, you must build your application with the build tag `cuda`, like so:

``` 
go build -tags='cuda' .
```

Furthermore, there are some additional requirements:

1. [CUDA toolkit 9.0](https://developer.nvidia.com/cuda-toolkit) is required. Installing this installs the `nvcc` compiler which is required to run your code with CUDA.
2. Be sure to follow the [post-installation steps](http://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#post-installation-actions)
3. `go install gorgonia.org/gorgonia/cmd/cudagen`. This installs the `cudagen` program. Running `cudagen` will generate the relevant CUDA related code for Gorgonia. Note that you will need a folder at `src\gorgonia.org\gorgonia\cuda modules\target`
4. The CUDA ops must be manually enabled in your code with the `UseCudaFor` option.
5. `runtime.LockOSThread()` must be called in the main function where the VM is running. CUDA requires thread affinity, and therefore the OS thread must be locked.

Because `nvcc` only plays well with `gcc` version 6 and below (the current version is 7), this is also quite helpful: 

`sudo ln -s /path/to/gcc-6 /usr/local/cuda-9.0/bin/gcc` 


