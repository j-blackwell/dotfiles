from contextlib import suppress

print("Creating `new_obj()`")
new_obj = type("", (), {})

with suppress(ImportError):
    print("Importing `wat`")
    import wat

with suppress(ImportError):
    print("Importing `polars`")
    import polars as pl

    def print_pl(df: pl.DataFrame, tbl_rows=None, tbl_cols=-1):
        with pl.Config(tbl_rows=tbl_rows, tbl_cols=tbl_cols):
            print(df)


with suppress(ImportError):
    print("Importing `pandas`")
    import pandas as pd

with suppress(ImportError):
    print("Importing ipython helpers")
    import src.framework.ipython as i
