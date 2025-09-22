import numpy as np
import xarray as xr
import glob
import datetime
import os

# savepath = "./CALIPSO-AllSky-D_AOD.nc"
# files = np.sort(glob.glob("raw-allsky/CAL_LID_L3_Tropospheric_APro_AllSky-Standard-V4-20.*D.hdf"))
savepath = "./CALIPSO-CloudFree-D_AOD.nc"
files = np.sort(glob.glob("raw-cloudfree/CAL_LID_L3_Tropospheric_APro_CloudFree-Standard-V4-20.*D.hdf"))

for i,fi in enumerate(files):
    date = fi.split(".")[-2]
    time = datetime.datetime(int(date.split("-")[0]), int(date.split("-")[1].split("D")[0]), 15)
    
    dsi = xr.open_dataset(fi, engine="netcdf4")
    lon = (dsi.Longitude_Midpoint.values[0] + 360) % 360
    lat = dsi.Latitude_Midpoint.values[0]

    aod = np.reshape(dsi.AOD_Mean.where(dsi.AOD_Mean >= 0, np.nan).values, (len(lat), len(lon), 1))
    
    dsn = xr.Dataset(
        {
            "AOD_Mean": (("lat","lon","time"), aod),
        },
        coords={
            "lon":lon,
            "lat":lat,
            "time":np.array([time]),
        },)
    dsn = dsn.sortby("lat").sortby("lon")

    if i == 0:
        ds = dsn
    else:
        ds = xr.merge([ds, dsn])

if os.path.exists(savepath):
    os.remove(savepath)
ds.to_netcdf(savepath)

dsi.close()
dsn.close()
ds.close()
print("done")
