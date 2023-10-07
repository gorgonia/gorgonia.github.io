---
title: "Simple Convolution Neural Net (MNIST)"
date: 2019-10-29T20:09:05+01:00
draft: false
weight: -98
---

## About

This a step by step tutorial to build and train a convolution neural network on the MNIST dataset.

The complete code can be found in the `examples` directory of the principal Gorgonia repository.
The goal of this tutorial is to explain in detail the code. Further explanation of how it works can be found in the
book [Go Machine Learning Projects](https://www.packtpub.com/eu/big-data-and-business-intelligence/go-machine-learning-projects)

### The dataset

{{% notice info %}}
This part is about loading and printing the dataset. If you want to jump straight into the neural net, feel free to skip it and go to [The Convolution Neural Net part](#the-convolution-neural-net).
{{% /notice %}}

The training and testing sets can be downloaded from [Yann LeCun's MNIST website](http://yann.lecun.com/exdb/mnist/)

* [train-images-idx3-ubyte.gz](http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz):  training set images (9912422 bytes)
* [train-labels-idx1-ubyte.gz](http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz):  training set labels (28881 bytes)
* [t10k-images-idx3-ubyte.gz](http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz):   test set images (1648877 bytes)
* [t10k-labels-idx1-ubyte.gz](http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz):   test set labels (4542 bytes)

As explained on the website, those files hold multiple images or labels encoded in binary.
Every image/label starts with a magic number. The `encoding/binary` package of the standard library of Go makes it easy to read those files.

##### The `mnist` package

As a commodity, Gorgonia has created a package `mnist` in the `examples` subdirectory. Its goal is to extract the information from the data and to create `tensors`.

The function [`readImageFile`](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/io.go#L50:6) creates an array of bytes
that represents all the images contained in the reader.

A similar [`readLabelFile`](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/mnist/io.go#L21) function extracts the labels.

```go
// Image holds the pixel intensities of an image.
// 255 is foreground (black), 0 is background (white).
type RawImage []byte

// Label is a digit label in 0 to 9
type Label uint8

func readImageFile(r io.Reader, e error) (imgs []RawImage, err error)

func readLabelFile(r io.Reader, e error) (labels []Label, err error)
```

Then two functions take care of the conversion from `RawImage` and `Label` into `tensor.Tensor`:

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

This layout of the test directory is expected:

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

We have 60000 pictures of $28\times28=784$ pixels, 60000 corresponding labels "one-hot" encoded, and 10000 test files in the test set.

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
We are using the `native` package to access the underlying `[]float64` backend easily. This operation does not generate new data.
{{% /notice %}}

This produce this png file:
![5](/images/mnist_5.png?width=10pc)

and the corresponding label vector that indicates that it is a `5`:
```shell
$ go run main.go
[0.1 0.1 0.1 0.1 0.1 0.9 0.1 0.1 0.1 0.1]
```

## The convolution neural net

We are building a 5 layers convolution network. $x_0$ is the input image, as defined previously.

The first three layers $i$ are defined this way:

$ x\_{i+1} = Dropout(Maxpool(ReLU(Convolution(x_i,W_i)))) $

with $i$ in range 0-2

The fourth layer is basically a dropout layer to randomly zeroed some activations:

$ x\_{4} = Dropout(ReLU(x_3\cdot W_3)) $

The final layer applies a simple multiplication and a softmax in order to get an output vector (this vector represent the label predicted):

$ y = softmax(x_4\cdot W_4)$

### Variables of the network

The learnables parameters are $W_0,W_1,W_2,W_3,W_4$. Other variables of the network are the dropout probabilities $d_0,d_1,d_2,d_3$.

Let's create a structure to hold the variables and the output node of the model:

```go
type convnet struct {
	g                  *gorgonia.ExprGraph
	w0, w1, w2, w3, w4 *gorgonia.Node // weights. the number at the back indicates which layer it's used for
	d0, d1, d2, d3     float64        // dropout probabilities

	out *gorgonia.Node
}
```

#### Definition of the learnables

The convolution is using a standard $3\times3$ kernel, and 32 filters.
As the images of the dataset are in black and white, we are using only one channel. This leads to the following definition of the weights:

* $W_0 \in \mathbb{R}^{32\times 1\times3\times3}$ for the first convolution operator
* $W_1 \in \mathbb{R}^{64\times 32\times3\times3}$ for the second convolution operator
* $W_2 \in \mathbb{R}^{128\times 64\times3\times3}$ for the third convolution operator
* $W_3 \in \mathbb{R}^{128*3*3\times 625}$ we are preparing the final matrix multiplication, so we need to reshape the 4D input into a matrix (128x3x3). 625 is an arbitrary number.
* $W_4 \in \mathbb{R}^{625\times 10}$ to reduce the output size to a single vector of 10 entries

{{% notice note %}}
In NN optimization, it's commonly known that if you have a middle layer that is smaller than the output and input,
you are "squeezing" useless information.
Input is 784; then next layer should be smaller. 625 is a good looking number.
{{% /notice %}}

The dropout probabilities are fixed to idiomatic values:

* $d_0=0.2$
* $d_1=0.2$
* $d_2=0.2$
* $d_3=0.55$

We can now create the structure with the placeholder for the learnables:

```go
// Note: gorgonia is abbreviated G in this example for clarity
func newConvNet(g *G.ExprGraph) *convnet {
	w0 := G.NewTensor(g, dt, 4, G.WithShape(32, 1, 3, 3), G.WithName("w0"), G.WithInit(G.GlorotN(1.0)))
	w1 := G.NewTensor(g, dt, 4, G.WithShape(64, 32, 3, 3), G.WithName("w1"), G.WithInit(G.GlorotN(1.0)))
	w2 := G.NewTensor(g, dt, 4, G.WithShape(128, 64, 3, 3), G.WithName("w2"), G.WithInit(G.GlorotN(1.0)))
	w3 := G.NewMatrix(g, dt, G.WithShape(128*3*3, 625), G.WithName("w3"), G.WithInit(G.GlorotN(1.0)))
	w4 := G.NewMatrix(g, dt, G.WithShape(625, 10), G.WithName("w4"), G.WithInit(G.GlorotN(1.0)))
	return &convnet{
		g:  g,
		w0: w0,
		w1: w1,
		w2: w2,
		w3: w3,
		w4: w4,

		d0: 0.2,
		d1: 0.2,
		d2: 0.2,
		d3: 0.55,
	}
}
```

{{% notice info %}}
The learnables are initialized with some values normally sampled using Glorot et al.'s algorithm. For more info: [All you need is a good init](https://arxiv.org/pdf/1511.06422.pdf) on Arxiv.
{{% /notice %}}

### Definition of the network

It is now possible to define the network by adding a method to the convnet structure:

_Note_: error checking are, once again, removed for clarity

```go
// This function is particularly verbose for educational reasons. In reality, you'd wrap up the layers within a layer struct type and perform per-layer activations
func (m *convnet) fwd(x *gorgonia.Node) (err error) {
	var c0, c1, c2, fc *gorgonia.Node
	var a0, a1, a2, a3 *gorgonia.Node
	var p0, p1, p2 *gorgonia.Node
	var l0, l1, l2, l3 *gorgonia.Node

	// LAYER 0
	// here we convolve with stride = (1, 1) and padding = (1, 1),
	// which is your bog standard convolution for convnet
	c0, _ = gorgonia.Conv2d(x, m.w0, tensor.Shape{3, 3}, []int{1, 1}, []int{1, 1}, []int{1, 1})
	a0, _ = gorgonia.Rectify(c0)
	p0, _ = gorgonia.MaxPool2D(a0, tensor.Shape{2, 2}, []int{0, 0}, []int{2, 2})
	l0, _ = gorgonia.Dropout(p0, m.d0)

	// Layer 1
	c1, _ = gorgonia.Conv2d(l0, m.w1, tensor.Shape{3, 3}, []int{1, 1}, []int{1, 1}, []int{1, 1})
	a1, _ = gorgonia.Rectify(c1)
	p1, _ = gorgonia.MaxPool2D(a1, tensor.Shape{2, 2}, []int{0, 0}, []int{2, 2})
	l1, _ = gorgonia.Dropout(p1, m.d1)

	// Layer 2
	c2, _ = gorgonia.Conv2d(l1, m.w2, tensor.Shape{3, 3}, []int{1, 1}, []int{1, 1}, []int{1, 1})
	a2, _ = gorgonia.Rectify(c2)
	p2, _ = gorgonia.MaxPool2D(a2, tensor.Shape{2, 2}, []int{0, 0}, []int{2, 2})

	var r2 *gorgonia.Node
	b, c, h, w := p2.Shape()[0], p2.Shape()[1], p2.Shape()[2], p2.Shape()[3]
	r2, _ = gorgonia.Reshape(p2, tensor.Shape{b, c * h * w})
	l2, _ = gorgonia.Dropout(r2, m.d2)

	// Layer 3
	fc, _ = gorgonia.Mul(l2, m.w3)
	a3, _ = gorgonia.Rectify(fc)
	l3, _ = gorgonia.Dropout(a3, m.d3)

	// output decode
	var out *gorgonia.Node
	out, _ = gorgonia.Mul(l3, m.w4)
	m.out, _ = gorgonia.SoftMax(out)
	return
}
```

### Training the neural network

The input we got from the training set are a matrix $numExample \times 784$. The convolution operator expects a 4D tensor BCHW. The first thing we need to do is to reshape the input:

```go
numExamples := inputs.Shape()[0]
inputs.Reshape(numExamples, 1, 28, 28)
```

We will train the network by batch. The batch size is a variable (`bs`). We create two new tensors that will hold the values and labels of the current batch.
Then we instantiate the neural net:

```go
g := gorgonia.NewGraph()
x := gorgonia.NewTensor(g, dt, 4, gorgonia.WithShape(bs, 1, 28, 28), gorgonia.WithName("x"))
y := gorgonia.NewMatrix(g, dt, gorgonia.WithShape(bs, 10), gorgonia.WithName("y"))
m := newConvNet(g)
m.fwd(x)
```
#### Cost function

We define a cost function we want to minimize based on a simple cross-entropy by multiplying the expected output element-wise and then averaging it:

$cost = -\dfrac{1}{bs} \sum_{i=1}^{bs}(pred^{(i)}\cdot y^{(i)})$

```go
losses := gorgonia.Must(gorgonia.HadamardProd(m.out, y))
cost := gorgonia.Must(gorgonia.Mean(losses))
cost = gorgonia.Must(gorgonia.Neg(cost))
```

and keep a pointer on the value of the cost for later:

```go
var costVal gorgonia.Value
gorgonia.Read(cost, &costVal)
```

Then we will perform symbolic backpropagation with:

```go
gorgonia.Grad(cost, m.learnables()...)
```

Learnables is defined like this:
```go
func (m *convnet) learnables() gorgonia.Nodes {
    return gorgonia.Nodes{m.w0, m.w1, m.w2, m.w3, m.w4}
}
```

##### The training loop

First we need a [vm](/reference/vm) to run the graph, and a solver to adapt the learnables at each step. We also need to bind the dual values of the learnables to
actually store the values of the gradient for the solver to work.

```go
vm := gorgonia.NewTapeMachine(g, gorgonia.BindDualValues(m.learnables()...))
solver := gorgonia.NewRMSPropSolver(gorgonia.WithBatchSize(float64(bs)))
defer vm.Close()
```

We define a number of batches that compose an epoch regarding the batchsize:

```go
batches := numExamples / bs
```

and then create the training loops:

```go
for i := 0; i < *epochs; i++ {
    for b := 0; b < batches; b++ {
        // ...
    }
}
```

##### Inside the loop:
Now we need to extract values from the input tensor (which is $60000 \times 784$) for each batch.
Each input is ($bs\times 784$). First batch will hold values from 0 to bs-1, second bs to 2*bs-1, and so on. Then the tensor is reshaped into a 4D tensor:

```go
var xVal, yVal tensor.Tensor
xVal, _ = inputs.Slice(sli{start, end})

yVal, _ = targets.Slice(sli{start, end})

xVal.(*tensor.Dense).Reshape(bs, 1, 28, 28)
```

Then we assign the values to the graph:

```go
gorgonia.Let(x, xVal)
gorgonia.Let(y, yVal)
```
and run the VM and the solver to adapt the weights

```go
vm.RunAll()
solver.Step(gorgonia.NodesToValueGrads(m.learnables()))
vm.Reset()
```

That's it, you now have a neural network that can learn.

### Conclusion

Running the code is relatively slow due to the massive amount of data involved, but it learns.
You can get the full code in the [Gorgonia's example directory](https://github.com/gorgonia/gorgonia/blob/e6bc7dd8951410b733bb85091d0e4506c25e6f70/examples/convnet/main.go#L1).

To save the weights, the user can create two methods of `load` and `save` as described in the [iris tutorial](/tutorials/iris).
Then it is let as an exercise to the reader to code a little utility to use this neural network.

Have fun!
