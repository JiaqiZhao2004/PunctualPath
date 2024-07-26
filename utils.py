import json
from enum import Enum
import requests
from PIL import Image
from bs4 import BeautifulSoup
from tqdm import tqdm
from datetime import datetime
import colorsys
import cv2
import numpy as np
from matplotlib import pyplot as plt
from ocrmac import ocrmac


class OperationTime(Enum):
    WEEKDAY = "工作日"
    WEEKEND = "双休日"


class TimetableURL(object):
    def __init__(self):
        self.urls: list[str] = []

    def __str__(self):
        return f"{self.urls}"

    def add_url(self, url: str):
        self.urls.append(url)

    def switch(self):
        self.urls = self.urls[1:] + self.urls[:1]
        return self

    def get_img(self) -> Image.Image:
        print(f"Getting image from {self.urls[0]}")
        img = Image.open(requests.get(self.urls[0], stream=True).raw)
        return img


class Station(object):
    def __init__(self, native_name: str):
        self.native_name = native_name
        self.weekday_urls: list[str] = []
        self.weekend_urls: list[str] = []
        self.unknown_urls: list[str] = []
        self.weekday_arrival_times: list[str] = []
        self.weekend_arrival_times: list[str] = []

    def __str__(self):
        return self.native_name

    def add_arrival_times(self, arrival_times: list[str], operation_time: OperationTime) -> None:
        if operation_time is OperationTime.WEEKDAY:
            self.weekday_arrival_times.extend(arrival_times)
        elif operation_time is OperationTime.WEEKEND:
            self.weekend_arrival_times.extend(arrival_times)

    def add_url(self, timetable_url: str) -> OperationTime or None:
        if '工作日' in timetable_url:
            self.weekday_urls.append(timetable_url)
            return OperationTime.WEEKDAY
        if '双休日' in timetable_url:
            self.weekend_urls.append(timetable_url)
            return OperationTime.WEEKEND
        if '工作日' not in timetable_url and '双休日' not in timetable_url:
            self.unknown_urls.append(timetable_url)
            return None

    def get_tb_urls(self, time: OperationTime):
        urls = TimetableURL()
        if time == OperationTime.WEEKDAY:
            for weekday_url in self.weekday_urls:
                urls.add_url(weekday_url)
        elif time == OperationTime.WEEKEND:
            for weekend_url in self.weekend_urls:
                urls.add_url(weekend_url)
        if len(urls.urls) == 0:
            for unknown_url in self.unknown_urls:
                urls.add_url(unknown_url)
        return urls

    def to_dict(self):
        return {
            'native_name': self.native_name,
            'weekday_tb': self.weekday_urls,
            'weekend_tb': self.weekend_urls,
            'unknown_tb': self.unknown_urls,
            'weekday_arrival_times': self.weekday_arrival_times,
            'weekend_arrival_times': self.weekend_arrival_times,
        }

    @classmethod
    def from_dict(cls, data):
        station = cls(data['native_name'])
        station.weekday_urls = data['weekday_tb']
        station.weekend_urls = data['weekend_tb']
        station.unknown_urls = data['unknown_tb']
        station.weekday_arrival_times = data['weekday_arrival_times']
        station.weekend_arrival_times = data['weekend_arrival_times']
        return station


class Line(object):
    def __init__(self, native_name: str, station_list: list[str], stations: dict[str, Station]):
        self.native_name = native_name
        self.station_list = station_list
        self.stations = stations
        assert len(self.stations) >= 2

    def __str__(self):
        return (
            f"Line(native_name={self.native_name}, stations={[str(station) for station in self.stations]})")

    def get_station(self, station: str):
        return self.stations.get(station)

    def get_stations(self):
        return self.stations.values()

    def to_dict(self):
        # Convert the stations dictionary to a JSON-serializable dictionary
        stations_dict = {name: station.to_dict() for name, station in self.stations.items()}
        return {
            'native_name': self.native_name,
            'station_list': self.station_list,
            'stations': stations_dict
        }

    @classmethod
    def from_dict(cls, data):
        # Convert the JSON-serializable dictionary back to a dictionary of Station objects
        stations = {name: Station.from_dict(station_data) for name, station_data in data['stations'].items()}
        return cls(data['native_name'], data['station_list'], stations)


