---
title: "Hello World"
date: 2019-10-29T17:54:31+01:00
draft: false
weight: -100
---

This is a step by step tutorial to do a very simple computation with Gorgonia.

Our goal is to use all the plumbing of Gorgonia to do a simple operation:

$ f(x,y) = x + y $

with  `x = 2` and `y = 5`

## how it works

The equation `x + y = z` can be represented as a graph:

{{<mermaid align="left">}}
graph LR;
    z[z] --> add(Round edge)
    add[+] --> x
    add[+] --> y
{{< /mermaid >}}

To compute the result, we use 4 steps:

* Make a similar [graph](/reference/exprgraph) with Gorgonia
* sets some [values](/reference/value) on the [nodes](/reference/node) `x` and `y` then
* instanciate a graph on a [gorgonia vm](/reference/vm)
* extract the [value](/reference/value) from node `z`
    *

### Create a graph

Create an empty [expression graph](/reference/exprgraph) with this method:

```go
g := gorgonia.NewGraph()
```

### Create the nodes

We will create some [nodes](/reference/node) and associate them to the ExprGraph.

```go
var x, y, z *gorgonia.Node
```

#### Create the placeholder
`x` and `y` are scalar variables, we can create the corresponding node with:

```go
x = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("x"))
y = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("y"))
```

{{% notice note %}}
the functions take the exprgraph as argument; the resulting node is automatically associated to the graph.
{{% /notice %}}


Now create the addition operator; this operator takes two [nodes](/reference/node) and returns a new node z:

```go
if z, err = gorgonia.Add(x, y); err != nil {
        log.Fatal(err)
}
```

{{% notice info %}}
the returning node `z` is added to the graph even if `g` is not passed to `z` or to the `Add` function.
{{% /notice %}}


### Set the values

We have a ExprGraph that represents the equation `z = x + y`. Now it's time to assign some values to `x` and `y`.

We use the [`Let`](https://godoc.org/gorgonia.org/gorgonia#Let) function:

```go
gorgonia.Let(x, 2.0)
gorgonia.Let(y, 2.5)
```

### Run the graph

To run the graph and compute the result, we need to instanciate a [VM](/reference/vm).
Let's use the [TapeMachine](/reference/vm/tapemachine):

```go
machine := gorgonia.NewTapeMachine(g)
defer machine.Close()
```

and run the graph:

```go
if err = machine.RunAll(); err != nil {
        log.Fatal(err)
}
```

{{% notice warning %}}
If a second run is needed, it is mandatory to call the `Reset()` method of the `vm` object:
` machine.Reset() `
{{% /notice %}}

### Get the result

Now the node `z` holds the result.
We can extract its [value](/reference/value) by calling the `Value()` method:

```go
fmt.Printf("%v", z.Value())
```

{{% notice note %}}
we could also access the underlying "Go" value with a call to `z.Value().Data()` which would return an `interface{}` holding a `float64` in our case
{{% /notice %}}

# Final result

```go
package main

import (
        "fmt"
        "log"

        "gorgonia.org/gorgonia"
)

func main() {
        g := gorgonia.NewGraph()

        var x, y, z *gorgonia.Node
        var err error

        // define the expression
        x = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("x"))
        y = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("y"))
        if z, err = gorgonia.Add(x, y); err != nil {
                log.Fatal(err)
        }

        // create a VM to run the program on
        machine := gorgonia.NewTapeMachine(g)
        defer machine.Close()

        // set initial values then run
        gorgonia.Let(x, 2.0)
        gorgonia.Let(y, 2.5)
        if err = machine.RunAll(); err != nil {
                log.Fatal(err)
        }

        fmt.Printf("%v", z.Value())
}
```

```shell
$ go run main.go
4.5
```
