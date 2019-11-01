---
title: "Régression linéaire multivariée sur le dataset Iris"
date: 2019-10-31T14:53:37+01:00
draft: false
---

## A propos

Nous allons utiliser Gorgonia pour créer un modèle de régression linéaire.

Le but de ce tutoriel est de prédire l'espèce d'une fleur en fonction de ses caractéristiques:

* sepal_length // longueur du sépale
* sepal_width  // largeur du sépale
* petal_length // longueur du pétale
* petal_width  // largeurdu pétale

Les espèces que nous voulons prédire sont:

* setosa
* virginica
* versicolor

Le but de ce tutoriel est de programmer Gorgonia pour qu'il trouve seul les paramètres qui permettent de déterminer la relation entre les attributs
et le spécimen.
À la fin, nous écrirons un utilitaire CLI (autonome) dont l'interface sera la suivante:

```text
./iris
sepal length: 5
sepal width: 3.5
petal length: 1.4
sepal length: 0.2

It is probably a setosa
```

{{% notice warning %}}
Ce tutoriel est à vocation académique. Son but est de décrire comment réaliser une régression linéaire
multivariée avec Gorgonia; Ainsi, le modèle utilisé n'est pas la meilleur réponse à ce problème particulier.
{{% /notice %}}

### Représentation Mathématique

Nous considérons que l'espèce d'une Iris est fonction de la longueur et de la largeur de son sépale ainsi que de la longueur et de la largeur de son pétale.

Par conséquent, soit $y$ une valeur représentant l'espèce, l'équation que nous essayons de résoudre est:

$$ y = \theta_0 + \theta_1 * sepal\\_length + \theta_2 * sepal\\_width + \theta_3 * petal\\_length + \theta_4 * petal\\_width$$

Considérons à présent les vecteurs $x$ et $\Theta$ suivants:

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

Nous pouvons réécrire l'équation:

$$y = x\cdot\Theta$$

### Régression linéaire

Pour trouver les bonnes valeurs de $\Theta$  rendant l'équation vraie pour la majorité des Iris, nous allons utiliser une régression linéaire.

Nous allons encoder les données d'entrainement (les constats fait sur plusieurs fleurs) dans une matrice $X$.
$X$ est composée de 5 colonnes: sepal length, sepal width, petal length, petal width et une colonne contenant 1 pour le biais.
Chaque ligne de la matrice représente une fleur.

Nous allons encoder les espèces dans un vecteur colonne $Y$ composé de nombres flottants.

* setosa = 1.0
* virginica = 2.0
* versicolor = 3.0

Lors de la phase d'apprentissage, le coût est exprimé de la manière suivante:

$cost = \dfrac{1}{m} \sum_{i=1}^m(X^{(i)}\cdot\Theta-Y^{(i)})^2$

Nous allons utiliser la méthode de descente de gradient pour optimiser le coût et obtenir les valeurs optimales de $\Theta$.

