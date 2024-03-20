import warnings

warnings.filterwarnings("ignore", category=RuntimeWarning, module="pandasdmx")


try:
    import dagster as dag

    warnings.filterwarnings("ignore", category=dag.ExperimentalWarning)
except ModuleNotFoundError:
    pass
