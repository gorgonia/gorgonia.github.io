---
title: "Sauver les matrices de poids"
date: 2019-10-29T20:07:16+01:00
draft: false
---

## But

Le but de cet article est de décrire la façon de sauvegarder les valeurs des noeuds [values](/reference/value) et de les restaurer.

## Implementation

La meilleure chose à faire de suite est de de sauvegarder la valeur des noeuds correspondants et de les restaurer.

Les tenseurs remplissent les contrats d'interface `GobEncode` et `GobDecode`, ce qui représente la meilleure option. On peut aussi sauvegarder le tableau d'éléments sous-jascent au tenseur, mais c'est un peu plus complexe.

Voici un simple code à réaliser de cette façon (il n'est pas du tout optimisé, n'hésitez pas à le modifier):

```go
package main

import (
        "encoding/gob"
        "fmt"
        "log"
        "os"

        "gorgonia.org/gorgonia"
        "gorgonia.org/tensor"
)

var (
        backup = "/tmp/example_gorgonia"
)

func main() {
        g := gorgonia.NewGraph()

        var x, y, z *gorgonia.Node
        var err error

        // Create the graph
        x = gorgonia.NewTensor(g,
                gorgonia.Float64,
                2,
                gorgonia.WithShape(2, 2),
                gorgonia.WithName("x"))
        y = gorgonia.NewTensor(g,
                gorgonia.Float64,
                2,
                gorgonia.WithShape(2, 2),
                gorgonia.WithName("y"))
        if z, err = gorgonia.Add(x, y); err != nil {
                log.Fatal(err)
        }

        // Init variables
        xT, yT, err := readFromBackup()
        if err != nil {
                log.Println("cannot read backup, doing init", err)
                xT = tensor.NewDense(gorgonia.Float64, []int{2, 2}, tensor.WithBacking([]float64{0, 1, 2, 3}))
                yT = tensor.NewDense(gorgonia.Float64, []int{2, 2}, tensor.WithBacking([]float64{0, 1, 2, 3}))
        }
        err = gorgonia.Let(x, xT)
        if err != nil {
                log.Fatal(err)
        }
        err = gorgonia.Let(y, yT)
        if err != nil {
                log.Fatal(err)
        }

        // create a VM to run the program on
        machine := gorgonia.NewTapeMachine(g)
        defer machine.Close()

        if err = machine.RunAll(); err != nil {
                log.Fatal(err)
        }

        fmt.Printf("%v", z.Value())
        err = save([]*gorgonia.Node{x, y})
        if err != nil {
                log.Fatal(err)
        }
}

func readFromBackup() (tensor.Tensor, tensor.Tensor, error) {
        f, err := os.Open(backup)
        if err != nil {
                return nil, nil, err
        }
        defer f.Close()
        dec := gob.NewDecoder(f)
        var xT, yT *tensor.Dense
        log.Println("decoding xT")
        err = dec.Decode(&xT)
        if err != nil {
                return nil, nil, err
        }
        log.Println("decoding yT")
        err = dec.Decode(&yT)
        if err != nil {
                return nil, nil, err
        }
        return xT, yT, nil
}

func save(nodes []*gorgonia.Node) error {
        f, err := os.Create(backup)
        if err != nil {
                return err
        }
        defer f.Close()
        enc := gob.NewEncoder(f)
        for _, node := range nodes {
                err := enc.Encode(node.Value())
                if err != nil {
                        return err
                }
        }
        return nil
}
```

Qui donne:

```text
$  go run main.go
2019/10/28 08:07:26 cannot read backup, doing init open /tmp/example_gorgonia: no such file or directory
⎡0  2⎤
⎣4  6⎦
$  go run main.go
2019/10/28 08:07:29 decoding xT
2019/10/28 08:07:29 decoding yT
⎡0  2⎤
⎣4  6⎦
```
