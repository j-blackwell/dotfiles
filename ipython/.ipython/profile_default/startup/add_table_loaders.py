try:
    import src.helpers.ipython as i

    cm = i.create_schema_loader("capacity", globals=globals())
    cy = i.create_schema_loader("capacity_yearly", globals=globals())
    gy = i.create_schema_loader("generation_yearly", globals=globals())
    gm = i.create_schema_loader("generation_monthly", globals=globals())
    gh = i.create_schema_loader("generation_hourly", globals=globals())
    ga = i.create_schema_loader("google_analytics", globals=globals())
    m = i.create_schema_loader("methane", globals=globals())
    p = i.create_schema_loader("price", globals=globals())
    rt = i.create_schema_loader("res_tracker", globals=globals())
    s = i.create_schema_loader("sources", globals=globals())
except ImportError:
    pass

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
