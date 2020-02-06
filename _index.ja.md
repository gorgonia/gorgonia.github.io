+++
title = "Gorgonia はどの様に動作するのか"
date = 2019-10-28T11:41:02+01:00
description = "Gorgonia の仕組みを説明することを目的とした記事。"
weight = -9
chapter = true
+++

# はじめに

Gorgonia は計算グラフを作成して実行することで動作します。言わばプログラミング言語と考えてください。ただし数学関数に限定されており、分岐機能はありません(if/then やループもありません)。実際、これはユーザーが考える事に慣れているる必要がある支配的なパラダイムです。計算グラフは [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree) です。

BrainScript を使用した Microsoftの [CNTK](https://github.com/Microsoft/CNTK) は、計算グラフの構築と計算グラフの実行はおそらく異なるものであり、ユーザーはそれらを扱う時には異なる思考モードになる必要があります。

Gorgonia の実装は、CNTK の BrainScript ほど思考の分離を強制しません。構文がそれを補助します。

## もっと遠くへ

この章には Gorgonia の仕組みを説明することを目的とした記事が含まれています。

{{% notice info %}}
このセクションの記事は理解を目的としており、背景とコンテキストを提供します。
{{% /notice %}}

{{% children description="true" %}}

