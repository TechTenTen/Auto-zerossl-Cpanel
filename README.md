# AutoSSL - Tự động cài SSL trên cPanel

Công cụ tự động hóa cài đặt chứng chỉ SSL ZeroSSL miễn phí trên cPanel. Sử dụng acme.sh để quản lý và tự động gia hạn chứng chỉ.

## Yêu cầu

- cPanel Account với quyền Terminal
- Tên miền đã trỏ đúng IP hosting
- Email hợp lệ
- Bash shell (Linux)

## Cài đặt nhanh

### Cách 1: Clone repo (Khuyên dùng)

Chạy lệnh trong Terminal cPanel:

```bash
git clone https://github.com/TechTenTen/Auto-zerossl-Cpanel
cd Auto-zerossl-Cpanel
bash install-ssl.sh admin@example.com example.com ~/public_html
```

### Cách 2: Chạy script trực tiếp từ GitHub

Nếu không muốn clone, chạy lệnh này:

```bash
bash <(curl -s https://raw.githubusercontent.com/TechTenTen/Auto-zerossl-Cpanel/main/install-ssl.sh) admin@example.com example.com ~/public_html
```

Thay thế:
- admin@example.com: Email của bạn
- example.com: Tên miền
- ~/public_html: Đường dẫn thư mục website

Lệnh sẽ:
1. Kiểm tra thư mục
2. Cài đặt acme.sh
3. Cấp chứng chỉ từ ZeroSSL
4. Triển khai vào cPanel
5. Xác nhận tự động gia hạn

Hoàn tất trong 1-2 phút.

### Cài SSL cho nhiều domain

Clone repo và tạo file config:

```bash
git clone https://github.com/TechTenTen/Auto-zerossl-Cpanel
cd Auto-zerossl-Cpanel
cp domains.conf.example domains.conf
nano domains.conf
```

Chỉnh sửa nội dung:

```
EMAIL=admin@example.com

example.com:~/public_html
blog.example.com:~/public_html_blog
api.example.com:~/public_html/api
```

Nhấn Ctrl+X, Y, Enter để lưu.

Chạy:

```bash
bash install-ssl-batch.sh domains.conf
```

## Các Script Có Sẵn

Cách chạy: Clone repo hoặc chạy trực tiếp từ GitHub.

### install-ssl.sh
Cài SSL cho 1 domain.

Cách dùng:
```bash
# Từ GitHub
bash <(curl -s https://raw.githubusercontent.com/TechTenTen/Auto-zerossl-Cpanel/main/install-ssl.sh) <email> <domain> <webroot>

# Hoặc clone repo rồi chạy
bash install-ssl.sh <email> <domain> <webroot>
```

### install-ssl-batch.sh
Cài SSL cho nhiều domain từ file config.

Cách dùng (cần clone repo):
```bash
bash install-ssl-batch.sh domains.conf
```

### ssl-manager.sh
Menu quản lý chứng chỉ SSL (liệt kê, kiểm tra, tái cấp, xóa chứng chỉ).

Cách dùng (cần clone repo):
```bash
bash ssl-manager.sh
```

### precheck.sh
Kiểm tra hệ thống sẵn sàng cài đặt.

Cách dùng:
```bash
# Từ GitHub
bash <(curl -s https://raw.githubusercontent.com/TechTenTen/Auto-zerossl-Cpanel/main/precheck.sh)

# Hoặc clone repo rồi chạy
bash precheck.sh
```

## Xác định Webroot

Cách 1: Trong cPanel
- Mở cPanel, chọn "Addon Domains"
- Tìm domain, xem "Document Root"

Cách 2: Dùng Terminal
```bash
ls -la ~/ | grep public
```

Phổ biến:
- Domain chính: ~/public_html
- Addon domain: ~/public_html_tenmien hoặc ~/public_html/tenmien
- Subdomain: ~/public_html/subdomain

## Kiểm tra Kết Quả

Sau cài đặt:

1. Chờ 1-2 phút
2. Truy cập https://domain.com
3. Xem ổ khóa xanh trên thanh URL = Thành công

Hoặc dùng lệnh:
```bash
acme.sh --info -d example.com
```

## Tự Động Gia Hạn

Không cần làm gì. acme.sh sẽ:
- Kiểm tra mỗi ngày
- Tự động gia hạn trước 60 ngày hết hạn
- Chứng chỉ 90 ngày

Kiểm tra:
```bash
acme.sh --info -d example.com
```

## Xử Lý Sự Cố

### Domain validation failed
Nguyên nhân: Tên miền chưa trỏ đúng IP

Giải pháp:
1. Kiểm tra IP hosting (cPanel Home, Server IP)
2. Đi Registrar (GoDaddy, Cloudflare...)
3. Cập nhật A Record thành IP hosting
4. Chờ 5-30 phút DNS cập nhật
5. Chạy lại script

Kiểm tra DNS:
```bash
nslookup example.com
dig example.com A
```

### Directory not found
Nguyên nhân: Đường dẫn webroot sai

Giải pháp:
```bash
# Kiểm tra thư mục
ls -la ~/public_html
ls -la ~/public_html_blog

# Chạy lại với webroot đúng
bash install-ssl.sh admin@example.com example.com ~/public_html_blog
```

