---
title: "Commencer à contribuer à la documentation"
date: 2020-01-31T14:59:03+01:00
draft: false
---

Si vous souhaitez commencer à contribuer à la documentation de Gorgonia, cette page et ses points liés peuvent vous aider. Pas besoin d'être un développeur ou un rédacteur technique pour avoir un grand impact sur la documentation de Gorgonia et l'expérience utilisateur ! Pour les points de cette page, il vous suffit d'avoir un compte GitHub et un navigateur internet.

Si vous cherchez des informations sur comment contribuer aux dépôts de code de Gorgonia, consultez les [directives de contribution](https://github.com/gorgonia/gorgonia/blob/master/CONTRIBUTING.md).

### Les bases de la documentation

La documentation de Gorgonia est écrite en Markdown et traitée avec Hugo. Sa source est sur GitHub à ce lien https://github.com/gorgonia/gorgonia.github.io. La plupart de la source de la documentation est située dans `/content/`. 

Vous pouvez signaler les problèmes, modifier le contenu et examiner les modifications des autres, le tout à partir du site web GitHub. Vous pouvez également utiliser l'historique intégré et les outils de recherche de GitHub.

### Mise en page de la documentation

La documentation suit la mise en page décrite dans l'article [Ce que personne ne vous dit sur la documentation](https://www.divio.com/blog/documentation/).

Elle est divisée en 4 sections. Chaque section est un sous-répertoire dans le directoire `content/` du dépôt.

#### Les tutoriels
Un tutoriel :

- est orienté sur l'apprentissage
- aide un débutant à commencer
- est une leçon

Analogie: ça doit être comme apprendre à un enfant à cuisiner

Sources du contenu dans le dépôt : [`content/tutorials`](https://github.com/gorgonia/gorgonia.github.io/tree/develop/content/tutorials)

#### Les guides HOW-TO 
Un guide how-to :

- est orienté sur un objectif 
- montre comment résoudre un problème précis
- est une série d'étapes

Analogie: comme une recette dans un livre de cuisine

Sources du contenu dans le dépôt : [`content/how-to`](https://github.com/gorgonia/gorgonia.github.io/tree/develop/content/how-to)

#### Les explications
Une explication :

- est orientée sur la compréhension
- explique
- apporte du contexte 

Analogie : un article sur l'histoire sociale culinaire

Sources du contenu dans le dépôt : [`content/about`](https://github.com/gorgonia/gorgonia.github.io/tree/develop/content/about)

#### Les références
Un guide de référence :

- est orienté sur l'information
- décrit les mécanismes
- est précis et complet

Analogie : un article d'encyclopédie de référence

Sources du contenu dans le dépôt : [`content/reference`](https://github.com/gorgonia/gorgonia.github.io/tree/develop/content/reference)

### Plusieurs langues
La source de documentation est disponible en plusieurs langues dans / content /. Chaque page peut être traduite dans n'importe quelle langue en ajoutant un code à deux lettres déterminé par la [norme ISO 639-1] (https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes).
Un fichier sans suffixe est par défaut en anglais.

Par exemple, la documentation française d'une page s'appelle `page.fr.md`.

## Améliorer la documentation

### Corriger un contenu existant

Vous pouvez améliorer la documentation en corrigeant un bug ou une faute de frappe dans la doc.
Pour améliorer le contenu existant, vous déposez une _pull request (PR) _ après avoir créé une _fourche (fork) _. Ces deux termes sont [spécifiques à GitHub] (https://help.github.com/categories/collaborating-with-issues-and-pull-requests/).
Pour les besoins de cette rubrique, vous n'avez pas besoin de tout savoir à leur sujet, car vous pouvez tout faire à l'aide de votre navigateur Web.

### Créer de nouveaux contenus

{{% notice info %}}
Les sources du référentiel sont conservées dans la branche `develop`. Par conséquent, créez votre nouvelle branche dans `develop` et la PR doit également pointer vers cette branche.
{{% /notice %}}
Pour créer un nouveau contenu, merci de créer une nouvelle page dans le directoire correspondant au sujet de la doc (voir le paragraphe [Mise en page de la documentation](#layout-of-the-documentation))

Si vous avez `hugo` localement, vous pouvez créer une nouvelle page avec :

```shell
hugo new content/about/mypage.md
```

sinon, veuillez créer une nouvelle page avec un en-tête qui ressemble à :

```yaml
---
title: "The title of the page"
date: 2020-01-31T14:59:03+01:00
draft: false
---

your content
```
Ensuite, soumettez une PR comme expliqué ci-dessous.

### Soumettre une pull request (PR)
Suivez ces étapes pour soumettre une PR afin d'améliorer la documentation de Gorgonia.

-  Sur la page où vous voyez l'issue, cliquez sur l'icône "modifier cette page" en haut à droite.
Une nouvelle page GitHub apparaît, avec un texte d'aide.
-  Si vous n'avez jamais créé de fork du référentiel de documentation Gorgonia, vous êtes invité à le faire.
     Créez le fork sous votre nom d'utilisateur GitHub, plutôt que sous celui d'une autre organisation dont vous pouvez être membre.
     Le fork a généralement une URL type `https://github.com/ <username> / website`, sauf si vous avez déjà un référentiel avec un nom en conflit.

    La raison pour laquelle vous êtes invité à créer un fork est que vous n'avez pas accès aux droits pour créer une branche directement dans le référentiel Gorgonia définitif.

-  L'éditeur GitHub Markdown apparaît avec le fichier Markdown source.
     Faites vos changements. Sous l'éditeur, remplissez le formulaire ** Propose file change **.
     Le premier champ est le résumé de votre message de validation et ne doit pas contenir plus de 50 caractères.
     Le deuxième champ est facultatif, mais peut inclure plus de détails le cas échéant.
     Cliquez sur ** Propose file change **. La modification est enregistrée en tant que commit dans une nouvelle branche de votre fork, qui est automatiquement nommée quelque chose comme `patch-1`.
     
{{% notice info %}}
N'incluez pas de références à d'autres isuues GitHub ou pull requests dans votre message de validation. Vous pouvez les ajouter à la description de la pull request plus tard.
{{% /notice %}}


-  L'écran suivant résume les modifications que vous avez apportées, en comparant votre nouvelle branche (les cases de sélection **head fork** et **compare**) à la 
    **base fork** et **base** de la branche actuelle (`develop` dans le référentiel `gorgonia/gorgonia.github.io` par défaut). Vous pouvez modifier n'importe quelle
     boîte de sélection, mais ne le faites pas maintenant. Jetez un œil au visualisateur de différences en bas de l'écran, et si tout semble correct, cliquez sur
    **Create pull request**.

{{% notice info %}}
Si vous ne souhaitez pas créer la pull request maintenant, vous pouvez le faire
plus tard, en accédant à l'URL principale du référentiel du site Web Gorgonia ou
le référentiel de votre fork. Le site Web GitHub vous invite à faire une
pull request s'il détecte que vous avez poussé une nouvelle branche vers votre fork.
{{% /notice %}}

-  L'écran **Open a pull request** apparaît. L'objet de la pull request
     est le même que le résumé du commit, mais vous pouvez le modifier si nécessaire. le
     Le corps est rempli par votre message de validation (si présent) et du texte
     du modèle. Lisez le texte du modèle et remplissez les détails qu'il demande,
     puis supprimez le texte du modèle en trop.
     Si vous ajoutez `fixes #<000000>` ou `closes #<000000>` à la description, 
     avec `#<000000>` le numéro de l'issue associée, GitHub fermera automatiquement l'issue lors de l'intégration de la PR.
    Laissez la case **Allow edits from maintainers** sélectionnée. Cliquez sur **Create pull request**.

    Félicitations ! Votre pull request est disponible dans 
    [Pull requests](https://github.com/gorgonia/gorgonia.github.io/pulls).

{{% notice info %}}
Veuillez limiter vos pull requests à une langue par PR. Par exemple, si vous devez apporter une modification identique au même bout de code dans plusieurs langues, ouvrez une PR distincte pour chaque langue.
{{% /notice %}}

-  Attendez une relecture. 
    Si un relecteur vous demande de faire une modification, vous pouvez ouvrir l'onglet 
    **Files changed** et cliquer sur l'icône crayon ou n'importe quel fichier concerné par la pull request.
    Quand vous sauvegardez le fichier modifié, un nouveau commit est créé dans la branche de la pull request.
    Si vous attendez qu'un relecteur relise les modifications, relancez-le tous les 7 jours.
   Vous pouvez aussi accéder à la chaîne `#gorgonia` sur [gopherslack](https://invite.slack.golangbridge.org/),
    bon endroit pour demander de l'aide sur les relectures de PR.

-  Si votre modification est acceptée, un réviseur valide votre pull request et le
     le changement se fait en direct sur le site Web de Gorgonia quelques minutes plus tard.

Ce n'est qu'une manière de soumettre une pull request. Si vous êtes déjà un utilisateur avancé de GitHub, 
vous pouvez utiliser une interface graphique locale ou un client Git en ligne de commande
au lieu d'utiliser l'interface utilisateur de GitHub.
