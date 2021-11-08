---
title: "Create a tensor from a Dataframe (gota)"
date: 2019-10-30T22:57:09+01:00
draft: false
---

This howto explains how to create a tensor from a dataframe using [gota](https://github.com/go-gota/gota)
The goal is to read a csv file and create a [`*tensor.Dense`](https://godoc.org/gorgonia.org/tensor#Dense) with shape (2,2).

## Create the dataframe from a csv file

Consider a csv file with the following content:

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
This is extract from the [Iris flower data set](https://en.wikipedia.org/wiki/Iris_flower_data_set).
A copy of the dataset can be found [here](https://gist.github.com/owulveryck/19a5ba9553ff8209b3b4227b5325041b#file-iris-csv)
{{% /notice %}}

We want to create a tensor with all values but the species.

## Create the dataframe with gota.

gota's dataframe package has a function [`ReadCSV`](https://godoc.org/github.com/kniren/gota/dataframe#ReadCSV) that takes an io.Reader as argument.

```go
f, err := os.Open("iris.csv")
if err != nil {
    log.Fatal(err)
}
defer f.Close()
df := dataframe.ReadCSV(f)
```

`df` is a [`DataFrame`](https://godoc.org/github.com/kniren/gota/dataframe#DataFrame) that contains all the data present in the file.

{{% notice info %}}
gota uses the first line of the CSV to reference the columns in the dataframe
{{% /notice %}}

Let's remove the species column:

```go
xDF := df.Drop("species")
```
## Convert the dataframe into a matrix

To make things easier, we will convert our dataframe into a `Matrix` as defined by gonum (see [the matrix godoc](https://godoc.org/gonum.org/v1/gonum/mat#Matrix)).
`matrix` is an interface. gota's dataframe does not fulfill the `Matrix` interface. As described into gota's documentation,
we create a wrapper around DataFrame to fulfil the `Matrix` interface.

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
## Create the tensor

Now we can create a `*Dense` tensor thanks to the function [`tensor.FromMat64`](https://godoc.org/gorgonia.org/tensor#FromMat64)
by wrapping the dataframe into the `matrix` structure.

```go
xT := tensor.FromMat64(mat.DenseCopyOf(&matrix{xDF}))
```