### acme.sh: command not found
Nguyên nhân: acme.sh chưa cài

Giải pháp:
```bash
wget -O - https://get.acme.sh | sh -s email=admin@example.com
source ~/.bashrc
bash install-ssl.sh admin@example.com example.com ~/public_html
```

### Port 80 not accessible
Nguyên nhân: Firewall chặn HTTP

Giải pháp: Sử dụng DNS validation
```bash
acme.sh --issue --dns -d example.com
# Thêm TXT record theo hướng dẫn vào Zone Editor cPanel
```

### Certificate already exists
Lệnh sẽ tự động ghi đè chứng chỉ cũ.

Nếu muốn xóa trước:
```bash
bash ssl-manager.sh
# Chọn: 5 (Xóa)
```

### Chứng chỉ không hiện ổ khóa xanh
Kiểm tra SSL đã cài vào cPanel:
```bash
bash ssl-manager.sh
# Chọn: 2 (Kiểm tra tình trạng)
```

Nếu chưa cài, deploy thủ công:
```bash
acme.sh --deploy --deploy-hook cpanel_uapi -d example.com
```

## Lệnh Hữu Ích

```bash
# Xem tất cả chứng chỉ
acme.sh --list

# Chi tiết 1 chứng chỉ
acme.sh --info -d example.com

# Gia hạn manual
acme.sh --renew -d example.com

# Xóa chứng chỉ
acme.sh --remove -d example.com

# Deploy lại
acme.sh --deploy --deploy-hook cpanel_uapi -d example.com

# Xem log lỗi
tail -f ~/.acme.sh/acme.sh.log

# Kiểm tra cron job
crontab -l | grep acme

# Gỡ bỏ acme.sh
bash uninstall-acme.sh
```

## FAQ

**Q: Có cần tài khoản ZeroSSL không?**
A: Không. acme.sh tự động tạo.

**Q: Chứng chỉ hết hạn bao lâu?**
A: 90 ngày. acme.sh tự động gia hạn sau 60 ngày.

**Q: Xóa chứng chỉ thì sao?**
A: Chạy lại install-ssl.sh để cấp mới.

**Q: Cài SSL cho tên miền con không?**
A: Có. Cấu hình giống domain chính.

**Q: Nếu không có quyền Terminal?**
A: Yêu cầu hosting kích hoạt hoặc sử dụng SSH.

**Q: Sau cài xong có cần làm gì?**
A: Không. Truy cập https:// là xong.

**Q: Tại sao mất 1-2 phút?**
A: Thời gian xác thực domain với ZeroSSL.

## An Toàn

- ZeroSSL là nhà cung cấp uy tín
- Mã hóa đầy đủ
- Miễn phí, không chi phí ẩn
- Tự động gia hạn
- Tương thích 99% trình duyệt

## Cấu Trúc File

Repository: https://github.com/TechTenTen/Auto-zerossl-Cpanel

```
Auto-zerossl-Cpanel/
├── install-ssl.sh           Cài SSL cho 1 domain
├── install-ssl-batch.sh     Cài SSL cho nhiều domain
├── ssl-manager.sh           Menu quản lý SSL
├── precheck.sh              Kiểm tra yêu cầu
├── uninstall-acme.sh        Gỡ bỏ acme.sh
├── domains.conf.example     File config mẫu
├── README.md                File này
└── note.txt                 Note gốc hướng dẫn
```

## Bắt Đầu Nhanh

Cách 1: Clone repo (dễ nhất, tất cả script sẵn sàng)
```bash
git clone https://github.com/TechTenTen/Auto-zerossl-Cpanel
cd Auto-zerossl-Cpanel
bash precheck.sh
bash install-ssl.sh admin@example.com example.com ~/public_html
```

Cách 2: Chạy trực tiếp từ GitHub (không cần clone)
```bash
bash <(curl -s https://raw.githubusercontent.com/TechTenTen/Auto-zerossl-Cpanel/main/precheck.sh)
bash <(curl -s https://raw.githubusercontent.com/TechTenTen/Auto-zerossl-Cpanel/main/install-ssl.sh) admin@example.com example.com ~/public_html
```

Sau khi chạy:
1. Chờ 1-2 phút
2. Truy cập https://example.com
3. Xem ổ khóa xanh = Thành công

## Thêm Domain Sau

Nếu đã clone repo:
```bash
cd Auto-zerossl-Cpanel
bash install-ssl.sh admin@example.com newdomain.com ~/public_html_new
```

Hoặc chạy từ GitHub:
```bash
bash <(curl -s https://raw.githubusercontent.com/TechTenTen/Auto-zerossl-Cpanel/main/install-ssl.sh) admin@example.com newdomain.com ~/public_html_new
```

Hoặc dùng manager (cần clone repo):
```bash
cd Auto-zerossl-Cpanel
bash ssl-manager.sh
# Chọn: 3 (Tái cấp chứng chỉ)
```

## Liên Hệ

Nếu gặp vấn đề:
1. Chạy bash precheck.sh
2. Kiểm tra phần "Xử Lý Sự Cố" trên
3. Xem log: tail -f ~/.acme.sh/acme.sh.log

Version 1.0 - 2024
