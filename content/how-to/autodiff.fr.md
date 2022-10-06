---
title: "Comment calculer le gradient (dérivation)"
date: 2019-10-29T20:07:07+01:00
draft: false
---

## Objectif

Prenez cette équation simple :

$$ f(x,y,z) = ( x + y ) \times z $$

L'objectif de cet article est de vous montrer comment Gorgonia peut évaluer le gradient $\nabla f$ avec ses dérivées partielles :

$$ \nabla f = [\frac{\partial f}{\partial x}, \frac{\partial f}{\partial y}, \frac{\partial f}{\partial z}] $$

### Explication

En utilisant la [règle de dérivation d'une fonction composée](https://www.khanacademy.org/math/ap-calculus-ab/ab-differentiation-2-new/ab-3-1a/a/chain-rule-review), on peut obtenir la valeur du gradient à chaque étape comme démontré ici :

{{<mermaid align="left">}}
graph LR;
    x -->|$x=-2$<br>$\partial f/\partial x = -4$| add
    y -->|$y=5$<br>$\partial f/\partial y = -4$| add
    add(+) -->|$q=3$<br>$\partial f/\partial q = -4$| mul
    z -->|$z=-4$<br>$\partial f/\partial z = 3$| mul
    mul(*) -->|$f=-12$<br>$1$| f
{{< /mermaid >}}

{{% notice info %}}
Pour plus d'informations sur le calcul de gradient, veuillez lire cet [article de cs231n (en anglais)](http://cs231n.github.io/optimization-2/) de Stanford.
{{% /notice %}}

Nous allons représenter cette équation dans un [exprgraph](/reference/exprgraph) et voir comment demander à Gorgonia de calculer le gradient.

Quand le calcul est effectué, chaque point aura une [double valeur](/reference/dualvalue) qui contiendra à la fois sa valeur réelle et la dérivée wrt de x.

par exemple, prenons le point x :

```go
var x *gorgonia.Node
```

Une fois que Gorgonia a évalué l'exprgraph, il est possible d'extraire la valeur de `x` aet la valeur du gradient $\frac{\partial f}{\partial x}$ en appelant :

```go
xValue := x.Value()    // -2
dfdx, _ := x.Grad()    // -4, please check for errors in proper code
```

Voyons comment faire cela.

## Créer l'équation

D'abord, créons l'[exprgraph](/reference/exprgraph) qui représente l'équation.

{{% notice info %}}
Si vous voulez plus d'infos sur cette partie, veuillez lire le tutoriel [hello world](/tutorials/hello-world/).
{{% /notice %}}

```go
g := gorgonia.NewGraph()

var x, y, z *gorgonia.Node
var err error

// define the expression
x = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("x"))
y = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("y"))
z = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("z"))
q, err := gorgonia.Add(x, y)
if err != nil {
    log.Fatal(err)
}
result, err := gorgonia.Mul(z, q)
if err != nil {
    log.Fatal(err)
}
```

Et définissez quelques valeurs :

```go
gorgonia.Let(x, -2.0)
gorgonia.Let(y, 5.0)
gorgonia.Let(z, -4.0)
```

### Obtenir les gradients

Il y a deux manières d'obtenir les gradients :

* en utilisant la compétence de [dérivation automatique](https://fr.wikipedia.org/wiki/D%C3%A9rivation_automatique) de la [LispMachine](/reference/lispmachine);
* en utilisant la compétence de [calcul symbolique](https://fr.wikipedia.org/wiki/Calcul_formel) proposée par Gorgonia;

#### Dérivation automatique

La dérivation automatique n'est possible qu'avec la [LispMachine](/reference/lispmachine).
Par défaut, lispmachine fonctionne avec des mode d'exécution en avant et en arrière.

Ainsi, utiliser la méthode RunAll suffit pour obtenir le résultat.

```go
m := gorgonia.NewLispMachine(g)
defer m.Close()
if err = m.RunAll(); err != nil {
    log.fatal(err)
}
```

Les valeurs et gradients peuvent à présent être extraites :

```go
fmt.Printf("x=%v;y=%v;z=%v\n", x.Value(), y.Value(), z.Value())
fmt.Printf("f(x,y,z) = %v\n", result.Value())

if xgrad, err := x.Grad(); err == nil {
    fmt.Printf("df/dx: %v\n", xgrad)
}
if ygrad, err := y.Grad(); err == nil {
    fmt.Printf("df/dy: %v\n", ygrad)
}
if xgrad, err := z.Grad(); err == nil {
    fmt.Printf("df/dx: %v\n", xgrad)
}
```

#### Calcul symbolique

Une autre option est d'utiliser le calcul symbolique.
Le calcul symbolique fonctionne en ajoutant des points aux graphiques. Ces nouveaux points contiennent les gradients par rapport aux nœuds passés en argument.

Pour créer ces nouveaux points, on utilise la fonction [Grad()](https://godoc.org/gorgonia.org/gorgonia#Grad).

Grad prend un point de coût scalaire et une liste de ce qui concerne, et renvoie le gradient.

Prenez le code suivant :

```go
var grads Nodes
if grads, err = Grad(result,z, x, y); err != nil {
    log.Fatal(err)
}
```

Cela signifie qu'il faut calculer les dérivées partielles (gradients) par rapport à `z`, `x` et `y`.

`grads` dans un tableau de `[]*gorgonia.Node`, dans le même ordre que les WRTs qui y sont passés :

* `grads[0]` = $\frac{\partial f}{\partial z}$
* `grads[1]` = $\frac{\partial f}{\partial x}$
* `grads[2]` = $\frac{\partial f}{\partial y}$

Le gradient est compatible avec [TapeMachine](/reference/tapemachine) et [LispMachine](/reference/lispmachine). Mais TapeMachine est beaucoup plus rapide.

```go
machine := gorgonia.NewTapeMachine(g)
defer machine.Close()
if err = machine.RunAll(); err != nil {
        log.Fatal(err)
}

fmt.Printf("result: %v\n", result.Value())
if zgrad, err := z.Grad(); err == nil {
        fmt.Printf("dz/dx: %v | %v\n", zgrad, grads[0].Value())
}

if xgrad, err := x.Grad(); err == nil {
        fmt.Printf("dz/dx: %v | %v\n", xgrad, grads[1].Value())
}

if ygrad, err := y.Grad(); err == nil {
        fmt.Printf("dz/dy: %v | %v\n", ygrad, grads[2].Value())
}
```

Notez que vous pouvez accéder aux dérivées partielles de deux manières :

1. En utlisant la méthode `.Grad()` par exemple pour le gradient de `x` dans l'exemple présent, utilisez `x.Grad()`
2. En utlisant la méthode `.Value()` du point gradient par exemple pour le gradient de `x` de l'exemple, utilisez `grads[1].Value()`.

La raison d'avoir ces deux manières différentes de faire les choses se résume à la pertinence. Lorsqu'il est plus significatif d'obtenir des valeurs à partir des points de gradient (par exemple, vous pouvez vouloir calculer la dérivée seconde), utilisez les nœuds de gradient. Mais si vous voulez une récupération rapide des valeurs de gradient, la méthode `.Grad()` pourrait être la plus appropriée. En fin de compte, cela dépend de votre goût.

## Full Code (Dérivation automatique)

```go
func main() {
 g := gorgonia.NewGraph()

 var x, y, z *gorgonia.Node
 var err error

 // define the expression
 x = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("x"))
 y = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("y"))
 z = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("z"))
 q, err := gorgonia.Add(x, y)
 if err != nil {
  log.Fatal(err)
 }
 result, err := gorgonia.Mul(z, q)
 if err != nil {
  log.Fatal(err)
 }

 // set initial values then run
 gorgonia.Let(x, -2.0)
 gorgonia.Let(y, 5.0)
 gorgonia.Let(z, -4.0)

 // by default, lispmachine performs forward mode and backwards mode execution
 m := gorgonia.NewLispMachine(g)
 defer m.Close()
 if err = m.RunAll(); err != nil {
  log.fatal(err)
 }

 fmt.Printf("x=%v;y=%v;z=%v\n", x.Value(), y.Value(), z.Value())
 fmt.Printf("f(x,y,z)=(x+y)*z\n")
 fmt.Printf("f(x,y,z) = %v\n", result.Value())

 if xgrad, err := x.Grad(); err == nil {
  fmt.Printf("df/dx: %v\n", xgrad)
 }

 if ygrad, err := y.Grad(); err == nil {
  fmt.Printf("df/dy: %v\n", ygrad)
 }
 if xgrad, err := z.Grad(); err == nil {
  fmt.Printf("df/dz: %v\n", xgrad)
 }
}
```

qui donne :

```text
$ go run main.go
x=-2;y=5;z=-4
f(x,y,z)=(x+y)*z
f(x,y,z) = -12
df/dx: -4
df/dy: -4
df/dz: 3
```

## Full Code (Calcul symbolique)

```go
func main() {
 g := gorgonia.NewGraph()

 var x, y, z *gorgonia.Node
 var err error

 // define the expression
 x = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("x"))
 y = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("y"))
 z = gorgonia.NewScalar(g, gorgonia.Float64, gorgonia.WithName("z"))
 q, err := gorgonia.Add(x, y)
 if err != nil {
  log.Fatal(err)
 }
 result, err := gorgonia.Mul(z, q)
 if err != nil {
  log.Fatal(err)
 }

 if grads, err = Grad(result,z, x, y); err != nil {
  log.Fatal(err)
 }

 // set initial values then run
 gorgonia.Let(x, -2.0)
 gorgonia.Let(y, 5.0)
 gorgonia.Let(z, -4.0)

 machine := gorgonia.NewTapeMachine(g)
 defer machine.Close()
 if err = machine.RunAll(); err != nil {
  log.Fatal(err)
 }

 fmt.Printf("x=%v;y=%v;z=%v\n", x.Value(), y.Value(), z.Value())
 fmt.Printf("f(x,y,z)=(x+y)*z\n")
 fmt.Printf("f(x,y,z) = %v\n", result.Value())

 if zgrad, err := z.Grad(); err == nil {
  fmt.Printf("dz/dx: %v | %v\n", zgrad, grads[0].Value())
 }

 if xgrad, err := x.Grad(); err == nil {
  fmt.Printf("dz/dx: %v | %v\n", xgrad, grads[1].Value())
 }

 if ygrad, err := y.Grad(); err == nil {
  fmt.Printf("dz/dy: %v | %v\n", ygrad, grads[2].Value())
 }
}
```

qui donne :

```text
$ go run main.go
x=-2;y=5;z=-4
f(x,y,z)=(x+y)*z
f(x,y,z) = -12
df/dx: -4 | -4
df/dy: -4 | -4
df/dz: 3 | 3
```
