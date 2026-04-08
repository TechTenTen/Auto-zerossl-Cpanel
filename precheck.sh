#!/bin/bash

################################################################################
# PreCheck - Kiểm tra yêu cầu trước cài đặt SSL
# Script này giúp xác nhận hosting của bạn sẵn sàng cài đặt SSL
################################################################################

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_pass() {
    echo -e "${GREEN}✓ PASS${NC} - $1"
}

print_fail() {
    echo -e "${RED}✗ FAIL${NC} - $1"
}

print_warn() {
    echo -e "${YELLOW}⚠ WARN${NC} - $1"
}

# Đếm kết quả
PASS=0
FAIL=0
WARN=0

print_header "Kiểm tra yêu cầu cài đặt SSL"
echo ""

# 1. Kiểm tra shell
print_header "1. Kinểm tra Shell"
if [ -n "$BASH" ]; then
    print_pass "Sử dụng Bash shell"
    ((PASS++))
else
    print_fail "Không sử dụng Bash shell"
    ((FAIL++))
fi
echo ""

# 2. Kiểm tra quyền cơ bản
print_header "2. Kiểm tra quyền"
if [ -w "$HOME" ]; then
    print_pass "Có quyền ghi trong home directory"
    ((PASS++))
else
    print_fail "Không có quyền ghi trong home directory"
    ((FAIL++))
fi
echo ""

# 3. Kiểm tra các lệnh quan trọng
print_header "3. Kiểm tra lệnh/công cụ"

# wget
if command -v wget &> /dev/null; then
    print_pass "wget có sẵn"
    ((PASS++))
else
    print_warn "wget không có sẵn (sẽ cài tự động)"
    ((WARN++))
fi

# curl
if command -v curl &> /dev/null; then
    print_pass "curl có sẵn"
    ((PASS++))
else
    print_warn "curl không có sẵn"
    ((WARN++))
fi

# git (tùy chọn)
if command -v git &> /dev/null; then
    print_pass "git có sẵn"
    ((PASS++))
else
    print_warn "git không có sẵn (không bắt buộc)"
    ((WARN++))
fi

echo ""

# 4. Kiểm tra public_html
print_header "4. Kiểm tra thư mục webroot"
if [ -d "$HOME/public_html" ]; then
    print_pass "~/public_html tồn tại"
    ((PASS++))
    
    if [ -w "$HOME/public_html" ]; then
        print_pass "Có quyền ghi vào ~/public_html"
        ((PASS++))
    else
        print_fail "Không có quyền ghi vào ~/public_html"
        ((FAIL++))
    fi
else
    print_fail "~/public_html không tồn tại"
    ((FAIL++))
fi
echo ""

# 5. Kiểm tra port 80
print_header "5. Kiểm tra port 80 (DNS validation)"
if timeout 5 bash -c "</dev/tcp/127.0.0.1/80" 2>/dev/null; then
    print_pass "Port 80 có thể truy cập"
    ((PASS++))
else
    print_warn "Port 80 không thể truy cập từ localhost (hoàn toàn bình thường)"
    ((WARN++))
fi
echo ""

# 6. Kiểm tra kết nối internet
print_header "6. Kiểm tra kết nối internet"
if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
    print_pass "Kết nối internet có sẵn"
    ((PASS++))
else
    print_fail "Không thể kết nối internet"
    ((FAIL++))
fi
echo ""

# 7. Kiểm tra domain
print_header "7. Kiểm tra DNS (cần nhập domain)"
read -p "Nhập tên domain để kiểm tra [bỏ qua nếu muốn]: " test_domain

if [ -n "$test_domain" ]; then
    if getent hosts "$test_domain" &> /dev/null; then
        RESOLVED_IP=$(getent hosts "$test_domain" | awk '{ print $1 }')
        print_pass "Domain '$test_domain' đã resolve: $RESOLVED_IP"
        ((PASS++))
        
        # Kiểm tra IP có trùng server IP không
        if command -v hostname &> /dev/null; then
            SERVER_IP=$(hostname -I | awk '{print $1}')
            if [ "$RESOLVED_IP" = "$SERVER_IP" ]; then
                print_pass "Domain trỏ đúng đến server ($SERVER_IP)"
                ((PASS++))
            else
                print_warn "Domain trỏ đến $RESOLVED_IP, nhưng server IP là $SERVER_IP"
                ((WARN++))
            fi
        fi
    else
        print_fail "Không thể resolve domain '$test_domain'"
        print_warn "Hãy kiểm tra cấu hình DNS tại Registrar"
        ((FAIL++))
    fi
else
    print_warn "Không kiểm tra domain"
fi
echo ""

# 8. Kiểm tra acme.sh đã cài chưa
print_header "8. Kiểm tra acme.sh"
if command -v acme.sh &> /dev/null; then
    print_pass "acme.sh đã cài đặt"
    ACME_VERSION=$(acme.sh --version)
    echo -e "${BLUE}  Version: $ACME_VERSION${NC}"
    ((PASS++))
else
    print_warn "acme.sh chưa cài đặt (sẽ cài tự động)"
    ((WARN++))
fi
echo ""

# 9. Kiểm tra PHP/Apache (tùy chọn)
print_header "9. Kiểm tra web server"
if command -v apache2ctl &> /dev/null; then
    print_pass "Apache có sẵn"
    ((PASS++))
elif command -v nginx &> /dev/null; then
    print_pass "Nginx có sẵn"
    ((PASS++))
else
    print_warn "Không tìm thấy Apache hoặc Nginx (cPanel thường có sẵn)"
    ((WARN++))
fi
echo ""

# Tóm tắt kết quả
print_header "Tóm tắt kết quả kiểm tra"
echo -e "${GREEN}Pass:${NC} $PASS"
echo -e "${YELLOW}Warning:${NC} $WARN"
echo -e "${RED}Fail:${NC} $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ Hệ thống của bạn sẵn sàng cài đặt SSL!${NC}"
    echo ""
    echo "Bạn có thể chạy:"
    echo "  bash install-ssl.sh your@email.com domain.com ~/public_html"
    exit 0
else
    echo -e "${RED}✗ Có vấn đề cần được giải quyết trước khi cài đặt SSL${NC}"
    echo ""
    echo "Vui lòng xem mục 'Xử lý sự cố' trong README.md"
    exit 1
fi
