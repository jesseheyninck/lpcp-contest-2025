#!/usr/bin/python

import sys


def process_cell(row, col, word):
    print("input(" + str(row) + "," + str(col) + "," + str(word) + ").\n")

first_line = sys.stdin.readline()
print("#const m=" + first_line + ".")
row = 1
for line in sys.stdin:
    col = 1
    for word in line.split():
        process_cell(row, col, word)
        col += 1
    row += 1
