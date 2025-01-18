import pandas as pd
import ipeds
import pprint
from ipeds import continuous_ranges

p = "S:/steinbaum_share/IPEDS-CS/Axel/ipeds_data_analysis/datasets"
d = f"{p}/source/institutional_characteristics/directory_information/dictionaries"
a = ipeds.tDictionary(f"{d}/directory_information_1986_dict.html")
print(a.imputation_table)
print(a.get_value_label("STABBR"))
# dfs1 = ipeds.DataFiles(d)
# ds = ipeds.Dictionaries(d)
