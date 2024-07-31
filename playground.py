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

txt = """5	28 38 49 55
6	00 05 10 15 20 25 28 33 37 39 41 43 45 47 49 51 53 55 57
7	01 03 05 07 09 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 41 44 46 49 51 53 56
8	01 03 05 08 10 13 15 17 19 23 25 27 29 31 35 37 39 41 44 47 49 51 54 57
9	01 04 06 09 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 41 43 45 48 50 52 54 56 59
10	01 04 07 09 12 15 17 21 26 31 35 40 45 50 53 57
11	02 05 09 14 17 21 26 29 34 38 44 50 56
12	02 08 14 20 26 32 38 44 50 56
13	02 08 14 20 26 32 38 44 50 56
14	02 08 14 20 26 32 38 44 50 56
15	02 08 14 20 26 32 36 41 45 48 52 55 59
16	02 06 09 13 16 20 23 27 30 34 37 41 44 48 50 54 57
17	01 04 08 11 16 18 21 24 26 29 31 33 36 38 40 43 45 47 50 52 54 57
18	01 04 06 08 11 13 15 18 20 22 25 27 29 32 34 36 39 41 43 46 48 50 53 55
19	00 02 04 07 09 11 14 16 18 21 23 25 28 30 33 35 37 39 42 44 47 51 54
20	02 05 09 12 16 19 23 26 30 34 37 40 43 45 50 53 56
21	00 03 07 11 13 17 21 25 27 32 34 38 42 45 49 52 56 59
22	05 11 17 23 28 35 41 47 53 59
23	06 13 20 27 33 39 46 53
0	00 07 14"""


def transform(s):
    l = []
    a = s.split("\n")
    for line in a:
        h, ms = line.split("\t")
        for m in ms.split(" "):
            l.append(str(int(h) * 3600 + int(m) * 60))
    print(', '.join(l))

transform(txt)
