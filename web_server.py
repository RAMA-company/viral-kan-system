import os
import json
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

# تنظیمات
PORT = 8080
CONFIG_PATH = "dashboard/config.json"

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            if self.path == '/reset':
                # اجرای ریست سیستم
                os.system("./run_system.sh --reset &")
                
                # به‌روزرسانی زمان آخرین ریست
                with open(CONFIG_PATH, 'r') as f:
                    config = json.load(f)
                config['last_reset'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                with open(CONFIG_PATH, 'w') as f:
                    json.dump(config, f)
                
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'OK')
                
            elif self.path.startswith('/update-schedule'):
                # استخراج ساعت جدید
                hours = int(self.path.split('=')[1])
                
                # به‌روزرسانی برنامه‌ریزی
                with open(CONFIG_PATH, 'r') as f:
                    config = json.load(f)
                config['schedule'] = hours
                with open(CONFIG_PATH, 'w') as f:
                    json.dump(config, f)
                
                # اعمال تنظیمات جدید
                os.system("./run_system.sh --update-schedule &")
                
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'OK')
                
            else:
                self.send_response(404)
                self.end_headers()
                
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())

def run_server():
    server = HTTPServer(('', PORT), RequestHandler)
    print(f"🌐 سرور وب در حال اجرا روی پورت {PORT}")
    server.serve_forever()

if __name__ == "__main__":
    # ایجاد فایل تنظیمات اولیه
    if not os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, 'w') as f:
            json.dump({
                "schedule": 6,
                "last_reset": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }, f)
    
    run_server()
