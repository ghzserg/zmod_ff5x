import sys
import re

gcode = ''
output = []
tools = set(['0'])
colors = []
types = []
t = ''
print(sys.argv[1])
with open(sys.argv[1], 'r') as gcode:
    for line in gcode:
        if re.match("_IFS_COLORS.*", line):
            exit()
        elif re.match("T([0-9]+)", line):
            output.append(line)
            tools.add(re.match("T([0-9]+)", line).group(1))
        elif re.match("; filament_colour = (.*)", line):
            output.append(line)
            colors = re.match("; filament_colour = (.*)", line).group(1).split(";")
        elif re.match("; filament_type = (.*)", line):
            output.append(line)
            types = re.match("; filament_type = (.*)", line).group(1).split(";")
        else:
            output.append(line)
            

with open(sys.argv[1], 'w') as f:
    f.write("_IFS_COLORS START=1 TYPES=" + ",".join(types) + " COLORS=" + ",".join("{0}".format(c[1:]) for c in colors) + " TOOLS=" + ",".join(sorted(tools)) + "\n") 
    for line in output:
        f.write(line)
