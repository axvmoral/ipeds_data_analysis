"""Module for creating crosswalks for necessary categorical variables."""

__author__ = "Axel V. Morales Sanchez"

import os
import re
import ipeds
from functools import reduce

IPEDS_DATASETS_PATH = "S:/steinbaum_share/IPEDS-CS/Axel/ipeds_data_analysis/datasets"
crosswalk_handle = ipeds.Crosswalk(f"{IPEDS_DATASETS_PATH}/helper/ipeds_crosswalk.xlsx")

# var_info = {
#    "institutional_characteristics": {"directory_information": ["CONTROL", "HBCU", "CARNEGIE_BASIC"]},
#    "twelve_month_enrollment": {"headcount": ["HEADCOUNT_STUDENT_LEVEL", "HEADCOUNT_LEVEL"]},
#    "completions": {"awards_by_program": ["AWARD_LEVEL", "MAJOR_LEVEL"]},
# }

var_info = {"institutional_characteristics": {"directory_information": ["STATE"]}}

for parent_directory in var_info.keys():
    for child_directory, variable_list in var_info[parent_directory].items():
        for variable in variable_list:
            crosswalk_handle.make_cat_crosswalk(
                sheet_name=child_directory,
                variable=variable,
                destination=f"{IPEDS_DATASETS_PATH}/helper/variable_crosswalks/{variable.lower()}_variable_crosswalk.xlsx",
                year_dict_map={
                    int(re.findall(r"[0-9]+", dict_path.path)[0]): ipeds.Dictionary(
                        dict_path.path
                    )
                    for dict_path in os.scandir(
                        f"{IPEDS_DATASETS_PATH}/source/{parent_directory}/{child_directory}/dictionaries"
                    )
                },
                drop=["YearRangeDescription"],
            )
