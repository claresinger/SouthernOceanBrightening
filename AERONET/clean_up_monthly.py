import xarray as xr

# open monthly data
ar = xr.open_dataset("AERONET/Monthly_SO_AOD_500nm.nc")
ar["lon"] = (ar["lon"] + 360) % 360
ar = ar.sortby("lat").sortby("lon")

# calculate median at each station
med = ar.AOD_500nm.median("time")

# drop stations without any data
locs = med.dropna("location").location.values
ar_nonan = ar.sel(location=locs)

# remove outlier points that are more than 3x the median at each station
ar_nooutliers = ar_nonan.where(ar_nonan.AOD_500nm <= 3*med)

# only keep stations with more than 36 months of data
ar_nooutliers["keep"] = (ar_nooutliers.count("time").AOD_500nm >= 36) 
ar_min = ar_nooutliers.where(ar_nooutliers.keep, drop=True).drop_vars(["keep"])

# remove time coordinate from lat/lon
ar_min["lat"] = ar_min.lat.mean("time")
ar_min["lon"] = ar_min.lon.mean("time")

# remove months that have no data at any station
ar_min = ar_min.dropna("time", how="all")

# save cleaned-up data to new file
ar_min.to_netcdf("AERONET/Monthly_SO_AOD_500nm_clean.nc")