---
date: 2016-04-23T15:21:22+02:00
title: About
weight: 0
---

<img src="https://raw.githubusercontent.com/gorgonia/gorgonia/master/media/mascot_small.jpg" align="right" />

Gorgonia is a library that helps facilitate machine learning in Go. Write and evaluate mathematical equations involving multidimensional arrays easily. If this sounds like [Theano](http://deeplearning.net/software/theano/) or [TensorFlow](https://www.tensorflow.org/), it's because the idea is quite similar. Specifically, the library is pretty low-level, like Theano, but has higher goals like Tensorflow.

Gorgonia:

* Can perform automatic differentiation
* Can perform symbolic differentiation
* Can perform gradient descent optimizations
* Can perform numerical stabilization
* Provides a number of convenience functions to help create neural networks
* Is fairly quick (comparable to Theano and Tensorflow's speed)
* Supports CUDA/GPGPU computation (OpenCL not yet supported, send a pull request)
* Will support distributed computing

# Goals 

The primary goal for Gorgonia is to be a *highly performant* machine learning/graph computation-based library that can scale across multiple machines. It should bring the appeal of Go (simple compilation and deployment process) to the ML world. It's a long way from there currently, however, the baby steps are already there.

The secondary goal for Gorgonia is to provide a platform for exploration for non-standard deep-learning and neural network related things. This includes things like neo-hebbian learning, corner-cutting algorithms, evolutionary algorithms and the like. 



