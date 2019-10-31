---
title: "Créer un tensor depuis un Dataframe (gota)"
date: 2019-10-30T22:57:09+01:00
draft: false
---

Cet article explique comment créer un tenseur depuis un dataframe en utilisant le package [gota](https://github.com/go-gota/gota).

Le but est de lire un fichier csv et de créer un objet [`*tensor.Dense`](https://godoc.org/gorgonia.org/tensor#Dense) de forme (2,2).

## Creation du dataframe depuis le fichier csv

Considerons un ficier csv avec le contenu suivant:

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
Ceci est un extrait du [Iris flower data set](https://en.wikipedia.org/wiki/Iris_flower_data_set).
Une copie du dataset peut être téléchargée [ici](https://gist.github.com/owulveryck/19a5ba9553ff8209b3b4227b5325041b#file-iris-csv)
{{% /notice %}}

Nous voulons créer un tenseur qui contient toutes les valeurs *sauf*  la colonne "species".

## Creation du dataframe avec gota

le package dataframe de gota propose une fonction [`ReadCSV`](https://godoc.org/github.com/kniren/gota/dataframe#ReadCSV)
qui prend pour argument un io.Reader.

```go
f, err := os.Open("iris.csv")
if err != nil {
    log.Fatal(err)
}
defer f.Close()
df := dataframe.ReadCSV(f)
```

`df` est un [`DataFrame`](https://godoc.org/github.com/kniren/gota/dataframe#DataFrame) qui remferme toutes les données présentes dans le fichier.

{{% notice info %}}
gota utilise la première ligne du fichier csv pour référencer les colonnes dans le dataframe
{{% /notice %}}

Supprimons à présent la colonne species du dataframe:

```go
xDF := df.Drop("species")
```
## Conversion du dataframe vers une matrice

Pour simplifier les choses, nous allons convertir le dataframe en une `Matrix` telle que définie dans le package gonum
(cf [la godoc de Matrix](https://godoc.org/gonum.org/v1/gonum/mat#Matrix)).
`Matrix` est une interface. Cependant, la structure `Dataframe` de gota ne remplit pas le contrat d'interface `Matrix`
Nous allons donc encapsuler l'objet dans une structure de plus haut niveau et nous allons
implémenter les fonctions nécessaire au contrat d'interface telle que décrit dans la documentation de gota:

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
## Creation du tenseur

Nous pouvons à présent créer un tenseur `*Dense` grâce à la fonction [`tensor.FromMat64`](https://godoc.org/gorgonia.org/tensor#FromMat64)
du package tensor en encapsulant le dataframe dans la structure `matrix`.

```go
xT := tensor.FromMat64(mat.DenseCopyOf(&matrix{xDF}))
```
