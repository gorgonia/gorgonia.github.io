---
title: "Multivariate linear regression on Iris Dataset"
date: 2019-10-31T14:53:37+01:00
draft: false
---

## About

We will use Gorgonia to create a linear regression model.

The goal is, to predict the species of the Iris flowers given the characteristics:

* sepal_length
* sepal_width
* petal_length
* petal_width

The species we want to predict are:

* setosa
* virginica
* versicolor

The goal of this tutorial is to use Gorgonia to find the correct values of $\Theta$ given the iris dataset, in order to write a CLI utility that would look like this:

```text
./iris
sepal length: 5
sepal width: 3.5
petal length: 1.4
sepal length: 0.2

It is probably a setosa
```

{{% notice warning %}}
This tutorial is for academic purpose. Its goal is to describe how to do this with Gorgonia;
It is not the state of the art answer to this particular problem.
{{% /notice %}}

### Mathematical representation

We will consider that the species of Iris if a function of its sepal length and width as well as its petal length and width.

Therefore, if we consider that $y$ is the value of the species, we the equation we would like to solve is:

$$ y = \theta_0 + \theta_1 * sepal\\_length + \theta_2 * sepal\\_width + \theta_3 * petal\\_length + \theta_4 * petal\\_width$$

Let's consider the vectors $x$ and $\Theta$ such as:

$$ x =  \begin{bmatrix} sepal\\_length & sepal\\_width & petal\\_length & petal\\_width & 1\end{bmatrix}$$

$$
\Theta = \begin{bmatrix}
        \theta_4 \\
        \theta_3 \\
        \theta_2 \\
        \theta_1 \\
        \theta_0 \\
        \end{bmatrix}
$$

We have

$$y = x\cdot\Theta$$

### Linear regression

To find the correct values, we will use a linear regression.
We will encode the data (the true facts from observation of different flowers) into a matrix $X$ containing 5 columns (sepal length, sepal width, petal length, petal width and 1 for the bias).
A row of the matrix represent a flower.

The we will encode the corresponding species into a column vector $Y$ with float values.

* setosa = 1.0
* virginica = 2.0
* versicolor = 3.0

In the learning phase, the cost is expressed like this:

$cost = \dfrac{1}{m} \sum_{i=1}^m(X^{(i)}\cdot\Theta-Y^{(i)})^2$

We will use the gradient descent to lower the cost and get the accurate values for $\Theta$

