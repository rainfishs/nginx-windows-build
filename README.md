# nginx for Windows + headers-more

用 GitHub Actions 從官方原始碼編譯 Windows 版 nginx，加入 headers-more 模組，用來移除 `Server` 回應標頭。

## 來源

版本設定只有一處：`.github/workflows/build.yml` 的 `env` 區塊。

| 元件 | 來源 | 版本從哪來 |
|---|---|---|
| nginx | github.com/nginx/nginx（tag `release-<版本>`） | `NGINX_VERSION` |
| headers-more | github.com/openresty/headers-more-nginx-module | `HEADERS_MORE_VERSION` |
| OpenSSL、zlib、PCRE2 | 各自官方 GitHub releases | 讀 nginx 原始碼的 `misc/GNUmakefile`，跟官方 Windows 版相同；下載後比對 `DEPS_SHA256` |

- configure 指令直接取自 nginx 原始碼 `misc/GNUmakefile` 的 `win32` target（官方 Windows 版用的那一條），只多加 `--add-module=../headers-more`。
- 編譯器用 MSVC（VS 2022），跟官方相同。
- build 完會實際啟動 nginx，用 `more_clear_headers Server;` 打一次 request，確認 `Server` 標頭真的不見了，才會產出檔案。

## 使用方式

1. 在 GitHub 建一個 repo，把這個資料夾的內容 push 上去。
2. 到 Actions → **build nginx for Windows with headers-more** → **Run workflow**。
3. 跑完後在該次 run 頁面下載 artifact（zip）。`BUILD-INFO.txt` 和 run summary 裡有 `nginx -V` 輸出和 `nginx.exe` 的 SHA256。

## 部署

1. 停止 nginx（或停止它的 Windows 服務）。
2. 備份原本的 `nginx.exe`，換成新的。
3. 在 `nginx.conf` 的 `http { }` 裡加上：
   ```nginx
   more_clear_headers Server;
   ```
4. 執行 `nginx -t` 檢查設定，沒問題再啟動。
5. 用 `curl -I https://你的網址/` 確認回應裡已經沒有 `Server:`。

## 升級 nginx 版本

1. 修改 `build.yml` 裡的 `NGINX_VERSION`，push。
2. 如果新版 nginx 官方換了 OpenSSL、zlib、PCRE2 的版本，build 會失敗並顯示 `xxx.tar.gz has no SHA256 in DEPS_SHA256`。到該函式庫的官方 release 頁面取得 SHA256，在 `DEPS_SHA256` 裡換掉對應那一行。

## 已知限制

- headers-more 作者表示這個模組沒有正式支援 Windows（headers-more issue #24）。在 MSVC 下必須讓每個 `.c` 檔第一行就 include `ngx_config.h`（nginx 的 precompiled header），workflow 會自動補上這一行（見 issue #167 的錯誤訊息）。
