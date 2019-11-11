---
title: "Simple Convolution Neural Net (MNIST)"
date: 2019-10-29T20:09:05+01:00
draft: false
weight: -98
---

## About

This a step by step tutorial to build and train a convolution neural network on the MNIST dataset.

The complete code can be found in the `examples` directory of the main gorgonia repository.

### The dataset

{{% notice info %}}
This part is about loading and printing the dataset. If you want to jump straight into the neural net, feel free to skip it and go to [The Convolution Neural Net part](#the-convolution-neural-net).
{{% /notice %}}

The training and testing sets can be downloaded from [Yann LeCun's MNIST website](http://yann.lecun.com/exdb/mnist/)

* [train-images-idx3-ubyte.gz](http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz):  training set images (9912422 bytes)
* [train-labels-idx1-ubyte.gz](http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz):  training set labels (28881 bytes)
* [t10k-images-idx3-ubyte.gz](http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz):   test set images (1648877 bytes)
* [t10k-labels-idx1-ubyte.gz](http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz):   test set labels (4542 bytes)

As explained on the website, those files holds multiple images or labels encoded in binary.
Every image/label starts with a magic number. The `encoding/binary` package of the standard library of Go make it easy to read those files.

##### The `mnist` package

As a commodity, Gorgonia has created a package `mnist` in the `examples` subdirectory. Its goal is to extract the information from the data and to create `tensors`.

The function [`readImageFile`](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/io.go#L50:6) creates an array of bytes
that represents all the images contained in the reader.

A similar [`readLabelFile`](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/io.go#L21) function extract the labels.

```go
// Image holds the pixel intensities of an image.
// 255 is foreground (black), 0 is background (white).
type RawImage []byte

// Label is a digit label in 0 to 9
type Label uint8

func readImageFile(r io.Reader, e error) (imgs []RawImage, err error)

func readLabelFile(r io.Reader, e error) (labels []Label, err error)
```

Then two functions takes care of the conversion from `RawImage` and `Label` into `tensor.Tensor`:

* [prepareX](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/mnist.go#L70)
* [prepareY](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/mnist.go#L99)

```go
func prepareX(M []RawImage, dt tensor.Dtype) (retVal tensor.Tensor)

func prepareY(N []Label, dt tensor.Dtype) (retVal tensor.Tensor)
```

The only exported function from the package is [`Load`](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/mnist.go#L24) that
reads the files `typ` from `loc` and returns tensors of a specific type (float32 or float64):

```go
// Load loads the mnist data into two tensors
//
// typ can be "train", "test"
//
// loc represents where the mnist files are held
func Load(typ, loc string, as tensor.Dtype) (inputs, targets tensor.Tensor, err error)
```

##### Testing the package

Now, let's create a simple main file to validate that the data are loaded.

This layout of test directory is expected:

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

Now let's write this simple Go file that will read both test and train data and display the resulting tensors:

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

Run the file:

```shell
$ go run main.go
test inputs: (10000, 784)
test data: (10000, 10)
train inputs: (60000, 784)
train data: (60000, 10)
```

We have 60000 pictures of $28x28=784$ pixels, 60000 corresponding labels "one-hot" encoded, and 10000 test files in the test set.

#### Image representation

Let's draw a picture of the first element:

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
We are using the `native` package to easily access the underlying []float64 backend. This operation does not generate new data.
{{% /notice %}}

This produce this png file:
![5](/images/mnist_5.png?width=10pc)

and the corresponding label vector that indicates that it is a '5':
```shell
$ go run main.go
[0.1 0.1 0.1 0.1 0.1 0.9 0.1 0.1 0.1 0.1]
```

## The convolution neural net
