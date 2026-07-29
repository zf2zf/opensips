#!/bin/bash
# =============================================================================
# OpenSIPS GB28181 HA - build.sh
# 从源码 build OpenSIPS（可选；环境已装可跳过）
# 用法: bash build.sh
# 依赖: SRC_DIR 指向 OpenSIPS 源码目录
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -f "${SCRIPT_DIR}/env.sh" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/env.sh"
else
    echo "ERROR: env.sh 不存在。请先 cp env.sh.example env.sh 并填好 SRC_DIR"
    exit 1
fi

: "${SRC_DIR:?SRC_DIR 未设置。env.sh 中指定 OpenSIPS 源码目录}"
: "${OPEN_SIPS_USER:=opensips}"

if [[ ! -d "${SRC_DIR}" ]]; then
    echo "ERROR: SRC_DIR=${SRC_DIR} 不存在"
    exit 1
fi

echo "==> 在 ${SRC_DIR} 配置 + 编译 + 安装 OpenSIPS"
cd "${SRC_DIR}"

# 1. 配置（启用本方案所需的所有模块）
echo "==> [1/3] make menuconfig（预设：以下模块全部启用）..."
# 交互式 menuconfig 不友好，用预设参数
# 用户也可手动跑 menuconfig 调整
make menuconfig \
    PREFIX="/usr/local" \
    LIBDIR="/usr/local/lib64" \
    EXCLUDE_MODULES="" \
    include_modules="db_sqlite db_text sqlops signaling sl tm rr maxfwd sipmsgops usrloc registrar acc dispatcher uac nathelper xml proto_udp proto_bin clusterer httpd json mi_fifo"

# 2. 编译
echo "==> [2/3] make all..."
make -j"$(nproc)"

# 3. 安装
echo "==> [3/3] make install..."
make install

# 4. 验证
echo "==> 验证："
/usr/local/sbin/opensips -V | head -3
echo
echo "==> 模块目录："
ls /usr/local/lib64/opensips/modules/ | grep -E "proto_bin|clusterer|httpd|json|usrloc|dispatcher" | head -20

echo "==> build 完成。"
