import json
from enum import Enum
import requests
from PIL import Image, ImageEnhance
from bs4 import BeautifulSoup
from tqdm import tqdm
from datetime import datetime


class OperationTime(Enum):
    WEEKDAY = "工作日"
    WEEKEND = "双休日"


class Date(object):
    def __init__(self, yyyy: int, mm: int, dd: int):
        self.yyyy = yyyy
        self.mm = mm
        self.dd = dd

    def __str__(self):
        return f"{self.yyyy}-{self.mm}-{self.dd}"


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

    def __str__(self):
        return self.native_name

    def add_url(self, timetable_url: str):
        if '工作日' in timetable_url:
            self.weekday_urls.append(timetable_url)
        if '双休日' in timetable_url:
            self.weekend_urls.append(timetable_url)
        if '工作日' not in timetable_url and '双休日' not in timetable_url:
            self.unknown_urls.append(timetable_url)

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
            'unknown_tb': self.unknown_urls
        }

    @classmethod
    def from_dict(cls, data):
        station = cls(data['native_name'])
        station.weekday_urls = data['weekday_tb']
        station.weekend_urls = data['weekend_tb']
        station.unknown_urls = data['unknown_tb']
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
            'stations': stations_dict
        }

    @classmethod
    def from_dict(cls, data):
        # Convert the JSON-serializable dictionary back to a dictionary of Station objects
        stations = {name: Station.from_dict(station_data) for name, station_data in data['stations'].items()}
        return cls(data['native_name'], stations)


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


def get_lines() -> BeijingSubway:
    url = "https://www.bjsubway.com/station/xltcx/line1/"
    r = requests.get(url)
    r.encoding = r.apparent_encoding
    soup = BeautifulSoup(r.text, "html.parser")

    lines = BeijingSubway()

    # Find all line elements
    line_elements = soup.find_all('div', class_='line_name')

    # Iterate through line elements
    for line_elem in tqdm(line_elements):
        # Extract line name
        line_native_name = line_elem.find('div').text.strip()

        # Find stations for the current line
        stations: dict[str, Station] = {}

        next_elem = line_elem.find_next_sibling()
        while next_elem and next_elem.get('class') == ['station']:
            station_native_name = next_elem.text.strip()
            a_element = next_elem.find('a')
            station = Station(native_name=station_native_name)
            if a_element is not None:
                station_href = a_element['href']
                station_timetables_url = get_station_timetables_url(station_href)
                for url in station_timetables_url:
                    station.add_url(url)
            stations[station_native_name] = station
            next_elem = next_elem.find_next_sibling()

        lines[line_native_name] = Line(native_name=line_native_name,
                                       stations=stations)

    return lines
