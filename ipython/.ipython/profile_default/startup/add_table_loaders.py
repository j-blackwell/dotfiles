try:
    import src.helpers.ipython as i
    cm = i.create_schema_loader("capacity", globals=globals())
    gy = i.create_schema_loader("generation_yearly", globals=globals())
    gm = i.create_schema_loader("generation_monthly", globals=globals())
    gh = i.create_schema_loader("generation_hourly", globals=globals())
    ga = i.create_schema_loader("google_analytics", globals=globals())
    p = i.create_schema_loader("price", globals=globals())
    s = i.create_schema_loader("sources", globals=globals())
except ImportError:
    pass
