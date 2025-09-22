import cdsapi

dataset = "satellite-sea-ice-concentration"
request = {
    "variable": "all",
    "version": "v3",
    "sensor": "ssmis",
    "origin": "eumetsat_osi_saf",
    "region": ["southern_hemisphere"],
    "cdr_type": ["cdr"],
    "temporal_aggregation": "monthly",
    "year": [
        "2000", "2001", "2002",
        "2003", "2004", "2005",
        "2006", "2007", "2008",
        "2009", "2010", "2011",
        "2012", "2013", "2014",
        "2015", "2016", "2017",
        "2018", "2019", "2020"
    ],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ]
}

client = cdsapi.Client()
client.retrieve(dataset, request).download()
