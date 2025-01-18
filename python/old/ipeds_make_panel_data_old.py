"""Module for creating desired panel data."""

__author__ = "Axel V. Morales Sanchez"

import pandas as pd
import IPEDS
import os
import re
from functools import reduce

IPEDS_DATASETS_PATH = "S:/steinbaum_share/IPEDS-CS/Axel/ipeds_data_analysis/datasets/"

CROSSWALK_HANDLE = IPEDS.CROSSWALK(IPEDS_DATASETS_PATH + "helper/ipeds_crosswalk.xlsx")

CONTROL_VARIABLE_CROSSWALK = pd.read_excel(
    IPEDS_DATASETS_PATH + "helper/variable_crosswalks/control_variable_crosswalk.xlsx",
    sheet_name=None,
)
CONTROL_VARIABLE_TRANSLATION = CROSSWALK_HANDLE.GetVariableTranslations(
    CATEGORICAL_CROSSWALK=CONTROL_VARIABLE_CROSSWALK,
    VARIABLE="CONTROL",
)

HEADCOUNT_STUDENT_LEVEL_VARIABLE_CROSSWALK = CATEGORICAL_CROSSWALK = pd.read_excel(
    IPEDS_DATASETS_PATH
    + "helper/variable_crosswalks/headcount_student_level_variable_crosswalk.xlsx",
    sheet_name=None,
)
HEADCOUNT_STUDENT_LEVEL_VARIABLE_TRANSLATION = CROSSWALK_HANDLE.GetVariableTranslations(
    CATEGORICAL_CROSSWALK=HEADCOUNT_STUDENT_LEVEL_VARIABLE_CROSSWALK,
    VARIABLE="HEADCOUNT_STUDENT_LEVEL",
)

DIRECTORY_NAMES = [
    "ins",
    "headcount",
    "full_enrollment",
    "pr_fp_ins",
    "pr_nfp_ins",
    "pub_ins",
    "gen_fin",
]


data_list = []
for DIRECTORY_NAME in DIRECTORY_NAMES:
    CURRENT_DIRECTORY_PATH = IPEDS_DATASETS_PATH + "/".join(
        ["source", DIRECTORY_NAME, "datafiles"]
    )
    YEAR_DATA_PATH_MAP = {
        int(re.findall(r"[0-9]+", PATH)[0]): CURRENT_DIRECTORY_PATH + "/" + PATH
        for PATH in os.listdir(CURRENT_DIRECTORY_PATH)
    }
    if DIRECTORY_NAME == "ins":
        data_list.append(
            CROSSWALK_HANDLE.MakeAnalysisData(
                SHEET_NAME=DIRECTORY_NAME,
                YEAR_DATA_PATH_MAP=YEAR_DATA_PATH_MAP,
                CATEGORICAL_VARIABLE_TRANSLATION={
                    "CONTROL": CONTROL_VARIABLE_TRANSLATION
                },
            )
        )
    elif DIRECTORY_NAME == "headcount":
        HEADCOUNT_DATASET = CROSSWALK_HANDLE.MakeAnalysisData(
            SHEET_NAME=DIRECTORY_NAME,
            YEAR_DATA_PATH_MAP=YEAR_DATA_PATH_MAP,
            CATEGORICAL_VARIABLE_TRANSLATION={
                "HEADCOUNT_STUDENT_LEVEL": HEADCOUNT_STUDENT_LEVEL_VARIABLE_TRANSLATION
            },
        )
        HEADCOUNT_DATASET_NO_HEADCOUNT_STUDENT_LEVEL = HEADCOUNT_DATASET.loc[
            HEADCOUNT_DATASET["YEAR"] < 2001
        ].drop(
            columns=[
                "HEADCOUNT_STUDENT_LEVEL",
                "MASTER_HEADCOUNT_STUDENT_LEVEL",
                "TOTAL_HEADCOUNT",
            ]
        )
        HEADCOUNT_DATASET_WITH_HEADCOUNT_STUDENT_LEVEL = (
            HEADCOUNT_DATASET.loc[HEADCOUNT_DATASET["YEAR"] >= 2001]
            .pivot_table(
                values="TOTAL_HEADCOUNT",
                index=["UNITID", "YEAR"],
                columns="MASTER_HEADCOUNT_STUDENT_LEVEL",
            )
            .reset_index()
            .rename(
                columns={
                    0: "HEADCOUNT_ALL_TOTAL",
                    1: "HEADCOUNT_UG",
                    2: "HEADCOUNT_DPP",
                    3: "HEADCOUNT_G",
                    -1: "HEADCOUNT_NASD",
                }
            )
        )
        data_list.append(
            pd.concat(
                [
                    HEADCOUNT_DATASET_NO_HEADCOUNT_STUDENT_LEVEL,
                    HEADCOUNT_DATASET_WITH_HEADCOUNT_STUDENT_LEVEL,
                ]
            )
        )
    else:
        data_list.append(
            CROSSWALK_HANDLE.MakeAnalysisData(
                SHEET_NAME=DIRECTORY_NAME,
                YEAR_DATA_PATH_MAP=YEAR_DATA_PATH_MAP,
            )
        )
FINANCE_DATA = pd.concat(data_list[-4:])
panel_data = reduce(
    lambda x, y: pd.merge(x, y, on=["UNITID", "YEAR"], how="outer"),
    data_list[:-4] + [FINANCE_DATA],
)
panel_data.sort_values(by=["UNITID", "YEAR"], inplace=True)
panel_data["MASTER_CONTROL_FILLED"] = (
    panel_data.groupby("UNITID")["MASTER_CONTROL"].bfill().ffill()
)
COLUMNS_SET = set(panel_data.columns)
VARIABLE_GUIDE = CROSSWALK_HANDLE.CROSSWALK["variable_guide"]
variable_labels_map = {}
for ROW in VARIABLE_GUIDE.itertuples():
    if ROW.TargetName in COLUMNS_SET:
        variable_labels_map[ROW.TargetName] = ROW.VariableLabel
        panel_data[ROW.TargetName] = CROSSWALK_HANDLE.ConvertDataType(
            TYPE=ROW.PythonDataType, COLUMN=panel_data[ROW.TargetName]
        )
MASTER_CONTROL_VL_MAP = dict(
    CONTROL_VARIABLE_CROSSWALK["master_coding"][["codevalue", "valuelabel"]].values
)
panel_data.to_stata(
    IPEDS_DATASETS_PATH + "produced/panel_data.dta",
    write_index=False,
    variable_labels=variable_labels_map,
    value_labels={
        "MASTER_CONTROL": MASTER_CONTROL_VL_MAP,
        "MASTER_CONTROL_FILLED": MASTER_CONTROL_VL_MAP,
    },
)
