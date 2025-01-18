"""Module for downloading datasets from IPEDS data center website."""

__author__ = "Axel V. Morales Sanchez"

import pandas as pd
import itertools
import re
import ipeds

IPEDS_DATASETS_PATH = "S:/steinbaum_share/IPEDS-CS/Axel/ipeds_data_analysis/datasets"

website = ipeds.Website()
download_info = pd.read_excel(f"{IPEDS_DATASETS_PATH}/helper/ipeds_download_info.xlsx")
for row_x in download_info.itertuples():
    if row_x.Survey != "Student Financial Aid and Net Price":
        continue
    years = (int(year) for year in re.findall(r"[0-9]+", row_x.YearRanges))
    year_set = (
        {  # Expects every range in string to be in format "last year - first year"
            n
            for n in itertools.chain.from_iterable(
                range(next(years), year + 1) for year in years
            )
        }
    )
    title_condition = (
        website.table.Title.str.contains(
            row_x.Title, case=row_x.CaseIndicator, regex=False
        )
        if row_x.KeywordIndicator
        else website.table.Title == row_x.Title
    )
    search_table = website.table.loc[
        (website.table.Survey == row_x.Survey)
        & (website.table.Year.isin(year_set))
        & title_condition
    ]
    for row_y in search_table.itertuples():
        website.download_file(  # Download data file
            survey=row_y.Survey,
            title=row_y.Title,
            year=row_y.Year,
            destination=f"{IPEDS_DATASETS_PATH}/source/{row_x.ParentDirectory}/{row_x.ChildDirectory}/datafiles",
            new_name=f"{row_x.ChildDirectory}_{row_y.Year}",
        )
        website.download_file(  # Download dictionary file
            survey=row_y.Survey,
            title=row_y.Title,
            year=row_y.Year,
            data=False,
            destination=f"{IPEDS_DATASETS_PATH}/source/{row_x.ParentDirectory}/{row_x.ChildDirectory}/dictionaries",
            new_name=f"{row_x.ChildDirectory}_{row_y.Year}_dict",
        )
