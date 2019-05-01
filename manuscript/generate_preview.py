#!/usr/bin/python

with open("Book.txt") as f:
    print ('echo "Starting build of {book}.epub";'
            "pandoc {files} " +
            "+smart --table-of-contents --chapters -o {book}.epub;"
            'echo "  {book}.epub created."'
            ).format(book="Book", files=f.read().replace("\n", " "))
