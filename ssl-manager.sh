#!/bin/bash

################################################################################
# AutoSSL Manager - Quản lý và duy trì chứng chỉ SSL
# Script này giúp quản lý chứng chỉ, tái gia hạn, xóa chứng chỉ cũ
################################################################################

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_menu() {
    echo -e "${BLUE}=== Menu Quản Lý SSL ===${NC}"
    echo "1. Liệt kê các chứng chỉ SSL đang có"
    echo "2. Kiểm tra tình trạng chứng chỉ"
    echo "3. Tái cấp chứng chỉ cho domain"
    echo "4. Tái triển khai chứng chỉ lên cPanel"
    echo "5. Xóa chứng chỉ"
    echo "6. Kiểm tra auto-renew"
    echo "7. Thoát"
    echo ""
    read -p "Chọn một tùy chọn (1-7): " choice
}

# Hàm liệt kê các chứng chỉ
list_certs() {
    print_info "Danh sách các chứng chỉ:"
    acme.sh --list
}

# Hàm kiểm tra tình trạng chứng chỉ
check_cert_status() {
    read -p "Nhập tên domain (vd: mydomain.com): " domain
    
    if [ -z "$domain" ]; then
        print_error "Tên domain không được để trống"
        return
    fi
    
    print_info "Thông tin chứng chỉ cho domain: $domain"
    acme.sh --info -d "$domain"
}

# Hàm tái cấp chứng chỉ
renew_cert() {
    read -p "Nhập tên domain (vd: mydomain.com): " domain
    read -p "Nhập đường dẫn webroot (vd: ~/public_html): " webroot
    
    if [ -z "$domain" ] || [ -z "$webroot" ]; then
        print_error "Domain và webroot không được để trống"
        return
    fi
    
    if [ ! -d "$webroot" ]; then
        print_error "Thư mục webroot không tồn tại: $webroot"
        return
    fi
    
    print_info "Đang tái cấp chứng chỉ cho domain: $domain"
    
    if acme.sh --issue --webroot "$webroot" -d "$domain" -d "www.$domain" --force; then
        print_info "✓ Tái cấp chứng chỉ thành công"
    else
        print_error "Tái cấp chứng chỉ thất bại"
        return 1
    fi
}

# Hàm tái triển khai chứng chỉ
redeploy_cert() {
    read -p "Nhập tên domain (vd: mydomain.com): " domain
    
    if [ -z "$domain" ]; then
        print_error "Tên domain không được để trống"
        return
    fi
    
    print_info "Đang tái triển khai chứng chỉ lên cPanel: $domain"
    
    if acme.sh --deploy --deploy-hook cpanel_uapi -d "$domain" -d "www.$domain"; then
        print_info "✓ Tái triển khai thành công"
    else
        print_error "Tái triển khai thất bại"
        return 1
    fi
}

# Hàm xóa chứng chỉ
remove_cert() {
    read -p "Nhập tên domain cần xóa (vd: mydomain.com): " domain
    
    if [ -z "$domain" ]; then
        print_error "Tên domain không được để trống"
        return
    fi
    
    read -p "Bạn có chắc muốn xóa chứng chỉ của $domain không? (y/n): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_warning "Hủy bỏ"
        return
    fi
    
    print_info "Đang xóa chứng chỉ của domain: $domain"
    
    if acme.sh --remove -d "$domain"; then
        print_info "✓ Xóa chứng chỉ thành công"
    else
        print_error "Xóa chứng chỉ thất bại"
        return 1
    fi
}

# Hàm kiểm tra auto-renew
check_auto_renew() {
    print_info "Kiểm tra cấu hình tự động gia hạn chứng chỉ..."
    print_info ""
    
    # Kiểm tra cron job
    if crontab -l 2>/dev/null | grep -q "acme.sh"; then
        print_info "✓ Cron job đã được cấu hình:"
        crontab -l 2>/dev/null | grep "acme.sh"
    else
        print_warning "Không tìm thấy cron job cho acme.sh"
        print_info "Bạn có thể tạo cron job bằng lệnh:"
        print_info "acme.sh --install-cronjob"
    fi
}

# Vòng lặp chính
while true; do
    echo ""
    print_menu
    
    case $choice in
        1)
            list_certs
            ;;
        2)
            check_cert_status
            ;;
        3)
            renew_cert
            ;;
        4)
            redeploy_cert
            ;;
        5)
            remove_cert
            ;;
        6)
            check_auto_renew
            ;;
        7)
            print_info "Thoát chương trình"
            exit 0
            ;;
        *)
            print_error "Lựa chọn không hợp lệ"
            ;;
    esac
done
