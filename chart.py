#!/usr/bin/env python3

import json
import os
import re
import sys

import pandas as pd
import seaborn as sns


def get_data():
    data = []
    for filename in os.listdir('results'):
        if match := re.match(
            r'(results\-)?(?P<type>(install|load))-(?P<kind>.*)\.json', filename
        ):
            info = match.groupdict()
            if info['kind'] == 'base':
                continue
            with open(os.path.join('results', filename), 'r') as f:
                results = json.load(f)['results']
                assert len(results) == 1
                file_data = results[0]
                file_data.update(info)
                data.append(file_data)

    data.sort(key=lambda d: (d['type'], d['kind']))

    return pd.concat(pd.DataFrame(d) for d in data)


def chart(ty):
    df = get_data()
    sns.set(rc={'figure.dpi': 200, 'savefig.dpi': 200})
    g = sns.barplot(data=df[df.type == ty], x='kind', y='times', palette='pastel')
    g.set(
        title=f'{ty.title()} time',
        xlabel='',
        ylabel='Time taken (secs)',
    )
    filename = f'results/{ty}.png'
    g.figure.savefig(filename)
    return filename


if __name__ == '__main__':
    print(f'Output chart to {chart(sys.argv[1])}')
