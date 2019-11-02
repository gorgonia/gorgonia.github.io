---
title: "main"
date: 2019-10-29T14:59:59+01:00
draft: false
---

# Gorgonia

Gorgonia is a library that helps facilitate machine learning in Go.

Write and evaluate mathematical equations involving multidimensional arrays easily.

If this sounds like Theano or TensorFlow, it's because the idea is quite similar.

Specifically, the library is pretty low-level, like Theano, but has higher goals like Tensorflow.


## Why use Gorgonia?

The main reason to use Gorgonia is developer comfort. If you're using a Go stack extensively, now you have access to the ability to create production-ready machine learning systems in an environment that you are already familiar and comfortable with.

ML/AI at large is usually split into two stages: the experimental stage where one builds various models, test and retest; and the deployed state where a model after being tested and played with, is deployed. This necessitate different roles like data scientist and data engineer.

Typically the two phases have different tools: Python/Lua (using [Theano](http://deeplearning.net/software/theano/), [Torch](http://torch.ch/), etc) is commonly used for the experimental stage, and then the model is rewritten in some more performant language like C++ (using [dlib](http://dlib.net/ml.html), [mlpack](http://mlpack.org) etc). Of course, nowadays the gap is closing and people frequently share the tools between them. Tensorflow is one such tool that bridges the gap.

Gorgonia aims to do the same, but for the Go environment. Gorgonia is currently fairly performant - its speeds are comparable to Theano's and Tensorflow's  CPU implementations. GPU implementations are a bit finnicky to compare due to the heavy cgo tax, but rest assured that this is an area of active improvement.


### How is this website organized?

This website is composed of four sections with different goals:

{{% children description="true" %}}
