---
title: "Iris データセットでの多変量線形回帰"
date: 2019-10-31T14:53:37+01:00
draft: false
---

## はじめに

Gorgoniaを使用して線形回帰モデルを作成します。

ゴールは以下に与えられた特性を考慮して花の種別を予測することです:

* sepal_length
* sepal_width
* petal_length
* petal_width

存在する種別は以下の通り:

* setosa
* virginica
* versicolor

このチュートリアルのゴールはgorgoniaを使用して、与えられたirisデータセットから $\Theta$ の正しい値を見つけ以下のようなcliユーティリティを作成することです:

```text
./iris
sepal length: 5
sepal width: 3.5
petal length: 1.4
sepal length: 0.2

It is probably a setosa
```

{{% notice warning %}}
このチュートリアルは学術目的の為の物です。Gorgoniaでこれをどの様にして行うかを説明することがゴールです;
これは特定の問題に対する最先端の答えではありません。
{{% /notice %}}

### 数学的表現

良くある花弁の長さと幅だけでなく、がく片の長さと幅の関数であった場合とその種別について考察します。

したがって $y$ が種別の値であると考える場合に解決すべき方程式は次の通りです:

$$ y = \theta_0 + \theta_1 * sepal\\_length + \theta_2 * sepal\\_width + \theta_3 * petal\\_length + \theta_4 * petal\\_width$$

ベクトルを考慮した場合の $x$ と $\Theta$ はこうなります:

$$ x =  \begin{bmatrix} sepal\\_length & sepal\\_width & petal\\_length & petal\\_width & 1\end{bmatrix}$$

$$
\Theta = \begin{bmatrix}
        \theta_4 \\
        \theta_3 \\
        \theta_2 \\
        \theta_1 \\
        \theta_0 \\
        \end{bmatrix}
$$

よってこうなります。

$$y = x\cdot\Theta$$

### 線形回帰

正しい値を見つける為に線形回帰を使用します。
データを5列(がく片の長さ、がく片の幅、花弁の長さ、花弁の幅、およびバイアスの1)を含む行列 $X$ にエンコードします。
行列の行は種別を表します。

対応する種別をfloat値を持つ列ベクトル $Y$ にエンコードします。

* setosa = 1.0
* virginica = 2.0
* versicolor = 3.0

学習段階ではコストは次のように表す事ができます:

$cost = \dfrac{1}{m} \sum_{i=1}^m(X^{(i)}\cdot\Theta-Y^{(i)})^2$

勾配降下法を使用してコストを下げ $\Theta$ の正確な値を取得します

