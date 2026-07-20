[sdl](../../index.md) › [sdl.dialogs](index.md) › MessageBoxButton

# MessageBoxButton

`sdl.dialogs` 包中的 public struct

消息框中的一个按钮：标签、返回给调用者的编号，以及是否绑定回车/Esc 快捷键。

## 声明

```cangjie
public struct MessageBoxButton
```

## 示例

```cangjie verify
package docexample

import sdl.dialogs.MessageBoxButton

main(): Unit {
    let ok = MessageBoxButton("确定", id: 1, returnKeyDefault: true)
    let cancel = MessageBoxButton("取消", id: 0, escapeKeyDefault: true)
    println("${ok.label}=${ok.id} 回车默认=${ok.returnKeyDefault}；${cancel.label}=${cancel.id}")
    // 输出: 确定=1 回车默认=true；取消=0
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(label: String, id!: Int32, returnKeyDefault!: Bool, escapeKeyDefault!: Bool)`](#init) | 由标签与编号构造，快捷键绑定可选。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`id`](#id) | 按钮编号；用户点击后由 `showMessageBox` 返回。 |
| [`label`](#label) | 按钮文字。 |
| [`returnKeyDefault`](#returnkeydefault) | 是否绑定回车键。 |
| [`escapeKeyDefault`](#escapekeydefault) | 是否绑定 Esc 键。 |

## 构造函数

### init

由标签与编号构造，快捷键绑定可选。

```cangjie
public init(label: String, id!: Int32, returnKeyDefault!: Bool = false, escapeKeyDefault!: Bool = false)
```

**参数**

- `label`: `String` — 按钮文字。
- `id!`: `Int32` — 按钮编号，点击后由 [`showMessageBox`](functions.md#showmessagebox) 返回。
- `returnKeyDefault!`: `Bool` — 绑定回车键；默认 `false`。
- `escapeKeyDefault!`: `Bool` — 绑定 Esc 键；默认 `false`。

## 字段

### id

按钮编号；用户点击后由 `showMessageBox` 返回。

```cangjie
public let id: Int32
```

### label

按钮文字。

```cangjie
public let label: String
```

### returnKeyDefault

是否绑定回车键。

```cangjie
public let returnKeyDefault: Bool
```

### escapeKeyDefault

是否绑定 Esc 键。

```cangjie
public let escapeKeyDefault: Bool
```

## 另请参阅

- [MessageBoxOptions](MessageBoxOptions.md) — 携带按钮列表。
