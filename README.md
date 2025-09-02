# EV Data (Fork of Open EV Data)

This repository is a fork of [Open EV Data](https://github.com/KilowattApp/open-ev-data), 
a comprehensive database of electric vehicle specifications focusing on charging capabilities 
and energy consumption. 

In this fork I am extending the dataset with **additional EV specifications** such as:

- Top speed (`top_speed_kmh`)
- Driving range by cycle (`range_wltp_km`, `range_epa_km`, `range_cltc_km`)
- Other technical details relevant for research and applications

The goal is to create a richer, more complete dataset for use in my bachelor thesis and 
potential EV-related projects.

---

## Upstream project

The original project was created and maintained by Kilowatt (the *Kilowatt – Electric Car Timer* app).  
Data is released under the MIT License with Attribution Requirement. Please see 
[LICENSE](LICENSE) for full terms.

Original repository: [KilowattApp/open-ev-data](https://github.com/KilowattApp/open-ev-data)

---

## Current extensions

- Added new fields for EV performance specs (top speed, ranges).
- Work in progress: scripts for automated data extraction and enrichment.
- Plan: convert enriched data into convenient formats (CSV, XLSX, SQLite).

---

## License and attribution

This fork retains the original MIT License with Attribution.  
If you use this dataset, please include attribution to both:

- [Open EV Data](https://github.com/KilowattApp/open-ev-data) (original dataset)
- This repository (extended dataset)
