# Kwrt GitHub‑Actions 云编译教程｜京东云 RE‑SP‑01B（MT7621）
> Kwrt 源码：https://github.com/kiddin9/Kwrt
> 内置大量插件，兼容iStore商店，支持Breed直刷京东云RE‑SP‑01B
> 两种编译途径：1. openwrt.ai网页在线生成；2.GitHub Actions云编译

## 仓库目录结构
仓库根目录
├─ .github
│ └─ workflows
│ └─ kwrt-build.yml
├─ configs
│ └─ re‑sp‑01b.config
├─ diy‑part1.sh
└─ diy‑part2.sh

## 1. kwrt‑build.yml
> 文件路径：`.github/workflows/kwrt-build.yml`
```yaml
name: Build‑Kwrt‑RE‑SP‑01B
permissions:
  contents: write

on:
  workflow_dispatch:
    inputs:
      ssh:
        description: "开启SSH调试tmate true/false"
        default: 'false'
        required: false
  schedule:
    - cron: '0 17 * * *'

env:
  REPO_URL: https://github.com/kiddin9/Kwrt
  REPO_BRANCH: main
  CONFIG_FILE: configs/re-sp-01b.config
  DIY_P1_SH: diy-part1.sh
  DIY_P2_SH: diy-part2.sh
  UPLOAD_FIRMWARE: true
  UPLOAD_RELEASE: true
  TZ: Asia/Shanghai

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Init environment
        env:
          DEBIAN_FRONTEND: noninteractive
        run: |
          sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
          sudo apt-get -qq update
          sudo apt-get -qq install $(curl -fsSL https://github.com/281677160/Actions-OpenWrt/raw/main/depends-ubuntu-2204)
          sudo apt-get -qq autoremove --purge
          sudo timedatectl set-timezone $TZ
          sudo mkdir -p /workdir
          sudo chown $USER:$GROUPS /workdir

      - name: Clone Kwrt Source
        working-directory: /workdir
        run: |
          git clone $REPO_URL -b $REPO_BRANCH openwrt
          ln -sf /workdir/openwrt $GITHUB_WORKSPACE/openwrt

      - name: Run diy‑part1 feeds
        run: |
          chmod +x $DIY_P1_SH
          cd openwrt
          $GITHUB_WORKSPACE/$DIY_P1_SH

      - name: Feeds update & install
        run: |
          cd openwrt
          ./scripts/feeds update -a
          ./scripts/feeds install -a

      - name: Load config & diy‑part2
        run: |
          [ -e $CONFIG_FILE ] && mv $CONFIG_FILE openwrt/.config
          chmod +x $DIY_P2_SH
          cd openwrt
          $GITHUB_WORKSPACE/$DIY_P2_SH
          make defconfig

      - name: Open SSH debug(tmate)
        if: inputs.ssh == 'true'
        uses: mxschmitt/action-tmate@v3

      - name: Download source
        run: |
          cd openwrt
          make download -j8

      - name: Compile firmware
        id: compile
        run: |
          cd openwrt
          make -j$(nproc) || make -j1 V=s
          echo "status=success" >> $GITHUB_OUTPUT
          grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*DEVICE_(.*)=y/\1/' > DEVICE_NAME
          [ -s DEVICE_NAME ] && echo "DEVICE_NAME=_$(cat DEVICE_NAME)" >> $GITHUB_ENV
          echo "BUILD_DATE=_$(date +%Y%m%d-%H%M)" >> $GITHUB_ENV

      - name: Organize firmware
        id: organize
        if: env.status == 'success'
        run: |
          cd openwrt/bin/targets/*/*
          rm -rf packages
          echo "FIRMWARE_PATH=$PWD" >> $GITHUB_ENV

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        if: steps.organize.outputs.status == 'success'
        with:
          name: Kwrt‑RE‑SP‑01B${{ env.BUILD_DATE }}
          path: ${{ env.FIRMWARE_PATH }}

      - name: Release tag
        id: release_tag
        if: env.UPLOAD_RELEASE == 'true'
        run: |
          echo "tag=$(date +%Y.%m.%d-%H%M)" >> $GITHUB_OUTPUT

      - name: Upload to GitHub Release
        uses: softprops/action-gh-release@v1
        if: steps.release_tag.outputs.tag
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ steps.release_tag.outputs.tag }}
          files: ${{ env.FIRMWARE_PATH }}/*
2. diy‑part1.sh 仓库根目录
#!/bin/bash
echo "Kwrt feeds init done"
## 3. diy‑part2.sh 仓库根目录

> 
> 修改 LAN 网关：`192.168.10.1`
#!/bin/bash
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
4. configs/re‑sp‑01b.config
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_jdcloud_re-sp-01b=y

# USB、docker、luci中文、iStore依赖
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget=y

