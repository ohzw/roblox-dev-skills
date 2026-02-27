# Quality Gate: セルフレビュー & 動作確認ルール

コード変更後、作業完了を宣言する前に以下のゲートを **必ず** 通過すること。

---

## Gate 1: rojo build 検証

全ファイル変更後、必ず `rojo build -o /tmp/bumper-battle-check.rbxl` を実行し、ビルドエラーがないことを確認する。

```bash
rojo build -o /tmp/bumper-battle-check.rbxl
```

失敗した場合はエラーを修正してから次に進む。

---

## Gate 2: Luau 構文セルフレビュー

変更した全 `.luau` ファイルを Read で再読し、以下のチェックリストを確認する：

### 必須チェック項目

- [ ] **型アノテーション構文**: テーブルプロパティ代入に型アノテーションを付けていないか
  ```lua
  -- NG: Luau はテーブルプロパティ代入に型注釈を許可しない
  Module.ITEMS: { string } = { "A", "B" }

  -- OK: キャスト構文を使う
  Module.ITEMS = { "A", "B" } :: { string }

  -- OK: 型注釈を省略する（自明な場合）
  Module.ITEMS = { "A", "B" }
  ```

- [ ] **メソッドチェーン**: 関数呼び出し結果に直接 `:Method()` をチェーンしていないか
  ```lua
  -- NG: パーサーが混乱する
  ClientRemotes.SomeEvent():OnClientEvent:Connect(handler)

  -- OK: 一時変数に分ける
  local remote = ClientRemotes.SomeEvent()
  remote.OnClientEvent:Connect(handler)
  ```

- [ ] **pcall ラッピング**: RemoteFunction の `InvokeServer()` は pcall で囲んでいるか
  ```lua
  local success, result = pcall(function()
      return remote:InvokeServer(args)
  end)
  if not success then return end
  ```

- [ ] **export type の配置**: `export type` はモジュールのトップレベルで宣言しているか（関数内ではないか）

- [ ] **string interpolation**: バッククォート内で `{expression}` を使う際に構文が正しいか
  ```lua
  -- OK
  Text = `Lv.{level}`

  -- NG: Luau は ${} ではなく {} を使う
  Text = `Lv.${level}`
  ```

- [ ] **コイン操作のアトミック性**: DataStoreManager.transaction を使っているか（get→加算→set の分離は不可）

- [ ] **ロック解放の安全性**: processingLock 等を使う場合、pcall でラップし finally 相当で必ず解放しているか

- [ ] **メモリリーク**: `.Destroying` や cleanup 関数でイベント接続を切断しているか

---

## Gate 3: Roblox MCP 動作確認

Roblox Studio が起動している場合、`mcp__roblox__run_code` を使って実機確認を行う。

### 3a. モジュール存在確認

新規ファイル作成後、Studio 上で存在を確認：

```lua
-- 例: 新規サービスの存在確認
local ok, err = pcall(function()
    return require(game.ServerScriptService.services.LevelService)
end)
print("LevelService loaded:", ok, err)
```

### 3b. RemoteEvent/Function 確認

remotes.luau を変更した場合、Remote インスタンスの存在を確認：

```lua
local remotes = game.ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
    for _, child in remotes:GetChildren() do
        print(child.ClassName, child.Name)
    end
end
```

### 3c. ランタイムエラー確認

Play mode (F5) 実行後、Output のエラーを確認：

```lua
-- Studio の Output ウィンドウに赤いエラーが出ていないか確認
-- MCP で直接確認できない場合はユーザーに確認を依頼
```

### 3d. UI 表示確認（可能な場合）

```lua
-- PlayerGui 内の ScreenGui 存在確認
local player = game.Players:GetPlayers()[1]
if player then
    local gui = player:FindFirstChild("PlayerGui")
    if gui then
        for _, sg in gui:GetChildren() do
            if sg:IsA("ScreenGui") then
                print("ScreenGui:", sg.Name, "Enabled:", sg.Enabled)
            end
        end
    end
end
```

---

## Gate 4: 変更影響チェック

### 依存モジュールの確認

変更したファイルを `require()` している他のファイルを Grep で検索し、破壊的変更がないか確認する。

```
例: LevelConfig.luau を変更した場合
→ Grep: "LevelConfig" で全ファイルを検索
→ 参照元が新しいAPIと互換性があるか確認
```

### 初期化順序の確認

サービスを追加・変更した場合、`main.server.luau` と `main.client.luau` の初期化順序が依存関係を満たしているか確認する。

---

## 適用タイミング

| シナリオ | 必須ゲート |
|---------|-----------|
| 新規 .luau ファイル作成 | Gate 1 + 2 + 3a + 4 |
| 既存 .luau ファイル編集 | Gate 1 + 2 + 4 |
| remotes.luau 変更 | Gate 1 + 2 + 3b + 4 |
| UI コンポーネント変更 | Gate 1 + 2 + 3d |
| 全作業完了時 | Gate 1 + 2 + 3 (全項目) + 4 |

---

## よくある Luau の罠（過去のバグから）

1. **テーブルプロパティへの型注釈** → キャスト構文 `:: Type` を使うか省略
2. **関数呼び出し結果へのメソッドチェーン** → 一時変数に分割
3. **boolean と string の型混在** → 一貫した型を選択（例: `""` / `"completed"` で統一）
4. **InvokeServer のエラーハンドリング不足** → 必ず pcall
5. **コイン操作の非アトミック性** → DataStoreManager.transaction を使用
6. **ロック未解放** → pcall + finally パターン
7. **Character 破棄時のクリーンアップ漏れ** → `.Destroying` で接続切断
