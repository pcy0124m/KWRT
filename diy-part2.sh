#!/bin/bash

# ============================================================
# diy-part2.sh - 配置后自定义脚本
# 作用：修改默认 IP、主机名、时区、WiFi 等
# ============================================================

# 避免单个 sed 没匹配到就退出整个脚本
set +e

# ---------- 修改默认 LAN IP ----------
# LEDE 默认一般是 192.168.100.1，这里改成 192.168.12.1
sed -i 's/192.168.100.1/192.168.12.1/g' package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 修改默认主机名 ----------
sed -i 's/^hostname=\w\+/hostname=JDCloud-Router/g' package/base-files/files/bin/config_generate 2>/dev/null
# 如果上面没匹配到，试试直接加一行
grep -q 'hostname=' package/base-files/files/bin/config_generate || \
  sed -i "/system.@system\[-1\].hostname=/a\	set system.@system[-1].hostname='JDCloud-Router'" package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 修改默认时区为上海 ----------
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate 2>/dev/null
sed -i "/zonename=/a\	set system.@system[-1].zonename='Asia\/Shanghai'" package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 移除缺少依赖的包（避免编译报错） ----------
rm -rf package/feeds/luci/luci-app-passwall 2>/dev/null
rm -rf package/feeds/luci/luci-app-passwall2 2>/dev/null

set -e
echo "===== diy-part2.sh 执行完成 ====="