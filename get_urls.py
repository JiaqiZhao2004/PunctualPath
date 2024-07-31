from utils import get_lines
import json

lines = get_lines(load_arrival_times=True, index_begin=0, index_end=1)

# Specify the filename
filename = 'data/1号线八通线2.json'

# Open the file in write mode and use json.dump to write the data to the file
with open(filename, 'w') as file:
    json.dump(lines.to_dict(), file, ensure_ascii=False, indent=4)

print(f"JSON data has been written to {filename}")