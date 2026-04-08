#!/bin/bash

################################################################################
# AutoSSL Batch - Cài đặt SSL cho nhiều domain cùng một lúc
# Script này cho phép bạn cài đặt SSL cho nhiều domain bằng file config
################################################################################

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Kiểm tra đầu vào
if [ $# -eq 0 ]; then
    print_error "Cách sử dụng: $0 <file_config>"
    echo ""
    echo "Tạo file domains.conf với nội dung như sau:"
    echo "======================================"
    echo "# domains.conf"
    echo "EMAIL=my@example.com"
    echo ""
    echo "# Format: domain:webroot"
    echo "mydomain.com:~/public_html"
    echo "blog.mydomain.com:~/public_html/blog"
    echo "shop.example.com:~/public_html/shop"
    echo "======================================"
    exit 1
fi

CONFIG_FILE=$1

# Kiểm tra file config có tồn tại không
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "File config không tồn tại: $CONFIG_FILE"
    exit 1
fi

# Đọc file config
EMAIL=""
DOMAINS=()

while IFS= read -r line || [ -n "$line" ]; do
    # Bỏ qua dòng trống và chú thích
    [[ -z "$line" || "$line" == "#"* ]] && continue
    
    # Đọc EMAIL
    if [[ $line == EMAIL=* ]]; then
        EMAIL="${line#EMAIL=}"
        continue
    fi
    
    # Đọc domain:webroot
    if [[ $line == *":"* ]]; then
        DOMAINS+=("$line")
    fi
done < "$CONFIG_FILE"

# Kiểm tra EMAIL
if [ -z "$EMAIL" ]; then
    print_error "EMAIL không được định nghĩa trong file config"
    exit 1
fi

# Kiểm tra có domain nào không
if [ ${#DOMAINS[@]} -eq 0 ]; then
    print_error "Không tìm thấy domain nào trong file config"
    exit 1
fi

print_info "======================================"
print_info "AutoSSL Batch - Cài đặt SSL Hàng loạt"
print_info "======================================"
print_info "Email: $EMAIL"
print_info "Số lượng domain: ${#DOMAINS[@]}"
print_info ""

# Cài đặt acme.sh nếu chưa có
if ! command -v acme.sh &> /dev/null; then
    print_info "Đang cài đặt acme.sh..."
    wget -O - https://get.acme.sh | sh -s email=$EMAIL
    source ~/.bashrc
    print_info "✓ acme.sh đã được cài đặt"
fi

# Xử lý từng domain
SUCCESS_COUNT=0
FAIL_COUNT=0

for domain_config in "${DOMAINS[@]}"; do
    IFS=':' read -r DOMAIN WEBROOT <<< "$domain_config"
    
    # Xóa khoảng trắng
    DOMAIN=$(echo $DOMAIN | xargs)
    WEBROOT=$(echo $WEBROOT | xargs)
    
    print_info ""
    print_info "=================================================="
    print_info "Xử lý: $DOMAIN"
    print_info "Webroot: $WEBROOT"
    print_info "=================================================="
    
    # Kiểm tra webroot
    if [ ! -d "$WEBROOT" ]; then
        print_error "Thư mục không tồn tại: $WEBROOT"
        ((FAIL_COUNT++))
        continue
    fi
    
    # Cấp chứng chỉ
    if acme.sh --issue --webroot "$WEBROOT" -d "$DOMAIN" -d "www.$DOMAIN" --force 2>&1; then
        print_info "✓ Cấp chứng chỉ thành công: $DOMAIN"
        
        # Triển khai
        if acme.sh --deploy --deploy-hook cpanel_uapi -d "$DOMAIN" -d "www.$DOMAIN" 2>&1; then
            print_info "✓ Triển khai thành công: $DOMAIN"
            ((SUCCESS_COUNT++))
        else
            print_error "Triển khai thất bại: $DOMAIN"
            ((FAIL_COUNT++))
        fi
    else
        print_error "Cấp chứng chỉ thất bại: $DOMAIN"
        ((FAIL_COUNT++))
    fi
done

# Tóm tắt kết quả
print_info ""
print_info "======================================"
print_info "Kết quả tổng hợp"
print_info "======================================"
print_info "Thành công: $SUCCESS_COUNT"
print_error "Thất bại: $FAIL_COUNT"
print_info "Tổng: ${#DOMAINS[@]}"
print_info ""

if [ $FAIL_COUNT -eq 0 ]; then
    print_info "✓ Tất cả domain đã được cài đặt SSL thành công!"
else
    print_warning "Có $FAIL_COUNT domain cài đặt thất bại. Vui lòng kiểm tra lại."
fi
