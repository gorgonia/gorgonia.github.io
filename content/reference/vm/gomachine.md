---
title: "Go Machine"
description: "This page describes the plumbing inside the Go Machine"
date: 2019-10-29T19:50:15+01:00
draft: false
---

This page explains the plumbing inside the GoMachine.

A GoMachine is a runtime environment that executes an `*exprgraph`.

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
graph LR;
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

_Note_: It is the responsibility of every state function to handle context cancelation mechanism.

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

A change in the `*node` structure triggers an action that induce the change of state.

For example, let's take a simple calculator that the performs `a+b`.

- $+$ is waiting for two inputs values to do the sum $a$ and $b$
- $a$ is waiting for a value
- $b$ is waiting for a value

let's _send_ a value to $a$... $+$ should be notified of this event, _receive_ the value, and expect one more value.

Then we _send_ a value to $b$, $+$ is notified; it _receives_  the value, and change its state to `compute`.

Then it _sends_ the result to whoever is interested in using it.

In `Go` send and receive events are easily performeded with channels.

The node structure owns two channels, one to receive the input (`inputC`), and one to emit the output (`outputC`):

```go
type node struct {
	outputC        chan gorgonia.Value
	inputC         chan ioValue
    err            error
    // ...
}
```

## Communication HUB

Now we have all nodes running in goroutines, we need to wire them together to actually compute a formulae.

For example in: $ a\times x+b$, we need to send the result of $a\times x$ into the node carrying the _addition_ operator.

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
A node is also subscribing for content sent by publishers.

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

To actually wire all the publishers and subscribers, we use a top level structure `pubsub`

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


## The machine