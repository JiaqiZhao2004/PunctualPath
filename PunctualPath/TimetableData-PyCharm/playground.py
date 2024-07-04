import json
import time
from enum import Enum
from PIL import Image
from ImageProcessing import load_timetable
from utils import get_lines, OperationTime, BeijingSubway

# class SavedJPG(Enum):
#     WUKESONG = "1号线-五棵松站-古城站方向-双休日.jpg"
#     GUOMAO = "1号线-国贸站-环球度假区站方向-工作日.jpg"
#     GULOUDAJIE = "2号线-鼓楼大街站-积水潭站方向-工作日.jpg"
#     BEIXINQIAO = "5号线-北新桥站-天通苑北站方向-双休日.jpg"
# code = SavedJPG.GUOMAO
# img = Image.open(code.value)

path = "data/urls.json"
lines = BeijingSubway.from_json_file(path)

# for line in lines.get_lines():
#     for station in line.get_stations():
#         for TIME in OperationTime:
#             for url in station.get_tb_urls(TIME):


    # for station in lines.get_line(line_name).stations:
    #     print(station.native_name)
    #     for time in OperationTime:
    #         print(time)

# station_images = lines.get_line("1号线/八通线").get_station("八宝山").get_tb_urls(OperationTime.WEEKDAY)
# img: Image.Image = station_images.get_img()
# # img.show()
#
# table = load_timetable(img, filter=True, verbose=False)
# print(table)
#
# while True:
#     # Code executed here
#     print('\r' + table.next_train(), end='')
#     time.sleep(1)

