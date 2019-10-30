# About

Thie repository contains the sources and the website of gorgonia.org.

The website is hosted in the `master` branch, and the sources are in the `develop` branch.

## How to contribute:

The default branch for sources is `develop`.

```
git clone https://github.com/gorgonia/gorgonia.github.io.git
git submodule init
git submodule update
```

### Fix existing content

locate the source within the `develop` branch under the `content` subdirectory.
Fix it and create a PR against the develop branch of this repository.
You can also use the link "edit on github" on the top right corner of the corresponding page on the gorgonia.org website.

### Create new content

To add some new content to one of the sections, please use the command

`hugo new section/my-content.md`

where section is one of:

* about
* how-to
* reference
* tutorials

Edit the corresponding file and create a PR against the develop branch

### Test your dev

Test your developments from the `src` subdirectory with:

```
hugo -D serve
```

## Going live

This repo uses github actions to deploy the content; every event on develop triggers the build and deploy the website
on master. Please ask a review of your content in doubt.


## vanity import (for the Gorgonia team)

Vanity import paths are handled by hugo.

#### Add a new repository

To add a new go-gettable repository, add a file in the `content/vanity-import-paths` subdir.

#### Add a subpackage

To add a new subpackage to an existing repository, add an entry in the `aliases` array within the md of the repository.
