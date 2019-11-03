+++
title = "Fonctionnement de Gorgonia"
date = 2019-10-28T11:41:02+01:00
description = "Suite d'articles pour expliquer le fonctionnement de Gorgonia"
weight = -9
chapter = true
pre = "<b>X. </b>"
+++

# À propos

Gorgonia fonctionne en créant un graphe de calcul et en l'exécutant.
C'est en quelque sorte un langage de programmation, mais limité aux fonctions mathématiques sans capacité de branche (pas d'instructions conditionnelles
if/else ou de boucles).
C'est le paradigme dominant que l'utilisateur doit avoir en tête.
Le graphe de calcul est un [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree).

[CNTK](https://github.com/Microsoft/CNTK) de Microsoft, avec le BrainScript,
représente probablement le meilleur exemple de cette idée que construire et exécuter le graphe sont deux choses distinctes.
L'utilisateur dois penser différemment la construction du graphe et son exécution.

Cependant que l'implémentation utilisée par Gorgonia ne force pas la séparation des choses de manière aussi poussée que Brainscript.

## Pour aller plus loin

Ce chapitre contient des articles ayant pour but d'expliquer comment Gorgonia fonctionne.

{{% notice info %}}
Les articles de cette section focus surla compréhension des choses. Chaque article est auto suffisant et fournit le context nécessaire à la compréhension.
{{% /notice %}}

{{% children description="true" %}}
