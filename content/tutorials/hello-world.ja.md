---
title: "こんにちわ世界"
date: 2019-10-29T17:54:31+01:00
draft: false
weight: -100
---

これはGorgoniaでとても簡単な計算を行うための段階的なチュートリアルです。

私たちのゴールはGorgoniaのすべての配管を使用して簡単な操作を行うことです:

$ f(x,y) = x + y $

値は `x = 2` と `y = 5`

## どの様に動作するか

`x + y = z` の評価はグラフで表す事ができます:

{{<mermaid align="left">}}
graph LR;
    z[z] --> add(Round edge)
    add[+] --> x
    add[+] --> y
{{< /mermaid >}}

結果を計算する為に4つのステップを使います:

* Gorgonia で[式](/reference/exprgraph)の様なグラフを作成する
* [nodes](/reference/node) `x` と `y` に幾つかの[値](/reference/value)を設定する
* [gorgonia vm](/reference/vm)上でグラフを起動する
* node `z`から[value](/reference/value)を取り出す
    *

### グラフの作成

以下の方法で空の[式グラフ](/reference/exprgraph)を作成します:

```go
g := gorgonia.NewGraph()
```

### ノードの作成

いくつかの[ノード](/reference/node)を作成しそれらを ExprGraph に関連付けます。

```go
var x, y, z *gorgonia.Node
```

#### プレースホルダの作成

`x`と`y`はスカラー変数です。対応するノードは次のように作成できます:

```go
x = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("x"))
y = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("y"))
```

{{% notice note %}}
関数は引数としてexprgraphを取ります; 結果のノードは自動的にグラフに関連付けられます。
{{% /notice %}}


次に加算演算子を作成します。この演算子は2つの[ノード](/reference/node)を取り新しいノードzを返します:

```go
if z, err = gorgonia.Add(x, y); err != nil {
        log.Fatal(err)
}
```

{{% notice info %}}
戻り値のノード`z`は`g`が`z`または`Add`関数に渡されていない場合でもグラフには追加されます。
{{% /notice %}}


### 値の設定

式 `z = x + y` を表す ExprGraph ができました。では`x`と`y`にいくつかの値を割り当てます。

関数 [`Let`](https://godoc.org/gorgonia.org/gorgonia#Let) を使います:

```go
gorgonia.Let(x, 2.0)
gorgonia.Let(y, 2.5)
```

### グラフの実行

グラフを実行して結果を計算するには [VM](/reference/vm) をインスタンス化する必要があります。
[TapeMachine](/reference/vm/tapemachine)を使いましょう:

```go
machine := gorgonia.NewTapeMachine(g)
defer machine.Close()
```

そしてグラフの実行:

```go
if err = machine.RunAll(); err != nil {
        log.Fatal(err)
}
```

{{% notice warning %}}
2回目の実行が必要な場合`vm`オブジェクトの`Reset()`メソッドを呼び出すことが必須です:
` machine.Reset() `
{{% /notice %}}

### 値の取得

これでノード`z`が結果を保持します。
[Value](/reference/value)を抽出するには`Value()`メソッドを呼び出します:

```go
fmt.Printf("%v", z.Value())
```

{{% notice note %}}
この場合`float64`を保持する`interface{}`を返す`z.Value().Data()`を呼び出して、基になる"Go"値にアクセスすることもできます。
{{% /notice %}}

# 最終結果

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
