[sdl](../../index.md) › [sdl.system](index.md) › CpuInfo

# CpuInfo

`sdl.system` 包中的 public struct

CPU 与内存能力快照：核心数、缓存行、内存与页大小，以及各 SIMD 指令集的可用性。字段全部带默认值（0/`false`），`CpuInfo()` 构造空白值后由 [`cpuInfo`](functions.md#cpuinfo) 填充。

## 声明

```cangjie
public struct CpuInfo
```

## 示例

```cangjie verify
package docexample

import sdl.system.{CpuInfo, cpuInfo}

main(): Unit {
    let cpu: CpuInfo = cpuInfo()
    println(cpu.logicalCores > 0)
    println(cpu.systemRamMb > 0)
    // 输出:
    // true
    // true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建字段均为 0 或 `false` 的空白 CPU 信息快照。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`logicalCores`](#logicalcores) | 逻辑核心数。 |
| [`cacheLineBytes`](#cachelinebytes) | CPU 缓存行大小，字节。 |
| [`systemRamMb`](#systemrammb) | 系统内存，MB。 |
| [`pageBytes`](#pagebytes) | 内存页大小，字节。 |
| [`hasAltiVec`](#hasaltivec) | 支持 AltiVec（PowerPC SIMD）。 |
| [`hasMmx`](#hasmmx) | 支持 MMX。 |
| [`hasSse`](#hassse) | 支持 SSE。 |
| [`hasSse2`](#hassse2) | 支持 SSE2。 |
| [`hasSse3`](#hassse3) | 支持 SSE3。 |
| [`hasSse41`](#hassse41) | 支持 SSE4.1。 |
| [`hasSse42`](#hassse42) | 支持 SSE4.2。 |
| [`hasAvx`](#hasavx) | 支持 AVX。 |
| [`hasAvx2`](#hasavx2) | 支持 AVX2。 |
| [`hasAvx512F`](#hasavx512f) | 支持 AVX-512 基础指令。 |
| [`hasArmSimd`](#hasarmsimd) | 支持 ARM SIMD。 |
| [`hasNeon`](#hasneon) | 支持 NEON。 |
| [`hasLsx`](#haslsx) | 支持龙芯 LSX。 |
| [`hasLasx`](#haslasx) | 支持龙芯 LASX。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建字段均为 0 或 `false` 的空白 CPU 信息快照。

```cangjie
public init()
```

## 字段

### logicalCores

逻辑核心数。

```cangjie
public var logicalCores: Int32 = 0
```

### cacheLineBytes

CPU 缓存行大小，字节。

```cangjie
public var cacheLineBytes: Int32 = 0
```

### systemRamMb

系统内存，MB。

```cangjie
public var systemRamMb: Int32 = 0
```

### pageBytes

内存页大小，字节。

```cangjie
public var pageBytes: Int32 = 0
```

### hasAltiVec

支持 AltiVec（PowerPC SIMD）。

```cangjie
public var hasAltiVec: Bool = false
```

### hasMmx

支持 MMX。

```cangjie
public var hasMmx: Bool = false
```

### hasSse

支持 SSE。

```cangjie
public var hasSse: Bool = false
```

### hasSse2

支持 SSE2。

```cangjie
public var hasSse2: Bool = false
```

### hasSse3

支持 SSE3。

```cangjie
public var hasSse3: Bool = false
```

### hasSse41

支持 SSE4.1。

```cangjie
public var hasSse41: Bool = false
```

### hasSse42

支持 SSE4.2。

```cangjie
public var hasSse42: Bool = false
```

### hasAvx

支持 AVX。

```cangjie
public var hasAvx: Bool = false
```

### hasAvx2

支持 AVX2。

```cangjie
public var hasAvx2: Bool = false
```

### hasAvx512F

支持 AVX-512 基础指令。

```cangjie
public var hasAvx512F: Bool = false
```

### hasArmSimd

支持 ARM SIMD。

```cangjie
public var hasArmSimd: Bool = false
```

### hasNeon

支持 NEON。

```cangjie
public var hasNeon: Bool = false
```

### hasLsx

支持龙芯 LSX。

```cangjie
public var hasLsx: Bool = false
```

### hasLasx

支持龙芯 LASX。

```cangjie
public var hasLasx: Bool = false
```

## 另请参阅

- [cpuInfo](functions.md#cpuinfo) — 查询入口。
