"""Module for Website, Dictionary, and Crosswalk classes"""

__author__ = "Axel V. Morales Sanchez"

import requests
import pandas as pd
from pandas import DataFrame, Series
import zipfile
from pathlib import Path
import io
from bs4 import BeautifulSoup, Tag, Comment, NavigableString
import re
import string
import os
import itertools
import warnings
import pprint


WEBSITE_URL = "https://nces.ed.gov/ipeds/datacenter/DataFiles.aspx?year=-1&surveyNumber=-1&sid=4b38741e-b781-4338-809c-1fcbd140a4b0&rtid=7"

warnings.filterwarnings("ignore", category=UserWarning, module="openpyxl")


class Website:
    """Behaves as a simple interface of the IPEDS complete data files web page."""

    def __init__(self) -> None:
        """
        Constructs a new Website object with table data member that is a DataFrame representation of
        the data table in the IPEDS complete data files web page for specifications 'All Surveys' and
        'All Years'.
        """
        website_url_root = WEBSITE_URL[: WEBSITE_URL.rfind("/") + 1]
        self.table = (
            pd.read_html(
                requests.get(WEBSITE_URL).content,
                attrs={"id": "contentPlaceHolder_tblResult"},
                extract_links="body",
            )[0]
            .assign(
                DataFileName=lambda x: x["Data File"].map(
                    lambda y: (y[0].lower(), None)
                ),
                Year=lambda x: x["Year"].map(lambda y: (int(y[0]), None)),
            )
            .map(lambda x: x[0] if x[1] is None else website_url_root + x[1])
        )

    def download_file(
        self,
        survey: str,
        title: str,
        year: int,
        data_file: bool = True,
        destination: str | None = None,
        new_name: str | None = None,
    ) -> None:
        """
        Downloads either a data file or dictionary from the IPEDS complete data files web page.

        :param survey: the name of the survey
        :param title: the title of the data file or dictionary
        :year: the year the survey was conducted
        :data_file: specification to download a data file or dictionary; defaults to data file
        :destination: directory to download data file or dictionary to; defaults to current directory
        :new_name: name to assign downloaded file; defaults to None indicating to retain original file name
        """
        link_search = self.table.loc[
            (self.table["Survey"] == survey)
            & (self.table["Title"] == title)
            & (self.table["Year"] == year)
        ].reset_index()
        if link_search.empty:
            raise ValueError(
                "Data File or Dictionary link does not exist for that combination of parameters."
            )
        else:
            link = link_search["Data File" if data_file else "Dictionary"][0]
            with zipfile.ZipFile(
                io.BytesIO(requests.get(link, stream=True).content)
            ) as zip_folder:
                zip_file_name = {
                    Path(zname).stem.lower(): zname for zname in zip_folder.namelist()
                }[link_search["DataFileName"][0]]
                zip_file = zip_folder.getinfo(zip_file_name)
                if new_name is not None:
                    zip_file.filename = new_name + Path(zip_file_name).suffix
                if destination is None:
                    zip_folder.extract(zip_file, os.getcwd())
                else:
                    zip_folder.extract(zip_file, destination)
            return None


