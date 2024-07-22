from utils import get_lines
import json

lines = get_lines()

# Specify the filename
filename = 'data/urls.json'

# Open the file in write mode and use json.dump to write the data to the file
with open(filename, 'w') as file:
    json.dump(lines.to_dict(), file, ensure_ascii=False, indent=4)

print(f"JSON data has been written to {filename}")