#!/usr/bin/env python3
import re
import sys
from html.parser import HTMLParser
from io import StringIO

class MLStripper(HTMLParser):
    def __init__(self):
        super().__init__()
        self.reset()
        self.strict = False
        self.convert_charrefs = True
        self.text = StringIO()
        self.tags = []
        self.indent = 0

    def handle_starttag(self, tag, attrs):
        if tag in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6'):
            self.text.write('\n' + '#' * int(tag[1]) + ' ')
        elif tag == 'p':
            self.text.write('\n')
        elif tag == 'li':
            self.text.write('\n- ')
        elif tag == 'br':
            self.text.write('\n')
        elif tag == 'code':
            self.text.write('`')
        elif tag == 'pre':
            self.text.write('\n```\n')
        elif tag == 'table':
            self.text.write('\n<table>\n')
        elif tag == 'tr':
            self.text.write('\n<tr>')
        elif tag == 'td':
            self.text.write('<td>')
        elif tag == 'th':
            self.text.write('<th>')
        self.tags.append(tag)

    def handle_endtag(self, tag):
        if self.tags and self.tags[-1] == tag:
            self.tags.pop()
        if tag == 'code':
            self.text.write('`')
        elif tag == 'pre':
            self.text.write('\n```\n')
        elif tag == 'table':
            self.text.write('\n</table>\n')
        elif tag == 'tr':
            self.text.write('</tr>\n')
        elif tag == 'td':
            self.text.write('</td>')
        elif tag == 'th':
            self.text.write('</th>')

    def handle_data(self, d):
        self.text.write(d)

def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.text.getvalue()

def clean_text(text):
    # Remove multiple blank lines
    text = re.sub(r'\n\s*\n', '\n\n', text)
    # Remove extra spaces
    text = re.sub(r'[ \t]+', ' ', text)
    # Fix markdown code blocks
    text = re.sub(r'```\s*```', '', text)
    return text.strip()

def main():
    # Read HTML from stdin or file
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r', encoding='utf-8') as f:
            html = f.read()
    else:
        html = sys.stdin.read()
    
    # Extract text
    text = strip_tags(html)
    text = clean_text(text)
    
    # Write to stdout
    print(text)

if __name__ == '__main__':
    main()