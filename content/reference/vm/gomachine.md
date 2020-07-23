---
title: "Go Machine"
description: "This page describes the plumbing inside the Go Machine"
date: 2019-10-29T19:50:15+01:00
draft: false
---

This page explains the plumbing inside the GoMachine.

GoMachine is an experimental feature hold in the [`xvm` package](https://github.com/gorgonia/gorgonia/tree/master/x/vm). 
The API of the package and its name may change.

This document is based on [commit 7538ab3](https://github.com/gorgonia/gorgonia/tree/7538ab3b58ceae68f162c17d19052324bf1dc587)

## The states of the nodes

The principle relies on the state of the nodes.

As explained in [_Lexical Scanning in Go_](https://www.youtube.com/watch?v=HxaD_trXwRE):

- a state represents where we are
- an action represents what we do
- actions result in a new state


As of today, the GoMachine expects a node to be in those possible states:

- _waiting for input_
- _emitting output_

If a node is carrying an operator may have an extra state:

- _computing_

{{% notice info%}}
Later, a new state will eventually be added when implementing automatic differentiation: _computing gradient_ 
{{%/notice%}}

This leads to this state graph of the possible states of a node:

{{<mermaid align="left">}}
graph TB;
    A(Initial Stage) --> BB{input is an op}
    BB -->|no| D[Emit output]
    BB -->|yes| B[Waiting for input]
    B --> C{inputs == arity}
    C -->|no| B
    C -->|yes| Computing
    Computing --> E{Has error}
    E -->|no| D
    E -->|yes| F
    D --> F(end)
{{< /mermaid >}}

### Implementation

The `node` is a private structure:

```go
type node struct {
    // ...
}
```

We define a type `stateFn` that represents an action to perform on a `*node` in a specific `context`, and returns a new state. This type is a `func`:

```go
type stateFn func(context.Context, *node) stateFn
```

_Note_: It is the responsibility of every state function to handle context cancelation mechanism. This means that if a cancelation signal is received, the node should return the end state. For simplicity:

```go
func mystate(ctx context.Context, *node) stateFn { 
    // ...
    select {
        // ...
        case <- ctx.Done():
            n.err = ctx.Error()
            return nil
    }
}
```

We define four functions of type `stateFn` to implement the actions required by the node:

```go
func defaultState(context.Context, *node) stateFn { ... }

func receiveInput(context.Context, *node) stateFn { ... }

func computeFwd(context.Context, *node) stateFn { ... }

func emitOutput(context.Context, *node) stateFn { ... }
```

_Note_: the `end` state is `nil` (the zero value of the `stateFn`)

### Running the state machine

Each node is a state machine.
To run it, we set a method `run` that takes a context as an argument.

```go
func (n *node) Compute(ctx context.Context) error {
	for state := defaultState; state != nil; {
		state = state(ctx, n)
	}
	return n.err
}
```
_Note_: the `*node` stores an error that should be set by a stateFn that indicates the reason why it broke the state machine (for example, if an error occurs during the computation, this error contains the reason)

Then every `*node` is triggered in its own goroutine by the machine.

### State modification on event

We use the paradigm of reactive programming to switch from a state to another.

A change in the `*node` structure triggers an action that induces the change of state.

For example, let's take a simple calculator that computes `a+b`.

- $+$ is waiting for two inputs values to do the sum $a$ and $b$
- $a$ is waiting for a value
- $b$ is waiting for a value

When we _send_ a value to $a$

$+$ is notified of this event ($a$ owns a value); it receives and stores the value internally. 

Then we _send_ a value to $b$, $+$ is notified, and _receives_  the value. Then its state changes to `compute`.

Once computed, the $+$ _sends_ the result to whoever is interested in using it.

In Go sending and receiving values, and events programming are implemented with channels.

The node structure owns two channels, one to receive the input (`inputC`), and one to emit the output (`outputC`):

```go
type node struct {
	outputC        chan gorgonia.Value
	inputC         chan ioValue
    err            error
    // ...
}
```

_Note_: the `ioValue` structure is explained later in this doc; for now, consider `ioValue` = `gorgonia.Value`

## Communication HUB

Now we have all nodes running in goroutines; we need to wire them together actually to compute formulae.

For example, in: $ a\times x+b$, we need to send the result of $a\times x$ into the node carrying the _addition_ operator.

which is roughly:
```go
var aTimesX *node{op: mul}
var aTimesXPlusB *node{op: sum}

var a,b,c gorgonia.Value

aTimesX.inputC <- a
aTimesX.inputC <- x
aTimesXPlusB.inputC <- <- aTimesX.outputC 
aTimesXPlusB.inputC <- <- b
```

The problem is that a channel is not a "topic" and it does not handle subscriptions natively. The first consumer takes a value, and drain the channel.

Therefore if we take this equation $(a + b) \times c + (a + b) \times d$, the implementation would not work:

{{< highlight go "linenos=table,hl_lines=9 12" >}}
var aPlusB *node{op: add}
var aPlusBTimesC *node{op: mul}
var aPlusBTimesCPlusAPlusB *node{op: add}

var a,b,c gorgonia.Value

aPlusB.inputC <- a
aPlusB.inputC <- b
aPlusBTimesC.inputC <- <- aPlusB.outputC
aPlusBTimesC.inputC <- c
aPlusBTimesCPlusAPlusB <- <- aPlusBTimesC.outputC
aPlusBTimesCPlusAPlusB <- <- aPlusB.outputC // Deadlock
{{< / highlight >}}

This will provide a deadlock because `aPlusB.outputC` is emptied at line 9 and therefore line 12 will never receive value anymore.

The solution is to use temporary channels and a broadcast mechanism as described in the article [
Go Concurrency Patterns: Pipelines and cancellation](https://blog.golang.org/pipelines#TOC_4.).

### Publish / subscribe

A node is publishing some content to some subscribers.
A node is also subscribing to content sent by publishers.

We setup two structures:

```go
type publisher struct {
	id          int64
	publisher   <-chan gorgonia.Value
	subscribers []chan<- gorgonia.Value
}

type subscriber struct {
	id         int64
	publishers []<-chan gorgonia.Value
	subscriber chan<- ioValue
}
```

Each node providing output via the `outputC` is a publisher, and all the nodes in the graph reaching this node are its subscriber**s**. This defines a `publisher` object. The ID of the object is the ID of the node providing its output.

Each node expecting inputs via its `inputC` is a subscriber. The publisher**s** are the node reached by this node in the `*ExprGraph`


#### Merge and broadcast

publishers are broadcasting their data to the subscriber by calling 

```go
func broadcast(ctx context.Context, globalWG *sync.WaitGroup, ch <-chan gorgonia.Value, cs ...chan<- gorgonia.Value) { ... } 
```

subscribers are merging the results from the publishers by calling:

```go
func merge(ctx context.Context, globalWG *sync.WaitGroup, out chan<- ioValue, cs ...<-chan gorgonia.Value) { ... }
```

_Note_: both functions are handling context cancelation

### pubsub

To wire all the publishers and subscribers, we use a top-level structure: `pubsub`

```go
type pubsub struct {
	publishers  []*publisher
	subscribers []*subscriber
}
```

`pubsub` is in charge of setting up the network of channels.

Then a `run(context.Context)` method is triggering the `broadcast` and `merge` for all elements:

```go
func (p *pubsub) run(ctx context.Context) (context.CancelFunc, *sync.WaitGroup) { ... }
```

This method returns a `context.CancelFunc` and a `sync.WaitGroup` that will be down to zero when all pubsubs are settled after a cancelation. 

#### about `ioValue`

The subscriber has a single input channel; the input values can be sent in any order. 
The subscriber's merge function tracks the order of the subscribers, wraps the value into the ioValue structure, and adds the position of the operator emitting the value:

```go
type ioValue struct {
	pos int
	v   gorgonia.Value
}
```


## The machine

The `Machine` is the only exported structure of the package.

It is a support for nodes and pubsub.

```go
type Machine struct {
	nodes  []*node
	pubsub *pubsub
}
```

### Creating a machine

A machine is created from an `*ExprGraph` by calling 

```go
func NewMachine(g *gorgonia.ExprGraph) *Machine { ... }
```

Under the hood, it parses the graph and generates a `*node` for each `*gorgonia.Node`. 
If a node carries an Op (= an object that implements a `Do(... Value) Value` method), a pointer to the Op is added to the structure.

{{%notice info%}}
For transitioning, the package declares a `Doer` interface.
This interface is fulfilled by the `*gorgonia.Node` structure.
{{%/notice%}}

Two individual cases are handled:

- the top-level node of the `*ExprGraph` have `outputC = nil`
- the bottom nodes of the `*ExprGraph` have `inputC = nil`

Then the `NewMachine` calls the `createNetwork` methods to create the `*pubsub` elements.

### Running the machine

A call to the `Run` method of the Machine triggers the computation.
The call to this function is blocking.
It returns an error and stops the process if:
- all the nodes have reached their final states
- one node's execution state returns an error

In case of error, a cancel signal is automatically sent to the `*pubsub` infrastructure to avoid leakage.

### Closing the machine

After the computation, it is safe to call `Close` to avoid a memory leak.
`Close()` closes all the channels hold by the `*node` and the `*pubsub`

## Misc

It is important to notice that the machine is independent of the `*ExprGraph`. Therefore the values held by the `*gorgonia.Node` are not updated.

To access the data, you must call the `GetResult` method of the machine. This method takes a node ID as input (`*node` and `*gorgonia.Node` have the same IDs)

Ex:

```go
var add, err := gorgonia.Add(a,b)
fmt.Println(machine.GetResult(add.ID()))
```

## Example

This is a trivial example that computes two float 32

```go
func main(){
    g := gorgonia.NewGraph()
    forty := gorgonia.F32(40.0)
    two := gorgonia.F32(2.0)
    n1 := gorgonia.NewScalar(g, gorgonia.Float32, gorgonia.WithValue(&forty), gorgonia.WithName("n1"))
    n2 := gorgonia.NewScalar(g, gorgonia.Float32, gorgonia.WithValue(&two), gorgonia.WithName("n2"))

    added, err := gorgonia.Add(n1, n2)
    if err != nil {
        log.Fatal(err)
    }
    machine := NewMachine(g)
    ctx, cancel := context.WithTimeout(context.Background(), 1000*time.Millisecond)
    defer cancel()
    defer machine.Close()
    err = machine.Run(ctx)
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(machine.GetResult(added.ID()))
}
```

prints 

```shell
42
```