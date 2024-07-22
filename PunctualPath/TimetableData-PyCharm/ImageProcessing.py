import colorsys

import cv2
import numpy as np
from PIL import Image
from matplotlib import pyplot as plt
from ocrmac import ocrmac

from utils import TimeTable, Row


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
