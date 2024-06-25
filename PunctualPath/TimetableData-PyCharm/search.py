import json
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

image_url = lines.get_line("1号线/八通线").get_station("复兴门").get_tb(OperationTime.WEEKDAY)
img: Image.Image = image_url.get_img()
img.show()

table = load_timetable(img, filter=True, verbose=False)
print(table)
