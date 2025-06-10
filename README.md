## 前言

本筆記是使用 `wget` 備份網站的實際案例
包含一些備份時需要考慮的東西
因為沒有很多網站要備份，所以密前只有寫到半手動
待未來夠多經驗再增加自動化程度

### 目標

- 目標：將指定網址備份到本機，供離線存取備份
- 範例：Moodle 網站

### 標的類別

Moodle 網站大致可以分為：

- query 類型頁面，網址路徑固定且使用類似 `?id=...` 來切換，但上限未知

  + `/course?section=...`
  + `/course?view=...`
  + `/enrol?index=...`
  + `/mod/forum?view=...`
  + `/mod/page?view=...`
  + `/mod/resource?view=...`
  + `/mod/quiz?view=...`
  + `/mod/assign?view=...`

- 結構化的網頁，網址路徑不固定

## 半手動備份流程

### 第零步：取得登入 Cookie

1. 開啟瀏覽器，登入目標網域
2. F12 進入開發工具後 F15 重整
3. 網路 | 全部 | (第一個) | 請求標頭 | Header: ...

### 第一步：列表資源數量

這一步驟在於確認 query 類型頁面數量
使用腳本範本 `list.bash.tpl` 搜集 query 類型頁面，須設定以下參數:

- WEBSITE_URL
- COOKIE_STRING
- BACKUP_DIR
- SUFFIX_LIST

使用範例腳本 `list_*.bash`，須設定以下參數:

- WEBSITE_URL
- COOKIE_STRING

不同子路徑可以分開並行同時執行以節省時間

### 第二步：取得一般結構化網頁

使用腳本 `fetch.bash`，須設定以下參數:

- WEBSITE_URL
- COOKIE_STRING

第一步跟第二步可平行處理，不互相干擾 (注意存取次數不要大到被擋)

### 第三步：清潔 query 網頁

針對第一步取得的網頁，可以進行清潔，列出實際有用的網頁
針對無法存取的網頁就可以忽略

```
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" course_section/section.php\?id=* | wc
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" course_view/view.php\?id=* | wc
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_page_view/view.php\?id=* | wc
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_forum_view/view.php\?id=* | wc
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_quiz_view/view.php\?id=* | wc
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_resource_view/view.php\?id=* | wc
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_assign_view/view.php\?id=* | wc
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" enrol_index/index.php\?id=* | wc

grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" course_section/section.php\?id=*
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" course_view/view.php\?id=*
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_page_view/view.php\?id=*
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_forum_view/view.php\?id=*
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_quiz_view/view.php\?id=*
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_resource_view/view.php\?id=*
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" mod_assign_view/view.php\?id=*
grep -L -E "(This content can't be found\.|You cannot enrol yourself in this course\.|Sorry, this activity is currently hidden)" enrol_index/index.php\?id=*
```

列出的資訊貼到 Sublime Text 進行替換，目標符合以下格式用於第四步

```
    "/course/section.php?id=1::"
    "/course/section.php?id=29::"
    "/course/section.php?id=30::"
    "/course/section.php?id=301::"
    "/course/section.php?id=31::"
    "/course/section.php?id=32::"
```

### 第四步：取得 query 網頁

將第三步的所得用於 `fetch_on_id.bash`，須設定以下參數:

- WEBSITE_URL
- COOKIE_STRING
- SUFFIX_LIST

可能不能平行處理，因為雖然機會低，但可能會打架

### 第五步：修正錯誤

#### 本地檔名問題

在下載網頁後，部分 HTML 導向的檔案可能是 png, css, jpg 等並非 HTML 檔案，但 HTML 導向的連結卻會自動添加 `.html` ，這會導致在顯示相關資源時失敗
因此，此步驟在於修正這些錯誤本地連結

```
# 列出有問題的本地連結種類
grep -rho '"[^"]*\.[^"/@]*\.html"' yourdomain.com/ | sed 's/.*\(\.[^.]*\.html\)".*/\1/' | sort -u
  # .JPG.html
  # .css.html
  # .jpeg.html
  # .jpg.html
  # .php.html
  # .png.html

# 除了 php 以外其他有添加 `.html` 需要移除該 `.html`
grep -rho '"[^"]*\.\(png\|jpg\|JPG\|css\|jpeg\)\.html"' yourdomain.com/ | wc
  #     3433    3433  289235
grep -rho '"[^"]*\.\(php\)\.html"' yourdomain.com/ | wc
  #        7       7     155
grep -rho '"[^"]*\.[^"/@]*\.html"' yourdomain.com/ | wc
  #     3440    3440  289390

# 取代
find yourdomain.com/ -name "*.html" -exec perl -i -pe 's/"([^"]*\.(png|jpg|JPG|css|jpeg))\.html"/"$1"/g' {} +
```

#### 依然聯外連結

因為有使用低階層一頁頁存取，部分連結可能即使已經下載依然導向回原網站
因此需要修正此錯誤

```
grep -rho '"https://yourdomain.com/[^"?]*\.php"' yourdomain.com/ | wc
  #     7270    7270  305286
grep -rho '"https://yourdomain.com/[^"]*\?id=[^"]*"' yourdomain.com/ | wc
  #    14414   14414  642636

find yourdomain.com/ -name "*.html" -exec sh -c '
  file="$1"
  # 移除 yourdomain.com/ 前綴，計算斜線數量
  path_without_prefix="${file#yourdomain.com/}"
  depth=$(echo "$path_without_prefix" | tr -cd "/" | wc -c)
  # 生成相對路徑前綴
  relative=""
  i=1
  while [ $i -lt $depth ]; do
    relative="${relative}../"
    i=$((i + 1))
  done
  # 使用 perl 進行替換，將 ? 替換為 @
  perl -i -pe "s|\"https://tksg\\.org/([^\"]*?)\\?([^\"]*?)\"|\"${relative}\\1@\\2.html\"|g" "$file"
' _ {} \;


find yourdomain.com/ -name "*.html" -exec sh -c '
  file="$1"
  path_without_prefix="${file#yourdomain.com/}"
  depth=$(echo "$path_without_prefix" | tr -cd "/" | wc -c)
  relative=""
  i=1
  while [ $i -lt $depth ]; do
    relative="${relative}../"
    i=$((i + 1))
  done
  perl -i -pe "s|\"https://tksg\\.org/([^\"?]*?\\.php)\"|\"${relative}\\1.html\"|g" "$file"
' _ {} \;
```

#### 有問題的本地連結

`wget` 在抓取時，絕大多數檔案都能正確抓取。其中`.php` 會變成 `.php.html`，此錯誤我們接受，否則無法本地顯示該頁面。
但其他如 `.png@time=a2bv5af.html` 就會出現檔案系統沒有 `.html` 但連結有 `.html`，導致顯示問題

```
# 確認內容
grep -rho 'pluginfile\.php[a-zA-Z0-9/_]*/[a-zA-Z0-9_]*\.[a-zA-Z0-9_\.]\+@[a-zA-Z0-9_]\+=[a-zA-Z0-9_]\+\.html' yourdomain.com/
# 確認影響檔案
grep -rl 'pluginfile\.php/[^"]*\.png@time=[^"]*\.html' yourdomain.com/
# Sublime 手動修正 (因為寫腳本失敗了，誒嘿～)
```

#### 移除使用者名稱

隱私問題

```
grep -rho 'Your Name' yourdomain.com/ | wc
  #     6186   12372   92790
find yourdomain.com/ -name "*.html" -exec perl -i -pe 's/Your Name/Anonymous/g' {} +
```
