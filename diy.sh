#!/bin/bash

# ============================================================
# diy.sh - 自定义配置脚本
# 作用：添加软件源、修改默认配置、清理不需要的包
# ============================================================

echo "===== diy.sh 开始执行 ====="

# ---------- 添加 Argon 主题源 ----------
echo 'src-git argon https://github.com/jerrykuku/luci-theme-argon.git' >> feeds.conf.default

# ---------- 添加 Turbo ACC 网络加速源 ----------
echo 'src-git turboacc https://github.com/chenmozhijin/turboacc.git' >> feeds.conf.default

# ---------- PassWall 依赖包源 ----------
echo 'src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git' >> feeds.conf.default

# ---------- （可选）OpenClash 源 ----------
# echo 'src-git openclash https://github.com/vernesong/OpenClash.git' >> feeds.conf.default

# ---------- 修改默认 LAN IP ----------
sed -i 's/192.168.100.1/192.168.12.1/g' package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 修改默认主机名 ----------
sed -i 's/^hostname=\w\+/hostname=JDCloud-Router/g' package/base-files/files/bin/config_generate 2>/dev/null
grep -q 'hostname=' package/base-files/files/bin/config_generate || \
  sed -i "/system.@system\[-1\].hostname=/a\	set system.@system[-1].hostname='JDCloud-Router'" package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 修改默认时区为上海 ----------
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate 2>/dev/null
sed -i "/zonename=/a\	set system.@system[-1].zonename='Asia\/Shanghai'" package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 移除缺少依赖的包 ----------
rm -rf package/feeds/luci/luci-app-passwall 2>/dev/null
rm -rf package/feeds/luci/luci-app-passwall2 2>/dev/null
# 清除 feeds.conf 中已不存在的 passwall2 源引用
sed -i '/passwall2/d' feeds.conf.default 2>/dev/null

# ---------- 移除编译失败的内核补丁 ----------
# UVC 摄像头补丁与 LEDE 内核不兼容，删除后不影响基本功能
find target/linux -name "*uvc*" -o -name "*iPassion*" -o -name "*iP2970*" 2>/dev/null | while read f; do
  rm -f "$f" 2>/dev/null
  echo "已删除补丁: $f"
done

echo "===== diy.sh 执行完成 ====="