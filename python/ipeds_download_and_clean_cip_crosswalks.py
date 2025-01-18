"""Module for downloading and modifying the CIP code crosswalks"""

__author__ = "Axel V. Morales Sanchez"

import pandas as pd
from selenium import webdriver
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
import io
from functools import reduce

PATH_STEM = "S:/steinbaum_share/IPEDS-CS/Axel/ipeds_data_analysis/datasets/helper/cip_crosswalks"

CIP_1985_1990_CROSSWALK_URL = "https://nces.ed.gov/pubs2002/cip2000/crosswalk8590.ASP"
CIP_1990_2000_CROSSWALK_URL = "https://nces.ed.gov/pubs2002/cip2000/crosswalk.asp"

download_info = {
    (1985, 1990): (CIP_1985_1990_CROSSWALK_URL, "//input[@id='SUBMIT1']"),
    (1990, 2000): (CIP_1990_2000_CROSSWALK_URL, "//input[@value='Show All']"),
}

existing_crosswalks_year_ranges = [(2000, 2010), (2010, 2020)]

with webdriver.Chrome() as driver:
    for year_range, info in download_info.items():
        from_year, to_year = year_range
        url, button_xpath = info
        driver.get(url)
        load_results_button = driver.find_element(By.XPATH, button_xpath)
        load_results_button.click()  # Loads all records into webpage as html
        crosswalk = None
        while crosswalk is None:
            try:  # Try until button loads results to find and scrape
                crosswalk = pd.read_html(
                    io.StringIO(driver.page_source),
                    skiprows=4,
                    attrs={"border": 0, "cellpadding": 0, "cellspacing": 0},
                )[0]
            except:
                continue
        crosswalk.columns = [
            f"CIPCode{from_year}",
            f"CIPTitle{from_year}",
            f"CIPCode{to_year}",
            f"CIPTitle{from_year}",
        ]
        crosswalk.to_csv(
            f"{PATH_STEM}/cip_crosswalk_{from_year}_{to_year}.csv", index=False
        )

for year_range in existing_crosswalks_year_ranges:
    from_year, to_year = year_range
    crosswalk = pd.read_csv(
        f"{PATH_STEM}/cip_crosswalk_{from_year}_{to_year}.csv"
    ).astype(str)
    crosswalk[f"CIPCode{from_year}"] = crosswalk[f"CIPCode{from_year}"].str.extract(
        r"([0-9.])", expand=False
    )  # Extracts the xx.xxxx CIP code from weird ="xx.xxxx" format
    crosswalk[f"CIPCode{to_year}"] = crosswalk[f"CIPCode{to_year}"].str.extract(
        r"([0-9.])", expand=False
    )
    crosswalk.to_csv(
        f"{PATH_STEM}/cip_crosswalk_{from_year}_{to_year}.csv", index=False
    )
