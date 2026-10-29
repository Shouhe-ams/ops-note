# 备忘录 · 线上版

这是一个可直接部署到任意静态托管平台的版本，不需要自己的服务器、没有构建步骤。云同步使用 Supabase（个人免费版即可）。

上线后你会得到一个 HTTPS 网址，电脑和手机都能打开；支持添加到手机桌面（PWA）和离线使用。

> 不登录时，数据保存在**每个浏览器自己的 localStorage** 里。登录云同步后，会写入你自己的 Supabase 项目，并在同一账号的设备间合并同步。换设备或清理浏览器数据前，仍建议在应用内「更多 → 导出备份」保存一份 JSON。

---

## 目录结构

```
线上版/
├── index.html                  # 应用本体，单文件
├── cloud-config.js             # Supabase 项目地址与 publishable key
├── manifest.json               # PWA 配置
├── sw.js                       # 离线缓存 / Service Worker
├── _headers                    # Netlify / Cloudflare Pages 安全与缓存响应头
├── robots.txt                  # 禁止搜索引擎收录
├── .nojekyll                   # GitHub Pages 不经过 Jekyll
├── icon-192.png
├── icon-512.png
├── icon-maskable-512.png
├── apple-touch-icon.png
├── favicon-64.png
├── screenshot-home.png
└── screenshot-review.png
```

图标和截图都放在根目录，避免只上传部分文件时出现 404。部署时请上传**整个 `线上版` 文件夹的内容**，不要只上传 `index.html`，否则 PWA 图标和离线缓存不可用。

> 更新已有 Netlify 站点时，进入项目 → **Deploys → Deploy manually**，拖入整个文件夹（或平台支持的 zip）。不要只拖单个 `index.html`，否则图标、截图和 Service Worker 预缓存会 404。

---

## 云同步（个人版）

当前 `cloud-config.js` 已填入 Supabase 项目：

- Project URL：`https://kfzqiaquucqgvklcqals.supabase.co`
- 前端只使用 `publishable` key
- 数据结构在 [`supabase-schema.sql`](supabase-schema.sql)
- 登录方式：邮箱 + 密码

同步逻辑：

- 未登录时完全本地，不请求云端
- 登录后按备忘 `updatedAt` 和删除墓碑合并
- 保留两边较新的修改
- 删除会同步到其他设备
- 示例数据标记为 `demo`，不会进入云端，避免新设备重复
- 断网时继续本地使用，联网后自动补同步
- 每次本地保存后约 1.8 秒触发同步；页面重新可见、恢复网络和每 60 秒也会检查

> 如果更换 Supabase 项目，需要同时修改 `cloud-config.js` 和 `_headers` 里的 `connect-src` 域名，否则浏览器 CSP 会拦截请求。

### 登录 / 注册

1. 打开线上版，点右上角 **登录**
2. 输入邮箱和至少 6 位密码
3. 第一次使用点 **创建账号**
4. 如果 Supabase 开启了邮箱确认，去邮箱点确认链接；确认后会回到应用并自动登录
5. 换设备时用同一个邮箱密码登录即可

Supabase 的 **Authentication → URL Configuration** 里：

- Site URL 必须指向线上站点
- Redirect URLs 建议同时加入：
  - `https://你的域名/**`
  - `http://localhost:8765/**`（本地测试）

应用在注册时会带上当前站点作为 `redirect_to`，但目标地址仍需在 Supabase 允许列表里。

> 这是公开网址。创建好自己的账号后，建议在 **Authentication → Providers → Email** 关闭公开注册（Signups），避免陌生人也在你的 Supabase 项目里注册。RLS 会隔离数据，但关闭注册更干净。

### 常见问题：点验证邮件后跳到 localhost:3000 或 unauthorized

这是 Supabase 的 **Site URL 仍然是 `http://localhost:3000`** 导致的，不是账号密码错误。

1. 打开 Supabase → **Authentication → URL Configuration**
2. Site URL 改成线上地址：
   `https://loquacious-travesseiro-aec066.netlify.app`
3. Redirect URLs 加入：
   - `https://loquacious-travesseiro-aec066.netlify.app/**`
   - `http://localhost:8765/**`
4. 保存后，重新发送验证邮件或用新账号重新注册；旧邮件里的链接不会自动更新
5. 如果 Users 里显示邮箱已经确认，直接在应用里登录即可，不用再点邮件

最省事的个人用法：**Authentication → Providers → Email → 关闭 Confirm email**，删除未确认账号后重新注册，不需要验证邮件。

