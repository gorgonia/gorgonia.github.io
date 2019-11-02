+++
title = "Premiers pas"
description = "Démarrer rapidement avec Gorgonia"
date = 2019-10-29T17:42:44+01:00
weight = -10
chapter = true
pre = "<b>X. </b>"
+++

## Obtenir Gorgonia

Gorgonia est go-gettable et supporte les go-modules.
Pour récupérer la bibliothèque ainsi que ses dépendances, il suffit d'exécuter:

```bash
$ go get gorgonia.org/gorgonia
```

## Premier programme pour faire un calcul simple

Créer ce programme simple dans un fichier `main.go` pour vérifier que tout est correctement installé:

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

Exécuter le programme devrait afficher le résultat `4.5`.

Pour plus d'explications sur le fonctionnement, veuillez consulter le tutoriel [Hello World](/tutorials/hello-world).

