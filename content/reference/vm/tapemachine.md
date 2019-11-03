---
title: "Tapemachine"
date: 2019-10-29T19:50:15+01:00
draft: false
---

The `TapeMachine` is useful for executing expressions that are generally static (that is to say the computation graph does not change).
Due to its static nature, the `TapeMachine` is good for running expressions that are compiled-once-run-many-times
(such as linear regression, SVM and the like).

## Technical details

The `TapeMachine` pre-compiles a graph into a list of instructions,
then executes the instructions linearly and sequentially.
The main trade-off is dynamism.
Graphs cannot be dynamically created on the fly as a re-compilation process is required (and compilation is relatively expensive).
However, graphs executed with the `TapeMachine` run much faster as plenty of optimizations has been done in the code generation stage.
