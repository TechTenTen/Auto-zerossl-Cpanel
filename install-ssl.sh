#!/bin/bash

################################################################################
# AutoSSL - Tự động cài đặt SSL ZeroSSL trên cPanel
# Script này sẽ thực hiện tất cả các bước cần thiết để cài đặt SSL miễn phí
################################################################################

set -e  # Dừng script nếu có lỗi

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Hàm in ra tin nhắn
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Kiểm tra xem user có nhập đủ tham số không
if [ $# -lt 3 ]; then
    print_error "Cách sử dụng: $0 <email> <domain> <webroot_path>"
    echo ""
    echo "Ví dụ:"
    echo "  $0 my@example.com mydomain.com ~/public_html"
    echo "  $0 my@example.com subdomain.mydomain.com ~/public_html/subdomain"
    exit 1
fi

EMAIL=$1
DOMAIN=$2
WEBROOT=$3

print_info "======================================"
print_info "AutoSSL - Cài đặt SSL ZeroSSL"
print_info "======================================"
print_info "Email: $EMAIL"
print_info "Domain: $DOMAIN"
print_info "Webroot: $WEBROOT"
print_info ""

# Bước 1: Kiểm tra webroot có tồn tại không
if [ ! -d "$WEBROOT" ]; then
    print_error "Thư mục webroot không tồn tại: $WEBROOT"
    exit 1
fi

print_info "✓ Thư mục webroot đã được xác nhận"

# Bước 2: Cài đặt acme.sh nếu chưa có
if ! command -v acme.sh &> /dev/null; then
    print_info "Đang cài đặt acme.sh..."
    wget -O - https://get.acme.sh | sh -s email=$EMAIL
    
    # Load bashrc để nhận diện biến môi trường của acme.sh
    source ~/.bashrc
    
    if command -v acme.sh &> /dev/null; then
        print_info "✓ acme.sh đã được cài đặt thành công"
    else
        print_error "Cài đặt acme.sh thất bại"
        exit 1
    fi
else
    print_info "✓ acme.sh đã tồn tại trên hệ thống"
fi

# Bước 3: Yêu cầu cấp chứng chỉ SSL từ ZeroSSL
print_info ""
print_info "Đang yêu cầu cấp chứng chỉ SSL từ ZeroSSL..."
print_info "Quá trình này sẽ mất khoảng 1-2 phút..."

if acme.sh --issue --webroot "$WEBROOT" -d "$DOMAIN" -d "www.$DOMAIN" --force; then
    print_info "✓ Chứng chỉ SSL đã được cấp thành công"
else
    print_error "Cấp chứng chỉ SSL thất bại"
    print_error "Vui lòng kiểm tra:"
    print_error "  - Tên miền đã trỏ đúng về IP không?"
    print_error "  - Đường dẫn webroot có chính xác không?"
    exit 1
fi

# Bước 4: Triển khai chứng chỉ vào cPanel
print_info ""
print_info "Đang triển khai chứng chỉ vào cPanel..."

if acme.sh --deploy --deploy-hook cpanel_uapi -d "$DOMAIN" -d "www.$DOMAIN"; then
    print_info "✓ Chứng chỉ SSL đã được triển khai thành công"
else
    print_error "Triển khai chứng chỉ thất bại"
    print_warning "Bạn có thể thử triển khai lại bằng lệnh:"
    print_warning "acme.sh --deploy --deploy-hook cpanel_uapi -d $DOMAIN -d www.$DOMAIN"
    exit 1
fi

# Bước 5: Kiểm tra auto-renew
print_info ""
print_info "Kiểm tra cấu hình tự động gia hạn..."

if acme.sh --info -d "$DOMAIN" | grep -q "renewal-hook"; then
    print_info "✓ Tự động gia hạn đã được cấu hình"
else
    print_warning "Cấu hình tự động gia hạn. acme.sh sẽ tự động gia hạn chứng chỉ trong vòng 60 ngày"
fi

# Hiển thị kết quả cuối cùng
print_info ""
print_info "======================================"
print_info "✓ CÀI ĐẶT SSL HOÀN TẤT!"
print_info "======================================"
print_info ""
print_info "Các thông tin chứng chỉ:"
acme.sh --info -d "$DOMAIN"
print_info ""
print_info "Tiếp theo:"
print_info "1. Chờ 1-2 phút để DNS cập nhật"
print_info "2. Truy cập https://$DOMAIN để kiểm tra ổ khóa xanh"
print_info "3. Chứng chỉ sẽ tự động gia hạn trước khi hết hạn"
print_info ""
