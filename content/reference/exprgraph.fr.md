---
title: "Graph / Exprgraph"
date: 2019-10-29T19:49:05+01:00
weight: -100
draft: false
---

Beaucoup de choses ont été dites sur les graphes de calcul ou sur les graphes d'expression.   Mais qu'est-ce donc en fait? Considérez les comme des AST (arbres d'expression syntaxique) pour l'expression de façon mathématique de ce que vous voulez. 
Voici pour exemple un graphe (mais avec un vecteur et une addition scalaire à la place):

![graph1](https://raw.githubusercontent.com/gorgonia/gorgonia/master/media/exprGraph_example1.png)

Gorgonia permet de présenter les capacités avec un graphe agréable.
Voici par exemple le graphe de l'équation $y = x^2$ et sa dérivation:

![graph1](https://raw.githubusercontent.com/gorgonia/gorgonia/master/media/exprGraph_example2.png)

Lire le graphe est chose facile. L'expression est construite de bas en haut, pendant que les dérivations sont construites de haut en bas. De cette façon, la dérivative de chaque noeud est grossièrement au même niveau.

Le marquage en rouge autour d'un noeud indique qu'il s'agit d'un noeud principal. Les noeuds en coloris vert sont des noeuds feuille. Les noeuds avec un fond jaune sont des noeuds d'entrée. 
Les flèches pointillées indiquent quel noeud est le noeud gradient pour le noeud pointé.


Concrétement, ça indique que `c42011e840` ($\frac{\partial{y}}{\partial{x}}$) est le noeud gradient pour l'entrée `c42011e000` (qui est $x$).
