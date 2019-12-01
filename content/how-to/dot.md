---
title: "Drawing the ExprGraph with Graphviz (dot)"
date: 2019-12-01T10:14:55+01:00
draft: false
---

The [`encoding`](https://godoc.org/gorgonia.org/gorgonia/encoding/dot) package of Gorgonia contains a function to marshal the [`ExprGraph`](/reference/exprgraph) into the [dot language](https://www.graphviz.org/doc/info/lang.html).

This make it possible to use the [graphviz](https://www.graphviz.org/) program to generate png or svg versions of the graph.

A simple way to do it:

```go
package main

import (
        "fmt"
        "log"

        "gorgonia.org/gorgonia"
        "gorgonia.org/gorgonia/encoding/dot"
)

func main() {
        g := gorgonia.NewGraph()

        var x, y *gorgonia.Node

        // define the expression
        x = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("x"))
        y = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("y"))
        gorgonia.Add(x, y)
        b, err := dot.Marshal(g)
        if err != nil {
                log.Fatal(err)
        }
        fmt.Println(string(b))
}
```

Running this program and sending its output into the dot process produces a picture.

for example:

```shell
$ go run main.go | dot -Tsvg > dot-example.svg
```

produces this graph:

![graph](/images/dot-example.svg)
