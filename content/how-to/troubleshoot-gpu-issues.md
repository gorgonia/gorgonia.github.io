---
title: "Troubleshoot GPU Issues"
date: 2020-07-17T06:24:26+10:00
draft: false
---

This document is a running list of troubleshooting TODOs. Should you run into issues with GPU usage, this document should help.


The `cu` package ships with an application called `cudatest` which will be helpful in troubleshooting issues.

To install `cudatest`, run

```shell
go install gorgonia.org/cu/cmd/cudatest
```

This also assumes that you already have installed CUDA, and cuDNN.


# Error in Initialization with Multiple GPUs #

If you are running multiple GPUs, you might run into a message that looks as follows:

```shell
Error in initialization, please refer to "https://docs.nvidia.com/cuda/cuda-driver-api/group__CUDA__INITIALIZE.html"
```


This usually means that one of your GPUs does not support CUDA. You can still run with CUDA if you know at least one of your GPUs supports CUDA.

First, use `nvidia-smi` to find the running GPUs. An example is provided below

```shell
Thu Jul 16 17:41:10 2020
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 450.51.05    Driver Version: 450.51.05    CUDA Version: 11.0     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  Tesla K20Xm         On   | 00000000:06:00.0 Off |                    0 |
| N/A   33C    P8    16W / 235W |      0MiB /  5700MiB |      0%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
|   1  GeForce GT 1030     On   | 00000000:07:00.0  On |                  N/A |
| 35%   33C    P0    N/A /  30W |    656MiB /  1994MiB |     51%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|    1   N/A  N/A      XXXX      G   /usr/lib/xorg/Xorg                270MiB |
|    1   N/A  N/A      XXXX      G   /usr/bin/PROGRAMNAME               77MiB |
|    1   N/A  N/A      XXXX      G   /usr/bin/PROGRAMNAME               68MiB |
|    1   N/A  N/A      XXXX      G   ...AAAAAAAAA= --shared-files      221MiB |
+-----------------------------------------------------------------------------+
```

Here, we see that there are two GPUs:

* GPU ID 0 is Tesla K20Xm.
* GPU ID 1 is GeForce GT 1030.

The GeForce GT 1030 does not supoprt CUDA. While the Tesla K20Xm does. To remedy this, simply add this environment variable:

```shell
CUDA_VISIBLE_DEVICES=0 cudatest
```

Something like the following should be returned:

```shell
$ CUDA_VISIBLE_DEVICES=0 cudatest
CUDA version: 11000
CUDA devices: 1
Device 0
========
Name      :     "Tesla K20Xm"
Clock Rate:     732000 kHz
Memory    :     5977800704 bytes
Compute   :     3.5
```
