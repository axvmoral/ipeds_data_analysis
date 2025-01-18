"""Module for creating panel dataset."""

__author__ = "Axel V. Morales Sanchez"

import pandas as pd
import os
import re
from functools import reduce
import ipeds
import string

######### Preperation #########
IPEDS_DATASETS_PATH = "S:/steinbaum_share/IPEDS-CS/Axel/ipeds_data_analysis/datasets"
crosswalk_handle = ipeds.Crosswalk(f"{IPEDS_DATASETS_PATH}/helper/ipeds_crosswalk.xlsx")
categorical_variables = [
    "CONTROL",
    "HEADCOUNT_STUDENT_LEVEL",
    "AWARD_LEVEL",
    "MAJOR_LEVEL",
    "HBCU",
    "CARNEGIE_BASIC",
    "STATE",
]
categorical_variables_crosswalks = {
    variable: pd.read_excel(
        f"{IPEDS_DATASETS_PATH}/helper/variable_crosswalks/{variable.lower()}_variable_crosswalk.xlsx",
        sheet_name=None,
    )
    for variable in categorical_variables
}
categorical_variables_translations = {
    variable: crosswalk_handle.get_var_translations(
        categorical_crosswalk=cat_crosswalk,
        variable=variable,
    )
    for variable, cat_crosswalk in categorical_variables_crosswalks.items()
}
analysis_data_info = {
    "institutional_characteristics": {
        "directory_information": {
            "CONTROL": categorical_variables_translations["CONTROL"],
            "HBCU": categorical_variables_translations["HBCU"],
            "CARNEGIE_BASIC": categorical_variables_translations["CARNEGIE_BASIC"],
            "STATE": categorical_variables_translations["STATE"],
        },
        "student_charges": None,
    },
    "completions": {
        "awards_by_program": {
            "AWARD_LEVEL": categorical_variables_translations["AWARD_LEVEL"],
            "MAJOR_LEVEL": categorical_variables_translations["MAJOR_LEVEL"],
        }
    },
    "twelve_month_enrollment": {
        "full_enrollment": None,
        "headcount": {
            "HEADCOUNT_STUDENT_LEVEL": categorical_variables_translations[
                "HEADCOUNT_STUDENT_LEVEL"
            ]
        },
    },
    "finance": {
        "public": None,
        "private_not_for_profit": None,
        "private_for_profit": None,
        "all_institutions": None,
    },
    "student_financial_aid_and_net_price": {
        "student_finaid_netprice": None,
    },
}
######### End of Preperation #########

######### Make panel dataset #########
letters = set(string.ascii_letters)
raw_datasets = {}
for parent_directory in analysis_data_info.keys():
    for child_directory, categorical_variable_translation in analysis_data_info[
        parent_directory
    ].items():
        raw_datasets[child_directory] = crosswalk_handle.make_analysis_data(
            sheet_name=child_directory,
            year_data_path_map={
                int(re.findall(r"[0-9]+", data_path.path)[0]): data_path.path
                for data_path in os.scandir(
                    f"{IPEDS_DATASETS_PATH}/source/{parent_directory}/{child_directory}/datafiles"
                )
            },
            categorical_var_translation=categorical_variable_translation,
        )

headcount = pd.concat(
    [
        raw_datasets["headcount"]
        .loc[
            lambda x: x["YEAR"] >= 2020
        ]  # This subset has student level and level variables
        .groupby(["UNITID", "YEAR", "MASTER_HEADCOUNT_STUDENT_LEVEL"])
        .sum(min_count=1)
        .pivot_table(
            values="TOTAL_HEADCOUNT",
            index=["UNITID", "YEAR"],
            columns="MASTER_HEADCOUNT_STUDENT_LEVEL",
        )
        .rename(
            columns={  # Indices of columns correspond to headcount student levels
                0: "HEADCOUNT_ALL_TOTAL",
                1: "UNDERGRADUATE_HEADCOUNT",
                2: "DOCTORS_PRACT_HEADCOUNT",
                3: "GRADUATE_HEADCOUNT",
                -1: "HEADCOUNT_NASD",
            }
        )
        .reset_index(),
        raw_datasets["headcount"]
        .loc[
            lambda x: (x["YEAR"] >= 2001) & (x["YEAR"] < 2020)
        ]  # This subset has the student level variable
        .pivot_table(
            values="TOTAL_HEADCOUNT",
            index=["UNITID", "YEAR"],
            columns="MASTER_HEADCOUNT_STUDENT_LEVEL",
        )
        .rename(
            columns={  # Indices of columns correspond to headcount student levels
                0: "HEADCOUNT_ALL_TOTAL",
                1: "UNDERGRADUATE_HEADCOUNT",
                2: "DOCTORS_PRACT_HEADCOUNT",
                3: "GRADUATE_HEADCOUNT",
                -1: "HEADCOUNT_NASD",
            }
        )
        .reset_index(),
        raw_datasets["headcount"]
        .loc[
            lambda x: x["YEAR"] < 2001
        ]  # This subset does not have the student level variable
        .drop(
            columns=[  # These variables are empty for this subset
                "HEADCOUNT_STUDENT_LEVEL",
                "HEADCOUNT_LEVEL",
                "MASTER_HEADCOUNT_STUDENT_LEVEL",
                "TOTAL_HEADCOUNT",
            ]
        ),
    ]
)

