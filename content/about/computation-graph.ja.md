---
title: "計算グラフ"
date: 2019-11-10T21:09:19+01:00
description: "Graphs and *Nodes"
weight: -100
draft: false
---

## Gorgonia はグラフベース

_Note_：この記事は [このブログ投稿](http://gopherdata.io/post/deeplearning_in_go_part_1/) からインスピレーションを得ています。

Tensorflow や Theano など殆どの深層学習ライブラリと同様に、Gorgonia は方程式がグラフで表現できるという概念に依存しています。

方程式グラフをプログラマーが操作できる [ExprGraph](/reference/exprgraph) オブジェクトとして公開します。

ですので以下の様に書く代わりに:

```go
func main() {
	fmt.Printf("%v", 1+1)
}
```

プログラマはこう書くのです:

```go
func main() {
	// Create a graph.
	g := gorgonia.NewGraph()

	// Create a node called "x" with the value 1.
	x := gorgonia.NodeFromAny(g, 1, gorgonia.WithName("x"))

	// Create a node called "y" with the value 1.
	y := gorgonia.NodeFromAny(g, 1, gorgonia.WithName("y"))

	// z := x + y
	z := gorgonia.Must(gorgonia.Add(x, y))

	// Create a VM to execute the graph.
	vm := gorgonia.NewTapeMachine(g)

	// Run the VM. Errors are not checked.
	vm.RunAll()

	// Print the value of z.
	fmt.Printf("%v", z.Value())
}
```

#### 数値の安定性

方程式 $y = log(1+x)$ を考えてみてください。
この方程式は数値的には安定していません- $x$ の値が非常に小さい場合、答えはおそらく間違っています。
これは float64 の設計方法が原因です。float64 には、1 と 1 + 10e-16 を区別するのに十分なビットがありません。
実際には、Go でそれを正しく行うには標準ライブラリ関数 math.Log1p を使用します。
次の簡単なプログラムで表示できます:

```go
func main() {
	fmt.Printf("%v\n", math.Log(1.0+10e-16))
	fmt.Printf("%v\n", math.Log1p(10e-16))
}
```

```text
1.110223024625156e-15 // wrong
9.999999999999995e-16 // correct
```

Gorgonia は数値の安定性を確保するために最適な実装を使用する事でこれを処理します。


### ExpGraph と *Node

ExprGraph は方程式を保持するオブジェクトです。このグラフの頂点は方程式を構成する具体化すべき値または演算子です。
これらの頂点は "ノード" と呼ばれる構造によって表されます。グラフはこの構造へのポインタを保持しています。

方程式を作成するには ExprGraph を作成しいくつかの *Node を追加し、それらを互いに結びつける必要があります。

幸いなことにノード間の接続を手動で管理する必要はありません。

#### プレースホルダとオペレータ

Node はいくつかの値を保持できます ([Value](/reference) はスカラーやテンソルなどの具象型を表す Go インタフェースです)。
ただし [オペレータ](/reference/operator) も保持できます。

計算時には値はグラフに沿って流れ、オペレータを含む各ノードは対応するコードを実行し、値を対応するノードに設定します。

### 勾配計算

さらに Gorgonia はシンボリックと自動微分の両方を行うことができます。
この [ページ](/about/differentiation) ではその仕組みについて詳しく説明しています。


