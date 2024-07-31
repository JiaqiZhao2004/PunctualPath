import json
import time
from enum import Enum
from PIL import Image
from utils import load_timetable, OperationTime, BeijingSubway

# class SavedJPG(Enum):
#     WUKESONG = "1号线-五棵松站-古城站方向-双休日.jpg"
#     GUOMAO = "1号线-国贸站-环球度假区站方向-工作日.jpg"
#     GULOUDAJIE = "2号线-鼓楼大街站-积水潭站方向-工作日.jpg"
#     BEIXINQIAO = "5号线-北新桥站-天通苑北站方向-双休日.jpg"
# code = SavedJPG.GUOMAO
# img = Image.open(code.value)

path = "data/urls.json"
lines = BeijingSubway.from_json_file(path)

stations = ["宋家庄",
            "刘家窑",
            "蒲黄榆",
            "天坛东门",
            "磁器口",
            "崇文门",
            "东单",
            "灯市口",
            "东四",
            "张自忠路",
            "北新桥",
            "雍和宫",
            "和平里北街",
            "和平西桥",
            "惠新西街南口",
            "惠新西街北口",
            "大屯路东",
            "北苑路北",
            "立水桥南",
            "立水桥",
            "天通苑南",
            "天通苑",
            "天通苑北"]
for station in stations:
    for time_ in [OperationTime.WEEKEND, OperationTime.WEEKDAY]:
        station_images = lines.get_line("5号线").get_station(station).get_tb_urls(time_)
        img: Image.Image = station_images.get_img()
        img.show()
        table = load_timetable(img, filter=True, verbose=False)
        print(table)
        time.sleep(30)


# while True:
#     # Code executed here
#     print('\r' + table.next_train(), end='')
#     time.sleep(1)
