---
title: "Op's supported by CUDA"
date: 2018-09-24T21:32:15+02:00
draft: false
weight: 160
alwaysopen: true
---

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


