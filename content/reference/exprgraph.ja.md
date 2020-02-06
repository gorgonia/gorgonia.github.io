---
title: "グラフと Exprgraph"
date: 2019-10-29T19:49:05+01:00
weight: -100
draft: false
---

計算グラフまたは式グラフについて多くのことが言われています。しかしそれらは正しいのでしょうか？あなたが望む数学表現の AST と考えてください。上記の例のグラフを次に示します(ただし代わりにベクトルとスカラーを追加します):

![graph1](https://raw.githubusercontent.com/gorgonia/gorgonia/master/media/exprGraph_example1.png)

ちなみに Gorgonia には素敵なグラフ印刷機能が備わっています。方程式 $y = x^2$ とその派生のグラフの例を次に示します:

![graph1](https://raw.githubusercontent.com/gorgonia/gorgonia/master/media/exprGraph_example2.png)

グラフを読むのは簡単です。式は下から上に構築され、派生は上から下に構築されます。これにより各ノードの導関数はほぼ同じレベルとなります。

赤枠のノードはそれがルート node であることを示します。緑のアウトラインノードは葉 node であることを示します。背景が黄色のノードは入力ノードであることを示しています。点線の矢印はどのノードがポイント先ノードのグラデーションノードであるかを示しています。

具体的には `c42011e840` ($\frac{\partial{y}}{\partial{x}}$) が入力 `c42011e000` (つまり $x$) の勾配ノードであると言います。