class BeijingSubway(object):
    def __init__(self, lines=None):
        super().__init__()
        if lines is None:
            lines = dict()
        self.name = "BeijingSubway"
        self.lines: dict[str, Line] = lines

    def get_line(self, line: str):
        return self.lines.get(line)

    def get_lines(self):
        return self.lines.values()

    def __getitem__(self, key: str):
        return self.lines[key]

    def __setitem__(self, key, value):
        self.lines[key] = value

    def to_dict(self):
        beijing_subway_dict = {name: self.lines[name].to_dict() for name in self.lines}
        return {
            'name': self.name,
            'lines': beijing_subway_dict,
        }

    @classmethod
    def from_dict(cls, data):
        beijing_subway_dict = {name: Line.from_dict(line_data) for name, line_data in data['lines'].items()}
        return cls(beijing_subway_dict)

    @classmethod
    def from_json_file(cls, fp: str):
        with open(fp, 'r') as f:
            data = json.load(f)
            return cls.from_dict(data)


class Row(object):
    def __init__(self, hour: int):
        self.hour = hour
        self.minutes: list[int] = []

    def __str__(self):
        return str(self.hour) + '\t' + ' '.join(['0' + str(m) if len(str(m)) == 1 else str(m) for m in self.minutes])


class TimeTable(object):
    def __init__(self):
        self.rows: list[Row] = []

    def add_row(self, row: Row):
        self.rows.append(row)

    def __str__(self):
        return "Timetable:\n" + '\n'.join(str(row) for row in self.rows)

    def to_list(self) -> list[int]:
        schedule: list[int] = []
        for row in self.rows:
            for minute in row.minutes:
                schedule.append(hms_to_sec(row.hour, minute, 0))
        return schedule

    def to_list_str(self) -> list[str]:
        schedule: list[str] = []
        for row in self.rows:
            for minute in row.minutes:
                schedule.append(f"{row.hour}:{minute}")
        return schedule

    def next_train(self, h=None, m=None, s=0):
        if h is None or m is None:
            h, m, s = get_current_time()
        now_sec: int = hms_to_sec(h, m, s)
        schedule: list[int] = self.to_list()
        next_train = None
        next_2nd_train = None
        for i, timestamp in enumerate(schedule):
            if now_sec < safe_time(timestamp):
                next_train = sec_to_hms(safe_time(timestamp) - now_sec)
                if i == len(schedule) - 1:
                    next_2nd_train = sec_to_hms(safe_time(schedule[0]) - now_sec)
                else:
                    next_2nd_train = sec_to_hms(safe_time(schedule[i + 1]) - now_sec)
                break
        if next_train is None:
            return "No more trains"
        return f"\r{next_train[1]}:{next_train[2]}, {next_2nd_train[1]}:{next_2nd_train[2]}"


def safe_time(seconds: int) -> int:
    return seconds - 40


def hms_to_sec(h: int, m: int, s: int) -> int:
    return int(h) * 3600 + int(m) * 60 + int(s)


def sec_to_hms(s: int):
    h = int(s / 3600)
    s = s % 3600
    m = int(s / 60)
    s = s % 60
    return h, m, s


def get_current_time():
    time = datetime.now().strftime('%H:%M:%S')
    hour, minute, second = time.split(':')
    return int(hour), int(minute), int(second)


def get_station_timetables_url(station_url, root_path="https://www.bjsubway.com"):
    response = requests.get(root_path + station_url, stream=True)
    soup = BeautifulSoup(response.content, "html.parser")
    images = soup.find('li', class_="tab_con skk").find_all('img')
    images_url = []
    for img in images:
        images_url.append(root_path + img.get('src'))
    return images_url


def get_arrival_times(url: str) -> list[str]:
    img = Image.open(requests.get(url, stream=True).raw)
    table = load_timetable(img, filter=True, verbose=False)
    return table.to_list_str()


def get_lines() -> BeijingSubway:
    url = "https://www.bjsubway.com/station/xltcx/line1/"
    r = requests.get(url)
    r.encoding = r.apparent_encoding
    soup = BeautifulSoup(r.text, "html.parser")

    lines = BeijingSubway()

    # Find all line elements
    line_elements = soup.find_all('div', class_='line_name')[0:2]

    # Iterate through line elements
    for line_elem in tqdm(line_elements):
        # Extract line name
        line_native_name = line_elem.find('div').text.strip()

        # Find stations for the current line
        stations: dict[str, Station] = {}

        station_list: list[str] = []

        next_elem = line_elem.find_next_sibling()
        while next_elem and next_elem.get('class') == ['station']:
            station_native_name = next_elem.text.strip()
            station_list.append(station_native_name)
            a_element = next_elem.find('a')
            station = Station(native_name=station_native_name)
            if a_element is not None:
                station_href = a_element['href']
                station_timetables_url = get_station_timetables_url(station_href)
                for url in station_timetables_url:
                    operation_time = station.add_url(url)
                    if operation_time is None:
                        continue
                    try:
                        arrival_times = get_arrival_times(url)
                        station.add_arrival_times(arrival_times, operation_time)
                    except Exception as e:
                        print(e, f"{station_native_name}\t{url}")
            stations[station_native_name] = station
            next_elem = next_elem.find_next_sibling()

        lines[line_native_name] = Line(native_name=line_native_name, station_list=station_list,
                                       stations=stations)

    return lines


