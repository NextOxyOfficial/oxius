# Intentionally present, not empty by accident.
#
# `base` was the only app in the project without this file. Django still
# imported it (Python 3 namespace packages), so nothing looked broken — but
# unittest's discovery will not descend into a directory that is not a real
# package, so `python manage.py test` with no arguments silently collected
# ZERO tests from `base`. Every wallet, ownership and withdrawal test lived
# here and none of them ran unless the app was named explicitly.
#
# Do not delete this file to "tidy up". Deleting it turns the money-integrity
# suite back into decoration.
