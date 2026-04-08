#!/bin/bash

################################################################################
# Uninstall acme.sh - Gỡ bỏ acme.sh (nếu cần)
# CẢNH BÁO: Lệnh này sẽ xóa tất cả chứng chỉ SSL được quản lý bởi acme.sh
################################################################################

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cảnh báo
echo ""
print_warning "========================================"
print_warning "CẢNH BÁO - GỠ BỎ ACME.SH"
print_warning "========================================"
echo ""
print_warning "Lệnh này sẽ:"
print_warning "❌ XÓA tất cả chứng chỉ SSL"
print_warning "❌ XÓA tất cả cấu hình acme.sh"
print_warning "❌ XÓA auto-renew cron job"
print_warning "❌ XÓA file acme.sh"
echo ""
print_warning "KHÔNG THỂ HOÀN TÁC SAU KHI XÓA!"
echo ""

# Xác nhận
read -p "Bạn có CHẮC CHẮN muốn gỡ bỏ acme.sh? (y/N): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    print_info "Huỷ bỏ. Không xóa gì."
    exit 0
fi

# Xác nhận lần 2
read -p "BẠN CHẮC CHẮN? (Nhập 'yes' để xác nhận): " second_confirm

if [ "$second_confirm" != "yes" ]; then
    print_info "Huỷ bỏ. Không xóa gì."
    exit 0
fi

echo ""
print_info "Đang gỡ bỏ acme.sh..."

# Gỡ uninstall nếu có
if command -v acme.sh &> /dev/null; then
    if [ -f ~/.acme.sh/acme.sh ]; then
        print_info "Chạy uninstall script..."
        ~/.acme.sh/acme.sh --uninstall 2>/dev/null || true
    fi
fi

# Xóa thư mục acme.sh
if [ -d ~/.acme.sh ]; then
    print_info "Xóa thư mục ~/.acme.sh..."
    rm -rf ~/.acme.sh
fi

# Xóa cron job
print_info "Xóa cron job..."
if command -v crontab &> /dev/null; then
    # Xóa acme.sh từ crontab nếu có
    crontab -l 2>/dev/null | grep -v acme | crontab - 2>/dev/null || true
fi

# Xóa từ bashrc
print_info "Xóa từ bashrc..."
if grep -q "acme.sh" ~/.bashrc 2>/dev/null; then
    sed -i "/acme.sh/d" ~/.bashrc
fi

echo ""
print_info "========================================"
print_info "Gỡ bỏ acme.sh hoàn tất"
print_info "========================================"
echo ""
print_warning "Tất cả chứng chỉ SSL đã bị xóa"
print_warning "Website của bạn KHÔNG còn SSL nữa"
print_warning "Hãy cài lại nếu muốn:"
print_warning "  bash install-ssl.sh your@email.com domain.com ~/public_html"
echo ""
