---
title: "Ubiquitous Language and glossary"
date: 2020-02-05T16:45:51+01:00
draft: false
---

This page holds various definitions and glossary that will help you to understand Gorgonia and to communicate with the team (via PR or issues)

## Tensors

* **inner(most) dimension(s)** - given a shape, the inner dimensions tend to the right. e.g. in a shape (2,3,4), the inner dimensions are (3, 4). The innermost dimension is 4.
* **outer(most) dimension(s)** - given a shape, the outer dimensions tend to the left . e.g. in a shape (2,3,4), the outer dimensions are (2, 3). The outermost dimension is 2.
* **vector** - a `tensor` of rank-1. e.g. (2), (3) ... Vectors will be written `[...]`
* **column vector** (or **colvec**) - a `tensor` of rank-2 (i.e. a matrix) with the inner dimension as 1. e.g. (2, 1), (3, 1)...
* **row vector** - a `tensor` of rank-2 (i.e. a matrix) with the outer dimension as 1. e.g. (1, 2), (1, 3)...
* **matrix** a `tensor` of rank-2, with arbitrary inner and outer dimensions. e.g (1, 2), (2, 1), (2, 3)... Matrices will be written in full notation in this doc. This includes colvecs and rowvecs.
