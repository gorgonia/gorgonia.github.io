---
title: "Example"
date: 2018-09-24T21:32:15+02:00
draft: false
weight: 160
alwaysopen: true
---

So how do we use CUDA? Say we've got a file, `main.go`:

```go
import (
	"fmt"
	"log"
	"runtime"

	T "gorgonia.org/gorgonia"
	"gorgonia.org/tensor"
)

func main() {
	g := T.NewGraph()
	x := T.NewMatrix(g, T.Float32, T.WithName("x"), T.WithShape(100, 100))
	y := T.NewMatrix(g, T.Float32, T.WithName("y"), T.WithShape(100, 100))
	xpy := T.Must(T.Add(x, y))
	xpy2 := T.Must(T.Tanh(xpy))

	m := T.NewTapeMachine(g, T.UseCudaFor("tanh"))

	T.Let(x, tensor.New(tensor.WithShape(100, 100), tensor.WithBacking(tensor.Random(tensor.Float32, 100*100))))
	T.Let(y, tensor.New(tensor.WithShape(100, 100), tensor.WithBacking(tensor.Random(tensor.Float32, 100*100))))

	runtime.LockOSThread()
	for i := 0; i < 1000; i++ {
		if err := m.RunAll(); err != nil {
			log.Fatalf("iteration: %d. Err: %v", i, err)
		}
	}
	runtime.UnlockOSThread()

	fmt.Printf("%1.1f", xpy2.Value())
}

```

If this is run normally:

```
go run main.go
```

CUDA will not be used.

If the program is to be run using CUDA, then this must be invoked:

```
go run -tags='cuda'
```

And even so, only the `tanh` function uses CUDA. 

## Rationale

The main reasons for having such complicated requirements for using CUDA is quite simply performance related. As Dave Cheney famously wrote, [cgo is not Go](https://dave.cheney.net/2016/01/18/cgo-is-not-go). To use CUDA, cgo is unfortunately required. And to use cgo, plenty of tradeoffs need to be made.

Therefore the solution was to nestle the CUDA related code in a build tag, `cuda`. That way by default no cgo is used (well, kind-of - you could still use `cblas` or `blase`). 

The reason for requiring [CUDA toolkit 8.0](https://developer.nvidia.com/cuda-toolkit) is because there are many CUDA [Compute Capabilities](http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#compute-capabilities), and generating code for them all would yield a huge binary for no real good reason. Rather, users are encouraged to compile for their specific Compute Capabilities.

Lastly, the reason for requiring an explicit specification to use CUDA for which ops is due to the cost of cgo calls. Additional work is being done currently to implement batched cgo calls,  but until that is done, the solution is keyhole "upgrade" of certain ops


