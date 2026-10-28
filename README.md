# nginx for Windows + headers-more

用 GitHub Actions 從官方原始碼編譯 Windows 版 nginx，加入 headers-more 模組，用來移除 `Server` 回應標頭。

## 來源

程式碼裡沒有寫任何版本號，每次執行時決定：

| 元件 | 來源 | 版本 | 驗證 |
|---|---|---|---|
| nginx | github.com/nginx/nginx（tag `release-<版本>`） | 最新版，或執行時指定 | |
| headers-more | github.com/openresty/headers-more-nginx-module | 最新版，或執行時指定 | |
| OpenSSL、zlib、PCRE2 | 各自官方 GitHub releases | 跟官方 Windows 版相同（讀 nginx 原始碼的 `misc/GNUmakefile`） | 官方 GPG 簽章，公鑰在 `keys/` |

`keys/` 裡公鑰的指紋（`gpg --show-keys keys/xxx.asc` 可以看）跟以下官方來源核對過：

| 檔案 | 核對來源 |
|---|---|
| `openssl.asc` | openssl repo 的 `doc/fingerprints.txt` |
| `zlib.asc` | keys.openpgp.org（email 已驗證，`madler@alumni.caltech.edu` 是 zlib.h 裡的作者信箱） |
| `pcre2.asc` | pcre2 repo 的 `SECURITY.md` |

- configure 指令直接取自 nginx 原始碼 `misc/GNUmakefile` 的 `win32` target（官方 Windows 版用的那一條），只多加 `--add-module=../headers-more`。
- 編譯器用 MSVC（VS 2022），跟官方相同。
- build 完會實際啟動 nginx，用 `more_clear_headers Server;` 打一次 request，確認 `Server` 標頭真的不見了，才會發佈。

## 使用方式

1. 到 Actions → **build nginx for Windows with headers-more** → **Run workflow**。版本欄位留空就是最新版，要編特定版本就填進去。push 到 main 也會自動跑一次。
2. 編好的 zip 會發佈在 repo 的 **Releases** 頁面，名稱裡有實際編的版本，永久保留。說明欄有 `nginx -V` 輸出和 `nginx.exe` 的 SHA256。

nginx 出新版（例如修 CVE）時，直接 Run workflow 就好，不用改任何檔案。

- 同樣版本組合已經有 Release 時，workflow 不會重編，直接結束。要重編同一版，先在 Releases 頁面刪掉那個 Release 和它的 tag。
- 想在新版發佈時收到通知：repo 頁面右上 Watch → Custom → Releases。

## 部署

1. 停止 nginx（或停止它的 Windows 服務）。
2. 備份原本的 `nginx.exe`，換成新的。
3. 在 `nginx.conf` 的 `http { }` 裡加上：
   ```nginx
   more_clear_headers Server;
   ```
4. 執行 `nginx -t` 檢查設定，沒問題再啟動。
5. 用 `curl -I https://你的網址/` 確認回應裡已經沒有 `Server:`。

## 什麼時候需要改檔案

只有函式庫換了簽章金鑰的時候。build 會失敗並顯示 `xxx.tar.gz has no valid signature by keys/xxx.asc`，這時從官方來源取得新公鑰，換掉 `keys/` 裡對應的檔案。

- OpenSSL 目前的簽章子金鑰在 2027-05-26 到期，到時候可能要更新 `keys/openssl.asc`。

## 已知限制

- headers-more 作者表示這個模組沒有正式支援 Windows（headers-more issue #24）。在 MSVC 下必須讓每個 `.c` 檔第一行就 include `ngx_config.h`（nginx 的 precompiled header），workflow 會自動補上這一行（見 issue #167 的錯誤訊息）。
