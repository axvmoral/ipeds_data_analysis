class D:
    def __init__(self, source: str) -> None:
        self.var_desc_map = {}
        self.var_extended_desc_map = {}
        self.var_vl_map = {}
        self.var_type_map = {}
        found_var = False
        pPath = Path(source)
        if pPath.suffix == ".html":
            with open(source, "r", errors="replace") as f:
                meat = (
                    BeautifulSoup(f.read(), "html.parser").find_all("tr")[2].find("td")
                )
            i = 0
            for element in meat.contents:
                if not isinstance(element, Tag) and not isinstance(element, Comment):
                    if i == 0:
                        pVarDesc = re.findall(
                            r"(^[A-Z]\w*)-\d+-(.+)", element.text.strip()
                        )
                        if pVarDesc:
                            var, desc = pVarDesc[0]
                            self.var_desc_map[var] = desc
                            i = 1
                            found_var = True
                    elif i == 1:
                        self.var_extended_desc_map[var] = element.text
                elif isinstance(element, Tag):
                    if found_var:
                        pType = re.findall(r"Data type-(.+)", element.text.strip())
                        if pType:
                            self.var_type_map[var] = pType
                        pValuelabel = element.select(
                            "table:-soup-contains('Code Value')"
                        )
                        self.var_vl_map[var] = (
                            self.__normalize_value_label(
                                pd.read_html(io.StringIO(str(pValuelabel)))[-1],
                                self.var_type_map[var],
                            )
                            if pValuelabel
                            else None
                        )

                    if element.find("hr") is not None:
                        i = 0
                    elif element.name == "hr":
                        i = 0


class tDictionary:
    def __init__(self, source: str) -> None:
        path_suffix = source[source.rfind(".") :]
        if path_suffix == ".html":
            self.reg_var_desc_map, self.var_extended_desc_map, self.imp_var_desc_map = (
                {},
                {},
                {},
            )
            reg_var_vl_map, imp_var_vl_map = {}, {}
            block = []
            with open(source, "r", errors="replace") as f:
                meat = (
                    BeautifulSoup(f.read(), "html.parser").find_all("tr")[2].find("td")
                )
            for element in meat.contents:
                if isinstance(element, Tag):
                    if element.name == "hr" and block:  # This is unitid or instnm
                        variable, description = re.findall(
                            r"(^[A-Z]\w*)-(.+)", block[0]
                        )[0]
                        self.reg_var_desc_map[variable] = description
                        reg_var_vl_map[variable] = None
                        block = []
                    elif element.name == "table":
                        if element.find("hr") is not None:
                            block.append(element)
                            block = block[:1] + [" ".join(block[1:-1])] + block[-1:]
                            variable, description = re.findall(
                                r"(^[A-Z]\w*)-\d+-(.+)", block[0]
                            )[0]
                            self.reg_var_desc_map[variable] = description
                            self.var_extended_desc_map[variable] = block[1]
                            potential_value_label = block[-1].select(
                                "table:-soup-contains('Code Value')"
                            )
                            reg_var_vl_map[variable] = (
                                self.__normalize_value_label(
                                    pd.read_html(
                                        io.StringIO(str(potential_value_label))
                                    )[-1],
                                )
                                if len(potential_value_label) > 0
                                else None
                            )
                            block = []
                        elif element.find_next_sibling().name == "hr":
                            block.append(element)
                            block = block[:1] + [" ".join(block[1:-1])] + block[-1:]
                            variable, description = re.findall(
                                r"(^[A-Z]\w*)-(.+)", block[0]
                            )[0]
                            self.imp_var_desc_map[variable] = description
                            potential_value_label = block[-1].select(
                                "table:-soup-contains('Code Value')"
                            )
                            imp_var_vl_map[variable] = pd.read_html(
                                io.StringIO(str(potential_value_label))
                            )[-1]
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
            self.reg_var_desc_map = dict(
                workbook["varlist"][["varname", "varTitle"]].values
            )
            self.var_extended_desc_map = dict(
                workbook["Description"][["varname", "longDescription"]].values
            )
            reg_var_vl_map = (
                {
                    var: self.__normalize_value_label(
                        workbook["Frequencies"].loc[
                            workbook["Frequencies"]["varname"] == var,
                            ["valuelabel", "codevalue"],
                        ],
                        html=False,
                    )
                    for var in workbook["Frequencies"]["varname"].unique()
                }
                if "Frequencies" in workbook
                else {}
            )
            self.imp_var_desc_map = (
                dict(
                    workbook["varlist"]
                    .loc[
                        ~workbook["varlist"]["imputationvar"].isna(),
                        ["imputationvar", "varTitle"],
                    ]
                    .values
                )
                if "imputationvar" in workbook["varlist"].columns
                else {}
            )
            imp_var_vl_map = (
                {
                    imp_var: workbook["Imputation values"]
                    .rename(columns=workbook["Imputation values"].iloc[0])
                    .drop(0)
                    for imp_var in workbook["varlist"].loc[
                        ~workbook["varlist"]["imputationvar"].isna(), "imputationvar"
                    ]
                }
                if "Imputation values" in workbook
                else {}
            )
        self.var_desc_map = self.reg_var_desc_map | self.imp_var_desc_map
        self.var_vl_map = reg_var_vl_map | imp_var_vl_map
        return None

    def __repr__(self) -> str:
        return self.var_desc_map.__repr__()

    def __str__(self) -> str:
        return self.var_desc_map.__str__()

    def __contains__(self, variable: str) -> bool:
        return variable in self.var_desc_map

    def __getitem__(self, variable: str) -> str:
        return self.var_desc_map[variable]

    def __iter__(self):
        for variable in self.var_desc_map.keys():
            yield variable

    def get_extended_desc(self, variable: str) -> str:
        return self.var_extended_desc_map[variable]

    def get_value_label(self, variable: str) -> DataFrame:
        return self.var_vl_map[variable]

    def __normalize_value_label(self, value_label: DataFrame, html: bool = True):
        if html:
            value_label = value_label.rename(
                columns=value_label.iloc[0].str.replace(" ", "").str.lower()
            ).drop([0, len(value_label) - 1])[["valuelabel", "codevalue"]]
        return value_label.assign(
            valuelabel=lambda x: x["valuelabel"]
            .str.replace(
                f"[{string.punctuation.replace('/', '')}]",
                " ",
                regex=True,
            )
            .str.replace(r"\s\s+", " ", regex=True)
            .str.lower()
            .str.strip(),
            codevalue=lambda x: pd.to_numeric(x["codevalue"], errors="coerce"),
        )
