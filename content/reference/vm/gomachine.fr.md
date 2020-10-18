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

on définit 4 fonctions de type `stateFn` pour implémenter les actions requises par le noeud:

```go
func defaultState(context.Context, *node) stateFn { ... }

func receiveInput(context.Context, *node) stateFn { ... }

func computeFwd(context.Context, *node) stateFn { ... }

func emitOutput(context.Context, *node) stateFn { ... }
```

_Note_: Le statut final est `nil` (la valeur nulle de `stateFn`)

### Exécuter la machine d'état

Chaque noeud est une machine d'état.
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

Un changement dans la stucture du noeud (`*node`) déclenche une action qui va induire un changement d'état.

Par exemple, prenons un simple calculateur qui calcule `a+b`.

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

Le problème est que le canal n'est pas un "topic" et il ne gère pas les abonnements de manière native. Le premier consommateur prend une valeur, et vide le canal.

Donc si on prend l'équation $(a + b) \times c + (a + b) \times d$, l'implémentation ne devrait pas fonctionner:

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

Ceci devrait provoquer une impasse car `aPlusB.outputC` est vide à la ligne 9 et donc la ligne 12 ne recevra plus jamais de valeur.

La solution est d'utiliser des canaux temporaires et un mécanisme diffusé comme décrit dans l'article [
Go Concurrency Patterns: Pipelines and cancellation](https://blog.golang.org/pipelines#TOC_4.).

### Publier / souscrire

Un noeud publie du contenu pour des abonnés.
Le noeud inscrit aussi du contenu pour des producteurs.

On associe 2 structures:

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

Chaque noeud qui fournit une sortie via `outputC` est un producteur, et tous les noeuds du graphique qui rejoignent ce premier noeud sont ses abonnés. Ceci définit un objet producteur. L'identifiant de l'objet est l'identifiant du noeud qui envoie sa sortie (output).

Chaque noeud qui attend une entrée via son`inputC` est un abonné. Les producteurs sont les noeuds atteints par ce premier noeud dans le `*ExprGraph`


#### Fusionner et diffuser

Les producteurs diffusent leurs données à l'abonné par appel. 

```go
func broadcast(ctx context.Context, globalWG *sync.WaitGroup, ch <-chan gorgonia.Value, cs ...chan<- gorgonia.Value) { ... } 
```

Les abonnés fusionnent les résultats issus des producteurs par appel:

```go
func merge(ctx context.Context, globalWG *sync.WaitGroup, out chan<- ioValue, cs ...<-chan gorgonia.Value) { ... }
```

_Note_:les 2 fonctions gèrent l'annulation du contexte

### pubsub

Pour cabler les producteurs et les abonnés, on utilise la structure de plus haut niveau: `pubsub`

```go
type pubsub struct {
	publishers  []*publisher
	subscribers []*subscriber
}
```

`pubsub` est chargé de mettre en place le réseau de canaux.

Quand une méthode `run(context.Context)` déclenche le souscrire ( `broadcast`) et publier (`merge`) pour tous les éléments:

```go
func (p *pubsub) run(ctx context.Context) (context.CancelFunc, *sync.WaitGroup) { ... }
```

Cett méthode retourne un  `context.CancelFunc` et un `sync.WaitGroup` qui vont tomber à 0 quand tous les pubsubs sont colonisés après une annulation. 

#### A propos de `ioValue`

L'abonné a un seul canal d'entrée; la valeur de sortie peut être envoyée dans n'importe quel ordre. 
La fonction "merge"(fusion) de l'abonné traque l'ordre des abonnés, inclut la valeur dans la structure ioValue, et ajoute la position de l'opérateur qui a émis cette valeur: 

```go
type ioValue struct {
	pos int
	v   gorgonia.Value
}
```


## La machine

La `Machine` est la seule structure exportée du package.

C'est un suport pour les noeuds et pubsub.

```go
type Machine struct {
	nodes  []*node
	pubsub *pubsub
}
```

### Creating a machine

Une machine est créée à partir de `*ExprGraph` par appel 

```go
func NewMachine(g *gorgonia.ExprGraph) *Machine { ... }
```

De manière sous-jascente, il analyse le graphique et génère un noeud (`*node`) pour chaque noeud gorgonia (`*gorgonia.Node`). 
Si un noeud porte une opération "Op" (= un objet qui implémente une méthode `Do(... Value) Value` ), un pointeur sur l'opération est ajouté à la structure.

{{%notice info%}}
Pour faire la transition, le package déclare une interface `Doer`.
Cette interface est validée par la strucure `*gorgonia.Node`.
{{%/notice%}}

Deux cas particuliers sont pris en charge:

- Le noeud de plus haut niveau du graphe `*ExprGraph` contient`outputC = nil`
- les derniers noeuds du `*ExprGraph` présentent `inputC = nil`

 puis la nouvelle machine(`NewMachine`) fait appel aus méthodes de création de réseau pour crééer les éléments`*pubsub`.

### Exécuter la machine

Un appel à la méthode`Run` de la machine déclenche le calcul.
L'appel à cette fonction est bloqué.
Il renvoie une erreur et stoppe le process si:
- si tous les noeuds ont atteint leur état final
- si l'état d'éxécution d'un noeud renvoie une erreur

En cas d'erreur, un signal d'annulation est automatiquement envoyé à l'infrastructure `*pubsub` pour éviter les fuites.

### Fermer la machine

Après le calcul, il est sécuritaire d'appeler `Close` pour éviter une fuite mémoire.
`Close()` ferme tous les canaux tenus par le noeud `*node` et le `*pubsub`

## Divers

Il est important de remarquer que la machine est indépendante du `*ExprGraph`. Donc les valeurs contenues par le `*gorgonia.Node` ne sont pas mises à jour.

Pour accéder aux données, on doit appeler la méthode `GetResult` de la machine. cette méthode utilise l'identifiant d'un noeud comme entrée  ( le noeud (`*node`) et noeud gorgonia ( `*gorgonia.Node`)  ont les mêmes identifiants)

Ex:

```go
var add, err := gorgonia.Add(a,b)
fmt.Println(machine.GetResult(add.ID()))
```

## Exemple

Voici un exemple trivial qui calcule 2 float 32

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
