---
title: "Lstm"
date: 2019-11-08T10:22:27+01:00
draft: false
---

# LSTM with forget gate

[reference](https://en.wikipedia.org/wiki/Long_short-term_memory#LSTM_with_a_forget_gate)

Let $d$ the dictionnary size and $h$ the hidden layer size.

* The input vector $x$ at step $t$ is defined as $x_t \in \mathbb{R}^d$
* The hidden state vector $h$ at step $t$ is defined as $h_t \in \mathbb{R}^h$

### Equation

We define the LSTM with this equations:

$f_t = \sigma_g(W_f x_t + U_f h\_{t-1} + b_f)$

$i_t = \sigma_g(W_i x_t + U_i h\_{t-1} + b_i)$

$o_t = \sigma_g(W_o x_t + U_o h\_{t-1} + b_o)$

$c_t = f_t \circ c\_{t-1} + i_t \circ \sigma_c(W_c x_t + U_c h\_{t-1} + b_c)$

$h_t = o_t \circ \sigma_h(c_t)$

_Note_: $\circ$ is the element-wise product, also known as Hadamard Product

### Variables

* $x_t \in \mathbb{R}^d$
* $f_t \in \mathbb{R}^h$
* $i_t \in \mathbb{R}^h$
* $o_t \in \mathbb{R}^h$
* $h_t \in \mathbb{R}^h$
* $c_t \in \mathbb{R}^h$
* $W \in \mathbb{R}^{h\times d}$, $U \in \mathbb{R}^{h\times h}$, $b \in \mathbb{R}^{h}$,

### Activation functions

* $\sigma_g$: sigmoid function
* $\sigma_c$: hyperbolic tangent function
* $\sigma_h$: hyperbolic tangent function

# Code

### The top structure


```go
func newLSTM(vectorSize, hiddenSize int) *lstm {
	float := G.Float64
	g := G.NewGraph()
	// Declarations
	xt := G.NewVector(g, float, G.WithName("xₜ"), G.WithShape(vectorSize))
	htprev := G.NewVector(g, float, G.WithName("hₜ₋₁"), G.WithShape(hiddenSize))
	ctprev := G.NewVector(g, float, G.WithName("cₜ₋₁"), G.WithShape(hiddenSize))
	wf := G.NewMatrix(g, float, G.WithName("Wf"), G.WithShape(hiddenSize, vectorSize))
	wi := G.NewMatrix(g, float, G.WithName("Wᵢ"), G.WithShape(hiddenSize, vectorSize))
	wo := G.NewMatrix(g, float, G.WithName("Wₒ"), G.WithShape(hiddenSize, vectorSize))
	wc := G.NewMatrix(g, float, G.WithName("Wc"), G.WithShape(hiddenSize, vectorSize))
	uf := G.NewMatrix(g, float, G.WithName("Uf"), G.WithShape(hiddenSize, hiddenSize))
	ui := G.NewMatrix(g, float, G.WithName("Uᵢ"), G.WithShape(hiddenSize, hiddenSize))
	uo := G.NewMatrix(g, float, G.WithName("Uₒ"), G.WithShape(hiddenSize, hiddenSize))
	uc := G.NewMatrix(g, float, G.WithName("Uc"), G.WithShape(hiddenSize, hiddenSize))
	bf := G.NewVector(g, float, G.WithName("bf"), G.WithShape(hiddenSize))
	bi := G.NewVector(g, float, G.WithName("bᵢ"), G.WithShape(hiddenSize))
	bo := G.NewVector(g, float, G.WithName("bₒ"), G.WithShape(hiddenSize))
	bc := G.NewVector(g, float, G.WithName("bc"), G.WithShape(hiddenSize))
```

```go
it := G.Must(
    G.Sigmoid(
        G.Must(
            G.Add(
                G.Must(
                    G.Add(
                        G.Must(G.Mul(wi, xt)),
                        G.Must(G.Mul(ui, htprev)))),
                bi,
            ))))
```

```go
cct := G.Must(
    G.Tanh(
        G.Must(
            G.Add(
                G.Must(
                    G.Add(
                        G.Must(G.Mul(wc, xt)),
                        G.Must(G.Mul(uc, htprev)))),
                bc,
            ))))
ct := G.Must(G.Add(
    G.Must(G.HadamardProd(ft, ctprev)),
    G.Must(G.HadamardProd(it, cct)),
))
ht := G.Must(
    G.Mul(
        ot,
        G.Must(G.Tanh(ct)),
    ))
```
![graph](/images/lstm.svg)