---

## 方式一：Netlify Drop（最快）

1. 打开 <https://app.netlify.com/drop>
2. 把整个 `线上版` 文件夹拖进页面
3. 登录并认领这个站点
4. 得到一个 `https://xxx.netlify.app` 地址

适合先快速上线试用。之后可以在 Netlify 后台绑定自定义域名。

> `_headers` 会自动生效，负责基础安全头、禁止收录和静态资源缓存。

---

## 方式二：Cloudflare Pages

1. 登录 Cloudflare Dashboard
2. 进入 **Workers & Pages → Create → Pages → Upload assets**
3. 项目名填 `ops-note`（可自定义）
4. 把 `线上版` 文件夹里的全部内容拖入上传区
5. Deploy，得到 `https://ops-note.pages.dev`

Cloudflare Pages 同样支持 `_headers`。

---

## 方式三：Vercel

需要 Node.js：

```bash
cd 线上版
npx vercel --prod
```

按提示登录、创建项目即可。Vercel 更适合后续接 Git 自动部署；本项目是纯静态目录，不需要 Build Command，Output Directory 就是当前目录。

---

## 方式四：GitHub Pages

1. 新建一个仓库（Public 或 Private 均可，Private 需要相应 Pages 权限）
2. 把 `线上版` 文件夹里的内容上传到仓库根目录
3. 进入 **Settings → Pages**
4. Source 选择 **Deploy from a branch**，分支 `main`，目录 `/ (root)`
5. 保存后等待部署，得到 `https://用户名.github.io/仓库名/`

`.nojekyll` 已包含，避免以下划线开头的文件被 Jekyll 忽略。

> GitHub Pages 不读取 `_headers`，安全头需要在 Cloudflare 或反向代理层配置。

---

## PWA 安装

必须通过 **HTTPS** 访问（`localhost` 例外）。

- **Android / Chrome**：地址栏右侧的安装图标，或菜单 →「安装应用」
- **iPhone / Safari**：分享按钮 →「添加到主屏幕」
- **桌面 Chrome / Edge**：地址栏右侧安装图标

安装后可以独立窗口打开，并支持离线访问已经缓存的应用外壳。

---

## 上线后检查

- [ ] 首页能正常打开
- [ ] 「新建备忘」能创建并刷新后仍在
- [ ] 手机能添加到主屏幕
- [ ] 断网后再次打开仍能进入应用
- [ ] 「更多 → 导出备份」能下载 JSON
- [ ] 「更多 → 导出日历提醒」能下载 `.ics`

---

## 更新应用

站点已连接 GitHub 后，提交并推送 `main` 分支会自动触发 Netlify 部署。

修改前端资源后，建议同时修改 `sw.js` 顶部的缓存版本，否则老用户可能继续看到旧缓存：

```js
// 原来是 v1.0.3，改成 v1.0.4
const CACHE_VERSION = "ops-note-v1.0.4";
```

Service Worker 会在下一次访问时更新缓存。

---

## 数据与隐私

- 未登录：备忘、检查清单、收口记录只保存在浏览器 `localStorage`
- 登录后：完整状态写入你自己的 Supabase `ops_state` 表，行级权限只允许本人读写
- 前端只包含 `publishable` key；密码由 Supabase Auth 处理，应用不保存密码
- 示例数据带 `demo` 标记，不会上传到云端，也不会在第二台设备上重复出现
- 删除会同步为墓碑记录，避免另一台设备把已删除事项重新带回来
- `robots.txt` 和 `_headers` 已设置禁止搜索引擎收录
- 清理浏览器站点数据会丢失本地缓存，但登录后可从云端恢复
- 重要数据仍建议定期「导出备份」；备份 JSON 里包含备忘、收口记录和删除标记

如果需要团队共享、权限分配或服务端定时提醒，需要在这个单用户同步版基础上继续扩展。

---

## 国内访问说明

- Vercel、Netlify、Cloudflare 在国内不同网络下速度差异较大
- 面向国内团队长期使用，建议阿里云 OSS / 腾讯云 COS + CDN，并配置 HTTPS
- 使用中国大陆服务器和自定义域名通常需要 ICP 备案
- 只给内部小范围使用，可以不绑定域名，先用平台默认域名试用

---

## 本地预览

在 `线上版` 目录启动任意静态服务器，例如：

```bash
python -m http.server 8080
```

然后打开 <http://localhost:8080>。`localhost` 属于安全上下文，Service Worker 可以正常注册，便于测试离线能力。
