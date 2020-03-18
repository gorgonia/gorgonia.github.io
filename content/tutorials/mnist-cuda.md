---
title: "Convnet with CUDA"
date: 2020-02-16T22:08:40+01:00
draft: false
---

This tutorial describes how to run the simple convolutional neural network on a GPU.

The example used in this tutorial is based on MNIST. Your development environment should be ready as described in the tutorial ["Simple convolution neural net (mnist)"](/tutorials/mnist/)

## Preparing the CUDA binding

The CUDA binding relies on CGO and the official CUDA toolkit. You can install it manually or, if you use AWS, you can rely on an AMI with all the pre-requisites.

### Installing the CUDA toolkit manually

The installation of the CUDA toolkit is out-of-scope of this tutorial. But you must ensure that:

1. [CUDA toolkit](https://developer.nvidia.com/CUDA-toolkit) is installed (version 10 has been tested successfully). Installing this installs the `nvcc` compileri, which is required to run your code with CUDA.
2. you run the [post-installation steps](http://docs.nvidia.com/CUDA/CUDA-installation-guide-linux/index.html#post-installation-actions)

### Using AWS EC2

AWS provides AMI with the CUDA toolkit pre-installed. 
You can have a list of those AMI thanks to this command:

```shell
~ aws ec2 describe-images --owners amazon --filters 'Name=state,Values=available' 'Name=name,Values=Deep Learning AMI (Ubuntu)*' --query 'sort_by(Images, &CreationDate)[].Name'
```

Those AMI have been tested successfully on `g3s.xlarge` against version 0.9.8 of Gorgonia.

{{% notice info %}}
For convenience, you can find a [terraform](terraform.io) file to help you kickstarting a VM on AWS EC2 [here](https://github.com/gorgonia/dev/tree/master/infrastructure/aws/gpu) 
{{% /notice %}}

## Preparing the code

There is many different hardware. To address the specificities, Gorgonia provides a command that generates binding specifically for your hardware. This function is carried by a specific tool call `CUDAgen`

{{% notice warning %}}
`CUDAgen` does not play well with go modules, and you need to turn them off.
{{% /notice %}}

Those commands install the `cudagen` tool and generate the CUDA binding.
```shell
~ export GO111MODULE=off
~ go get gorgonia.org/gorgonia
~ export CGO_CFLAGS="-I/usr/local/cuda-10.0/include/"
~ export PATH=$PATH:/usr/local/cuda/bin/
~ go get gorgonia.org/cu
~ go install gorgonia.org/gorgonia/cmd/cudagen
~ $GOPATH/bin/cudagen
```

## Running the example

Gorgonia's example directory contains a [`convenet_CUDA`](https://github.com/gorgonia/gorgonia/tree/master/examples/convnet_cuda) example.
This example runs a convolution neural network against the MNIST database.

{{% notice info %}}
The code is similar to the `convnet` example; the only difference is in the operators import; 
This version uses the operators' from the [`nnops`](https://github.com/gorgonia/gorgonia/tree/master/ops/nn). This package holds a couple of operator definitions mostly used in neural networks (`Conv2D`, `Maxpool`, ...); the definitions have a signature that makes them compatible with their counterpart in CUDA. Package `nnops` ensure the compatibility with the CPU version of the operator if CUDA is not used.
{{% /notice %}}

Assuming that the tests file are in place in `../testdata` (cf the tutorial ["Simple convolution neural net (mnist)"](/tutorials/mnist/) if it's not), you can launch the training phase with a CUDA support by simply running:

```text
time go run -tags='CUDA'  main.go -epochs 1 2> /dev/null
Epoch 0 599 / 600 [====================================================]  99.83%
```

It is also possible to "monitor" the CUDA usage by running the `nvidia-smi` command in a separate window.
This should display something like this:

```text
~  nvidia-smi
Sun Feb 16 22:05:15 2020
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 418.87.00    Driver Version: 418.87.00    CUDA Version: 10.1     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla M60           On   | 00000000:00:1E.0 Off |                    0 |
| N/A   54C    P0    73W / 150W |    841MiB /  7618MiB |     76%      Default |
+-------------------------------+----------------------+----------------------+

+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|    0     18614      C   /tmp/go-build629284435/b001/exe/main         372MiB |
+-----------------------------------------------------------------------------+
```
