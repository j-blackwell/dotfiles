try:
    import src.framework.ipython as i
except ImportError:
    pass

new_obj = type("", (), {})

try:
    import polars as pl

    def print_pl(df: pl.DataFrame, tbl_rows=None, tbl_cols=None):
        with pl.Config(tbl_rows=tbl_rows, tbl_cols=tbl_cols):
            print(df)
except ImportError:
    pass

try:
    import pandas as pd
except ImportError:
    pass
