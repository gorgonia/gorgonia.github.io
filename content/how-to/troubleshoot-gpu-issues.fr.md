---
title: "Résoudre des problèmes de GPU"
date: 2020-07-17T06:24:26+10:00
draft: false
---

Ce document est une liste de conseils en cas de problème. Si vous rencontrez des difficultés en utilisant des GPUs, ce document devrait pouvoir vous aider.

Le package `cu` fonctionne avec une application appelée `cudatest` qui devrait être utile pour résoudre des problèmes.

Pour installer `cudatest`, lancez :

```shell
go install gorgonia.org/cu/cmd/cudatest
```

Cela implique que vous ayez déjà installé CUDA, et cuDNN.

# Erreur d'initalisation avec plusieurs GPUs #

Si vous utilisez plusieurs GPUs, vous pourriez tomber sur un message qui ressemble à ce qui suit :

```shell
Error in initialization, please refer to "https://docs.nvidia.com/cuda/cuda-driver-api/group__CUDA__INITIALIZE.html"
```

Cela signifie généralement que l'une de vos GPUs ne supporte pas CUDA. Vous pouvez tout de même utiliser CUDA si vous savez qu'au moins une de vous GPUs supporte CUDA.

D'abord, utilisez `nvidia-smi` pour trouver les GPUs utilisées. Voici un exemple ci-dessous.

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

Ici, on voit qu'il y a deux GPUs :

* GPU ID 0 est Tesla K20Xm.
* GPU ID 1 est GeForce GT 1030.

La GeForce GT 1030 ne supporte pas CUDA. Alors que la Tesla K20Xm, si. Pour résoudre ce problème, ajoutez simplement cette variable d'environnement :

```shell
CUDA_VISIBLE_DEVICES=0 cudatest
```

Cela devrait vous renvoyer quelque chose comme ça :

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
