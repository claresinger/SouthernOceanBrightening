import numpy as np
import xarray as xr
import statsmodels.api as sm
from cartopy.util import add_cyclic_point

def cyclic_wrapper(x, dim="lon"):
    """So add_cyclic_point() works on 'dim' via xarray Dataset.map()"""
    wrap_data, wrap_lon = add_cyclic_point(
        x.values, 
        coord=x.coords[dim].data,
        axis=x.dims.index(dim)
    )
    return xr.DataArray(
        wrap_data, 
        coords={dim: wrap_lon, **x.drop(dim).coords}, 
        dims=x.dims
    )

def make_cyclic(ds):
    return ds.map(cyclic_wrapper, keep_attrs=True)

def make_double_cyclic(ds):
    ds_end_extend = ds.map(cyclic_wrapper, keep_attrs=True)
    ds_front_extend = ds.sortby("lon", ascending=False).map(cyclic_wrapper, keep_attrs=True).sortby("lon", ascending=True)
    return xr.merge([ds_end_extend, ds_front_extend])

def symmetric_antisymmetric(ds):
    negds = ds.copy()
    negds["lat"] = ds.lat * -1
    return (ds + negds) / 2, (ds - negds) / 2

def sindeg(x):
    return np.sin(np.deg2rad(x))

def add_weights(ds):
    weights = ds.time.dt.days_in_month
    weights = weights.where(weights.time.dt.month!=2, 28.65)
    ds["days_in_month"] = weights
    return ds

def get_weights_values(da):
    weights = da.time.dt.days_in_month
    weights = weights.where(weights.time.dt.month!=2, 28.65)
    return weights.values

def rolling_mean(ds, n):
    if not "days_in_month" in ds:
        ds = add_weights(ds)
    w = ds.days_in_month / ds.days_in_month.isel(time=slice(0,n)).mean()
    return (ds * w).rolling(time=n, center=True).mean("time")

def time_mean(ds):
    if not "days_in_month" in ds.data_vars:
        ds = add_weights(ds)
    return ds.weighted(ds.days_in_month).mean("time")

def time_anom(ds):
    return ds - time_mean(ds)


def calc_trend_HAC(t, y, w=None, hac_maxlags=12):
    if w is None:
        w = np.ones_like(y)
    X = np.column_stack([np.ones_like(y), t])
    
    wls_res = sm.WLS(y, X, weights=w).fit()
    rob = wls_res.get_robustcov_results(cov_type="HAC", maxlags=hac_maxlags)

    slope = float(rob.params[1])
    lower,upper = rob.conf_int(alpha=0.05)[1,:]
    return wls_res.fittedvalues, slope, (upper-lower)/2


def linreg_weighted(x, y, weights=None):
    if weights is None:
        weights = np.ones_like(x)
    X = x.reshape(-1, 1) # make 2D
    
    # Fit weighted least squares
    model = sm.WLS(y, X, weights=weights)
    results = model.fit()
    slope = results.params[0]
    
    # Weighted correlation coefficient
    x_mean = np.average(x, weights=weights)
    y_mean = np.average(y, weights=weights)
    r_num = np.sum(weights * (x - x_mean) * (y - y_mean))
    r_den = np.sqrt(np.sum(weights * (x - x_mean)**2) * np.sum(weights * (y - y_mean)**2))
    rvalue = r_num / r_den
    
    return {'slope': slope, 'rvalue': rvalue}


def lat_mean(ds):
    return ds.weighted(np.cos(np.deg2rad(ds.lat))).mean("lat")


def calc_atm(F_TOA_up, S, F_surf_dn, F_surf_up):
    S_m = np.ma.masked_less(S, 1e-9)
    F_surf_dn_m = np.ma.masked_less(F_surf_dn, 1e-9)
    R = F_TOA_up / S_m
    T = F_surf_dn / S_m
    a = F_surf_up / F_surf_dn_m
    t = T * (1 - a * R) / (1 - a**2 * T**2)
    r = R - t * a * T
    F_atm = np.where(S_m.mask | F_surf_dn_m.mask, 0, S * r)
    return F_atm

def calc_surf(F_TOA_up, S, F_surf_dn, F_surf_up):
    S_m = np.ma.masked_less(S, 1e-9)
    F_surf_dn_m = np.ma.masked_less(F_surf_dn, 1e-9)
    R = F_TOA_up / S_m
    T = F_surf_dn / S_m
    a = F_surf_up / F_surf_dn_m
    t = T * (1 - a * R) / (1 - a**2 * T**2)
    r = R - t * a * T
    F_surf = np.where(S_m.mask | F_surf_dn_m.mask, 0, S * (a * t**2) / (1 - r * a))
    return F_surf


def sym_asym(ds, phi=False):
    if phi:
        negds = ds.copy()
        negds["phi"] = np.flip(ds.phi)
        return (ds + negds) / 2, (ds - negds) / 2
    else:
        negds = ds.copy()
        negds["lat"] = np.flip(ds.lat)
        return (ds + negds) / 2, (ds - negds) / 2
