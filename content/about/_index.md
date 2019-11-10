+++
title = "How Gorgonia works"
date = 2019-10-28T11:41:02+01:00
description = "Articles with a goal to explain how gorgonia works."
weight = -9
chapter = true
+++

# about

Gorgonia works by creating a computation graph, and then executing it. Think of it as a programming language, but is limited to mathematical functions, and has no branching capability (no if/then or loops). In fact this is the dominant paradigm that the user should be used to thinking about. The computation graph is an [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree).

Microsoft's [CNTK](https://github.com/Microsoft/CNTK), with its BrainScript, is perhaps the best at exemplifying the idea that building of a computation graph and running of the computation graphs are different things, and that the user should be in different modes of thoughts when going about them.

Whilst Gorgonia's implementation doesn't enforce the separation of thought as far as CNTK's BrainScript does, the syntax does help a little bit.

## going further

This chapter contains articles with a goal to explain how gorgonia works.

{{% notice info %}}
The articles in this section are understanding-oriented, and provides background and context.
{{% /notice %}}

{{% children description="true" %}}
