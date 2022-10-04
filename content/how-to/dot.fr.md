---
title: "Dessiner le ExprGraph avec Graphviz (dot)"
date: 2019-12-01T10:14:55+01:00
draft: false
---

Le package [`encoding`](https://godoc.org/gorgonia.org/gorgonia/encoding/dot) de Gorgonia contient une fonction permettant de déployer le [`ExprGraph`](/reference/exprgraph) en [dot language](https://www.graphviz.org/doc/info/lang.html).

Cela permet d'utiliser le programme [graphviz](https://www.graphviz.org/) pour générer des versions png ou svg du graphique.

Une manière simple de le faire :

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

Lancer ce programme et mettre ce qu'il renvoie dans le dot process permet d'obtenir une image.

par exemple :

```shell
$ go run main.go | dot -Tsvg > dot-example.svg
```

donne ce graphique :

![graph](/images/dot-example.svg)
