---
title: "LispMachine"
date: 2019-10-29T19:50:15+01:00
draft: false
---

`LispMachine` はグラフを入力として受け取るように設計されており、グラフのノードで直接実行されます。
グラフが変更された場合は、単純に新しい軽量 `LispMachine` を作成して実行します。
`LispMachine` はサイズが固定されていない recurrent neural networks の作成などのタスクに適しています。

トレードオフとしては `LispMachine` でのグラフの実行が `TapeMachine` での実行よりも一般に遅いことです。
グラフの同じ静的な "画像" が与えられます。
