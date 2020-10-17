---
title: "Language dédié et glossaire"
date: 2020-02-05T16:45:51+01:00
draft: false
---
Cette page contient diverses définitions et un glossaire vous permettant de comprendre Gorgonia et de communiquer avec l'équipe (via PR ou issues).

## Tenseurs

* **inner(most) dimension(s)** (dimensions intérieures (maximales))- pour une forme donnée, les dimensions intérieures tendent vers la droite. Par exemple, dans une forme (2,3,4), les dimensions intérieures sont (3, 4). La dimension intérieure maximale est 4.
* **outer(most) dimension(s)** (dimensions exérieures (maximales))- Pour une forme donnée, les dimensions extérieures tendent vers la gauche. Par exemple, dans une forme (2,3,4), les dimensions extérieures sont (2, 3). La dimension extérieure maximale est 2.
* **vector** (vecteur) - pour un tenseur de rang 1; par exemple (2), (3) ... les vecteurs vont s'écrire `[...]`
* **column vector** (or **colvec**) (colonnes de vecteurs) -un tenseur de rang 2 (par exemple une matrice) avec des dimensions intérieures comme 1, par exemple (2, 1), (3, 1)...
* **row vector** (vecteur de ligne) - un tenseur de rang 2 (par exemple une matrice) avec la dimension extérieure 1; par exemple (1, 2), (1, 3)...
* **matrix** (matrice) un tenseur de rang -2, avec des dimensions intérieures et extérieures aléatoires; par exemple (1, 2), (2, 1), (2, 3)... les matrices vont être notées en écriture intégrale dans ce doc. Ceci inclut les vecteurs colonnes et les vecteurs lignes.
