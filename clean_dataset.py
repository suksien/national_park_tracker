import pandas as pd

def clean():
  df = pd.read_csv('df_2.csv')
  new_data = {name: [], state: [], location: [], date_established: [], area_acres: [], area_km2: [], description: []}
