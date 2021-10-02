---
title: "Hello World"
date: 2019-10-29T17:54:31+01:00
draft: false
weight: -100
---

Ceci est un tutoriel étape par étape pour réaliser des oprations très simples avec Gorgonia. 

Notre objectif est d'utiliser toute la mécanique de Gorgonia pour réaliser une opération très simple :

$ f(x,y) = x + y $

avec  `x = 2` et `y = 5`

## Comment ça marche ?

L'équation `x + y = z` peut être représentée graphiquement :

{{<mermaid align="left">}}
graph LR;
    z[z] --> add(Round edge)
    add[+] --> x
    add[+] --> y
{{< /mermaid >}}

Pour en obtenir le résultat, nous avons besoin de 4 étapes :

* Réaliser un [graphique](/reference/exprgraph) similaire avec Gorgonia
* Attribuer des [valeurs](/reference/value) aux [points](/reference/node) `x` et `y` 
* Instancier un graphique sur un [gorgonia vm](/reference/vm)
* Extraire la [valeur](/reference/value) du point `z`
    *

### Créer un graphique

Créer une [expression graphique](/reference/exprgraph) vide avec cette méthode :

```go
g := gorgonia.NewGraph()
```

### Créer les points

Nous allons créer des [points](/reference/node) et les associer à l'ExprGraph.

```go
var x, y, z *gorgonia.Node
```

#### Créer l'espace réservé
`x` et `y` sont des variables scalaires, nous pouvons créer le point correspond de la manière suivante:

```go
x = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("x"))
y = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("y"))
```

{{% notice note %}}
les fonctions prennent pour argument l'Exprgraph ; le point ainsi généré est automatiquement associé au graphique.
{{% /notice %}}


Il faut à présent créer l'opérateur d'addition ; cet opérateur nécessite deux [points](/reference/node) et renvoie un nouveau point 'z':

```go
if z, err = gorgonia.Add(x, y); err != nil {
        log.Fatal(err)
}
```

{{% notice info %}}
le point `z` renvoyé est ajouté au graphique même si `g` n'a pas été transmis à `z` ou à la fonction `Add` (addition).
{{% /notice %}}


### Définir les valeurs

Nous avons une ExprGraph qui représente l'équation `z = x + y`. À présent, il est temps d'attribuer des valeurs à `x` et `y`.

Nous utilisons la fonction [`Let`](https://godoc.org/gorgonia.org/gorgonia#Let) :

```go
gorgonia.Let(x, 2.0)
gorgonia.Let(y, 2.5)
```

### Activer le graphique

Pour lancer le graphique et calculer le résultat, il faut instancier une [VM](/reference/vm).
Utilisons la [TapeMachine](/reference/vm/tapemachine):

```go
machine := gorgonia.NewTapeMachine(g)
defer machine.Close()
```

et lancer le graphique :

```go
if err = machine.RunAll(); err != nil {
        log.Fatal(err)
}
```

{{% notice warning %}}
s'il faut lancer le graphique une deuxième fois, il faut utiliser le `Reset()` du `vm` :
` machine.Reset() `
{{% /notice %}}

### Obtenir le résultat

À présent, le point `z` contient le résultat.
Nous pouvons extraire sa [valeur](/reference/value) en utilisant `Value()` :

```go
fmt.Printf("%v", z.Value())
```

{{% notice note %}}
nous pourrions aussi accéder à la valeur cachée "Go" en faisant un appel à `z.Value().Data()` ce qui renverrait un `interface{}` contenant un `float64` dans le cas présent
{{% /notice %}}

# Résultat final

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
