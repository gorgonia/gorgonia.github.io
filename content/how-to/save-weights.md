---
title: "Save Weights"
date: 2019-10-29T20:07:16+01:00
draft: false
---

## Goal

The goal of this howto is to describe a way to save the [values](/reference/value) of the nodes and to restore them.

## Implementation

The best thing you can do right now is to save the value of the corresponding nodes and restore them.

The tensors are fulfilling the `GobEncode` and `GobDecode` interface and this is the best option. You can also save the backend as a slice of elements but this is a little bit trickier.

Here is a sample code to do so (it is not optimized at all, feel free to amend it):

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

which gives:

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

