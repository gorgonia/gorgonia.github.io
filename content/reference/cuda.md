---
title: "CUDA support"
date: 2020-03-24T17:17:17+01:00
draft: false
---

Gorgonia comes with CUDA support out of the box. However, usage is specialized. 
To use CUDA, you must build your application with the build tag `cuda`, like so:

```shell
go build -tags='cuda' .
```

Furthermore, there are some additional requirements:

- [CUDA toolkit](https://developer.nvidia.com/cuda-toolkit) is required. Installing this installs the `nvcc` compiler which is required to run your code with CUDA (Be sure to follow the [post-installation steps](http://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#post-installation-actions)).
- `go install gorgonia.org/gorgonia/cmd/cudagen`. This installs the `cudagen` program.
- Running `cudagen` will generate the relevant CUDA related code for Gorgonia. Note that you will need a folder at `src\gorgonia.org\gorgonia\cuda modules\target`
- Only certain ops are supported by the CUDA driver by now. They are implemented in a seperate [`ops/nn` package](https://godoc.org/github.com/gorgonia/gorgonia/ops/nn).


{{% notice warning %}}
CUDA requires thread affinity, and therefore the OS thread must be locked. `runtime.LockOSThread()` must be called in the main function where the VM is running. Please cf this [wiki](https://github.com/golang/go/wiki/LockOSThread) for a general information on how to handle this properly within your Go program 
{{% /notice %}}

### Rationale ###

The main reasons for having such complicated requirements for using CUDA is quite simply performance related. As Dave Cheney famously wrote, [cgo is not Go](https://dave.cheney.net/2016/01/18/cgo-is-not-go). To use CUDA, cgo is unfortunately required. And to use cgo, plenty of tradeoffs need to be made.

Therefore the solution was to nestle the CUDA related code in a build tag, `cuda`. That way by default no cgo is used (well, kind-of - you could still use `cblas` or `blase`).

### About `cudagen`

The reason for requiring [CUDA toolkit](https://developer.nvidia.com/cuda-toolkit) and the tool cudagen is because there are many CUDA [Compute Capabilities](http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#compute-capabilities), and generating code for them all would yield a huge binary for no real good reason. Rather, users are encouraged to compile for their specific Compute Capabilities.

{{% notice info %}}
The reason for requiring an explicit specification to use CUDA for which ops is due to the cost of cgo calls. Additional work is being done currently to implement batched cgo calls,  but until that is done, the solution is keyhole "upgrade" of certain ops
{{% /notice %}}
Lastly, the reason for requiring an explicit specification to use CUDA for which ops is due to the cost of cgo calls. Additional work is being done currently to implement batched cgo calls,  but until that is done, the solution is keyhole "upgrade" of certain ops

### `Op`s supported by CUDA ###

As of now, only the very basic simple ops support CUDA:

Elementwise unary operations:

* `abs`
* `sin`
* `cos`
* `exp`
* `ln`
* `log2`
* `neg`
* `square`
* `sqrt`
* `inv` (reciprocal of a number)
* `cube`
* `tanh`
* `sigmoid`
* `log1p`
* `expm1`
* `softplus`

Elementwise binary operations - only arithmetic operations support CUDA:

* `add`
* `sub`
* `mul`
* `div`
* `pow`

From a lot of profiling of this author's personal projects, the ones that really matter are `tanh`, `sigmoid`, `expm1`, `exp` and `cube` - basically the activation functions. The other operations do work fine with MKL+AVX and aren't the major cause of slowness in a neural network

### CUDA improvements ###

In a trivial benchmark, careful use of CUDA (in this case, used to call `sigmoid`) shows impressive improvements over non-CUDA code (bearing in mind the CUDA kernel is extremely naive and not optimized):

```
BenchmarkOneMilCUDA-8   	     300	   3348711 ns/op
BenchmarkOneMil-8       	      50	  33169036 ns/op
```




## Example
see this [tutorial](/tutorials/mnist-cuda/) for a complete example

### `Op`s supported by CUDA ###

As of now, only the very basic simple ops support CUDA:

Elementwise unary operations:

* `abs`
* `sin`
* `cos`
* `exp`
* `ln`
* `log2`
* `neg`
* `square`
* `sqrt`
* `inv` (reciprocal of a number)
* `cube`
* `tanh`
* `sigmoid`
* `log1p`
* `expm1`
* `softplus`

Elementwise binary operations - only arithmetic operations support CUDA:

* `add`
* `sub`
* `mul`
* `div`
* `pow`

From a lot of profiling of this author's personal projects, the ones that really matter are `tanh`, `sigmoid`, `expm1`, `exp` and `cube` - basically the activation functions. The other operations do work fine with MKL+AVX and aren't the major cause of slowness in a neural network

### CUDA improvements ###

In a trivial benchmark, careful use of CUDA (in this case, used to call `sigmoid`) shows impressive improvements over non-CUDA code (bearing in mind the CUDA kernel is extremely naive and not optimized):

```
BenchmarkOneMilCUDA-8   	     300	   3348711 ns/op
BenchmarkOneMil-8       	      50	  33169036 ns/op
```




## Example
see this [tutorial](/tutorials/mnist-cuda/) for a complete example