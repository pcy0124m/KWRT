#!/bin/bash

# ============================================================
# diy.sh - 自定义配置脚本
# 作用：添加软件源、修改默认配置、清理不需要的包
# ============================================================
# 
# 【自定义配置区域】—— 修改下面的值即可
# 
# 默认 LAN IP 地址（刷机后路由器的管理地址）
DEFAULT_IP="192.168.12.1"
# 默认主机名
DEFAULT_HOSTNAME="JDCloud-Router"
# root 密码（留空表示不设密码，刷机后首次登录会提示设置）
# 如果要设密码，把下面的值改成你想要的密码即可
ROOT_PASSWORD=""
# OPENSSL 生成密码哈希的工具（如果下面设了密码会自动生成哈希）
# 也可以直接填哈希值：$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF. 对应密码 "password"
# ============================================================

echo "===== diy.sh 开始执行 ====="

# ---------- 添加 Argon 主题源 ----------
echo 'src-git argon https://github.com/jerrykuku/luci-theme-argon.git' >> feeds.conf.default

# ---------- 添加 Turbo ACC 网络加速源 ----------
echo 'src-git turboacc https://github.com/chenmozhijin/turboacc.git' >> feeds.conf.default

# ---------- PassWall 依赖包源 ----------
echo 'src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git' >> feeds.conf.default

# ---------- （可选）OpenAppFilter 应用过滤源（需要时取消注释） ----------
# echo 'src-git oaf https://github.com/destan19/OpenAppFilter.git' >> feeds.conf.default

# ---------- （可选）OpenClash 源 ----------
# echo 'src-git openclash https://github.com/vernesong/OpenClash.git' >> feeds.conf.default

# ---------- 修改默认 LAN IP ----------
sed -i "s/192.168.100.1/$DEFAULT_IP/g" package/base-files/files/bin/config_generate 2>/dev/null
sed -i "s/192.168.1.1/$DEFAULT_IP/g" package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 修改默认主机名 ----------
sed -i "s/^hostname=\w\+/hostname=$DEFAULT_HOSTNAME/g" package/base-files/files/bin/config_generate 2>/dev/null
grep -q 'hostname=' package/base-files/files/bin/config_generate || \
  sed -i "/system.@system\[-1\].hostname=/a\	set system.@system[-1].hostname='$DEFAULT_HOSTNAME'" package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 修改默认时区为上海 ----------
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate 2>/dev/null
sed -i "/zonename=/a\	set system.@system[-1].zonename='Asia\/Shanghai'" package/base-files/files/bin/config_generate 2>/dev/null

# ---------- 设置 root 密码 ----------
if [ -n "$ROOT_PASSWORD" ]; then
  # 生成密码哈希并写入 shadow 文件
  PWD_HASH=$(openssl passwd -1 "$ROOT_PASSWORD" 2>/dev/null)
  if [ -n "$PWD_HASH" ]; then
    sed -i "s|root::0:0:99999:7:::|root:$PWD_HASH:0:0:99999:7:::|g" package/base-files/files/etc/shadow 2>/dev/null
    echo "root 密码已设置"
  fi
fi

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

# ---------- 修改固件品牌为 Kwrt ----------
sed -i 's/OpenWrt/Kwrt/g' package/base-files/files/bin/config_generate 2>/dev/null
sed -i 's/LEDE/Kwrt/g' package/base-files/files/bin/config_generate 2>/dev/null
# 修改版本发布名称
sed -i 's/OpenWrt/Kwrt/g' package/base-files/files/usr/lib/openwrt_release 2>/dev/null
sed -i 's/LEDE/Kwrt/g' package/base-files/files/usr/lib/openwrt_release 2>/dev/null
# 修改固件文件命名（ImageName）
find include -name "*.mk" -exec sed -i 's/OpenWrt/Kwrt/g' {} \; 2>/dev/null
find include -name "*.mk" -exec sed -i 's/LEDE/Kwrt/g' {} \; 2>/dev/null

echo "===== diy.sh 执行完成 ====="