class Dictionary:
    """Behaves as a simple interface of the IPEDS data dictionaries."""

    def __init__(self, source: str) -> None:
        """
        Constructs a new Dictionary object.

        :param source: the file path of the data dictionary to process; supports .html, .xls, and .xlsx files
        """
        path_suffix = Path(source).suffix
        if path_suffix == ".html":
            self.var_desc_map = {}
            self.extended_desc_map = {}
            self.var_vl_map = {}
            self.var_type_map = {}
            self.imputation_table = None
            block = []
            got_imputation_table = False
            with open(source, "r", errors="replace") as f:
                meat = (
                    BeautifulSoup(f.read(), "html.parser").find_all("tr")[2].find("td")
                )
            for element in meat.contents:
                if isinstance(element, Tag):
                    if element.name == "hr" and block:
                        variable, description = re.findall(
                            r"(^[A-Z]\w*)-(.+)", block[0]
                        )[0]
                        self.var_desc_map[variable] = description
                        block = []
                    elif element.name == "table":
                        format_type = re.findall(r"Data type-(.+)", element.text)
                        if format_type:
                            block.insert(1, format_type[0])
                        if element.find("hr") is not None:
                            block.append(element)
                            block = block[:2] + [" ".join(block[2:-1])] + block[-1:]
                            variable, description = re.findall(
                                r"(^[A-Z]\w*)-\d+-(.+)", block[0]
                            )[0]
                            self.var_desc_map[variable] = description
                            self.extended_desc_map[variable] = block[2]
                            self.var_type_map[variable] = block[1]
                            potential_value_label = block[-1].select(
                                "table:-soup-contains('Code Value')"
                            )
                            if potential_value_label:
                                self.var_vl_map[
                                    variable
                                ] = self.__standarize_value_label(
                                    pd.read_html(
                                        io.StringIO(str(potential_value_label))
                                    )[-1],
                                    self.var_type_map[variable],
                                )
                            block = []
                        elif element.find_next_sibling().name == "hr":
                            if not got_imputation_table:
                                block.append(element)
                                self.imputation_table = self.__standarize_value_label(
                                    pd.read_html(
                                        io.StringIO(
                                            str(
                                                block[-1].select(
                                                    "table:-soup-contains('Code Value')"
                                                )
                                            )
                                        )
                                    )[-1],
                                    "A",
                                    imputation_table=True,
                                )
                            block = []
                elif not isinstance(element, Comment):
                    if isinstance(element, NavigableString):
                        text = element.text.strip()
                        if len(text) > 0 and not text.startswith(
                            "Code values and value labels for:"
                        ):
                            block.append("".join(text.splitlines()))
                    else:
                        block.append(element)
        elif path_suffix == ".xls" or path_suffix == ".xlsx":
            workbook = pd.read_excel(source, sheet_name=None)
            self.var_desc_map = dict(
                workbook["varlist"][["varname", "varTitle"]].values
            )
            self.extended_desc_map = dict(
                workbook["Description"][["varname", "longDescription"]].values
            )
            self.var_type_map = dict(
                workbook["varlist"][["varname", "DataType"]].values
            )
            self.var_vl_map = (
                {
                    var: self.__standarize_value_label(
                        workbook["Frequencies"].loc[
                            workbook["Frequencies"]["varname"] == var,
                            ["valuelabel", "codevalue"],
                        ],
                        self.var_type_map[var],
                        html=False,
                    )
                    for var in workbook["Frequencies"]["varname"].unique()
                }
                if "Frequencies" in workbook
                else {}
            )
            self.imputation_table = (
                workbook["Imputation values"]
                .rename(columns=lambda x: x.iloc[0])
                .drop(0)
                if "Imputation values" in workbook
                else {}
            )
        return None

    def __repr__(self) -> str:
        """
        Provides a pretty print representation of all the variables and their
        descriptions in the given data dictionary.
        """
        return pprint.pformat(self.var_desc_map)

    def __contains__(self, variable: str) -> bool:
        """
        Checks if a variable is contained in the data dictionary.

        :param variable: the variable name
        :return: True if variable is in data dictionary else False
        """
        return variable in self.var_desc_map

    def __getitem__(self, variable: str) -> str:
        """
        Returns the description of the desired variable if it is in the
        data dictionary.

        :param variable: the variable name
        :return: variable description if variable is in dictionary, else error
        """
        return self.var_desc_map[variable]

    def __iter__(self) -> str:
        """
        An iterator of the variables in the data dictionary.

        :return: a variable name
        """
        return self.var_desc_map.keys()

    def get_extended_desc(self, variable: str) -> str:
        """
        Returns the extended description of the desired variable if it is in the
        data dictionary.

        :param variable: the variable name
        :return: extended variable description if variable is in dictionary, else error
        """
        return self.extended_desc_map[variable]

    def get_value_label(self, variable: str) -> DataFrame:
        """
        Returns the value label coding of a variable if it is in the data
        dictionary.

        :param variable: the variable name
        :return: a DataFrame representation of the value label coding of the given variable
        """
        return self.var_vl_map[variable]

    def get_format_type(self, variable: str) -> str:
        """
        Returns the data format type of a variable if it is in the data
        dictionary.

        :param variable: the variable name
        :return: the data format type of the given variable
        """
        return self.var_type_map[variable]

    def __standarize_value_label(
        self,
        value_label: DataFrame,
        data_type: str,
        html: bool = True,
        imputation_table=False,
    ) -> DataFrame:
        """
        Standarized the value label coding of a variable.

        :param value_label: the DataFrame representation of a variable's value label coding
        :param data_type: the data format type of the variable corresponding to the value label coding
        :param html: indicates if value label coding is derived from an .html data dictionary file;
        defaults to .html else process value label codings from .xls or .xlsx data dictionary files
        :param imputation_table: indicates if value label coding stems from an imputation variable;
        defaults to stemming from a regular variable
        :return: a DataFrame representation of the standarized value label coding

        """
        if html:
            to_drop = [0, len(value_label) - 1] if not imputation_table else [0]
            value_label = value_label.rename(
                columns=value_label.iloc[0].str.replace(" ", "").str.lower()
            ).drop(to_drop)[["valuelabel", "codevalue"]]
        return value_label.assign(
            valuelabel=lambda x: x["valuelabel"]
            .str.replace(
                f"[{string.punctuation.replace('/', '')}]",
                " ",
                regex=True,
            )
            .str.replace(r"\s\s+", " ", regex=True)
            .str.strip(),
            codevalue=lambda x: pd.to_numeric(x["codevalue"], errors="coerce")
            if data_type == "N"
            else x["codevalue"],
        )


