# SwiftTorch — Fabric 26.3

Author: `nekodon`

Modrinth: [SwiftTorch](https://modrinth.com/mod/swifttorch)

## English

### Overview

SwiftTorch is a Fabric mod that lets you place torches from your inventory without switching away from your pickaxe.

### Usage

Hold a pickaxe in your main hand and right-click a block. If a torch is available in your inventory, SwiftTorch places it on the clicked surface.

Normal block interactions take priority. Chests, doors, buttons, and other interactive blocks continue to work normally. Hold the sneak key while right-clicking to temporarily disable SwiftTorch and use vanilla behavior.

Items held in the offhand are not used or consumed when SwiftTorch places a torch.

### Requirements

- Minecraft 26.3
- Fabric Loader 0.20.1 or newer
- Fabric API
- Java 25

Install SwiftTorch on both the client and server.

### Building

```text
./gradlew build
```

The generated JAR is placed in `build/libs`.

---

## 日本語

### 概要

SwiftTorchは、ツルハシから持ち替えずにインベントリ内の松明を設置できるFabric製MODです。

### 使い方

メインハンドにツルハシを持ち、ブロックを右クリックします。インベントリに松明があれば、クリックした面へ自動的に設置します。

チェスト、ドア、ボタンなどの通常のブロック操作が優先されます。スニークしながら右クリックするとSwiftTorchを一時的に無効化し、バニラの動作を使用できます。

SwiftTorchによる松明設置時に、オフハンドのアイテムが使用・消費されることはありません。

### 必要環境

- Minecraft 26.3
- Fabric Loader 0.20.1以上
- Fabric API
- Java 25

クライアントとサーバーの両方に導入してください。

### ビルド

```text
./gradlew build
```

生成されたJARは `build/libs` に出力されます。
