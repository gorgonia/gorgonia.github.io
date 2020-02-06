---
title: "簡単なニューラルネットの構築 (MNIST)"
date: 2019-10-29T20:09:05+01:00
draft: false
weight: -98
---

## はじめに

これは MNIST データセットを使って convocation neural network を段階的に構築し練習する為のチュートリアルです。

完全なコードは、Gorgonia メインリポジトリの `examples` ディレクトリにあります。
このチュートリアルの目的はコードを詳細に説明することです。 仕組みの詳細については、次の書籍で見ることができます。 [Go Machine Learning Projects](https://www.packtpub.com/eu/big-data-and-business-intelligence/go-machine-learning-projects)

### データセット

{{% notice info %}}
このパートではデータセットの読み込みと表示について説明します。ニューラルネットの個所に直接ジャンプしたい場合はスキップして [Convolution Neural Net part](#the-convolution-neural-net) に進んでください。
{{% /notice %}}

学習およびテストセットは次からダウンロードできます。 [Yann LeCun's MNIST website](http://yann.lecun.com/exdb/mnist/)

* [train-images-idx3-ubyte.gz](http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz):  training set images (9912422 bytes)
* [train-labels-idx1-ubyte.gz](http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz):  training set labels (28881 bytes)
* [t10k-images-idx3-ubyte.gz](http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz):   test set images (1648877 bytes)
* [t10k-labels-idx1-ubyte.gz](http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz):   test set labels (4542 bytes)

Every image/label starts with a magic number. The `encoding/binary` package of the standard library of Go makes it easy to read those files.
すべての画像やラベルはマジックナンバーで始まります。Goの標準ライブラリの `encoding / binary` パッケージを使用するとこれらのファイルを簡単に読み取ることができます。

##### 'mnist' パッケージ

コモディティとして Gorgonia は `examples` サブディレクトリにパッケージ` mnist` を作成しました。データから情報を抽出し `tensors` を作成することをゴールとしています。。

この関数 [`readImageFile`](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/io.go#L50:6) は reader に含まれる画像の全体を表すバイト列を作ります。

よく似た関数 [`readLabelFile`](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/io.go#L21) はラベルを展開します。

```go
// Image holds the pixel intensities of an image.
// 255 is foreground (black), 0 is background (white).
type RawImage []byte

// Label is a digit label in 0 to 9
type Label uint8

func readImageFile(r io.Reader, e error) (imgs []RawImage, err error)

func readLabelFile(r io.Reader, e error) (labels []Label, err error)
```

そして2つの関数は `RawImage` と `Label` から `tensor.Tensor` への変換処理を担います。

* [prepareX](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/mnist.go#L70)
* [prepareY](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/mnist.go#L99)

```go
func prepareX(M []RawImage, dt tensor.Dtype) (retVal tensor.Tensor)

func prepareY(N []Label, dt tensor.Dtype) (retVal tensor.Tensor)
```

パッケージからエクスポートされる関数は `loc` からファイル `typ` を読み取って特定の型のテンソル(float32またはfloat64)を返す [`Load`](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/mnist.go#L24) のみです。

```go
// Load loads the mnist data into two tensors
//
// typ can be "train", "test"
//
// loc represents where the mnist files are held
func Load(typ, loc string, as tensor.Dtype) (inputs, targets tensor.Tensor, err error)
```

##### パッケージのテスト

では簡単なメインファイルを作成してデータがロードされることを検証しましょう。

テストディレクトリのこのレイアウトは次のとおりです:

```shell
$ ls -alhg *
-rw-r--r--  1 staff   375B Nov 11 13:48 main.go

testdata:
total 107344
drwxr-xr-x  6 staff   192B Nov 11 13:48 .
drwxr-xr-x  4 staff   128B Nov 11 13:48 ..
-rw-r--r--  1 staff   7.5M Jul 21  2000 t10k-images.idx3-ubyte
-rw-r--r--  1 staff   9.8K Jul 21  2000 t10k-labels.idx1-ubyte
-rw-r--r--  1 staff    45M Jul 21  2000 train-images.idx3-ubyte
-rw-r--r--  1 staff    59K Jul 21  2000 train-labels.idx1-ubyte
```

次にテストデータとトレーニングデータの両方を読み取り、結果のテンソルを表示する単純な Go ファイルを作成します:

```go
package main

import (
        "fmt"
        "log"

        "gorgonia.org/gorgonia/examples/mnist"
        "gorgonia.org/tensor"
)

func main() {
        for _, typ := range []string{"test", "train"} {
                inputs, targets, err := mnist.Load(typ, "./testdata", tensor.Float64)
                if err != nil {
                        log.Fatal(err)
                }
                fmt.Println(typ+" inputs:", inputs.Shape())
                fmt.Println(typ+" data:", targets.Shape())
        }
}
```

実行します:

```shell
$ go run main.go
test inputs: (10000, 784)
test data: (10000, 10)
train inputs: (60000, 784)
train data: (60000, 10)
```

テストセットには $28\times28=784 ピクセルの 60000 枚の写真、"one-hot" エンコードされた 60000 個のラベル、および 10000 個のテストファイルがあります。

#### 画像の表現

最初の要素の画像を表示してみましょう:

```go
import (
        //...
        "image"
        "image/png"

        "gorgonia.org/gorgonia/examples/mnist"
        "gorgonia.org/tensor"
        "gorgonia.org/tensor/native"
)

func main() {
        inputs, targets, err := mnist.Load("train", "./testdata", tensor.Float64)
        if err != nil {
                log.Fatal(err)
        }
        cols := inputs.Shape()[1]
        imageBackend := make([]uint8, cols)
        for i := 0; i < cols; i++ {
                v, _ := inputs.At(0, i)
                imageBackend[i] = uint8((v.(float64) - 0.1) * 0.9 * 255)
        }
        img := &image.Gray{
                Pix:    imageBackend,
                Stride: 28,
                Rect:   image.Rect(0, 0, 28, 28),
        }
        w, _ := os.Create("output.png")
        vals, _ := native.MatrixF64(targets.(*tensor.Dense))
        fmt.Println(vals[0])
        err = png.Encode(w, img)
}
```
{{% notice info %}}
基礎となる `[]float64` バックエンドに簡単にアクセスするために `native` パッケージを使用しています。この操作では新しいデータは生成されません。
{{% /notice %}}

これにより png ファイルが生成されます:
![5](/images/mnist_5.png?width=10pc)

そして `5` であることを示す対応するラベルベクトルは:

```shell
$ go run main.go
[0.1 0.1 0.1 0.1 0.1 0.9 0.1 0.1 0.1 0.1]
```

## 畳み込みニューラルネット

5層の畳み込みネットワークを構築しています。 $x_0$ は1つ前で定義した入力画像です。

最初の3つのレイヤー $i$ は次のように定義されます:

$ x\_{i+1} = Dropout(Maxpool(ReLU(Convolution(x_i,W_i)))) $

$i$ は 0-2 の範囲を取ります。

4番目のレイヤーは基本的にいくつかのアクティベーションを適度にゼロにするドロップアウトレイヤーです:

$ x\_{4} = Dropout(ReLU(x_3\cdot W_3)) $

最後のレイヤーは出力ベクトルを取得するために単純な乗算とソフトマックスを適用します(このベクトルは予測したラベルを表します):

$ y = softmax(x_4\cdot W_4)$

### ネットワークの変数

学習可能なパラメーターは $W_0,W_1,W_2,W_3,W_4$ です。ネットワークの他の変数はドロップアウト確率 $d_0,d_1,d_2,d_3$ です。

モデルの変数と出力ノードを保持する構造を作成してみましょう:

```go
type convnet struct {
	g                  *gorgonia.ExprGraph
	w0, w1, w2, w3, w4 *gorgonia.Node // weights. the number at the back indicates which layer it's used for
	d0, d1, d2, d3     float64        // dropout probabilities

	out *gorgonia.Node
}
```

#### learnables の定義

畳み込みは標準の $3\times3$ カーネルと32個のフィルターを使用しています。
データセットの画像は白黒なので1つのチャネルのみを使用しています。これは以下の重みの定義につながります。

* $W_0 \in \mathbb{R}^{32\times 1\times3\times3}$ は最初の畳み込み演算に
* $W_1 \in \mathbb{R}^{64\times 32\times3\times3}$ は2つ目の畳み込み演算に
* $W_2 \in \mathbb{R}^{128\times 64\times3\times3}$ は3つ目の畳み込み演算に
* $W_3 \in \mathbb{R}^{128*3*3\times 625}$ 最終的な行列乗算の為に用意していますを準。4D入力を行列 (128x3x3) に変形する必要があります。625は任意の数字です。
* $W_4 \in \mathbb{R}^{625\times 10}$ で出力サイズを10個のエントリの単一ベクトルに減らします。

{{% notice note %}}
NN 最適化では、出力と入力よりも小さい中間層がある場合に無駄な情報を「圧縮する」ことがよく知られています。
入力は784なので次のレイヤーは小さくする必要があります。625 は格好良い数です。
{{% /notice %}}

ドロップアウトの確率は慣用的な値に固定されています：

* $d_0=0.2$
* $d_1=0.2$
* $d_2=0.2$
* $d_3=0.55$

これで学習可能なプレースホルダーを持った構造を作成できます:

```go
// Note: gorgonia is abbreviated G in this example for clarity
func newConvNet(g *G.ExprGraph) *convnet {
	w0 := G.NewTensor(g, dt, 4, G.WithShape(32, 1, 3, 3), G.WithName("w0"), G.WithInit(G.GlorotN(1.0)))
	w1 := G.NewTensor(g, dt, 4, G.WithShape(64, 32, 3, 3), G.WithName("w1"), G.WithInit(G.GlorotN(1.0)))
	w2 := G.NewTensor(g, dt, 4, G.WithShape(128, 64, 3, 3), G.WithName("w2"), G.WithInit(G.GlorotN(1.0)))
	w3 := G.NewMatrix(g, dt, G.WithShape(128*3*3, 625), G.WithName("w3"), G.WithInit(G.GlorotN(1.0)))
	w4 := G.NewMatrix(g, dt, G.WithShape(625, 10), G.WithName("w4"), G.WithInit(G.GlorotN(1.0)))
	return &convnet{
		g:  g,
		w0: w0,
		w1: w1,
		w2: w2,
		w3: w3,
		w4: w4,

		d0: 0.2,
		d1: 0.2,
		d2: 0.2,
		d3: 0.55,
	}
}
```

{{% notice info %}}
The learnables are initialized with some values normally sampled using Glorot et al.'s algorithm. For more info: [All you need is a good init](https://arxiv.org/pdf/1511.06422.pdf) on Arxiv.
Learnablesは、通常Glorotらのアルゴリズムを使用してサンプリングされたいくつかの値で初期化されます。 詳細情報：[必要なのは適切なinitのみ]（https://arxiv.org/pdf/1511.06422.pdf）Arxivで。
{{% /notice %}}

### ネットワークの定義

convnet の構造にメソッドを追加することにより、ネットワークを定義できるようになりました:

_Note_: わかりやすくするためにエラーチェックは再度削除しています

```go
// This function is particularly verbose for educational reasons. In reality, you'd wrap up the layers within a layer struct type and perform per-layer activations
func (m *convnet) fwd(x *gorgonia.Node) (err error) {
	var c0, c1, c2, fc *gorgonia.Node
	var a0, a1, a2, a3 *gorgonia.Node
	var p0, p1, p2 *gorgonia.Node
	var l0, l1, l2, l3 *gorgonia.Node

	// LAYER 0
	// here we convolve with stride = (1, 1) and padding = (1, 1),
	// which is your bog standard convolution for convnet
	c0, _ = gorgonia.Conv2d(x, m.w0, tensor.Shape{3, 3}, []int{1, 1}, []int{1, 1}, []int{1, 1})
	a0, _ = gorgonia.Rectify(c0)
	p0, _ = gorgonia.MaxPool2D(a0, tensor.Shape{2, 2}, []int{0, 0}, []int{2, 2})
	l0, _ = gorgonia.Dropout(p0, m.d0)

	// Layer 1
	c1, _ = gorgonia.Conv2d(l0, m.w1, tensor.Shape{3, 3}, []int{1, 1}, []int{1, 1}, []int{1, 1})
	a1, _ = gorgonia.Rectify(c1)
	p1, _ = gorgonia.MaxPool2D(a1, tensor.Shape{2, 2}, []int{0, 0}, []int{2, 2})
	l1, _ = gorgonia.Dropout(p1, m.d1)

	// Layer 2
	c2, _ = gorgonia.Conv2d(l1, m.w2, tensor.Shape{3, 3}, []int{1, 1}, []int{1, 1}, []int{1, 1})
	a2, _ = gorgonia.Rectify(c2)
	p2, _ = gorgonia.MaxPool2D(a2, tensor.Shape{2, 2}, []int{0, 0}, []int{2, 2})

	var r2 *gorgonia.Node
	b, c, h, w := p2.Shape()[0], p2.Shape()[1], p2.Shape()[2], p2.Shape()[3]
	r2, _ = gorgonia.Reshape(p2, tensor.Shape{b, c * h * w})
	l2, _ = gorgonia.Dropout(r2, m.d2)

	// Layer 3
	fc, _ = gorgonia.Mul(l2, m.w3)
	a3, _ = gorgonia.Rectify(fc)
	l3, _ = gorgonia.Dropout(a3, m.d3)

	// output decode
	var out *gorgonia.Node
	out, _ = gorgonia.Mul(l3, m.w4)
	m.out, _ = gorgonia.SoftMax(out)
	return
}
```

### ネットワークのトレーニング

トレーニングセットから取得した入力は行列 $numExample \times 784$ です。畳み込み演算子は4Dテンソル BCHW を期待しています。最初にすべき事は入力の形状を変更することです:

```go
numExamples := inputs.Shape()[0]
inputs.Reshape(numExamples, 1, 28, 28)
```

ネットワークをバッチで学習します。バッチサイズは変数（`bs`）です。現在のバッチの値とラベルを保持する2つの新しいテンソルを作成します。
次にニューラルネットをインスタンス化します:

```go
g := gorgonia.NewGraph()
x := gorgonia.NewTensor(g, dt, 4, gorgonia.WithShape(bs, 1, 28, 28), gorgonia.WithName("x"))
y := gorgonia.NewMatrix(g, dt, gorgonia.WithShape(bs, 10), gorgonia.WithName("y"))
m := newConvNet(g)
m.fwd(x)
```
#### コスト関数

単純なクロスエントロピーに基づいて期待される出力を要素ごとに乗算し平均化することにより、値を最小化するコスト関数を定義します:

$cost = -\dfrac{1}{bs} \sum_{i=1}^{bs}(pred^{(i)}\cdot y^{(i)})$

```go
losses := gorgonia.Must(gorgonia.HadamardProd(m.out, y))
cost := gorgonia.Must(gorgonia.Mean(losses))
cost = gorgonia.Must(gorgonia.Neg(cost))
```

後で使用するためにコストの値にポインターを渡します:

```go
var costVal gorgonia.Value
gorgonia.Read(cost, &costVal)
```

そして symbolic backpropagation を実行します:

```go
gorgonia.Grad(cost, m.learnables()...)
```

Learnables はこの様に定義します:
```go
func (m *convnet) learnables() gorgonia.Nodes {
    return gorgonia.Nodes{m.w0, m.w1, m.w2, m.w3, m.w4}
}
```

##### トレーニングループ

まずグラフを実行するための [vm](/reference/vm) と、各ステップで学習可能な値を適応させるためのソルバーが必要です。またソルバーが機能するように2つの学習可能な値に対して実際の値をバインドし、勾配の値を保存する必要があります。

```go
vm := gorgonia.NewTapeMachine(g, gorgonia.BindDualValues(m.learnables()...))
solver := gorgonia.NewRMSPropSolver(gorgonia.WithBatchSize(float64(bs)))
defer vm.Close()
```

バッチサイズを考慮したエポックを構成するいくつかのバッチを定義します:

```go
batches := numExamples / bs
```

次にトレーニングループを作成します:

```go
for i := 0; i < *epochs; i++ {
    for b := 0; b < batches; b++ {
        // ...
    }
}
```

##### ループの中身:
次に各バッチの入力テンソル ($60000 \times 784$) から値を抽出する必要があります。
各入力は ($bs\times 784$) です。最初のバッチは 0 から bs-1 までの値、2番目の bs から 2*bs-1 までの値を保持します。そしてテンソルを4Dテンソルに変形します:

```go
var xVal, yVal tensor.Tensor
xVal, _ = inputs.Slice(sli{start, end})

yVal, _ = targets.Slice(sli{start, end})

xVal.(*tensor.Dense).Reshape(bs, 1, 28, 28)
```

そしてグラフに値を割り当てます:

```go
gorgonia.Let(x, xVal)
gorgonia.Let(y, yVal)
```
VMとソルバーを実行して重みを調整します。

```go
vm.RunAll()
solver.Step(gorgonia.NodesToValueGrads(m.learnables()))
vm.Reset()
```

これで学習できるニューラルネットワークができました。

### おわりに

大量のデータが含まれるためコードの実行は比較的遅くなりますが学習はできています。
[Gorgoniaのサンプルディレクトリ](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/convnet/main.go#L1) で完全なコードを見ることができます。

重みを保存するには [irisチュートリアル](/tutorials/iris) で説明されているように `load` と `save` の2つのメソッドを作成できます。
そして読者への練習としては、このニューラルネットワークを使う為の小さなユーティリティをコーディングがあります。

Have fun!