def is_color_in_range(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    return 0.55 <= h <= 0.7 and 0.01 <= s and 65 <= v <= 240


def increase_contrast(image: Image.Image):
    ret, th = cv2.threshold(np.array(image.convert('L')),
                            0,  # threshold value, ignored when using cv2.THRESH_OTSU
                            255,  # maximum value assigned to pixel values exceeding the threshold
                            cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    return Image.fromarray(th)


def filter_image(img: Image.Image):
    img = img.convert("RGB")  # Ensure image is in RGB format
    pixels = img.load()  # Create the pixel map

    # Get image dimensions
    width, height = img.size

    # Iterate over all pixels
    for y in range(height):
        for x in range(width):
            # Get the RGBA value of the pixel
            r, g, b = pixels[x, y]

            if not is_color_in_range(r, g, b):
                pixels[x, y] = (255, 255, 255)

    # new image
    return img


def locate_nth_color_change(img: Image.Image,
                            n: int,
                            vertical: bool,
                            start: tuple,
                            step: int = 1,
                            skip: int = 1,
                            skip_x: int = 0,
                            skip_y: int = 0,
                            percentage=False,
                            tolerance_high=100,
                            tolerance_low=5,
                            annotate=False) -> tuple:
    width, height = img.size

    if isinstance(start[0], int):
        x, y = start
    else:
        x, y = int(start[0] * width), int(start[1] * height)

    if skip_x == 0 and skip_y == 0:
        if vertical:
            y += skip
        else:
            x += skip
    else:
        x += skip_x
        y += skip_y

    r_prev, g_prev, b_prev = img.getpixel(xy=(x, y))
    color_change_count = 0
    changing = False
    while color_change_count < n and 0 < x < width - step and 0 < y < height - step:
        if vertical:
            y += step
        else:
            x += step
        r, g, b = img.getpixel(xy=(x, y))
        rgb_change = abs(r - r_prev) + abs(g - g_prev) + abs(b - b_prev)
        if rgb_change > tolerance_high and changing is False:
            color_change_count += 1
            changing = True
            if annotate:
                img.putpixel(xy=(x - 3, y - 3), value=(0, 0, 0))
                img.putpixel(xy=(x - 3, y + 3), value=(0, 0, 0))
                img.putpixel(xy=(x + 3, y - 3), value=(0, 0, 0))
                img.putpixel(xy=(x + 3, y + 3), value=(0, 0, 0))
        elif rgb_change < tolerance_low and changing is True:
            changing = False
        r_prev, g_prev, b_prev = r, g, b

    if percentage:
        return x / width, y / height
    return x, y


def locate_hour_strip(img: Image.Image, verbose=False) -> tuple:
    left_0 = locate_nth_color_change(img, 2, vertical=False, start=(0.02, 0.4), tolerance_high=50)
    left = locate_nth_color_change(img, 1, vertical=True, start=left_0, skip_x=1, skip_y=1)
    right = locate_nth_color_change(img, 1, vertical=False, start=left)
    if verbose:
        print("Hour Strip", left, right)
    return left, right


def locate_row_positions(img: Image.Image, hour_strip_right: tuple, verbose=False) -> list[int]:
    hour_strip_top_right = locate_nth_color_change(img, 1, vertical=True, start=hour_strip_right, step=-1, skip_x=8,
                                                   tolerance_high=100, annotate=True)
    row_1_b = locate_nth_color_change(img, 1, vertical=True, start=hour_strip_top_right, step=1, skip_x=1, skip_y=5,
                                      tolerance_high=20, annotate=True)
    row_height = row_1_b[1] - hour_strip_top_right[1]
    if verbose:
        print("Hour Strip Top Right", hour_strip_top_right)
        print("Row Width", row_height)
    row_b = row_1_b

    rows: list[int] = [hour_strip_top_right[1], row_1_b[1]]

    while row_b[1] < img.size[1] - row_height * 1.5:
        row_b_r = locate_nth_color_change(img, 1, vertical=True, start=row_b, step=1, skip_y=int(row_height * 0.9),
                                          annotate=True, tolerance_high=20)
        if row_b_r[1] - rows[-1] > row_height * 1.5:
            row_b_l = locate_nth_color_change(img, 1, vertical=True, start=row_b, step=1, skip_x=-12,
                                              skip_y=int(row_height * 0.9), annotate=True, tolerance_high=50)
            if row_b_l[1] - rows[-1] > row_height * 1.5:
                break
            else:
                row_b = (row_b_l[0] + 12, row_b_l[1])
        else:
            row_b = row_b_r
        rows.append(row_b[1])

    return rows


def load_timetable(img: Image.Image, filter=True, verbose=False) -> TimeTable:
    hour_strip_l, hour_strip_r = locate_hour_strip(img, verbose=verbose)
    rows = locate_row_positions(img, hour_strip_r, verbose=verbose)

    table = TimeTable()
    h = 4
    for i in range(len(rows) - 1):
        x_l = hour_strip_l[0]
        x_m = hour_strip_r[0]
        x_r = img.size[0]
        y_t = rows[i]
        y_b = rows[i + 1]
        # y_m = (y_b + y_t) // 2
        # height = y_b - y_t

        h_crop = img.crop((x_l, y_t, x_m, y_b))
        if filter:
            h_crop = filter_image(h_crop)
            h_crop = increase_contrast(h_crop)
        if verbose:
            h_crop.show()

        try:
            h_raw = int(ocrmac.OCR(h_crop).recognize()[0][0])
            if h_raw != h + 1 and h != 23:
                if len(table.rows) >= 3 and table.rows[-1].hour == table.rows[-2].hour + 1 and table.rows[-1].hour == \
                        table.rows[-3].hour + 2:
                    h += 1
                    if h == 24:
                        h = 0
                    print(f"Hour recognized incorrectly at {h} ({h_raw})")
            else:
                h = h_raw
        except Exception as e:
            h += 1
            if h == 24:
                h = 0
            print(f"Hour not recognized at {h}")

        row = Row(h)

        m_crop = img.crop((x_m, y_t, x_r, y_b))
        if filter:
            m_crop = filter_image(m_crop)
            m_crop = increase_contrast(m_crop)
        if verbose:
            m_crop.show()
        # x_running = 0
        # dist = []
        # while x_running < m_crop.size[0] - x_l:
        #     x_prev = x_running
        #     x_running, _ = locate_nth_color_change(m_crop, 1, vertical=False, start=(x_running, height // 2), annotate=True)
        #     dist.append(x_running - x_prev)
        # if h == 18:
        # m_crop.show()

        m_result = ocrmac.OCR(m_crop).recognize()
        m = ""
        for result in m_result:
            m += result[0] + ' '
        m = m.strip()
        m_formatted = format_minutes(m)
        row.minutes = m_formatted
        table.add_row(row)
    return table


def format_minutes(m: str) -> list[int]:
    m = m.replace('Z', '2').replace('S', '5')
    m = ''.join(c if c.isdigit() else ' ' for c in m).replace("  ", " ")
    m_list = m.split(' ')
    new_list = []
    for i, num_str in enumerate(m_list):
        if len(num_str) == 0:
            continue

        num_int = int(num_str)

        if num_int > 59 and num_int < 1000:
            rm_r = int(num_str[0:2])
            rm_l = int(num_str[1:3])

            if i == 0:
                prior_m = -1
            else:
                prior_m = int(m_list[i - 1])

            if i == len(m_list) - 1:
                next_m = 60
            else:
                try:
                    next_m = int(m_list[i + 1])
                except ValueError:
                    next_m = prior_m + 10
                    print(f"Inaccurate result from parsing {num_str}")

            midpoint = (next_m - prior_m) / 2

            if not prior_m < rm_r < next_m and prior_m < rm_l < next_m:
                num_int = rm_l
            elif not prior_m < rm_l < next_m and prior_m < rm_r < next_m:
                num_int = rm_r
            elif prior_m < rm_r < next_m and prior_m < rm_l < next_m:
                if abs(rm_r - midpoint) < abs(rm_l - midpoint):
                    num_int = rm_r
                else:
                    num_int = rm_l
            else:
                num_int = midpoint
                print("Failed to parse minute data {}, using midpoint value {}".format(num_str, midpoint))

        if num_int not in new_list:
            new_list.append(num_int)

    return new_list


def get_hsv_of_img(img: Image):
    h = []
    s = []
    v = []
    for x in range(img.size[0]):
        for y in range(img.size[1]):
            r, g, b, a = img.getpixel((x, y))

            if a == 255:
                h_, s_, v_ = colorsys.rgb_to_hsv(r, g, b)
                h.append(h_)
                s.append(s_)
                v.append(v_ / 255)

    plt.boxplot([h, s, v])
    plt.show()
