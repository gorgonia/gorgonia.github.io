---
title: "Start contributing to the doc"
date: 2020-01-31T14:59:03+01:00
draft: false
---

If you want to get started contributing to the Gorgonia documentation, this page and its linked topics can help you get started. You don't need to be a developer or a technical writer to make a big impact on the Gorgonia documentation and user experience! All you need for the topics on this page is a GitHub account and a web browser.

If you're looking for information on how to start contributing to Gorgonia code repositories, refer to the [Contribution guidelines](https://github.com/gorgonia/gorgonia/blob/master/CONTRIBUTING.md).

### The basics about the docs

The Gorgonia documentation is written in Markdown and processed and deployed using Hugo. The source is in GitHub at https://github.com/gorgonia/gorgonia.github.io. Most of the documentation source is stored in `/content/`. 

You can file issues, edit content, and review changes from others, all from the GitHub website. You can also use GitHub's embedded history and search tools.

### Layout of the documentation

The documentation follows the layout described in the post [What nobody tells you about documentation](https://www.divio.com/blog/documentation/).

It is is divided in 4 sections. Each section is a subdirectory in the `content/` directory of the repository.

#### Tutorials
A tutorial:

- is learning-oriented
- allows the newcomer to get started
- is a lesson

Analogy: teaching a small child how to cook

Sources of the content in the repo: [`content/tutorials`](https://github.com/gorgonia/gorgonia.github.io/tree/develop/content/tutorials)

#### HOW-TO Guides
A how-to guide:

- is goal-oriented
- shows how to solve a specific problem
- is a series of steps

Analogy: a recipe in a cookery book

Sources of the content in the repo: [`content/how-to`](https://github.com/gorgonia/gorgonia.github.io/tree/develop/content/how-to)

#### Explanation
An explanation:

- is understanding-oriented
- explains
- provides background and context

Analogy: an article on culinary social history

Sources of the content in the repo: [`content/about`](https://github.com/gorgonia/gorgonia.github.io/tree/develop/content/about)

#### Reference
A reference guide:

- is information-oriented
- describes the machinery
- is accurate and complete

Analogy: a reference encyclopaedia article

Sources of the content in the repo: [`content/reference`](https://github.com/gorgonia/gorgonia.github.io/tree/develop/content/reference)

### Multiple languages
Documentation source is available in multiple languages in /content/. Each page can be translated in any language by adding a two-letter code determined by the [ISO 639-1 standard](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes). 
A file without any suffix defaults to English.

For example, French documentation of a page is named `page.fr.md`.

## Improve documentation

### fix existing content

You can improve the documentation by fixing a bug or a typo in the doc.
To improve existing content, you file a _pull request (PR)_ after creating a _fork_. Those two terms are [specific to GitHub](https://help.github.com/categories/collaborating-with-issues-and-pull-requests/).
For the purposes of this topic, you don't need to know everything about them, because you can do everything using your web browser. 

### Create new content.

{{% notice info %}}
The sources of the repository are maintained in the `develop` branch. Therefore, this branch must be the base of a new branch and PR should be point to this branch as well.
{{% /notice %}}
To create a new content, please create a new page in the directory corresponding to the topic of the doc (see the paragraph [Layout of the documentation](#layout-of-the-documentation))

If you have `hugo` locally, you can create a new page with:

```shell
hugo new content/about/mypage.md
```

otherwise, please create a new page with a header that looks like:

```yaml
---
title: "The title of the page"
date: 2020-01-31T14:59:03+01:00
draft: false
---

your content
```
Then submit a pull request as explained below.

### Submit a pull request
Follow these steps to submit a pull request to improve the Gorgonia documentation.

-  On the page where you see the issue, click the "edit this page" icon at the top right.
    A new GitHub page appears, with some help text.
-  If you have never created a fork of the Gorgonia documentation repository, you are prompted to do so. 
    Create the fork under your GitHub username, rather than another organization you may be a member of. 
    The fork usually has a URL such as `https://github.com/<username>/website`, unless you already have a repository with a conflicting name.

    The reason you are prompted to create a fork is that you do not have access to push a branch directly to the definitive Gorgonia repository.

-  The GitHub Markdown editor appears with the source Markdown file loaded.
    Make your changes. Below the editor, fill in the **Propose file change** form. 
    The first field is the summary of your commit message and should be no more than 50 characters long. 
    The second field is optional, but can include more detail if appropriate.
    Click **Propose file change**. The change is saved as a commit in a new branch in your fork, which is automatically named something like `patch-1`.

{{% notice info %}}
Do not include references to other GitHub issues or pull
requests in your commit message. You can add those to the pull request
description later.
{{% /notice %}}


-  The next screen summarizes the changes you made, by comparing your new branch (the **head fork** and **compare** selection boxes) to the current
    state of the **base fork** and **base** branch (`develop` on the `gorgonia/gorgonia.github.io` repository by default). You can change any of the
    selection boxes, but don't do that now. Have a look at the difference viewer on the bottom of the screen, and if everything looks right, click
    **Create pull request**.

{{% notice info %}}
If you don't want to create the pull request now, you can do it
later, by browsing to the main URL of the Gorgonia website repository or
your fork's repository. The GitHub website will prompt you to create the
pull request if it detects that you pushed a new branch to your fork.
{{% /notice %}}

-  The **Open a pull request** screen appears. The subject of the pull request
    is the same as the commit summary, but you can change it if needed. The
    body is populated by your extended commit message (if present) and some
    template text. Read the template text and fill out the details it asks for,
    then delete the extra template text. If you add to the description `fixes #<000000>`
    or `closes #<000000>`, where `#<000000>` is the number of an associated issue,
    GitHub will automatically close the issue when the PR merges.
    Leave the **Allow edits from maintainers** checkbox selected. Click
    **Create pull request**.

    Congratulations! Your pull request is available in
    [Pull requests](https://github.com/gorgonia/gorgonia.github.io/pulls).

{{% notice info %}}
Please limit pull requests to one language per PR. For example, if you need to make an identical change to the same code sample in multiple languages, open a separate PR for each language.
{{% /notice %}}

-  Wait for review. 
    If a reviewer asks you to make changes, you can go to the **Files changed**
    tab and click the pencil icon on any files that have been changed by the
    pull request. When you save the changed file, a new commit is created in
    the branch being monitored by the pull request. If you are waiting on a
    reviewer to review the changes, proactively reach out to the reviewer
    once every 7 days. You can also drop into `#gorgonia` channel on [gopherslack](https://invite.slack.golangbridge.org/),
    which is a good place to ask for help regarding PR reviews.

-  If your change is accepted, a reviewer merges your pull request, and the
    change is live on the Gorgonia website a few minutes later.

This is only one way to submit a pull request. If you are already a Git and
GitHub advanced user, you can use a local GUI or command-line Git client
instead of using the GitHub UI. 
