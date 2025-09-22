import cdsapi

c = cdsapi.Client()

c.retrieve(
    'cams-global-reanalysis-eac4-monthly',
    {
        'format': 'netcdf',
        'variable': [
            'black_carbon_aerosol_optical_depth_550nm', 'dust_aerosol_0.03-0.55um_mixing_ratio', 'dust_aerosol_0.55-0.9um_mixing_ratio',
            'dust_aerosol_0.9-20um_mixing_ratio', 'dust_aerosol_optical_depth_550nm', 'hydrophilic_black_carbon_aerosol_mixing_ratio',
            'hydrophilic_organic_matter_aerosol_mixing_ratio', 'hydrophobic_black_carbon_aerosol_mixing_ratio', 'hydrophobic_organic_matter_aerosol_mixing_ratio',
            'organic_matter_aerosol_optical_depth_550nm', 'sea_salt_aerosol_0.03-0.5um_mixing_ratio', 'sea_salt_aerosol_0.5-5um_mixing_ratio',
            'sea_salt_aerosol_5-20um_mixing_ratio', 'sea_salt_aerosol_optical_depth_550nm', 'sulphate_aerosol_mixing_ratio',
            'sulphate_aerosol_optical_depth_550nm', 'total_aerosol_optical_depth_550nm',
        ],
        'pressure_level': [
            '100', '150', '200',
            '250', '300', '400',
            '500', '600', '700',
            '800', '850', '900',
            '925', '950', '1000',
        ],
        'model_level': '60',
        'year': [
            '2003', '2004', '2005',
            '2006', '2007', '2008',
            '2009', '2010', '2011',
            '2012', '2013', '2014',
            '2015', '2016', '2017',
            '2018', '2019', '2020',
            '2021', '2022', '2023',
        ],
        'month': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
        ],
        'product_type': 'monthly_mean',
    },
    'cams-aerosol.zip')