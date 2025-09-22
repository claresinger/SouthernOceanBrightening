import numpy as np
import xarray as xr
import os

import sys
homepath = "../"
sys.path.append(homepath)
from hlpr_func import make_cyclic, make_double_cyclic

ceres = xr.open_mfdataset("../CERES-data/CERES_Cru23_ds.nc")
ceres = ceres.sortby("lat").sortby("lon")

met = xr.open_dataset("./era5-surface.nc")
met = met.sel(expver=1).drop_vars(["expver"])
met = met.rename_dims({"longitude":"lon", "latitude":"lat"}).rename_vars({"longitude":"lon", "latitude":"lat"})
met = make_cyclic(met.sortby("lat").sortby("lon"))
met = met.interp(lat = ceres.lat, lon = ceres.lon)

wind = xr.open_dataset("era5-wind.nc")
wind = wind.sel(expver=1)
wind = wind.drop_vars(["u10","v10","expver"])
wind = wind.rename_dims({"longitude":"lon", "latitude":"lat"}).rename_vars({"longitude":"lon", "latitude":"lat"})
wind = make_cyclic(wind.sortby("lat").sortby("lon"))
wind = wind.interp(lat = ceres.lat, lon = ceres.lon)
ds = xr.merge([met, wind])
met.close()
wind.close()

sea_ice = xr.open_mfdataset("era5-sea_ice_cover.nc")
sea_ice = sea_ice.rename_dims(
    {"longitude":"lon", "latitude":"lat", "valid_time":"time"}).rename_vars(
    {"longitude":"lon", "latitude":"lat", "valid_time":"time"})
sea_ice = sea_ice.drop_vars(["expver","number"])
sea_ice = make_cyclic(sea_ice.sortby("lat").sortby("lon"))
sea_ice = sea_ice.interp(lat = ceres.lat, lon = ceres.lon)
ds = xr.merge([ds, sea_ice])
sea_ice.close()

humidity = xr.open_mfdataset("era5-humidity.nc")
humidity = humidity.rename_dims(
    {"longitude":"lon", "latitude":"lat", "valid_time":"time"}).rename_vars(
    {"longitude":"lon", "latitude":"lat", "valid_time":"time"})
humidity = humidity.drop_vars(["expver","number"])
humidity = make_cyclic(humidity.sortby("lat").sortby("lon"))
humidity = humidity.interp(lat = ceres.lat, lon = ceres.lon)
ds = xr.merge([ds, humidity])
humidity.close()


aod = xr.open_dataset("./levtype_sfc.nc")
aod = aod.rename_dims({"longitude":"lon", "latitude":"lat"}).rename_vars({"longitude":"lon", "latitude":"lat"})
aod = make_cyclic(aod.sortby("lat").sortby("lon"))
aod = aod.interp(lat = ceres.lat, lon = ceres.lon)
ds = xr.merge([ds, aod])
aod.close()


# aer = xr.open_dataset("./levtype_pl.nc")
# aer = aer.rename_dims({"longitude":"lon", "latitude":"lat"}).rename_vars({"longitude":"lon", "latitude":"lat"})
# aer = aer.sortby("lat").sortby("lon")
# aer = aer.interp(lat = ceres.lat, lon = ceres.lon)
# ds = xr.merge([ds,aer])
# aer.close()

ds["lsmask"] = (ds.sst / ds.sst).fillna(0)
ds["landmask"] = 1 - ds.lsmask
ds["icemask"] = (ds.siconc > 0.01).astype(int)
ds["limask"] = xr.where(ds.landmask + ds.icemask > 1, 1.0, ds.landmask + ds.icemask)

ds = ds.sel(time=slice("2000-03","2024-03"))
ds["time"] = ceres.time
print(ds)

if os.path.exists("./era5-interpolated.nc"):
    os.remove("./era5-interpolated.nc")
ds.to_netcdf("./era5-interpolated.nc")

ds.close()
ceres.close()
print("done")