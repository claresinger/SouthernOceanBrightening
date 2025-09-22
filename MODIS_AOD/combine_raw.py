import numpy as np
import xarray as xr
import glob
import datetime

days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
cumdays_in_month = np.cumsum(days_in_month)

###########
# Terra
###########

Terra_files = glob.glob("raw/MOD*.hdf")
print(len(Terra_files))

for i,f in enumerate(Terra_files):
    date = f.split(".A")[1].split(".")[0]
    year, day = date[:4], date[4:]
    for j,c in enumerate(cumdays_in_month):
        if int(day) < c:
            time = datetime.datetime(year=int(year), month=j+1, day=15)
            break
    ds_orig = xr.open_dataset(f, engine="netcdf4")
    dsi = xr.Dataset(
        data_vars = {
            "aod":(("lat","lon","time"), ds_orig.Aerosol_Optical_Depth_Land_Ocean_Mean_Mean.values[:,:, np.newaxis]), 
            # "sza":(("lat","lon","time"), ds_orig.Solar_Zenith_Mean_Mean.values[:,:, np.newaxis]),
        }, 
        coords = {
            "lat":ds_orig.YDim.values, 
            "lon":ds_orig.XDim.values,
            "time":[time],
        }
    )
    if i > 0:
        ds = ds.merge(dsi)
    else:
        ds = dsi

ds = ds.sortby("time")
ds["lon"] = (ds.coords['lon'] + 360) % 360
ds = ds.sortby("lon").sortby("lat")
print(ds)

ds.to_netcdf("./Terra_combined.nc")

ds_orig.close()
dsi.close()
ds.close()

###########
# Aqua
###########

Aqua_files = glob.glob("raw/MYD*.hdf")
print(len(Aqua_files))

for i,f in enumerate(Aqua_files):
    date = f.split(".A")[1].split(".")[0]
    year, day = date[:4], date[4:]
    for j,c in enumerate(cumdays_in_month):
        if int(day) < c:
            time = datetime.datetime(year=int(year), month=j+1, day=15)
            break
    ds_orig = xr.open_dataset(f, engine="netcdf4")
    dsi = xr.Dataset(
        data_vars = {
            "aod":(("lat","lon","time"), ds_orig.Aerosol_Optical_Depth_Land_Ocean_Mean_Mean.values[:,:, np.newaxis]), 
            # "sza":(("lat","lon","time"), ds_orig.Solar_Zenith_Mean_Mean.values[:,:, np.newaxis]),
        }, 
        coords = {
            "lat":ds_orig.YDim.values, 
            "lon":ds_orig.XDim.values,
            "time":[time],
        }
    )
    if i > 0:
        ds = ds.merge(dsi)
    else:
        ds = dsi

ds = ds.sortby("time")
ds["lon"] = (ds.coords['lon'] + 360) % 360
ds = ds.sortby("lon").sortby("lat")
print(ds)

ds.to_netcdf("./Aqua_combined.nc")

ds_orig.close()
dsi.close()
ds.close()