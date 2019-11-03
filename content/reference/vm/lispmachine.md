---
title: "LispMachine"
date: 2019-10-29T19:50:15+01:00
draft: false
---

The `LispMachine` was designed to take a graph as an input, and executes directly on the nodes of the graph.
If the graph change, simply create a new lightweight `LispMachine` to execute it on.
The `LispMachine` is suitable for tasks such as creating recurrent neural networks without a fixed size.

The trade-off is that executing a graph on `LispMachine` is generally slower than on `TapeMachine`,
given the same static "image" of a graph.


