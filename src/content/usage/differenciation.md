---
title: "Differentiation"
date: 2018-09-24T21:32:15+02:00
draft: false
weight: 105 
alwaysopen: true
---

Gorgonia performs both symbolic and automatic differentiation. There are subtle differences between the two processes. The author has found that it's best to think of it this way - Automatic differentiation is differentiation that happens at runtime, concurrently with the execution of the graph, while symbolic differentiation is differentiation that happens during the compilation phase. 

Runtime of course, refers to the execution of the expression graph, not the program's actual runtime.

With the introduction to the two VMs, it's easy to see how Gorgonia can perform both symbolic and automatic differentiation. Using the same example as above, the reader should note that there was no differentiation done. Instead, let's try with a `LispMachine`:

```go
package main

import (
	"fmt"
	"log"

	. "gorgonia.org/gorgonia"
)

func main() {
	g := NewGraph()

	var x, y, z *Node
	var err error

	// define the expression
	x = NewScalar(g, Float64, WithName("x"))
	y = NewScalar(g, Float64, WithName("y"))
	z, err = Add(x, y)
	if err != nil {
		log.Fatal(err)
	}

	// set initial values then run
	Let(x, 2.0)
	Let(y, 2.5)

	// by default, LispMachine performs forward mode and backwards mode execution
	m := NewLispMachine(g)
	if m.RunAll() != nil {
		log.Fatal(err)
	}

	fmt.Printf("z: %v\n", z.Value())

	xgrad, err := x.Grad()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("dz/dx: %v\n", xgrad)

	ygrad, err := y.Grad()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("dz/dy: %v\n", ygrad)

	// Output:
	// z: 4.5
	// dz/dx: 1
	// dz/dy: 1
}
```

Of course, Gorgonia also supports the more traditional symbolic differentiation like in Theano:

```go
package main

import (
	"fmt"
	"log"

	. "gorgonia.org/gorgonia"
)

func main() {
	g := NewGraph()

	var x, y, z *Node
	var err error

	// define the expression
	x = NewScalar(g, Float64, WithName("x"))
	y = NewScalar(g, Float64, WithName("y"))
	z, err = Add(x, y)
	if err != nil {
		log.Fatal(err)
	}

	// symbolically differentiate z with regards to x and y
	// this adds the gradient nodes to the graph g
	var grads Nodes
	grads, err = Grad(z, x, y)
	if err != nil {
		log.Fatal(err)
	}

	// create a VM to run the program on
	machine := NewTapeMachine(g)

	// set initial values then run
	Let(x, 2.0)
	Let(y, 2.5)
	if machine.RunAll() != nil {
		log.Fatal(err)
	}

	fmt.Printf("z: %v\n", z.Value())

	xgrad, err := x.Grad()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("dz/dx: %v | %v\n", xgrad, grads[0])

	ygrad, err := y.Grad()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("dz/dy: %v | %v\n", ygrad, grads[1])

	// Output:
	// z: 4.5
	// dz/dx: 1 | 1 :: float64{1}
	// dz/dy: 1 | 1 :: float64{1}
}
```

Currently Gorgonia only performs backwards mode automatic differentiation (aka backpropagation), although one may observe the vestiges of an older version which supported forwards mode differentiation in the existence of `*dualValue`. It may return in the future.


