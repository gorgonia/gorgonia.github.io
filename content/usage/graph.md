---
title: "Graph"
date: 2018-09-24T21:32:15+02:00
draft: false
weight: 110
alwaysopen: true
---

A lot has been said about a computation graph or an expression graph. But what is it exactly? Think of it as an AST for the math expression that you want. Here's the graph for the examples (but with a vector and a scalar addition instead) above:

![graph1](https://raw.githubusercontent.com/gorgonia/gorgonia/master/media/exprGraph_example1.png)

By the way, Gorgonia comes with nice-ish graph printing abilities. Here's an example of a graph of the equation `y = x²` and its derivation:

![graph1](https://raw.githubusercontent.com/gorgonia/gorgonia/master/media/exprGraph_example2.png)

To read the graph is easy. The expression builds from bottom up, while the derivations build from top down. This way the derivative of each node is roughly on the same level. 

Red-outlined nodes indicate that it's a root node. Green outlined nodes indicate that they're a leaf node. Nodes with a yellow background indicate that it's an input node. The dotted arrows indicate which node is the gradient node for the pointed-to node.

Concretely, it says that `c42011e840` (`dy/dx`) is the gradient node of the input `c42011e000` (which is `x`).

### Node Rendering ###

A Node is rendered thusly:

<table>
<tr><td>ID</td><td>node name :: type</td></tr>
<tr><td>OP*</td><td>op name :: type</td></tr>
<tr><td colspan="2">shape</td></tr>
<tr><td colspan="2">compilation metadata</td></tr>
<tr><td>Value†</td><td>Gradient</td></tr>
</table>

### Additional Notes ###

* If it's an input node, then the Op row will not show up.
* If there are no Values bound to the node, it will show up as NIL. However, when there are values and gradients, it will try to as best as possible display the values bound to the node.



