# line-autostart-tray

Windows ログイン時に LINE for Windows を自動起動し、メインウィンドウを閉じてタスクトレイへ格納する PowerShell スクリプトです。LINE のプロセス自体は終了させず、バックグラウンドで常駐させます。

## 仕組み

LINE を通常起動したあと、メインウィンドウが表示されるタイミングを待ち、約2.5秒後にウィンドウへ `WM_CLOSE` を送ります。LINEはこの操作で終了せず、トレイ常駐状態になります。

対象ウィンドウは次の条件で絞り込むため、他のアプリを誤って閉じないようにしています。

- 可視状態
- タイトルに `LINE` を含む
- クラス名が `QWindowIcon` で終わる
- トップレベルウィンドウ

レジストリとスタートアップフォルダーの両方に登録されていても、名前付きMutexで二重起動しません。

## 必要環境

- Windows 10 / 11
- PowerShell 5.1 以降（Windows 標準搭載）
- LINE for Windows がインストール済みであること

## 配置先

長期運用では、次のユーザー単位の配置先を推奨します。管理者権限は不要です。

```text
C:\Users\<ユーザー名>\AppData\Local\Programs\LINE Autostart Tray
```

`startup_line.ps1` をこのフォルダーへコピーし、スタートアップ登録ではこの配置先のファイルを指定してください。後からフォルダーを移動すると、登録済みの起動先を更新する必要があります。

## 手動実行

```powershell
$script = "$env:LOCALAPPDATA\Programs\LINE Autostart Tray\startup_line.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script
```

## Windows ログイン時に自動実行する

タスクスケジューラ、スタートアップフォルダー、またはユーザー単位のレジストリ `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` を利用できます。レジストリを使う場合の例です。

```powershell
$script = "$env:LOCALAPPDATA\Programs\LINE Autostart Tray\startup_line.ps1"
$powershell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$command = "`"$powershell`" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'LINE Autostart Tray' -Value $command
```

スタートアップフォルダーを使う場合は、`shell:startup` に次の内容のショートカットを作成します。

```text
実行ファイル: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
引数: -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\<ユーザー名>\AppData\Local\Programs\LINE Autostart Tray\startup_line.ps1"
```

LINE 自体の「Windows 起動時に自動起動する」設定は無効にしてください。二重起動を避けるため、自動起動方法は一つだけにすることを推奨します。

## 注意

- LINE の実行ファイルは `%LOCALAPPDATA%\LINE\bin\LineLauncher.exe` を前提にしています。環境によって異なる場合は `startup_line.ps1` の `$lineExe` を変更してください。
- LINE のアップデートでウィンドウのクラス名や再表示の挙動が変わると、2.5秒の待機時間や判定条件の調整が必要になる場合があります。
- 自動起動を解除する場合は、作成したレジストリ値またはスタートアップショートカットを削除してください。

## ライセンス

MIT License
