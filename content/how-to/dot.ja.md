---
title: "Graphviz (dot) を用いた ExprGraph の描画"
date: 2019-12-01T10:14:55+01:00
draft: false
---

Gorgonia の [`encoding`](https://godoc.org/gorgonia.org/gorgonia/encoding/dot) パッケージには、[`ExprGraph`](/reference/exprgraph) を [dot language](https://www.graphviz.org/doc/info/lang.html) にマーシャリングする関数が含まれています。

これにより [graphviz](https://www.graphviz.org/) プログラムを用いてグラフの png または svg バージョンを生成することができます。

簡単な方法:

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

このプログラムを実行して出力を dot プロセスに送り込むと画像が生成されます。

例:

```shell
$ go run main.go | dot -Tsvg > dot-example.svg
```

この画像が出力されます:

![graph](/images/dot-example.svg)
