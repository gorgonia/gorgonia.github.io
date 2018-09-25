---
title: "VM"
date: 2018-09-24T21:32:15+02:00
draft: false
weight: 100
alwaysopen: true
---

There are two VMs in the current version of Gorgonia:

* `TapeMachine`
* `LispMachine`

They function differently and take different inputs. The `TapeMachine` is useful for executing expressions that are generally static (that is to say the computation graph does not change). Due to its static nature, the `TapeMachine` is good for running expressions that are compiled-once-run-many-times (such as linear regression, SVM and the like).

The `LispMachine` on the other hand was designed to take a graph as an input, and executes directly on the nodes of the graph. If the graph change, simply create a new lightweight `LispMachine` to execute it on. The `LispMachine` is suitable for tasks such as creating recurrent neural networks without a fixed size.

Prior to release of Gorgonia, there was a third VM - a stack based VM that is similar to `TapeMachine` but deals with artificial gradients better. It may see light of day again, once this author has managed to fix all the kinks.