class Dictionaries:
    """Behaves as a simple interface for handling multiple data dictionary files"""

    def __init__(self, directory: str, use_year_as_key: bool = True) -> None:
        """
        Constructs a new Dictionaries object from a directory.

        :param directory: the directory holding the data dictionary files to process
        :param use_year_as_key: indicator if to use year in data dictionary file name
        as the key to access said dictionary; defaults to using year as key else uses
        file path as key; if True then expects a year number in file name with consistent
        format across files
        """
        if use_year_as_key:
            self.dictionaries_dict = {
                int(re.findall(r"[0-9]+", path.path)[0]): Dictionary(path.path)
                for path in os.scandir(directory)
            }
        else:
            self.dictionaries_dict = {
                path.name: Dictionary(path.path) for path in os.scandir(directory)
            }
        self.__used_year_as_key = use_year_as_key
        return None

    def check_for_var(
        self, variable: str, omit_empty: bool = True, get_ranges: bool = False
    ) -> dict[str: str | None] | str:
        """
        Checks given data dictionaries for a variable.

        :param variable: the variable name
        :param omit_empty: indicator if to omit keys if not the variable is not
        present in that data dictionary; if get_ranges is also specified then the
        return string indicates the accurate years for which the variable is in the
        data dictionaries else the return might specify a year for which the variable
        does not exist in the corresponding data dictionary
        :param get_ranges: indicates if to return a simple string representing the years
        for which the variable is present in the corresponding data dictionaries
        :return: a dict with the data dictionary keys and the variable or a string representing
        the years for which the variable is present
        """
        result = {
            key: variable in dictionary
            for key, dictionary in self.dictionaries_dict.items()
            if not omit_empty or variable in dictionary
        }
        if get_ranges:
            if self.__used_year_as_key:
                return continuous_ranges(list(result.keys()), do_sort=True)
            else:
                raise ValueError("Invalid. Did not use years as the dictionary keys!")
        else:
            return result

    def get_desc_for_var(self, variable: str) -> dict[str: str]:
        """
        Returns the description of the variable for each data dictionary in which
        it is present.

        :param variable: the variable name
        :return a dict mapping the data dictionary keys to the variable description in
        each corresponding data dictionary
        """
        return {
            key: dictionary[variable]
            for key, dictionary in self.dictionaries_dict.items()
            if variable in dictionary
        }

    def __getitem__(self, key: str) -> Dictionary:
        """
        Returns the Dictionary object of a given data dictionary.

        :param key: the key associated with the data dictionary in the Dictionaries object
        :return: the Dictionary object associated with the key if it is present else error
        """
        return self.dictionaries_dict[key]


