#!/usr/bin/python3

import sys
import re


def search_and_replace(script_content):
    for i, line in enumerate(script_content):
        line = line.strip()
        if re.match('^# *bash', line):
            script_content[i] = ""
            continue
        if not re.match('^ *bash', line):
            continue
        print("[*] Parsing line '"+line+"'")
        sh_filepath = re.sub('^ *bash *', '', line)
        sh_filepath = re.sub(' *#.*', '', sh_filepath)
        with open(sh_filepath, 'r') as f:
            script_content = script_content[:i] + f.readlines() + script_content[i+1:]
        return script_content

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} script.sh")
    sys.exit(1)

try:
    with open(sys.argv[1], 'r') as f:
        script_content = f.readlines()
except FileNotFoundError:
    print("File could not be read.")
    sys.exit(2)
except Exception as e:
    print("Unknown error: "+e)
    sys.exit(42)

if not script_content:
    print("Script file is empty.")
    sys.exit(3)

finished = False
while not finished:
    script_content = search_and_replace(script_content)
    if not any([re.match('^ *bash', line.strip()) for line in script_content]):
        finished = True

with open(sys.argv[1].replace('.sh', '') + '-static.sh', 'w') as f:
    for line in script_content:
        print(line, file=f, end="")

print("[+] Created final script " + sys.argv[1].replace('.sh', '') + '-static.sh')
