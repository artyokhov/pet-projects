import numpy as np
import pandas as pd
import json

df = pd.read_csv('/Users/artemohotnikov/Documents/__code/__pet_projects/Movies_project/Movies_DB/archive/movies_metadata.csv', sep=',')

df = df[['budget', 'genres', 'imdb_id', 'production_companies', 'production_countries', 'release_date']]

for pair in [{'genres':'name'}, {'production_companies':'name'}, {'production_countries':'iso_3166_1'}]:
    for index, col in df[[list(pair.keys())[0]]].iterrows():
        if df.loc[index, list(pair.keys())[0]] == '[]':
            pass
        else:
            df.loc[index, list(pair.keys())[0]] = json.loads(df.loc[index, list(pair.keys())[0]].replace('\'','"'))[0][list(pair.values())[0]]

df