import xarray as xr
import os
import datetime
import numpy as np

import sys
homepath = "../"
sys.path.append(homepath)
from hlpr_func import make_cyclic, make_double_cyclic

ceres = xr.open_mfdataset("../CERES-data/CERES_Cru23_ds.nc")
ceres = ceres.sortby("lat").sortby("lon")

ds = xr.open_mfdataset("MERRA2_*.tavgM_*flx*.nc4")

ds["lon"] = (ds.coords['lon'] + 360) % 360
ds = ds.sortby("lat").sortby("lon")
ds = make_double_cyclic(ds)
ds = ds.interp(lat = ceres.lat, lon = ceres.lon)

# ds = ds.sel(time=slice("2000-03","2023-12"))
# ds["time"] = ceres.time

year = ds.time.dt.year.values
month = ds.time.dt.month.values
time = []
for i,y in enumerate(ds.time.dt.year.values):
    m = ds.time.dt.month.values[i]
    t = datetime.datetime(int(y), int(m), 15)
    time.append(t)
ds["time"] = np.array(time)

print(ds)

if os.path.exists("./merra2-ws-interpolated.nc"):
    os.remove("./merra2-ws-interpolated.nc")
ds.to_netcdf("./merra2-ws-interpolated.nc")

ds.close()
ceres.close()
print("done")
