---
title: "VM"
date: 2019-10-29T14:59:59+01:00
draft: false
---

Gorgonia の VM は exprgraph を理解し、それを使用して計算を実行する機能を実装したオブジェクトです。

技術的に言えば、3つのメソッドを持つ `interface {}` です:

```go
type VM interface {
    RunAll() error
    Reset()

    // Close closes all the machine resources (CUDA, if any, loggers if any)
    Close() error
}
```

現在のバージョンの Gorgonia にはさまざまな VM があります。

{{% children %}}

機能が異なり、入力も異なります。
