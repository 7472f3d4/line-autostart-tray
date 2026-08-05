# line-autostart-tray

Windows ログオン時に LINE を自動起動し、メインウィンドウをトレイへ格納して常駐させる PowerShell スクリプトです。

## 背景

LINE for Windows には、Discord のような「起動直後からトレイに常駐する」オプションがありません。このスクリプトは LINE を通常起動したあと、ウィンドウが安定して表示されるタイミングを見計らって自動的に閉じる（＝トレイに格納する）ことで、疑似的な常駐起動を実現します。

## 特徴

- ログイン時に LINE を自動起動
- メインウィンドウ出現から約 2.5 秒後にトレイへ格納（実測値に基づくタイミング調整）
  - LINE はウィンドウ出現の約 1.9 秒後に一度だけ再表示する仕様があるため、それを越えたタイミングで閉じることで安定して定着します
- プロセス自体は終了させず、バックグラウンドに常駐したまま
- 対象ウィンドウは「可視」「タイトルに `LINE` を含む」「クラス名が `QWindowIcon` で終わる」「トップレベル」の条件で厳密に絞り込み、誤って他のウィンドウを閉じないようにしています

## 使い方

### 手動実行

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\startup_line.ps1
```

### Windows ログオン時に自動実行

タスクスケジューラ、またはスタートアップフォルダ（`shell:startup`）にこのスクリプトを呼び出すショートカットを登録してください。

```powershell
powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\path\to\startup_line.ps1"
```

## 注意

- LINE の実行ファイルパスは `%LOCALAPPDATA%\LINE\bin\LineLauncher.exe` を前提にしています。環境によって異なる場合はスクリプト内のパスを調整してください。
- LINE のアップデートでウィンドウのクラス名や再表示の挙動が変わった場合、タイミング調整（2.5 秒待機など）が合わなくなる可能性があります。動作しなくなった場合は `startup_line.ps1` 内のウィンドウ判定条件を見直してください。
- LINE 自体の「Windows 起動時に自動起動」設定は無効化しておくことを推奨します（二重起動を防ぐため）。

## 必要環境

- Windows 10 / 11
- PowerShell 5.1 以降（Windows 標準搭載のもので動作）
- LINE for Windows がインストール済みであること