class DataFiles:
    def __init__(
        self,
        directory: str,
        crosswalk_path: str | None = None,
        directory_name: str | None = None,
    ) -> None:
        if crosswalk_path is not None:
            crosswalk = Crosswalk(crosswalk_path)
            exploded_sheet = crosswalk.disagg_year_ranges(
                crosswalk.crosswalk[directory_name], year_range_column="YearRanges"
            )
            year_to_path = {
                int(re.findall(r"\d+", path.name)[0]): path.path
                for path in os.scandir(directory)
            }
            self.datafiles_dir = {}
            for year in exploded_sheet["Year"].unique():
                current_subset = exploded_sheet.loc[exploded_sheet["Year"] == year]
                self.datafiles_dir[year] = (
                    pd.read_csv(
                        year_to_path[year],
                        low_memory=False,
                        usecols=lambda x: x.upper()
                        in set(current_subset["CurrentName"].unique()).union(
                            {"UNITID"}
                        ),
                        encoding="latin-1",
                        index_col=False,
                    )
                    .rename(columns=lambda x: x.upper())
                    .rename(
                        columns=dict(
                            current_subset[["CurrentName", "TargetName"]].values
                        )
                    )
                )
        else:
            self.datafiles_dir = {
                int(re.findall(r"[0-9]+", path.path)[0]): pd.read_csv(
                    path.path, low_memory=False, encoding="latin-1", index_col=False
                )
                for path in os.scandir(directory)
            }
        return None

    def check_for_duplicates(self, on: list | str) -> dict[int:bool]:
        on = [on] if isinstance(on, str) else on
        return {
            year: sum(datafile.duplicated(subset=on)) > 0
            for year, datafile in self.datafiles_dir.items()
            if sum(column in set(datafile.columns) for column in on) == len(on)
        }

    def values_of_duplication(
        self, on: list | str, check_for: list | str
    ) -> dict[int:Series] | dict[str : dict[int:Series]]:
        on = [on] if isinstance(on, str) else on
        if isinstance(check_for, list):
            return {
                year: [subset[variable].unique() for variable in check_for]
                if not subset.empty
                else None
                for year, subset in (
                    (year, datafile.loc[datafile.duplicated(subset=on)])
                    for year, datafile in self.datafiles_dir.items()
                    if sum(column in set(datafile.columns) for column in on) == len(on)
                )
            }
        else:
            return {
                year: subset[check_for].unique() if not subset.empty else None
                for year, subset in (
                    (year, datafile.loc[datafile.duplicated(subset=on)])
                    for year, datafile in self.datafiles_dir.items()
                    if sum(column in set(datafile.columns) for column in on) == len(on)
                )
            }

    def __getitem__(self, key) -> DataFrame:
        return self.datafiles_dir[key]

    def __iter__(self):
        for datafile in self.datafiles_dir.values():
            yield datafile


