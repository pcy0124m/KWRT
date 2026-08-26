#!/bin/bash
echo "Kwrt feeds init done"

# ---------- 添加 Argon 主题源 ----------
echo 'src-git argon https://github.com/jerrykuku/luci-theme-argon.git' >> feeds.conf.default

# ---------- 添加 Turbo ACC 网络加速源 ----------
echo 'src-git turboacc https://github.com/chenmozhijin/turboacc.git' >> feeds.conf.default

# ---------- PassWall 源（LEDE 默认依赖，必须开启） ----------
echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall.git' >> feeds.conf.default
echo 'src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git' >> feeds.conf.default

# ---------- （可选）OpenClash 源 ----------
# echo 'src-git openclash https://github.com/vernesong/OpenClash.git' >> feeds.conf.default

echo "===== diy-part1.sh 执行完成 ====="
