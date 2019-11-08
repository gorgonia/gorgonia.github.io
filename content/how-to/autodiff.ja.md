---
title: "勾配(微分)の計算方法"
description: "勾配(微分)の計算方法"
date: 2019-10-29T20:07:07+01:00
draft: true
---


## ゴール

この簡単な方程式を考えます:

$$ f(x,y) = ( x + y ) z $$

Gorgoniaの能力を使用して勾配 $\nabla f$ を評価するにはどうすればよいか

以下の様な物

$$ \nabla f = [\frac{\partial f}{\partial x}, \frac{\partial f}{\partial y}, \frac{\partial f}{\partial z}] $$

## コード

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

参照: http://cs231n.github.io/optimization-2/
