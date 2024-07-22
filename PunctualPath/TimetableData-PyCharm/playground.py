
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