#!/bin/bash
# build-package.sh - 编译并打包为 .run 自解压安装包
# 用法:
#   ./build-package.sh           编译 + 打包
#   ./build-package.sh --pkg    仅打包（不重新编译，假设已 install 到 /opt/zfnproxy/opensips）
#   ./build-package.sh --run    制作 .run 包

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENSIPS_DIR="$SCRIPT_DIR"
PKG_NAME="opensips-gb28181-proxy"
PKG_VERSION=$(source "$OPENSIPS_DIR/Makefile.defs" 2>/dev/null; echo "${VERSION_MAJOR:-4}.${VERSION_MINOR:-1}")
STAMP=$(date +%Y%m%d%H%M)
DIST_DIR="$SCRIPT_DIR/dist"
STAGING="/tmp/opensips-pkg-$$"
RUN_FILE="${PKG_NAME}-${PKG_VERSION}-${STAMP}.run"
RUN_PATH="$DIST_DIR/$RUN_FILE"

usage() {
    echo "用法: $0 [--pkg|--run]"
    echo "  --pkg   仅打包（跳过编译，假设已安装）"
    echo "  --run   制作 .run 自解压安装包"
    echo "  不带参数  编译 + 打包 .tar.gz"
    exit 1
}

check_deps() {
    echo "=== 检查依赖 ==="
    local miss=()
    for cmd in make gcc g++ m4 sqlite3 tar gzip; do
        command -v "$cmd" &>/dev/null || miss+=("$cmd")
    done
    if [ ${#miss[@]} -gt 0 ]; then
        echo "缺少: ${miss[*]}  →  sudo apt-get install ${miss[*]}"
        exit 1
    fi
    echo "  OK"
}

build() {
    echo "=== 编译（使用 deploy/scripts/build.sh）==="
    "$OPENSIPS_DIR/deploy/scripts/build.sh" build
    "$OPENSIPS_DIR/deploy/scripts/build.sh" install
    echo "  OK"
}

prepare_staging() {
    echo "=== 准备打包内容 ==="
    local INSTALL_PREFIX="/opt/zfnproxy/opensips"

    mkdir -p "$STAGING/opt/zfnproxy/opensips/sbin"
    mkdir -p "$STAGING/opt/zfnproxy/opensips/lib64/opensips/modules"
    mkdir -p "$STAGING/opt/zfnproxy/opensips/etc"
    mkdir -p "$STAGING/opt/zfnproxy/opensips/data"
    mkdir -p "$STAGING/opt/zfnproxy/opensips/log"
    mkdir -p "$STAGING/opt/zfnproxy/opensips/deploy/scripts"
    mkdir -p "$STAGING/opt/zfnproxy/opensips/deploy/cfg"
    mkdir -p "$STAGING/opt/zfnproxy/opensips/deploy/cfg/cluster"
    mkdir -p "$STAGING/etc/systemd/system"

    # 1. make install 产物
    for f in "$INSTALL_PREFIX"/sbin/opensips*; do
        [ -f "$f" ] && cp -f "$f" "$STAGING/opt/zfnproxy/opensips/sbin/"
    done
    for mod in "$INSTALL_PREFIX"/lib64/opensips/modules/*.so; do
        [ -f "$mod" ] && cp -f "$mod" "$STAGING/opt/zfnproxy/opensips/lib64/opensips/modules/"
    done
    for d in "$INSTALL_PREFIX"/etc/openser "$INSTALL_PREFIX"/etc/opensips; do
        [ -d "$d" ] && { cp -rf "$d" "$STAGING/opt/zfnproxy/opensips/etc/"; break; }
    done

    # 2. deploy 部署脚本和配置模板
    cp -f "$OPENSIPS_DIR/deploy/scripts/gen-cfg.sh"      "$STAGING/opt/zfnproxy/opensips/deploy/scripts/"
    cp -f "$OPENSIPS_DIR/deploy/scripts/deploy.sh"        "$STAGING/opt/zfnproxy/opensips/deploy/scripts/"
    cp -f "$OPENSIPS_DIR/deploy/scripts/sync-to-peer.sh" "$STAGING/opt/zfnproxy/opensips/deploy/scripts/" 2>/dev/null || true
    cp -f "$OPENSIPS_DIR/deploy/env.m4"                   "$STAGING/opt/zfnproxy/opensips/deploy/"
    cp -f "$OPENSIPS_DIR/deploy/cfg/"*.m4                "$STAGING/opt/zfnproxy/opensips/deploy/cfg/"
    cp -f "$OPENSIPS_DIR/deploy/cfg/cluster/"*.m4        "$STAGING/opt/zfnproxy/opensips/deploy/cfg/cluster/"

    # 3. systemd
    cp -f "$OPENSIPS_DIR/deploy/systemd/opensips-gb28181.service" "$STAGING/etc/systemd/system/"

    echo "  OK"
}

make_tarball() {
    echo "=== 打包 tar.gz ==="
    mkdir -p "$DIST_DIR"
    local TARBALL="${PKG_NAME}-${PKG_VERSION}-${STAMP}.tar.gz"
    cd "$STAGING"
    tar -czf "$DIST_DIR/$TARBALL" *
    echo "  已生成: $DIST_DIR/$TARBALL"
    echo "  大小: $(du -sh "$DIST_DIR/$TARBALL" | cut -f1)"
}

make_run() {
    echo "=== 制作 .run 自解压包 ==="
    local TARBALL="${PKG_NAME}-${PKG_VERSION}-${STAMP}.tar.gz"
    local TARBALL_PATH="$DIST_DIR/$TARBALL"

    prepare_staging
    make_tarball

    local INSTALL_SCRIPT="$STAGING/install.sh"

    cat > "$INSTALL_SCRIPT" << 'INSTALL_EOF'
#!/bin/bash
# install.sh - 自解压安装脚本（由 build-package.sh 生成）
set -e

INSTALL_PREFIX="/opt/zfnproxy/opensips"
ARCHIVE=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0;}' "$0")

echo "=== 安装 OpenSIPS GB28181 Proxy ==="
echo "  安装路径: $INSTALL_PREFIX"

# 创建用户
if ! id opensips &>/dev/null; then
    useradd -r -s /usr/sbin/nologin -d "$INSTALL_PREFIX" -c "OpenSIPS GB28181" opensips 2>/dev/null || true
    echo "  创建用户 opensips"
fi

# 解压到 /
echo "  解压文件..."
tail -n +$ARCHIVE "$0" | tar -xzf - -C /

# 设置权限
chown -R opensips:opensips "$INSTALL_PREFIX/data" 2>/dev/null || true
chown -R opensips:opensips "$INSTALL_PREFIX/log"  2>/dev/null || true

# systemd
if command -v systemctl &>/dev/null; then
    systemctl daemon-reload
    echo "  systemd 已重载"
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "启动服务:"
echo "  systemctl enable --now opensips-gb28181"
echo ""
echo "配置并启动:"
echo "  $INSTALL_PREFIX/deploy/scripts/deploy.sh single \\"
echo "      -l <本机IP> -u <上游IP:PORT>"
echo ""
echo "查看日志:"
echo "  journalctl -u opensips-gb28181 -f"
echo "  tail -f $INSTALL_PREFIX/log/opensips.log"

exit 0

__ARCHIVE_BELOW__
INSTALL_EOF

    chmod +x "$INSTALL_SCRIPT"

    # 拼接：install.sh + tarball → .run
    mkdir -p "$DIST_DIR"
    cat "$INSTALL_SCRIPT" "$TARBALL_PATH" > "$RUN_PATH"
    chmod +x "$RUN_PATH"

    rm -rf "$STAGING"

    echo "  已生成: $RUN_PATH"
    echo "  大小: $(du -sh "$RUN_PATH" | cut -f1)"
    echo ""
    echo "部署: 将 $RUN_PATH 拷贝到目标机器，双击或 bash $RUN_FILE 运行即可"
}

# 主流程
MODE="all"
for arg in "$@"; do
    case "$arg" in
        --pkg)  MODE="pkg" ;;
        --run)  MODE="run" ;;
        -h|--help) usage ;;
    esac
done

check_deps

case "$MODE" in
    all)
        build
        prepare_staging
        make_tarball
        make_run
        ;;
    pkg)
        prepare_staging
        make_tarball
        ;;
    run)
        make_run
        ;;
esac

echo ""
echo "=== 完成 ==="
