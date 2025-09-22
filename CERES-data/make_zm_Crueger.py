import xarray as xr
import numpy as np
import os
import sys
homepath = "../"
sys.path.append(homepath)
from hlpr_func import calc_atm, calc_surf

ds = xr.open_mfdataset(["CERES_EBAF_Ed4.2_Subset_200003-201412.nc",
                        "CERES_EBAF_Ed4.2_Subset_201501-202312.nc",
                        "CERES_EBAF_Ed4.2_Subset_202401-202403.nc"
                       ])

ds["F_atm"] = xr.apply_ufunc(
    calc_atm, 
    ds.toa_sw_all_mon, 
    ds.solar_mon, 
    ds.sfc_sw_down_all_mon, 
    ds.sfc_sw_up_all_mon,
    vectorize=True,
    output_dtypes=[ds.solar_mon.dtype],
    dask="allowed"
)

ds["F_surf"] = xr.apply_ufunc(
    calc_surf, 
    ds.toa_sw_all_mon, 
    ds.solar_mon, 
    ds.sfc_sw_down_all_mon, 
    ds.sfc_sw_up_all_mon,
    vectorize=True,
    output_dtypes=[ds.solar_mon.dtype],
    dask="allowed"
)

ds["G_atm"] = xr.apply_ufunc(
    calc_atm, 
    ds.toa_sw_clr_t_mon, 
    ds.solar_mon, 
    ds.sfc_sw_down_clr_t_mon, 
    ds.sfc_sw_up_clr_t_mon,
    vectorize=True,
    output_dtypes=[ds.solar_mon.dtype],
    dask="allowed"
)

ds["G_surf"] = xr.apply_ufunc(
    calc_surf, 
    ds.toa_sw_clr_t_mon, 
    ds.solar_mon, 
    ds.sfc_sw_down_clr_t_mon, 
    ds.sfc_sw_up_clr_t_mon,
    vectorize=True,
    output_dtypes=[ds.solar_mon.dtype],
    dask="allowed"
)

ds["gamma"] = ds.F_surf / ds.G_surf # attenuation of surface contribution by clouds
ds["gamma"] = xr.where(ds.gamma < 1, 1, ds.gamma).fillna(0) # attenuation factor cannot be smaller than 1 because 1 means no attenuation. also if the clear-sky surface contribution is zero it is undefined, so fill as zero.
ds["F_clr"] = (ds.gamma * ds.G_atm).fillna(0) # assume attenuation of surface by clouds is same as attenuation of atmosphere by clouds (implicitly, assumes that aerosols are below clouds)
ds["F_clr"] = xr.where(ds.F_clr > ds.F_atm, ds.F_atm, ds.F_clr) # F_clr can't be larger than total atm component
ds["F_cloud"] = ds.F_atm - ds.F_clr
ds["F_TOA"] = ds.toa_sw_all_mon
ds["F_TOA_clr_t"] = ds.toa_sw_clr_t_mon
ds["F_TOA_clr_c"] = ds.toa_sw_clr_c_mon
ds["S"] = ds.solar_mon

ds = ds[["F_surf", "F_atm", "G_atm", "G_surf", "F_clr", "F_cloud", "F_TOA", "F_TOA_clr_t", "F_TOA_clr_c", "S"]]

zm = ds.mean("lon")
if os.path.exists("CERES_Cru23_zm.nc"):
    os.remove("CERES_Cru23_zm.nc")
zm.to_netcdf("CERES_Cru23_zm.nc")
zm.close()

ds = ds[["F_surf", "F_clr", "F_cloud", "F_TOA", "F_TOA_clr_t", "F_TOA_clr_c", "S"]]
if os.path.exists("CERES_Cru23_ds.nc"):
    os.remove("CERES_Cru23_ds.nc")
ds.to_netcdf("CERES_Cru23_ds.nc")
ds.close()