{{% notice info %}}
正規方程式での値として $\theta$ は取得することができます。
$$ \theta = \left( X^TX \right)^{-1}X^Ty $$
gonumでの基本的な実装についてはこの[gist](https://gist.github.com/owulveryck/19a5ba9553ff8209b3b4227b5325041b#file-normal-go)を参照してください。
{{% /notice %}}


## gota(データフレーム)を使用してトレーニングセットを生成する

まずトレーニングデータを生成しましょう。データフレームを使用してスムーズに行います。

{{% notice info %}}
データフレームの使用方法やその他の情報については[howto](/how-to/dataframe/)を参照
{{% /notice %}}


```go
func getXYMat() (*mat.Dense, *mat.Dense) {
        f, err := os.Open("iris.csv")
        if err != nil {
                log.Fatal(err)
        }
        defer f.Close()
        df := dataframe.ReadCSV(f)
        xDF := df.Drop("species")

        toValue := func(s series.Series) series.Series {
                records := s.Records()
                floats := make([]float64, len(records))
                for i, r := range records {
                        switch r {
                        case "setosa":
                                floats[i] = 1
                        case "virginica":
                                floats[i] = 2
                        case "versicolor":
                                floats[i] = 3
                        default:
                                log.Fatalf("unknown iris: %v\n", r)
                        }
                }
                return series.Floats(floats)
        }

        yDF := df.Select("species").Capply(toValue)
        numRows, _ := xDF.Dims()
        xDF = xDF.Mutate(series.New(one(numRows), series.Float, "bias"))
        fmt.Println(xDF.Describe())
        fmt.Println(yDF.Describe())

        return mat.DenseCopyOf(&matrix{xDF}), mat.DenseCopyOf(&matrix{yDF})
}
```

Gorgoniaで使用できる2つの行列を返します。

### 式グラフを作成する

方程式 $X\cdot\Theta$ は [ExprGraph](/reference/exprgraph) として表されます:

```go
func getXY() (*tensor.Dense, *tensor.Dense) {
	x, y := getXYMat()

	xT := tensor.FromMat64(x)
	yT := tensor.FromMat64(y)
	// Get rid of the last dimension to create a vector
	s := yT.Shape()
	yT.Reshape(s[0])
	return xT, yT
}

func main() {
	xT, yT := getXY()
	g := gorgonia.NewGraph()
	x := gorgonia.NodeFromAny(g, xT, gorgonia.WithName("x"))
	y := gorgonia.NodeFromAny(g, yT, gorgonia.WithName("y"))
	theta := gorgonia.NewVector(
		g,
		gorgonia.Float64,
		gorgonia.WithName("theta"),
		gorgonia.WithShape(xT.Shape()[1]),
		gorgonia.WithInit(gorgonia.Uniform(0, 1)))

	pred := must(gorgonia.Mul(x, theta))
    // Saving the value for later use
    var predicted gorgonia.Value
    gorgonia.Read(pred, &predicted)
```

{{% notice info %}}
Gorgoniaは高度に最適化されています。良いパフォーマンスを得る為にポインターとメモリを頻繁に使用しています。
したがって実行時(実行プロセス中)に`*Node`の`Value()`メソッドを呼び出すと誤った結果になる可能性があります。
もし実行時(例えば学習段階で)に`Value`に格納されている*Nodeの特定の値にアクセスする必要がある場合はその参照を保持する必要があります。
これが`Read`メソッドを使用している理由です。
`predicted`は $X\cdot\Theta$ の結果の値を常に格納しています。
{{% /notice %}}

## 勾配計算の準備

Gorgoniaの[象徴的な微分](/how-to/differentiation)機能を使います。

まずコスト関数を作成し [solver](/about/solver) を使用して勾配降下を実行しコストを下げます。

### コストを保持するノードの作成

コスト($cost = \dfrac{1}{m} \sum_{i=1}^m(X^{(i)}\cdot\Theta-Y^{(i)})^2$) を追加することにより [exprgraph](/reference/exprgraph)を補完します。

```go
squaredError := must(gorgonia.Square(must(gorgonia.Sub(pred, y))))
cost := must(gorgonia.Mean(squaredError))
```

このコストを下げたいので $\Theta$ に関する勾配を評価します:

```go
if _, err := gorgonia.Grad(cost, theta); err != nil {
        log.Fatalf("Failed to backpropagate: %v", err)
}
```

### 勾配降下法

勾配降下のメカニズムを使用します。これは勾配を使用してパラメーター $\Theta$ を段階的に調節することを意味します。

基本的な勾配降下はGorgoniaの[Vanilla Solver](https://godoc.org/gorgonia.org/gorgonia#VanillaSolver)によって実装されています。
学習率 $\gamma$ を0.001に設定します。

```go
solver := gorgonia.NewVanillaSolver(gorgonia.WithLearnRate(0.001))
```

そして各ステップで勾配に感謝しつつsolverに $ \ Theta$ パラメーターを更新するように依頼します。
したがってイテレーションごとにsolverに渡す変数 `update` を設定します。

{{% notice info %}}
勾配降下はこの方程式に従って各ステップで `[]gorgonia.ValueGrad` に渡されるすべての値を更新します。
${\displaystyle x^{(k+1)}=x^{(k)}-\gamma \nabla f\left(x^{(k)}\right)}$
solverは[`Nodes`](/reference/node)ではなく[`Values`](/reference/value)で動作することを理解する事が重要です。
ただし物事を簡単にする為にValueGradは`*Node`構造によって実現される interface{} になっています。
{{% /notice %}}

この場合 $\Theta$ を最適化し次のようにsolverに値を更新する様に依頼します。

${\displaystyle \Theta^{(k+1)}=\Theta^{(k)}-\gamma \nabla f\left(\Theta^{(k)}\right)}$

そのためには $\Theta$ を`Solver`の`Step`メソッドに渡す必要があります。

```go
update := []gorgonia.ValueGrad{theta}
// ...
if err = solver.Step(update); err != nil {
        log.Fatal(err)
}
```

#### The learning iterations

原理が分かりましたね。幾らかの勾配降下の魔法を起こし得る [vm](/reference/vm) を使用して計算を実行する必要があります。

[vm](/reference/vm) を作成してグラフを実行します(そして勾配計算を行います):

```go
machine := gorgonia.NewTapeMachine(g, gorgonia.BindDualValues(theta))
defer machine.Close()
```

{{% notice warning %}}
solverにパラメーター $\Theta$ についての勾配を更新するように依頼します。
そのためTapeMachineに $\Theta$ の値(言わば2次元の値)を保存するよう指示しなければなりません。
これは [BindDualValues](https://godoc.org/gorgonia.org/gorgonia#BindDualValues) 関数を使用して行います。
{{% /notice %}}

では各ステップでループを作成してグラフを実行しましょう; さぁ機械が学習します!

```go
iter := 1000000
var err error
for i := 0; i < iter; i++ {
        if err = machine.RunAll(); err != nil {
                fmt.Printf("Error during iteration: %v: %v\n", i, err)
                break
        }

        if err = solver.Step(model); err != nil {
                log.Fatal(err)
        }
        machine.Reset() // Reset is necessary in a loop like this
}
```

#### 幾らかの情報を取得

この呼び出しを使用して学習プロセスの情報をダンプできます

```go
fmt.Printf("theta: %2.2f  Iter: %v Cost: %2.3f Accuracy: %2.2f \r",
        theta.Value(),
        i,
        cost.Value(),
        accuracy(predicted.Data().([]float64), y.Value().Data().([]float64)))
```

`accuracy` は以下の様に定義しました:

```go
func accuracy(prediction, y []float64) float64 {
        var ok float64
        for i := 0; i < len(prediction); i++ {
                if math.Round(prediction[i]-y[i]) == 0 {
                        ok += 1.0
                }
        }
        return ok / float64(len(y))
}
```

これにより学習プロセス中には以下の様な行が表示されます:

```text
theta: [ 0.26  -0.41   0.44  -0.62   0.83]  Iter: 26075 Cost: 0.339 Accuracy: 0.61
```

### weightsの保存

訓練が完了したら予測を行えるように $\Theta$ の値を保存します:

```go
func save(value gorgonia.Value) error {
	f, err := os.Create("theta.bin")
	if err != nil {
		return err
	}
	defer f.Close()
	enc := gob.NewEncoder(f)
	err = enc.Encode(value)
	if err != nil {
		return err
	}
	return nil
}
```

## 推論を行う簡単なcliを作る

まずは訓練フェーズからパラメータを読み込んでみましょう：

```go
func main() {
        f, err := os.Open("theta.bin")
        if err != nil {
                log.Fatal(err)
        }
        defer f.Close()
        dec := gob.NewDecoder(f)
        var thetaT *tensor.Dense
        err = dec.Decode(&thetaT)
        if err != nil {
                log.Fatal(err)
        }
```

では前に行った様にモデル(exprgraph)を作成します:

{{% notice info %}}
実際のアプリケーションはおそらく別のパッケージでモデルを共有する事になるでしょう
{{% /notice %}}

```go
g := gorgonia.NewGraph()
theta := gorgonia.NodeFromAny(g, thetaT, gorgonia.WithName("theta"))
values := make([]float64, 5)
xT := tensor.New(tensor.WithBacking(values))
x := gorgonia.NodeFromAny(g, xT, gorgonia.WithName("x"))
y, err := gorgonia.Mul(x, theta)
```

そして標準入力から情報を取得するforループに入り計算を実行して結果を表示します:

```go
machine := gorgonia.NewTapeMachine(g)
values[4] = 1.0
for {
        values[0] = getInput("sepal length")
        values[1] = getInput("sepal widt")
        values[2] = getInput("petal length")
        values[3] = getInput("petal width")

        if err = machine.RunAll(); err != nil {
                log.Fatal(err)
        }
        switch math.Round(y.Value().Data().(float64)) {
        case 1:
                fmt.Println("It is probably a setosa")
        case 2:
                fmt.Println("It is probably a virginica")
        case 3:
                fmt.Println("It is probably a versicolor")
        default:
                fmt.Println("unknown iris")
        }
        machine.Reset()
}
```

以下は入力を得る為の便利関数です:

```go
func getInput(s string) float64 {
        reader := bufio.NewReader(os.Stdin)
        fmt.Printf("%v: ", s)
        text, _ := reader.ReadString('\n')
        text = strings.Replace(text, "\n", "", -1)

        input, err := strconv.ParseFloat(text, 64)
        if err != nil {
                log.Fatal(err)
        }
        return input
}
```

`go build` や `go run` を実行できます。そして _そう_ !
特徴を考慮して、あやめの種別を予測できる完全に自律的なcliになりました:

```text
$ go run main.go
sepal length: 4.4
sepal widt: 2.9
petal length: 1.4
petal width: 0.2
It is probably a setosa
sepal length: 5.9
sepal widt: 3.0
petal length: 5.1
petal width: 1.8
It is probably a virginica
```

# Conclusion

これは段階的な例です。
thetaの初期値を操作したりGorgoniaの中で物事がどの様に行われるのかを見る為にsolverを変更して試してみましょう。

全体のコードはGorgoniaプロジェクトの[example](https://github.com/gorgonia/gorgonia/tree/master/examples)で見つける事ができます。.

### ボーナス: 視覚的表現

gonum plotter ライブラリを使えばデータセットを可視化する事ができます。
これを実現する方法の簡単な例を次に示します:

![iris](/images/iris/iris.png)

```go
import (
    "gonum.org/v1/plot"
    "gonum.org/v1/plot/plotter"
    "gonum.org/v1/plot/plotutil"
    "gonum.org/v1/plot/vg"
    "gonum.org/v1/plot/vg/draw"
)

func plotData(x []float64, a []float64) []byte {
	p, err := plot.New()
	if err != nil {
		log.Fatal(err)
	}

	p.Title.Text = "sepal length & width"
	p.X.Label.Text = "length"
	p.Y.Label.Text = "width"
	p.Add(plotter.NewGrid())

	l := len(x) / len(a)
	for k := 1; k <= 3; k++ {
		data0 := make(plotter.XYs, 0)
		for i := 0; i < len(a); i++ {
			if k != int(a[i]) {
				continue
			}
			x1 := x[i*l+0] // sepal_length
			y1 := x[i*l+1] // sepal_width
			data0 = append(data0, plotter.XY{X: x1, Y: y1})
		}
		data, err := plotter.NewScatter(data0)
		if err != nil {
			log.Fatal(err)
		}
		data.GlyphStyle.Color = plotutil.Color(k - 1)
		data.Shape = &draw.PyramidGlyph{}
		p.Add(data)
		p.Legend.Add(fmt.Sprint(k), data)
	}

	w, err := p.WriterTo(4*vg.Inch, 4*vg.Inch, "png")
	if err != nil {
		panic(err)
	}
	var b bytes.Buffer
	writer := bufio.NewWriter(&b)
	w.WriteTo(writer)
	ioutil.WriteFile("out.png", b.Bytes(), 0644)
	return b.Bytes()
}
```
