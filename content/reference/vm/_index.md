---
title: "VM"
date: 2019-10-29T14:59:59+01:00
draft: false
---

A VM in Gorgonia is object that understands the exprgraph and has implemented the ability to do computation with it.

Techically speaking it is an `interface{}` with three methods:

```go
type VM interface {
    RunAll() error
    Reset()

    // Close closes all the machine resources (CUDA, if any, loggers if any)
    Close() error
}
```

There different VMs in the current version of Gorgonia:

{{% children %}}

They function differently and take different inputs.
