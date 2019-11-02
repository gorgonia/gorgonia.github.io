---
title: "How to compute gradient (differentiation)"
description: "How to compute gradient (differentiation)"
date: 2019-10-29T20:07:07+01:00
draft: true
---


## Goal
Consider this simple equation:

$$ f(x,y) = ( x + y ) z $$

How can we use the capacities of Gorgonia to evaluate the gradient $\nabla f$


such as

$$ \nabla f = [\frac{\partial f}{\partial x}, \frac{\partial f}{\partial y}, \frac{\partial f}{\partial z}] $$

## Code

```go
func main() {
	g := gorgonia.NewGraph()

	var x, y, z *gorgonia.Node
	var err error

	// define the expression
	x = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("x"))
	y = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("y"))
	z = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("z"))
	q, err := gorgonia.Add(x, y)
	if err != nil {
		log.Fatal(err)
	}
	result, err := gorgonia.Mul(z, q)
	if err != nil {
		log.Fatal(err)
	}

	// set initial values then run
	gorgonia.Let(x, -2.0)
	gorgonia.Let(y, 5.0)
	gorgonia.Let(z, -4.0)

	// by default, LispMachine performs forward mode and backwards mode execution
	m := gorgonia.NewLispMachine(g)
	defer m.Close()
	if err = m.RunAll(); err != nil {
		log.Fatal(err)
	}

	fmt.Printf("x=%v;y=%v;z=%v\n", x.Value(), y.Value(), z.Value())
	fmt.Printf("f(x,y,z)=(x+y)*z\n")
	fmt.Printf("f(x,y,z) = %v\n", result.Value())

	if xgrad, err := x.Grad(); err == nil {
		fmt.Printf("df/dx: %v\n", xgrad)
	}

	if ygrad, err := y.Grad(); err == nil {
		fmt.Printf("df/dy: %v\n", ygrad)
	}
	if xgrad, err := z.Grad(); err == nil {
		fmt.Printf("df/dx: %v\n", xgrad)
	}
}
```

reference: http://cs231n.github.io/optimization-2/