awards_by_program = (
    raw_datasets["awards_by_program"]
    .loc[
        lambda x: x["MASTER_AWARD_LEVEL"] == 2
    ]  # Want only entries that have an award level of "masters"
    .groupby(["UNITID", "YEAR"])
    .aggregate(
        TOTAL_AWARDS_WOMEN=pd.NamedAgg(
            "TOTAL_AWARDS_WOMEN", lambda x: x.sum(min_count=1)
        ),
        TOTAL_AWARDS_MEN=pd.NamedAgg("TOTAL_AWARDS_MEN", lambda x: x.sum(min_count=1)),
        TOTAL_AWARDS=pd.NamedAgg("TOTAL_AWARDS", lambda x: x.sum(min_count=1)),
        PROGRAMS_COUNT=pd.NamedAgg(
            "CIPCODE", lambda x: x.nunique()
        ),  # Give me the number of unique CIP Codes that are masters for every institution-year
    )
    .assign(
        TOTAL_AWARDS_MEN_WOMEN=lambda x: x[
            ["TOTAL_AWARDS_WOMEN", "TOTAL_AWARDS_MEN"]
        ].sum(axis=1, skipna=False)
    )
    .reset_index()
)


finance = pd.concat(  # Concatenation because these are not overlapping on the CONTROL or YEAR aspect
    [
        raw_datasets["public"],  # Has MASTER_CONTROL == 0 and YEAR from 2021 to 1997
        raw_datasets[
            "private_not_for_profit"  # Has MASTER_CONTROL == 1 and YEAR from 2021 to 1997
        ],
        raw_datasets[
            "private_for_profit"  # Has MASTER_CONTROL == 2 and YEAR from 2021 to 1998
        ],
        raw_datasets[
            "all_institutions"  # Has YEAR from 1996 and 1984, 1980 and all MASTER_CONTROL
        ],
    ]
)

directory_information = raw_datasets["directory_information"].loc[
    lambda x: ~x.duplicated(["UNITID", "YEAR"])
]
student_charges = raw_datasets["student_charges"].loc[
    lambda x: ~x.duplicated(["UNITID", "YEAR"])
]

final_datasets = [
    directory_information,
    student_charges,
    raw_datasets["student_finaid_netprice"],
    awards_by_program,
    headcount,
    raw_datasets["full_enrollment"],
    finance,
]

variable_to_type_map = dict(
    crosswalk_handle.crosswalk["panel_data_variable_guide"][
        ["TargetName", "PythonDataType"]
    ].values
)

panel_data = (
    reduce(
        lambda x, y: pd.merge(x, y, on=["UNITID", "YEAR"], how="outer"),
        (  # Convert to consistent data types before merging
            dataset.apply(
                lambda x: crosswalk_handle.convert_data_type(
                    column=x, var_type=variable_to_type_map[x.name]
                )
            )
            for dataset in final_datasets
        ),
    )
    .sort_values(by=["UNITID", "YEAR"])
    .assign(
        MASTER_CONTROL_FILLED=lambda x: x.groupby("UNITID")["MASTER_CONTROL"]
        .bfill()
        .ffill()
    )
)

master_control_value_label_map = dict(
    categorical_variables_crosswalks["CONTROL"]["master_coding"][
        ["codevalue", "valuelabel"]
    ].values
)

# panel_data.to_csv(f"{IPEDS_DATASETS_PATH}/produced/panel_data.csv", index=False)

panel_data.to_stata(
    f"{IPEDS_DATASETS_PATH}/produced/panel_data.dta",
    write_index=False,
    variable_labels=dict(
        crosswalk_handle.crosswalk["panel_data_variable_guide"][
            ["TargetName", "VariableLabel"]
        ].values
    ),
    value_labels={
        "MASTER_CONTROL": master_control_value_label_map,
        "MASTER_CONTROL_FILLED": master_control_value_label_map,
    },
)
######### End of making panel dataset #########
