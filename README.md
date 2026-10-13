# nginx for Windows + headers-more

用 GitHub Actions 從官方原始碼編譯 Windows 版 nginx，加入 headers-more 模組，用來移除 `Server` 回應標頭。

## 來源（全部釘死版本）

| 元件 | 版本 | 來源 | 驗證方式 |
|---|---|---|---|
| nginx | 1.30.5 | github.com/nginx/nginx | commit `4556c714` |
| headers-more | v0.40 | github.com/openresty/headers-more-nginx-module | commit `0bf283ff` |
| OpenSSL | 3.5.8 | github.com/openssl/openssl releases | SHA256 |
| zlib | 1.3.2 | github.com/madler/zlib releases | SHA256 |
| PCRE2 | 10.48 | github.com/PCRE2Project/pcre2 releases | SHA256 |

- configure 參數和函式庫版本都跟官方 Windows 版一樣（以 nginx 原始碼裡 `misc/GNUmakefile` 的 `win32` target 為準），唯一差別是多了 `--add-module=../headers-more`。build 時會自動比對，不一致就直接失敗。
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

1. 修改 `build.yml` 裡的 `NGINX_VERSION`、`NGINX_COMMIT`（tag `release-x.y.z` 指向的 commit）。
2. 跑一次。如果新版官方 build 改了 OpenSSL、zlib、PCRE2 的版本或 configure 參數，build 會失敗並列出差異。照差異更新 `OPENSSL`/`ZLIB`/`PCRE`、對應的 SHA256 和 `build/configure.sh`。

## 已知限制

- headers-more 作者表示這個模組沒有正式支援 Windows（headers-more issue #24）。在 MSVC 下必須讓每個 `.c` 檔第一行就 include `ngx_config.h`（nginx 的 precompiled header），workflow 會自動補上這一行（見 issue #167 的錯誤訊息）。
