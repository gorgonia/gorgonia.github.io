---
title: "Gorgonia"
date: 2019-10-29T14:59:59+01:00
draft: false
---

# Gorgonia

Gorgonia est une bibliothèque qui facilite la mise en place de mécanismes de machine learning en Go.

Elle permet d'écrire et de calculer des équations mathématiques utilisant des tableaux à multiples dimensions.

Dans l'idée, cette bibliothèque est semblable à Theano et TensorFlow.

D'une manière générale, cette bibliothèque est relativement bas-niveau, comme Theano, mais possède des objectifs plus ambitieux comme
TensorFlow.


## Pourquoi utiliser Gorgonia ?

La cible principale de Gorgonia est de rendre l'expérience du développeur agréable.
So vous êtes un Gopher, grâce à Gorgonia, vous avez la possibilité de créer des systèmes utilisant le machine learning qui
soient "production-ready".

Le développement en IA/ML est généralement divisé en deux étapes:

* Les expériences pendant lesquels sont conçus les modèles, et pendant lesquels beaucoup de tests sont réalisés.
* La phase de déploiement pendant laquelle les modèles sont industrialisés pour être opérés à l'échelle.

Ces différentes phases sont associées à divers métiers tels que data-scientiste ou data-ingénieur.

D'une manière générale, ces deux étapes ne sont pas réalisées en utilisant les mêmes outils:

* Python/Lua (et les frameworks de type [Theano](http://deeplearning.net/software/theano/), [Torch](http://torch.ch/), etc), sont
couramment utilisés dans les phases d'expérimentation.
* Durant les phases d'exploitation et de déploiement, le modèle est en général réécrit dans un langage plus performant tel que le C++.
(en utilisant par exemple [dlib](http://dlib.net/ml.html), [mlpack](http://mlpack.org) etc).

Bien entendu, de nos jours, l'écart de performance entre les outils se réduit, ce qui aboutit à un partage des outils entre les différentes phases.
TensorFlow est un exemple d'outil qui est utilisé dans les deux étapes du développement et qui opère comme un pont entre deux.

Le but de Gorgonia est le même, mais dans l'écosystème Go.
Gorgonia est performant. Sa vitesse d'exécution sur CPU est comparable à Theano et TensorFlow.
Les implémentations GPU sont plus délicates à comparer dû à la charge induite par l'utilisation de CGO. Cette partie est en développement
actif.

### Organisation de ce site web

Ce site web est composé de 4 sections ayant différents objectifs:

{{% children description="true" %}}
