---
title: "データフレームからテンソルを作成 (gota)"
date: 2019-10-30T22:57:09+01:00
draft: false
---

このハウツーでは、[gota](https://github.com/go-gota/gota)を使用してデータフレームからテンソルを作成する方法を説明します。
The goal is to read a csv file and create a [`*tensor.Dense`](https://godoc.org/gorgonia.org/tensor#Dense) with shape (2,2).
ゴールは、csvファイルを読み取り、(2,2) のシェイプの[`* tensor.Dense`](https://godoc.org/gorgonia.org/tensor#Dense)を作成することです。

## csvファイルからデータフレームを作成する

以下のコンテンツのcsvファイルを考えます:

```text
sepal_length,sepal_width,petal_length,petal_width,species
5.1         ,3.5        ,1.4         ,0.2        ,setosa
4.9         ,3.0        ,1.4         ,0.2        ,setosa
4.7         ,3.2        ,1.3         ,0.2        ,setosa
4.6         ,3.1        ,1.5         ,0.2        ,setosa
5.0         ,3.6        ,1.4         ,0.2        ,setosa
...
```

{{% notice info %}}
これは[Iris flower data set](https://en.wikipedia.org/wiki/Iris_flower_data_set)からの抜粋です。
データセットのコピーは[ここ](https://gist.github.com/owulveryck/19a5ba9553ff8209b3b4227b5325041b#file-iris-csv)から見つける事ができます。
{{% /notice %}}

種別以外のすべての値を含むテンソルを作成します。

## gotaを使用してデータフレームを作成する

gotaのデータフレームパッケージにはio.Readerを引数として取る関数[`ReadCSV`](https://godoc.org/github.com/kniren/gota/dataframe#ReadCSV)があります。

```go
f, err := os.Open("iris.csv")
if err != nil {
    log.Fatal(err)
}
defer f.Close()
df := dataframe.ReadCSV(f)
```

`df`がファイルに存在する全てのデータが含まれる[`DataFrame`](https://godoc.org/github.com/kniren/gota/dataframe#DataFrame)です。

{{% notice info %}}
gotaはデータフレームの列を参照する為にCSVの最初の行を使用します。
{{% /notice %}}

種別(species)カラムを削除しましょう:

```go
xDF := df.Drop("species")
```
## データフレームを行列に変換する

物事を簡単にするために、データフレームをgonumで定義されている`Matrix`に変換します([matrixのgodoc](https://godoc.org/gonum.org/v1/gonum/mat#Matrix)を参照)。
`matrix`はインタフェースです。gotaのデータフレームは`Matrix`インターフェイスを満たしません。gotaのドキュメントに記載されているように、
`Matrix`インターフェイスを満たすために、データフレームのラッパーを作成します。

```go
type matrix struct {
	dataframe.DataFrame
}

func (m matrix) At(i, j int) float64 {
	return m.Elem(i, j).Float()
}

func (m matrix) T() mat.Matrix {
	return mat.Transpose{Matrix: m}
}
```
## テンソルを作る

データフレームを`matrix`構造体の中にラッピングすると関数[`tensor.FromMat64`](https://godoc.org/gorgonia.org/tensor#FromMat64)のおかげで`*Dense`テンソルを作成できるようになります。

```go
xT := tensor.FromMat64(mat.DenseCopyOf(&matrix{xDF}))
```
