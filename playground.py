#
# class Row(object):
#     def __init__(self, hour: int):
#         self.hour = hour
#         self.minutes: list[int] = []
#
#     def __str__(self):
#         return str(self.hour) + '\t' + ' '.join(['0' + str(m) if len(str(m)) == 1 else str(m) for m in self.minutes])
#
#
# class TimeTable(object):
#     def __init__(self):
#         self.rows: list[Row] = []
#
#     def add_row(self, row: Row):
#         self.rows.append(row)
#
#     def __str__(self):
#         return "Timetable:\n" + '\n'.join(str(row) for row in self.rows)
#
#     def to_list(self) -> list[int]:
#         schedule: list[int] = []
#         for row in self.rows:
#             for minute in row.minutes:
#                 schedule.append(hms_to_sec(row.hour, minute, 0))
#         return schedule
#
#     def next_train(self, h=None, m=None, s=0):
#         if h is None or m is None:
#             h, m, s = get_current_time()
#         now_sec: int = hms_to_sec(h, m, s)
#         schedule: list[int] = self.to_list()
#         next_train = None
#         next_2nd_train = None
#         for i, timestamp in enumerate(schedule):
#             if now_sec < safe_time(timestamp):
#                 next_train = sec_to_hms(safe_time(timestamp) - now_sec)
#                 if i == len(schedule) - 1:
#                     next_2nd_train = sec_to_hms(safe_time(schedule[0]) - now_sec)
#                 else:
#                     next_2nd_train = sec_to_hms(safe_time(schedule[i + 1]) - now_sec)
#                 break
#         if next_train is None:
#             return "No more trains"
#         return f"\r{next_train[1]}:{next_train[2]}, {next_2nd_train[1]}:{next_2nd_train[2]}"
#
#
# def safe_time(seconds: int) -> int:
#     return seconds - 40
#
#
# def hms_to_sec(h: int, m: int, s: int) -> int:
#     return int(h) * 3600 + int(m) * 60 + int(s)
#
#
# def sec_to_hms(s: int):
#     h = int(s / 3600)
#     s = s % 3600
#     m = int(s / 60)
#     s = s % 60
#     return h, m, s

txt = """5\t06 17 23 28 33 38 42 48 53 56
6\t01 05 07 69 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 41 43 45 47 49 51 53 55 57 59
7\t01 03 05 07 09 12 14 17 19 21 24 26 29 31 33 36 38 41 43 45 47 49 51 53 55 57 59
8\t01 03 05 07 09 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 41 43 45 47 49 51 53 55 57 59
9\t01 03 05 07 09 11 13 15 18 20 22 24 27 29 32 35 37 40 43 45 49 54 59
10\t03 08 13 18 21 25 30 32 37 42 45 49 54 57
11\t02 06 12 18 24 30 36 42 48 54
12\t00 06 12 18 24 30 36 42 48 54
13\t00 06 12 18 24 30 36 42 48 54
14\t00 06 12 18 24 30 36 42 48 54
15\t00 03 08 12 15 19 22 26 29 33 36 40 43 47 50 54 57
16\t01 04 08 11 15 17 21 24 28 31 35 38 43 45 48 51 53 56 58
17\t00 03 05 07 10 12 14 17 19 21 24 26 28 31 33 35 38 40 42 45 47 49 52 54 56 59
18\t01 03 06 08 10 13 15 17 20 22 24 27 29 31 34 36 38 41 43 45 48 50 52 55 57
19\t00 02 04 06 09 11 14 18 21 25 29 31 35 39 43 46 50 53 56
20\t01 03 07 10 14 18 21 24 28 30 35 39 42 45 50 55 59
21\t04 11 14 19 24 28 34 41 48 56
22\t03 10 17 24 31 38 45 52 59
23\t06 13 20 27 34 42"""


def transform(s):
    l = []
    a = s.split("\n")
    for line in a:
        h, ms = line.split("\t")
        for m in ms.split(" "):
            l.append(str(int(h) * 3600 + int(m) * 60))
    print(', '.join(l))

transform(txt)
