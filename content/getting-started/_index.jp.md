+++
title = "事始め"
date = 2019-10-29T17:42:44+01:00
weight = -10
chapter = true
pre = "<b>X. </b>"
+++

## Gorgoniaの入手

Gorgoniaはgo-get可能でありgo modulesをサポートしています。
ライブラリとその依存物を取得するには単純に以下を実行します。

```bash
$ go get gorgonia.org/gorgonia
```

## 簡単な計算をする為の初めてのコード

配管が正常かどうかを確認する簡単なプログラムを作成します:

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

プログラムを実行するとこの結果が出力されるはずです： `4.5`

詳細については[Hello Worldチュートリアル](/tutorials/hello-world)を参照してください。

