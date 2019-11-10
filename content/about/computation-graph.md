---
title: "Computation Graph"
date: 2019-11-10T21:09:19+01:00
description: "Graphs and *Nodes"
weight: -100
draft: false
---

## Gorgonia is Graph based

_Note_: this article takes its inspiration from [this blog post](http://gopherdata.io/post/deeplearning_in_go_part_1/)

Like most deep learning libraries such as Tensorflow or Theano, Gorgonia rely on the concept that equations are representable by graphs.

It expose the equation graph as an [ExprGraph](/reference/exprgraph) object that can be manipulated by the programmer.

So instead of writing:

```go
func main() {
	fmt.Printf("%v", 1+1)
}
```

the programmer should write:

```go
func main() {
	// Create a graph.
	g := gorgonia.NewGraph()

	// Create a node called "x" with the value 1.
	x := gorgonia.NodeFromAny(g, 1, gorgonia.WithName("x"))

	// Create a node called "y" with the value 1.
	y := gorgonia.NodeFromAny(g, 1, gorgonia.WithName("y"))

	// z := x + y
	z := gorgonia.Must(gorgonia.Add(x, y))

	// Create a VM to execute the graph.
	vm := gorgonia.NewTapeMachine(g)

	// Run the VM. Errors are not checked.
	vm.RunAll()

	// Print the value of z.
	fmt.Printf("%v", z.Value())
}
```

#### Numerical stability

Consider the equation $y = log(1+x)$.
This equation is not numerically stable - for very small values of $x$, the answer will most likely be wrong.
This is because of the way float64 is designed - a float64 does not have enough bits to be able to tell apart 1 and 1 + 10e-16.
In fact, the correct way to do it in Go is to use the built in library function math.Log1p.
It can be shown in this simple program:

```go
func main() {
	fmt.Printf("%v\n", math.Log(1.0+10e-16))
	fmt.Printf("%v\n", math.Log1p(10e-16))
}
```

```text
1.110223024625156e-15 // wrong
9.999999999999995e-16 // correct
```

Gorgonia takes care of this using the best implementation to assure numerical stability.


### ExpGraph and *Node

The ExprGraph is the object holding the equation. This vertices of this graph are the values or operators that compose the equation we want to materialize.
Those vertices are represented by a structure called "Node". The graph holds pointer to this structure.

To create the equation, we need to create an ExprGraph, add some *Nodes, it and linked them together.

Luckily, we don't have to manage the connections between the nodes manually.

#### Placeholders and Operators

The Node can hold some Values (a [Value](/reference) is a Go interface that represents a concrete type such as a scalar or a tensor).
But it can also hold [Operators](/reference/operator).

At computation time, the values will flow along the graphs and each node containing an Operator will execute the corresponding code and set the value to the
corresponding node.

### Gradient computation

On top of that, Gorgonia can do both symbolic and automatic differentiation.
This [page](/about/differentiation) explains how it works in detail.