class Crosswalk:
    def __init__(self, crosswalk_path: str) -> None:
        self.crosswalk = pd.read_excel(crosswalk_path, sheet_name=None)
        return None

    def disagg_year_ranges(
        self, dataframe: DataFrame, year_range_column: str, drop: list | None = None
    ) -> DataFrame:
        return (
            dataframe.assign(
                RangeList=lambda df: df[year_range_column].str.findall(r"[0-9]+"),
                Year=lambda df: df["RangeList"].map(
                    lambda year_ranges: [
                        year
                        for year in itertools.chain.from_iterable(
                            [
                                range(int(start), int(end) + 1)
                                for start, end in zip(
                                    year_ranges[1::2], year_ranges[::2]
                                )
                            ]
                        )
                    ]
                ),
            )
            .drop(columns=[year_range_column, "RangeList"])
            .explode("Year")
        )

    def make_cat_crosswalk(
        self,
        sheet_name: str,
        variable: str,
        destination: str,
        year_dict_map: dict[int:Dictionary],
        drop: list[str] | None = None,
    ) -> None:
        crosswalk_sheet = self.crosswalk[sheet_name]
        target_crosswalk = self.disagg_year_ranges(
            dataframe=crosswalk_sheet.loc[
                crosswalk_sheet["TargetName"] == variable
            ].copy(),
            year_range_column="YearRanges",
        )
        if drop is not None:
            target_crosswalk.drop(columns=drop, inplace=True)
        value_labels_type_map = {}
        type_column = []
        current_type = 0
        with pd.ExcelWriter(destination, engine="xlsxwriter") as writer:
            for row in target_crosswalk.itertuples():
                current_value_label = year_dict_map[row.Year].get_value_label(
                    row.CurrentName
                )
                hashable_current_value_label = (
                    tuple(current_value_label["valuelabel"].tolist()),
                    tuple(current_value_label["codevalue"].tolist()),
                )
                if hashable_current_value_label not in value_labels_type_map:
                    value_labels_type_map[hashable_current_value_label] = current_type
                    type_column.append(current_type)
                    current_value_label.to_excel(
                        writer,
                        sheet_name="_".join(
                            [row.TargetName, "Type", str(current_type)]
                        ),
                        index=False,
                    )
                    current_type += 1
                else:
                    type_column.append(
                        value_labels_type_map[hashable_current_value_label]
                    )
            target_crosswalk["CodingType"] = type_column
            target_crosswalk.to_excel(writer, sheet_name="master", index=False)
        return None

    def get_var_translations(
        self, categorical_crosswalk: dict[str:DataFrame], variable: str
    ) -> None:
        target_master = categorical_crosswalk["master"].loc[
            categorical_crosswalk["master"]["TargetName"] == variable
        ]
        year_to_types = dict(target_master[["Year", "CodingType"]].values)
        return {
            year: dict(
                categorical_crosswalk["_".join([variable, "Type", str(coding_type)])][
                    ["codevalue", "master_codevalue"]
                ]
                .dropna()
                .values
            )
            for year, coding_type in year_to_types.items()
        }

    def make_analysis_data(
        self,
        sheet_name: str,
        year_data_path_map: dict[int:str],
        destination: str | None = None,
        categorical_var_translation: dict[str : dict[int : dict[str:int]]]
        | None = None,
    ) -> DataFrame | None:
        expanded_crosswalk_sheet = self.disagg_year_ranges(
            dataframe=self.crosswalk[sheet_name].copy(),
            year_range_column="YearRanges",
        )
        datasets_list = []
        for year, data_path in year_data_path_map.items():
            current_target_name_map = dict(
                expanded_crosswalk_sheet.loc[expanded_crosswalk_sheet["Year"] == year][
                    ["CurrentName", "TargetName"]
                ].values
            )
            current_dataset = (
                pd.read_csv(
                    data_path,
                    usecols=lambda x: x.upper()
                    in {"UNITID"}.union(set(current_target_name_map.keys())),
                    low_memory=False,
                    encoding="latin-1",
                    index_col=False,
                )
                .rename(columns=lambda x: x.upper())
                .rename(columns=current_target_name_map)
                .assign(YEAR=year)
            )
            if categorical_var_translation is not None:
                for variable in categorical_var_translation.keys():
                    translation_map = categorical_var_translation[variable].get(year)
                    if translation_map is not None:
                        current_dataset["MASTER_" + variable] = current_dataset[
                            variable
                        ].map(translation_map)
            datasets_list.append(current_dataset)
        analysis_dataset = pd.concat(datasets_list).reset_index(drop=True)
        if destination is not None:
            analysis_dataset.to_csv(destination, index=False)
            return None
        else:
            return analysis_dataset

    def convert_data_type(self, column: Series, var_type: str) -> Series:
        if var_type == "string":
            return column.astype(str)
        elif var_type == "numeric":
            return pd.to_numeric(column, errors="coerce")
        else:
            raise ValueError(f"{var_type} is not supported.")


def continuous_ranges(numbers: list, do_sort: bool = False) -> str:
    numbers_copy = numbers.copy()
    if do_sort:
        numbers_copy.sort()
    ranges = iter(
        numbers_copy[0:1]
        + sum(
            (
                list((this_number, next_number))
                for this_number, next_number in zip(numbers_copy, numbers_copy[1:])
                if this_number + 1 != next_number
            ),
            [],
        )
        + numbers_copy[-1:]
    )
    return ", ".join((f"{str(number)}-{str(next(ranges))}" for number in ranges))
