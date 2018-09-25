---
title: "Usage"
date: 2018-09-24T21:32:15+02:00
draft: false
weight: 150
alwaysopen: false
---

Gorgonia works by creating a computation graph, and then executing it. Think of it as a programming language, but is limited to mathematical functions, and has no branching capability (no if/then or loops). In fact this is the dominant paradigm that the user should be used to thinking about. The computation graph is an [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree). 

Microsoft's [CNTK](https://github.com/Microsoft/CNTK), with its BrainScript, is perhaps the best at exemplifying the idea that building of a computation graph and running of the computation graphs are different things, and that the user should be in different modes of thoughts when going about them. 

Whilst Gorgonia's implementation doesn't enforce the separation of thought as far as CNTK's BrainScript does, the syntax does help a little bit.

Here's an example - say you want to define a math expression `z = x + y`. Here's how you'd do it:

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

	// create a VM to run the program on
	machine := NewTapeMachine(g)

	// set initial values then run
	Let(x, 2.0)
	Let(y, 2.5)
	if machine.RunAll() != nil {
		log.Fatal(err)
	}

	fmt.Printf("%v", z.Value())
	// Output: 4.5
}
```

You might note that it's a little more verbose than other packages of similar nature. For example, instead of compiling to a callable function, Gorgonia specifically compiles into a `*program` which requires a `*TapeMachine` to run. It also requires manual a `Let(...)` call.

The author would like to contend that this is a Good Thing - to shift one's thinking to a machine-based thinking. It helps a lot in figuring out where things might go wrong.

Additionally, there are no support for branching - that is to say there are no conditionals (if/else) or loops. The aim is not to build a Turing-complete computer. 