{{% notice info %}}
Il est possible d'avoir les valeurs exactes de $\Theta$ (celle qui minimisent le coût) en utilisant l'équation normale:
$$ \theta = \left( X^TX \right)^{-1}X^TY $$
Vous trouverez sur ce [gist](https://gist.github.com/owulveryck/19a5ba9553ff8209b3b4227b5325041b#file-normal-go)
une implémentation basique de la solution réalisée avec Gonum.
{{% /notice %}}

## Génération des données d'entrainement avec gota (dataframe)

Tout d'abord, générons les données d'entrainement. Nous utiliserons un dataframe pour nous simplifier la tâche.

{{% notice info %}}
Ce [howto](/how-to/dataframe/) donne plus d'information sur l'utilisation du dataframe
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

Cette fonction retourne deux matrices que nous pourrons utiliser avec Gorgonia.

### Creation de l'ExprGrap

L'équation $X\cdot\Theta$ est encodée en tant qu'[ExprGraph](/reference/exprgraph):

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

{{% notice warning %}}
Gorgonia est très optimisé; il fait utilise beaucoup les pointeurs pour optimiser son empreinte mémoire.
Par conséquemt, appeler la méthode `Value()` d'un `*Node` pendant la phase d'exécution du graphe, peut produire des résultats incorrects.
Pour accéder à la valeur contenue dans un `*Node` (pendant la phase d'apprentissage par exemple), il est nécessaire de garder une référence
pointant sur ladite valeur. C'est la raison pour laquelle nous utilisons la méthode `Read`.
`predicted` contient une référence à la valeur résultante de l'opération $X\cdot\Theta$.
{{% /notice %}}

## Préparation du calcul du gradient

Nous allons utiliser la fonctionnalité de Gorgonia: [Symbolic differentiation](/how-to/differentiation).

Tout d'abord, nous allons créer une fonction de coût, puis utiliser un [solver](/about/solver) pour faire la descente de gradient.

### Creation du "node" qui contiendra le coût de l'équation

Completons à présent l'[exprgraph](/reference/exprgraph) en ajoutant le coût (pour rappel, $cost = \dfrac{1}{m} \sum_{i=1}^m(X^{(i)}\cdot\Theta-Y^{(i)})^2$)

```go
squaredError := must(gorgonia.Square(must(gorgonia.Sub(pred, y))))
cost := must(gorgonia.Mean(squaredError))
```

Notre but est de minimiser ce coût. Nous allons donc calculer le gradient de la fonction par rapport à $\Theta$:

```go
if _, err := gorgonia.Grad(cost, theta); err != nil {
        log.Fatalf("Failed to backpropagate: %v", err)
}
```

### La descente du gradient

Nous utilisons le principe de descente de gradient. Ceci signifie que nous utilisons le gradient de la fonction pour
altérer le paramètre $\Theta$ pas à pas.

Une implémentation basique de descente de gradient est implémentée dans le [Vanilla Solver](https://godoc.org/gorgonia.org/gorgonia#VanillaSolver) de Gorgonia.
Nous positionnons le "pas" $\gamma$ à 0.001.

```go
solver := gorgonia.NewVanillaSolver(gorgonia.WithLearnRate(0.001))
```

À chaque étape, nous allons demander au solver de mettre à jour $\Theta$ grâce au gradient.
Par conséquent, nous assignons une variable `update` que nous allons passer au solver à chaque itération.

{{% notice info %}}
La descente de gradient va mettre à jour toutes les valeurs présentes dans le tableau `[]gorgonia.ValueGrad` à chqaue étape
suivant cette équation:
${\displaystyle x^{(k+1)}=x^{(k)}-\gamma \nabla f\left(x^{(k)}\right)}$
Il est important de comprendre que le solver travaille sur des [`Values`](/reference/value) et non des [`Nodes`](/reference/node).
Cependant, afin de simplifier les choses, l'interface `ValueGrad` est implémenté par la structure `*Node`.
{{% /notice %}}

Dans notre cas, nous voulons trouver les valeurs de $\Theta$; nous demandons au solver de mettre à jour la valeur en suivant cette équation:

${\displaystyle \Theta^{(k+1)}=\Theta^{(k)}-\gamma \nabla f\left(\Theta^{(k)}\right)}$

Le solver se charge d'implémenter l'équation. Nous devons simplement passer $\Theta$ a chaque `Step` du `Solver`:

```go
update := []gorgonia.ValueGrad{theta}
// ...
if err = solver.Step(update); err != nil {
        log.Fatal(err)
}
```

#### L'apprentissage

À présent que la mécanique est en place, nous devons lancer le calcul grâce à une [vm](/referemce/vm).
Ce calcul doit être lancé un grand nombre de fois pour que la descente de gradient puisse agir.

Créons à présent une [vm](/reference/vm) pour lancer le calcul.

```go
machine := gorgonia.NewTapeMachine(g, gorgonia.BindDualValues(theta))
defer machine.Close()
```

{{% notice warning %}}
Nous demandons au solver de mettre à jour le paramètre $\Theta$ par rapport au gradient.
Par conséquent nous devons dire à la TapeMachine de stocker la valeur de $\Theta$ *ainsi que* sa dérivée (sa dual value)
Ceci est la raison de l'utilisation de la fonction [BindDualValues](https://godoc.org/gorgonia.org/gorgonia#BindDualValues).
{{% /notice %}}

Maintenant nous pouvons créer une boucle et calculer le graphe étape par étape; la machine va apprendre!

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

#### Afficer des informations

Nous pouvons afficher des informations sur le processus d'apprentissage en utilisant cet appel:

```go
fmt.Printf("theta: %2.2f  Iter: %v Cost: %2.3f Accuracy: %2.2f \r",
        theta.Value(),
        i,
        cost.Value(),
        accuracy(predicted.Data().([]float64), y.Value().Data().([]float64)))
```

Avec la fonction `accuracy` définie de la manière suivante:

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

Ceci affichera une ligne semblable à celle ci pendant la phase d'apprentissage:

```text
theta: [ 0.26  -0.41   0.44  -0.62   0.83]  Iter: 26075 Cost: 0.339 Accuracy: 0.61
```

### Sauvegarde des données

Une fois l'entrainement terminé, nous pouvons sauvegarder les valeurs de $\Theta$ pour pouvoir les utiliser dans des prédictions:

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

## Création d'un utilitaire CLI

Nous allons à présent créer un utilitaire qui va permettre de donner l'espèce d'une fleur en fonction des paramètres d'entrée.

Tout d'abord, chargeons les paramètres que nous venons de sauvegarder lors de la phase d'entrainement.

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

Ensuite, créeons le modèle (l'exprgraph) d'une manière semblable à ce que nous avons fait auparavant:

{{% notice info %}}
Dans un développement logiciel, il serait probablement souhaitable de partager ce code entre les deux outils (training et execution) en l'isolant dans un package.
{{% /notice %}}

```go
g := gorgonia.NewGraph()
theta := gorgonia.NodeFromAny(g, thetaT, gorgonia.WithName("theta"))
values := make([]float64, 5)
xT := tensor.New(tensor.WithBacking(values))
x := gorgonia.NodeFromAny(g, xT, gorgonia.WithName("x"))
y, err := gorgonia.Mul(x, theta)
```

Ensuite nous executons une boucle infinie pendant laquelle nous allons demander les infos, calculer et afficher le résultat:

```go
machine := gorgonia.NewTapeMachine(g)
values[4] = 1.0
for {
        values[0] = getInput("sepal length")
        values[1] = getInput("sepal widt")
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

Voici une fonction utilitaire pour récupérer les entrées:

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

Il ne reste plus qu'à "builder" le code et voilà!
Nous avons un utilitaire autonome capable de prédire l'espèce d'une Irir en fonction de ses attributs:

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

Dans cet exemple pas-à-pas, nous avons construit un logiciel complet.

À présent vous pouvez poursuivre les tests en changeant les valeurs initiales de $\Theta$ ou en utilisant un autre solver fournit par Gorgonia.

Le code complet de ce tutoriel est présent dans le répertoire [examples](https://github.com/gorgonia/gorgonia/tree/master/examples) des sources de Gorgonia.

### Bonus: visual representation

Il est possible de visualiser le dataset en utilisant la bibliothèque plotter du projet Gonum.
Voici un exemple.

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
