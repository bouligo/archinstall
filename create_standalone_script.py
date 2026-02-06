#!/usr/bin/python3

import sys
import re
import argparse


def search_and_replace(script_content, add_pause=False):
    for i, line in enumerate(script_content):
        line = line.strip()
        if re.match('^# *source', line):
            script_content[i] = ""
            continue
        if not re.match('^ *source', line):
            continue
        print("[*] Parsing line '"+line+"'")
        sh_filepath = re.sub(' *#.*', '', line)
        sh_filepath = re.sub('^ *source *', '', sh_filepath)
        with open(sh_filepath, 'r') as f:
            inserted_lines = f.readlines()
            if add_pause:
                inserted_lines.append("read _\n")
            script_content = script_content[:i] + inserted_lines + script_content[i+1:]
        return script_content

parser = argparse.ArgumentParser(description="Create a standalone script from multiple source'd bash files.")
parser.add_argument("script", help="The script file to process")
parser.add_argument("--add-pause", action="store_true", help="Pauses and wait for input after each source'd file")
args = parser.parse_args()

try:
    with open(args.script, 'r') as f:
        script_content = f.readlines()
except FileNotFoundError:
    print("File could not be read.")
    sys.exit(2)
except Exception as e:
    print(f"Unknown error: {e}")
    sys.exit(42)

if not script_content:
    print("Script file is empty.")
    sys.exit(3)

finished = False
while not finished:
    script_content = search_and_replace(script_content, add_pause=args.add_pause)
    if not any([re.match('^ *source', line.strip()) for line in script_content]):
        finished = True

with open(args.script.replace('.sh', '') + '-static.sh', 'w') as f:
    for line in script_content:
        print(line, file=f, end="")

print("[+] Created final script " + args.script.replace('.sh', '') + '-static.sh')