{{% notice info %}}
It is possible to get the exact $\theta$ values with the Normal Equation
$$ \theta = \left( X^TX \right)^{-1}X^TY $$
See this [gist](https://gist.github.com/owulveryck/19a5ba9553ff8209b3b4227b5325041b#file-normal-go) for
a basic implementation with Gonum.
{{% /notice %}}


## Generate the training set with gota (dataframe)

First, let's generate the training data. We use a dataframe to do this smoothly.

{{% notice info %}}
See this [howto](/how-to/dataframe/) for more info about using the dataframe
{{% /notice %}}


```go
func getXYMat() (*mat.Dense, *mat.Dense) {
        f, err := os.Open("iris.csv")
        if err != nil {
                log.Fatal(err)
        }
        defer f.Close()
        df := dataframe.ReadCSV(f)
        xDF := df.Drop("species")

        toValue := func(s series.Series) series.Series {
                records := s.Records()
                floats := make([]float64, len(records))
                for i, r := range records {
                        switch r {
                        case "setosa":
                                floats[i] = 1
                        case "virginica":
                                floats[i] = 2
                        case "versicolor":
                                floats[i] = 3
                        default:
                                log.Fatalf("unknown iris: %v\n", r)
                        }
                }
                return series.Floats(floats)
        }

        yDF := df.Select("species").Capply(toValue)
        numRows, _ := xDF.Dims()
        xDF = xDF.Mutate(series.New(one(numRows), series.Float, "bias"))
        fmt.Println(xDF.Describe())
        fmt.Println(yDF.Describe())

        return mat.DenseCopyOf(&matrix{xDF}), mat.DenseCopyOf(&matrix{yDF})
}
```

This returns two matrices we can use in Gorgonia.

### Create the expression graph

The equation $X\cdot\Theta$ is represented as an [ExprGraph](/reference/exprgraph):

```go
func getXY() (*tensor.Dense, *tensor.Dense) {
	x, y := getXYMat()

	xT := tensor.FromMat64(x)
	yT := tensor.FromMat64(y)
	// Get rid of the last dimension to create a vector
	s := yT.Shape()
	yT.Reshape(s[0])
	return xT, yT
}

func main() {
	xT, yT := getXY()
	g := gorgonia.NewGraph()
	x := gorgonia.NodeFromAny(g, xT, gorgonia.WithName("x"))
	y := gorgonia.NodeFromAny(g, yT, gorgonia.WithName("y"))
	theta := gorgonia.NewVector(
		g,
		gorgonia.Float64,
		gorgonia.WithName("theta"),
		gorgonia.WithShape(xT.Shape()[1]),
		gorgonia.WithInit(gorgonia.Uniform(0, 1)))

	pred := must(gorgonia.Mul(x, theta))
    // Saving the value for later use
    var predicted gorgonia.Value
    gorgonia.Read(pred, &predicted)
```

{{% notice info %}}
Gorgonia is higly optimized; it heavily plays with pointers and memory to get good performances.
Therefore, calling the `Value()` method of a `*Node` at runtime (during the execution process), may lead to incorrect results.
If we need to access a specific value of a *Node at runtime (for example during the learning phase), we need to keep a reference to its
underlying `Value`. This is why we use the `Read` method here.
`predicted` will hold a Value containing the result of $X\cdot\Theta$ at anytime.
{{% /notice %}}

## Preparing the gradient computation

We will use Gorgonia's [Symbolic differentiation](/how-to/differentiation) capability.

First, we will create the cost function, and use a [solver](/about/solver) to perform a gradient descent to lower the cost.

### Create the node holding the cost

We complete the [exprgraph](/reference/exprgraph) by adding the cost ($cost = \dfrac{1}{m} \sum_{i=1}^m(X^{(i)}\cdot\Theta-Y^{(i)})^2$)

```go
squaredError := must(gorgonia.Square(must(gorgonia.Sub(pred, y))))
cost := must(gorgonia.Mean(squaredError))
```

We want to lower this cost, so we evaluate the gradient wrt to $\Theta$:

```go
if _, err := gorgonia.Grad(cost, theta); err != nil {
        log.Fatalf("Failed to backpropagate: %v", err)
}
```

### The gradient descent

We are using the mechanism of the gradient descent. This means that we use the gradient to modulate the parameters $\Theta$
step by step.

The basic gradient descent is implemented by [Vanilla Solver](https://godoc.org/gorgonia.org/gorgonia#VanillaSolver) of Gorgonia.
We set the learning rate $\gamma$ to be 0.001.

```go
solver := gorgonia.NewVanillaSolver(gorgonia.WithLearnRate(0.001))
```

And at each step, we will ask the solver to update the $\Theta$ parameters thanks to its gradient.
Therefore, we set an `update` variable that we will pass to the solver at each iteration

{{% notice info %}}
The gradient descent will update the all the values passed into `[]gorgonia.ValueGrad` at each step according this equation:
${\displaystyle x^{(k+1)}=x^{(k)}-\gamma \nabla f\left(x^{(k)}\right)}$
It is important to understand that the solver works on [`Values`](/reference/value) and not on [`Nodes`](/reference/node).
But to make things easy, ValueGrad is an interface{} fulfilled by the `*Node` structure.
{{% /notice %}}

In our case, we want to optimize $\Theta$ and ask the solver will update its value like this:

${\displaystyle \Theta^{(k+1)}=\Theta^{(k)}-\gamma \nabla f\left(\Theta^{(k)}\right)}$

To do so, we need to pass $\Theta$ to the `Step` method of the `Solver`:

```go
update := []gorgonia.ValueGrad{theta}
// ...
if err = solver.Step(update); err != nil {
        log.Fatal(err)
}
```

#### The learning iterations

Now that we have the principle, we need to run the computation with a [vm](/reference/vm) several times so the gradient
descent's magic can happen.

Let's create a [vm](/reference/vm) to execute the graph (and do the gradient computation):

```go
machine := gorgonia.NewTapeMachine(g, gorgonia.BindDualValues(theta))
defer machine.Close()
```

{{% notice warning %}}
We will ask the solver to update the parameter $\Theta$ wrt to its gradient.
Therefore we must instruct the TapeMachine to store the value of $\Theta$ *as well as* its derivative (its dual value).
We do this with the [BindDualValues](https://godoc.org/gorgonia.org/gorgonia#BindDualValues) function.
{{% /notice %}}

Now let's create the loop and execute the graph at each step; the machine will learn!

```go
iter := 1000000
var err error
for i := 0; i < iter; i++ {
        if err = machine.RunAll(); err != nil {
                fmt.Printf("Error during iteration: %v: %v\n", i, err)
                break
        }

        if err = solver.Step(model); err != nil {
                log.Fatal(err)
        }
        machine.Reset() // Reset is necessary in a loop like this
}
```

#### Getting some infos

We can dump some info about the learning process by using this call
```go
fmt.Printf("theta: %2.2f  Iter: %v Cost: %2.3f Accuracy: %2.2f \r",
        theta.Value(),
        i,
        cost.Value(),
        accuracy(predicted.Data().([]float64), y.Value().Data().([]float64)))
```

with `accuracy` defined like this:

```go
func accuracy(prediction, y []float64) float64 {
        var ok float64
        for i := 0; i < len(prediction); i++ {
                if math.Round(prediction[i]-y[i]) == 0 {
                        ok += 1.0
                }
        }
        return ok / float64(len(y))
}
```

This will display a line like this during the learning process:

```text
theta: [ 0.26  -0.41   0.44  -0.62   0.83]  Iter: 26075 Cost: 0.339 Accuracy: 0.61
```

### Save the weights

Once the training is done, we save the values of $\Theta$ to be able to do some predictions:

```go
func save(value gorgonia.Value) error {
	f, err := os.Create("theta.bin")
	if err != nil {
		return err
	}
	defer f.Close()
	enc := gob.NewEncoder(f)
	err = enc.Encode(value)
	if err != nil {
		return err
	}
	return nil
}
```

## Create a simple CLI for predictions

First, let's load the parameters from the training phase:

```go
func main() {
        f, err := os.Open("theta.bin")
        if err != nil {
                log.Fatal(err)
        }
        defer f.Close()
        dec := gob.NewDecoder(f)
        var thetaT *tensor.Dense
        err = dec.Decode(&thetaT)
        if err != nil {
                log.Fatal(err)
        }
```

Then, let's create the model (the exprgraph) like we did before:

{{% notice info %}}
A real application would probably have shared the model in a separate package
{{% /notice %}}

```go
g := gorgonia.NewGraph()
theta := gorgonia.NodeFromAny(g, thetaT, gorgonia.WithName("theta"))
values := make([]float64, 5)
xT := tensor.New(tensor.WithBacking(values))
x := gorgonia.NodeFromAny(g, xT, gorgonia.WithName("x"))
y, err := gorgonia.Mul(x, theta)
```

Then enter a for loop that will get info from stdin, do the computation and display the result:

```go
machine := gorgonia.NewTapeMachine(g)
values[4] = 1.0
for {
        values[0] = getInput("sepal length")
        values[1] = getInput("sepal width")
        values[2] = getInput("petal length")
        values[3] = getInput("petal width")

        if err = machine.RunAll(); err != nil {
                log.Fatal(err)
        }
        switch math.Round(y.Value().Data().(float64)) {
        case 1:
                fmt.Println("It is probably a setosa")
        case 2:
                fmt.Println("It is probably a virginica")
        case 3:
                fmt.Println("It is probably a versicolor")
        default:
                fmt.Println("unknown iris")
        }
        machine.Reset()
}
```

This is a helper function to get the input:

```go
func getInput(s string) float64 {
        reader := bufio.NewReader(os.Stdin)
        fmt.Printf("%v: ", s)
        text, _ := reader.ReadString('\n')
        text = strings.Replace(text, "\n", "", -1)

        input, err := strconv.ParseFloat(text, 64)
        if err != nil {
                log.Fatal(err)
        }
        return input
}
```

Now we can `go build` or `go run` the code, and _voilà_!
We have a fully autonomous CLI that can predict the iris species regarding its features:

```text
$ go run main.go
sepal length: 4.4
sepal widt: 2.9
petal length: 1.4
petal width: 0.2
It is probably a setosa
sepal length: 5.9
sepal widt: 3.0
petal length: 5.1
petal width: 1.8
It is probably a virginica
```

# Conclusion

This is a step by step example.
You can now play with the initialization values of theta, or change to solver to see how thing goes within Gorgonia.

The full code can be found in the [example](https://github.com/gorgonia/gorgonia/tree/master/examples) of the Gorgonia project.

### Bonus: visual representation

It is possible to visualize the dataset using the Gonum plotter libraries.
Here is a simple example on how to achieve it:

![iris](/images/iris/iris.png)

```go
import (
    "gonum.org/v1/plot"
    "gonum.org/v1/plot/plotter"
    "gonum.org/v1/plot/plotutil"
    "gonum.org/v1/plot/vg"
    "gonum.org/v1/plot/vg/draw"
)

func plotData(x []float64, a []float64) []byte {
	p, err := plot.New()
	if err != nil {
		log.Fatal(err)
	}

	p.Title.Text = "sepal length & width"
	p.X.Label.Text = "length"
	p.Y.Label.Text = "width"
	p.Add(plotter.NewGrid())

	l := len(x) / len(a)
	for k := 1; k <= 3; k++ {
		data0 := make(plotter.XYs, 0)
		for i := 0; i < len(a); i++ {
			if k != int(a[i]) {
				continue
			}
			x1 := x[i*l+0] // sepal_length
			y1 := x[i*l+1] // sepal_width
			data0 = append(data0, plotter.XY{X: x1, Y: y1})
		}
		data, err := plotter.NewScatter(data0)
		if err != nil {
			log.Fatal(err)
		}
		data.GlyphStyle.Color = plotutil.Color(k - 1)
		data.Shape = &draw.PyramidGlyph{}
		p.Add(data)
		p.Legend.Add(fmt.Sprint(k), data)
	}

	w, err := p.WriterTo(4*vg.Inch, 4*vg.Inch, "png")
	if err != nil {
		panic(err)
	}
	var b bytes.Buffer
	writer := bufio.NewWriter(&b)
	w.WriteTo(writer)
	ioutil.WriteFile("out.png", b.Bytes(), 0644)
	return b.Bytes()
}
```
