---
title: "Go Machine"
description: "Cette page explique la tuyauterie à l'intérieur de la Go Machine"
date: 2019-10-29T19:50:15+01:00
draft: false
---
Cette page explique la tuyauterie à l'intérieur de la Go Machine.

GoMachine est une fonctionnalité expérimentale contenue dans [`xvm` package](https://github.com/gorgonia/gorgonia/tree/master/x/vm). 
L'API du package et son nom devraient changer.
Ce document s'appuie sur [commit 7538ab3](https://github.com/gorgonia/gorgonia/tree/7538ab3b58ceae68f162c17d19052324bf1dc587)

## Les états des noeuds

Le principe repose sur les états des noeuds.

Comme expliqué dans la vidéo [_Lexical Scanning in Go_](https://www.youtube.com/watch?v=HxaD_trXwRE):

- un état représente où nous sommes
- une action représente ce que nous faisons
-les actions activent un nouvel état


A ce jour, la GoMachine attend un noeud pour être dans ces divers états:

- _waiting for input_
- _emitting output_

Si un noeud contient un opérateur, il peut y avoir un nouvel état: 

- _computing_

{{% notice info%}}
Ultérieurement, un nouvel état va éventuellement être ajouté quand la différenciation automatique sera implémentée: _computing gradient_ 
{{%/notice%}}
Ceci amène à ce graphique des différents états d'un noeud:

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

### Implémentation

Le noeud (`node`) est une structure privée:

```go
type node struct {
    // ...
}
```

On définit un type `stateFn` qui représente une action pour éxécuter un noeud (`*node`) dans un contexte spécifique (`context`) et entraine un nouvel état. Ce type est une `func`:

```go
type stateFn func(context.Context, *node) stateFn
```

_Note_: C'est la responsabilité de chaque fonction d'état de maintenir le mécanisme d'annulation du contexte. cela signifie que si un signal d'annulation est reçu, le noeud devrait renvoyer à l'état final. pour faire simple:

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

on définit 4 fonctions de type `stateFn` pour implémenterles actions requises par le noeud:

```go
func defaultState(context.Context, *node) stateFn { ... }

func receiveInput(context.Context, *node) stateFn { ... }

func computeFwd(context.Context, *node) stateFn { ... }

func emitOutput(context.Context, *node) stateFn { ... }
```

_Note_: Le statut final est `nil` (la valeur nulle de `stateFn`)

### Exécuter la machine d'état

Chauqe noeud est une machine d'état.
Pour l'éxécuter, on fixe une méthode `run` qui utilise le contexte comme argument.

```go
func (n *node) Compute(ctx context.Context) error {
	for state := defaultState; state != nil; {
		state = state(ctx, n)
	}
	return n.err
}
```
_Note_: le noeud (`*node`) stocke une erreur qui devrait être écrite par une stateFn. Cette fonction d'état indique la raison pour laquelle la machine d'état a été cassée (par exemple, si une erreur survient durant le calcul, cette erreur contient la raison.)

Puis chaque noeud (`*node`) est déclenché dans sa propre Goroutine par la machine.

### Modification d'état dans un événement

On utilise le paradigme de la programmation réactive pour passer d'un état à un autre.

Un changement dans la stucture du noeud (`*node`) déclenche un eaction qui va induire un changement d'état.

Par exemple, prenons un simplscalculateur qui calcule `a+b`.

- $+$ attend 2 valeurs d'entrée pour faire la somme de $a$ et $b$
- $a$ attend une valeur
- $b$ attend une valeur

Quand on envoie une valeur à $a$

$+$ est notifié de l'événement ($a$ possède sa propre valeur); il reçoit et stocke en interne la valeur

Quand on envoie une valeur $b$, $+$ est informé, et reçoit la valeur. Son état change alors en `compute`.

Une fois compilé, le $+$ envoie le résultat à quiconque est intéressé par son usage.

En Go, envoyer et recevoir des valeurs, et programmer des événements nécessitent d'être implémentés avec des canaux.

La structure du noyeau possède 2 canaux, un pour recevoir les entrées (`inputC`), et un pour émettre les sorties (`outputC`):

```go
type node struct {
	outputC        chan gorgonia.Value
	inputC         chan ioValue
    err            error
    // ...
}
```

_Note_: La structure `ioValue` est expliquée plus loin dans ce document; pour le moment, considérons `ioValue` = `gorgonia.Value`

## HUB de communication

Désormais, tous les noeuds tournent dans des goroutines; on doit les cabler entre elles pour calculer une formule.

Par exemple, dans: $ a\times x+b$, on doit envoyer le résultat de $a\times x$ au noeud qui porte l'opération addition.

ce qui donne à peu près:
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
