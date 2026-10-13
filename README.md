# beethoven-sm

Private development repository for transitioning NIEHS SET group's [`beethoven`](https://github.com/NIEHS/beethoven) air pollution modelling project from `targets` to Snakemake.

The current workflow prepares temporal specifications, downloads AQS, NARR, and HMS data via `amadeus`, and merges AQS observations with NARR/HMS covariates in `output/dt_feat_merge_sptmpl.qs`. It then builds an H3 grid from the North Carolina county example bundled with `sf` and prepares NARR/HMS covariates for that grid. The default endpoint is `output/dt_pred_merge_sptmpl.qs`. Cross-validation and model fitting remain placeholders; the prediction tier currently prepares grid covariates, with model-based pollutant predictions still to be implemented.

Snakemake schedules the file dependencies between rules. NARR and HMS downloads and calculations also use local `mirai` worker processes within their R scripts; NARR extraction uses `mori` to share prepared locations between workers.

## Directory structure

```text
beethoven-sm/
├── Snakefile                       # Configuration, default target, rule includes
├── run.sh                          # SLURM job script and Apptainer-enabled launcher
├── config/
│   └── config.yaml                 # Dates, buffer radii, data directory, H3 resolution
├── rules/
│   ├── a01_initiate.smk            # Date initialization
│   ├── b01_download.smk            # AQS, NARR, and HMS downloads
│   ├── c01_calculate.smk           # AQS features, NARR/HMS covariates, and merge
│   └── f01_grid.smk                # H3 grid, grid covariates, and prediction-data merge
├── scripts/
│   ├── a01_initiate.R
│   ├── b01_aqs.R
│   ├── b02_narr.R
│   ├── b03_hms.R
│   ├── c01_aqs.R
│   ├── c02_narr.R
│   ├── c03_hms.R
│   ├── c99_merge.R
│   ├── d00_cross.R                 # Cross-validation placeholder
│   ├── e01_base.R                  # Base-model placeholder
│   ├── e02_meta.R                  # Meta-model placeholder
│   ├── f01_grid.R
│   ├── f02_narr.R
│   ├── f03_hms.R
│   └── f99_merge.R
├── R/
│   ├── amadeus.R                  # Local mirai download and extraction helpers
│   ├── beethoven.R                # Local date helpers and reduce_merge()
│   └── helpers.R                  # Interactive launch and SLURM utilities
├── container/
│   ├── def/                       # Covariates and models container definitions
│   ├── sh/                        # Apptainer build scripts
│   └── sif/                       # Built container images
├── input/                         # Raw downloads at the configured location
├── output/                        # Serialized R objects tracked by Snakemake
├── slurm/                         # SLURM standard output and error logs
└── .snakemake/                    # Snakemake runtime state and logs
```

The `.smk` files declare dependencies, parameters, outputs, and containers. Their corresponding R scripts perform the work using the `snakemake` object. `R/amadeus.R` supplies the local mirai-enabled download and extraction functions used by the NARR/HMS scripts. `R/beethoven.R` supplies temporary local implementations of `split_dates()`, `fl_dates()`, and `reduce_merge()`. `R/helpers.R` is for interactive use and is not sourced by the workflow scripts; `batch()` defaults to submitting `run.sh`. Downloaded inputs, generated outputs, container images, `.snakemake/`, and `slurm/` are ignored by Git.

## Names

Use lowercase, underscore-separated object names in the order `objecttype_stage_source_description`. Each component identifies the object's type, stage or configuration role, data source, and contents. Shared configuration and initialization objects omit the dataset source; download lists omit the additional description. For serialized objects, keep the R object name, named Snakemake input/output, and saved filename stem identical; for example, `sf_feat_aqs_sp` is saved as `output/sf_feat_aqs_sp.qs`.

| Component | Meaning | Codes used in the pipeline |
| --- | --- | --- |
| `objecttype` | Object type, class, or configured value type. | `sf`: spatial simple features; `dt`: `data.table`; `list`: list; `chr`: character values; `int`: integer values. |
| `stage` | Processing stage or configuration role. | `config`: configured values; `init`: derived initialization objects; `dl`: download results; `feat`: AQS-site feature data; `pred`: prediction-grid data; `iter`: variable selection, as in `chr_iter_narr`. |
| `source` | Dataset or combined-source result represented by the object. Not included for shared configuration or initialization objects. | `aqs`, `narr`, `hms`; `grid` for H3 geometry; `h3r8` for the grid identifier-column name; `merge` for combined covariate tables. |
| `description` | Contents or spatial/temporal scope. Not included for download list objects. | `daterange`: configured date endpoints; `dir`: data directory; `radii`: buffer radii; `dates`: calendar dates; `years`: included years; `datesj`: Julian-format dates (`YYYYJJJ`); `sp`: spatial only; `sptmpl`: spatiotemporal; `r8`: the H3 grid label anticipating resolution 8, with the actual resolution controlled by `int_grid_res`. |

Configuration names follow `objecttype_config_description` and are defined in `config/config.yaml`. Initialization outputs follow `objecttype_init_description` and are derived by `initiate`. For example, `chr_config_daterange` supplies the start and end dates used to generate `chr_init_dates`; the configuration value is not itself a `.qs` output.

The H3 resolution setting retains the shorter name `int_grid_res`. It is currently `6` for development, with a switch to resolution `8` planned. The `h3r8`/`r8` names are intentional: `prediction_h3r8`, `chr_pred_h3r8`, `sf_pred_grid_r8`, and the column `h3r8_id` keep those names at both resolutions. The configuration value determines the generated cell resolution.

AQS-site tables use `site_id`. Grid generation saves the character scalar `"h3r8_id"` as `chr_pred_h3r8.qs`; downstream grid scripts read it as `chr_pred_h3r8` and use it to select the location identifier and merge keys. The scalar names the identifier column; the actual cell IDs are stored in that column of `sf_pred_grid_r8`.

Examples from the current pipeline, ordered from configuration and initialization through AQS features and prediction-grid covariates:

| Object | Interpretation |
| --- | --- |
| `chr_config_daterange` | Configuration mapping with character `start` and `end` dates. |
| `int_config_radii` | Configured buffer radii in meters, reserved for buffered calculations; current NARR/HMS scripts use `radius = 0`. |
| `chr_config_dir` | Configured download directory, resolved by the rules and passed to the R scripts under the same parameter name. |
| `int_grid_res` | Configured H3 resolution, currently `6`, passed to `h3jsr::polygon_to_cells()`. |
| `chr_init_dates` | Character vector of all calendar dates in the configured period. |
| `int_init_years` | Years covered by the configured period, used by the AQS and NARR download rules. |
| `list_init_dates` | List of chunks of up to 100 calendar dates, with each chunk contained within one year. |
| `list_init_datesj` | The same date chunks in Julian format (`YYYYJJJ`); the `j` suffix identifies this representation. |
| `sf_feat_aqs_sp` | An `sf` object containing unique AQS feature locations for the configured period: site identifiers and spatial coordinates, without monitored PM2.5 values. |
| `dt_feat_aqs_sptmpl` | A `data.table` containing AQS feature locations and times with available PM2.5 observations. The script requests `Arithmetic.Mean` and `Event.Type` from the daily `88101` CSV files. |
| `dt_feat_narr_sptmpl` | A `data.table` of NARR covariates at AQS locations and times, combining the variables listed in `chr_iter_narr`. |
| `dt_feat_hms_sptmpl` | A `data.table` of HMS smoke-presence indicators at AQS locations and times: `light_00000`, `medium_00000`, and `heavy_00000` with the current zero-radius setting. |
| `dt_feat_merge_sptmpl` | The merged AQS-site `data.table`, joining observations and NARR/HMS covariates by `site_id` and character-valued `time`; an input to grid generation. |
| `chr_pred_h3r8` | Character scalar `"h3r8_id"`, saved by grid generation and read by grid NARR, HMS, and merge scripts to identify the location column. |
| `sf_pred_grid_r8` | An `sf` object of H3 cell polygons with an `h3r8_id` column, built from the North Carolina example geometry at `int_grid_res`. |
| `dt_pred_narr_sptmpl` | A `data.table` of NARR covariates by H3 cell and time, using the location column named by `chr_pred_h3r8`. |
| `dt_pred_hms_sptmpl` | A `data.table` of light, medium, and heavy smoke-presence indicators by H3 cell and time. |
| `dt_pred_merge_sptmpl` | The final `data.table`, joining grid NARR/HMS covariates by the column named by `chr_pred_h3r8` and character-valued `time`. |

The current download lists use `objecttype_stage_source`: `list_dl_aqs`, `list_dl_narr`, and `list_dl_hms`. The NARR variable selection uses the same three-part form, `chr_iter_narr`. `list_dl_collect` combines the three download results locally in `scripts/c01_aqs.R`. The calculation scripts also use temporary lists, `list_feat_narr_sptmpl` for per-variable NARR results and `list_feat_merge_sptmpl` for the three tables prepared for merging. These lists are not saved as pipeline outputs. The spatial and spatiotemporal feature outputs demonstrate the complete four-part convention.

The grid scripts use corresponding temporary lists, `list_pred_narr_sptmpl` and `list_pred_merge_sptmpl`, before writing their merged tables. Grid construction also uses `sf_nc`, `sf_geometry`, and `chr_r8ids` as local objects. The grid rule saves both the identifier-column name in `chr_pred_h3r8.qs` and the geometry with cell IDs in `sf_pred_grid_r8.qs`.

## Configuration

Edit `config/config.yaml` before running:

| Setting | Current value | Use |
| --- | --- | --- |
| `chr_config_daterange.start` | `"2021-01-01"` | First date in the inclusive date sequence. |
| `chr_config_daterange.end` | `"2022-12-31"` | Last date in the inclusive date sequence. |
| `int_config_radii` | `1000`, `5000`, `10000` | Buffer radii in meters; unused by the current rules. NARR/HMS calculations explicitly use `radius = 0`. |
| `chr_config_dir` | `"beethoven/beethoven-sm/input/"` | Data directory, resolved relative to `$HOME` by the download and calculation rules. An absolute path can also be supplied. |
| `int_grid_res` | `6` | H3 resolution used for development, with resolution `8` planned; the existing `h3r8` names are retained. The boundary is defined in `f01_grid.R` using the `sf` package's North Carolina county example. |

With the current configuration, downloads go to `$HOME/beethoven/beethoven-sm/input/{aqs,narr,hms}/`. If the checkout is elsewhere, update `chr_config_dir` to the intended data location. Serialized outputs remain under `output/` relative to the workflow working directory. AQS and NARR downloads receive `int_init_years`; HMS downloading and NARR/HMS processing for both AQS sites and grid cells use the endpoints of `chr_init_dates`, as does AQS processing. The initialization rule passes `chr_config_daterange.start` and `.end` to its script as the parameters `start` and `end`. The two merge rules declare `chr_config_dir` as a parameter, but their scripts read only serialized inputs.

`chr_iter_narr` is defined in `b02_narr.R` and currently selects 24 variables, including `air.sfc`, `weasd`, `omega`, and `shum`. Both AQS-site and grid NARR scripts retain `level == 1000` and drop the `level` column when a pressure-level result includes it.

Daemon counts are currently set directly in the R scripts, not in `config.yaml`. The local `download_narr_map()` accepts one year or two year endpoints; because `b02_narr.R` passes all of `int_init_years`, a configured period spanning more than two distinct years currently fails that helper's length check.

## Pipeline

| Tier | Script Prefix | Rule | Script | Behavior and outputs |
| --- | --- | --- | --- | --- |
| initiate | `a` | `initiate` | `a01_initiate.R` | Uses `chr_config_daterange` to generate `chr_init_dates.qs` for the configured date sequence and `int_init_years.qs` for the included years. Also writes `list_init_dates.qs` for chunks of up to 100 dates within each year, and `list_init_datesj.qs` for the same chunks in `YYYYJJJ` format. |
| download | `b` | `download_aqs` | `b01_aqs.R` | Downloads AQS CSV data for the included years into the `aqs/` download subdirectory and saves the returned list as `list_dl_aqs.qs`. Retains downloaded ZIP files. |
| download | `b` | `download_narr` | `b02_narr.R` | Calls local `download_narr_map()` with 50 mirai daemons to download NetCDF files for the included years and 24 selected NARR variables into `narr/`. Saves the variable names as `chr_iter_narr.qs` and the download summary as `list_dl_narr.qs`. |
| download | `b` | `download_hms` | `b03_hms.R` | Uses `fl_dates()` to pass the configured date endpoints to local `download_hms_map()` with 100 mirai daemons. Downloads and unzips shapefiles under `hms/`, retains the ZIP files, and saves the download summary as `list_dl_hms.qs`. |
| calculate | `c` | `calculate_aqs` | `c01_aqs.R` | Reads `chr_init_dates.qs` and all three download lists. Uses `amadeus::process_aqs()` in `location` mode to save spatial locations as `sf_feat_aqs_sp.qs`, and in `available-data` mode to save PM2.5 observations by location and time as `dt_feat_aqs_sptmpl.qs`. |
| calculate | `c` | `calculate_narr` | `c02_narr.R` | Reads `chr_init_dates.qs`, `chr_iter_narr.qs`, and `sf_feat_aqs_sp.qs`. Processes variables in sequence and distributes their raster layers across 100 daemons with `calculate_narr_mirai()`. Uses `radius = 0`, `fun = "mean"`, and `geom = FALSE`, retains pressure level 1000 when present, and merges results into `dt_feat_narr_sptmpl.qs`. |
| calculate | `c` | `calculate_hms` | `c03_hms.R` | Reads `chr_init_dates.qs` and `sf_feat_aqs_sp.qs`. Processes HMS files and calls local `calculate_hms_map()` to distribute date-specific smoke polygons across 100 daemons. Uses `radius = 0`, default `frac = FALSE`, and `geom = FALSE` to produce smoke-presence indicators in `dt_feat_hms_sptmpl.qs`. |
| calculate | `c` | `calculate_merge` | `c99_merge.R` | Reads the AQS, NARR, and HMS spatiotemporal feature tables, converts their `time` columns to character strings, and joins them on `site_id` and `time` with `reduce_merge()`. Saves `dt_feat_merge_sptmpl.qs`. |
| predict | `f` | `prediction_h3r8` | `f01_grid.R` | Reads `dt_feat_merge_sptmpl.qs`, then validates, transforms, and unions the bundled North Carolina county geometry. Uses `h3jsr` and `int_grid_res` to generate unique H3 cells. Saves their polygons and IDs as `sf_pred_grid_r8.qs`, and the column name `"h3r8_id"` as `chr_pred_h3r8.qs`. |
| predict | `f` | `prediction_narr` | `f02_narr.R` | Reads `chr_init_dates.qs`, `chr_iter_narr.qs`, `chr_pred_h3r8.qs`, and `sf_pred_grid_r8.qs`. Uses 100 daemons to extract NARR covariates with `locs_id = chr_pred_h3r8`, `radius = 0`, and `fun = "mean"`. Retains pressure level 1000 when present and merges variables by `c(chr_pred_h3r8, "time")` into `dt_pred_narr_sptmpl.qs`. |
| predict | `f` | `prediction_hms` | `f03_hms.R` | Reads `chr_init_dates.qs`, `chr_pred_h3r8.qs`, and `sf_pred_grid_r8.qs`. Uses 100 daemons to calculate smoke-presence indicators for the H3 polygons with `locs_id = chr_pred_h3r8`, `radius = 0`, and default `frac = FALSE`. Saves `dt_pred_hms_sptmpl.qs`. |
| predict | `f` | `prediction_merge` | `f99_merge.R` | Reads `chr_pred_h3r8.qs` and the two grid covariate tables, converts `time` to character strings, and joins by `c(chr_pred_h3r8, "time")`. Saves `dt_pred_merge_sptmpl.qs`. |
| — | — | `all` | None | Requests `output/dt_pred_merge_sptmpl.qs` as the default target. |

The tier identifies the rule's processing stage; Script Prefix gives the corresponding letter used in rule and script filenames: `a` = initiate, `b` = download, `c` = calculate, `d` = cross-validation, `e` = model, and `f` = predict. `d00_cross.R`, `e01_base.R`, and `e02_meta.R` are placeholders for spatiotemporal cross-validation, base learners, and meta learners, with no active rules yet. The `f` rules currently prepare prediction-grid covariates. `all` selects the workflow endpoint and has no processing tier or letter code.

The three download rules can run independently after `initiate`, subject to Snakemake's scheduling limit. Each dataset is handled by one rule invocation for the whole configured period; there are no per-date, per-year, or per-variable wildcard jobs. Within NARR/HMS rules, mirai distributes downloads or extraction tasks as described below. `list_init_dates.qs` and `list_init_datesj.qs` have no downstream consumers yet; `chr_iter_narr.qs` is consumed by both `calculate_narr` and `prediction_narr`.

`calculate_aqs` depends on all three download lists and combines them locally as `list_dl_collect`, while its feature processing reads the AQS files under `aqs/data_files/`. Once it produces `sf_feat_aqs_sp.qs`, `calculate_narr` and `calculate_hms` can run independently. They read raw data from `narr/<variable>/` and `hms/data_files/`, respectively. Their downloads are prerequisites through `calculate_aqs`; NARR also directly depends on `chr_iter_narr.qs` from `download_narr`.

`prediction_h3r8` waits for the merged AQS-site table, but the loaded table does not determine the grid geometry; the current boundary comes from `sf`'s `shape/nc.shp`. After it writes `chr_pred_h3r8.qs` and `sf_pred_grid_r8.qs`, `prediction_narr` and `prediction_hms` can run independently using the existing downloads. Their covariate tables and the shared identifier-column name feed `prediction_merge`.

The grid scripts use `chr_pred_h3r8` consistently: NARR and HMS pass it as `locs_id`, and both NARR variable merging and the final grid merge pass `by = c(chr_pred_h3r8, "time")` to `reduce_merge()`. AQS-site merges continue to use `site_id` and `time`.

The AQS, NARR, and HMS spatiotemporal outputs are explicitly saved as `data.table` objects. The AQS-site and prediction-grid merge scripts convert each input's `time` column with `as.character()` before joining on their location identifier and `time`. `reduce_merge()` preserves left-side rows by default and switches to full joins for the reduction if any consecutive input table has more rows than its predecessor. Missing matches remain missing; the merge does not generate a complete location-by-time grid or impute missing values.

Snakemake tracks the declared `.qs` outputs. Individual raw downloads are not declared rule outputs, so removing a raw file alone does not make its download rule out of date. All three download scripts pass `acknowledgement = TRUE` and `hash = FALSE`; AQS uses `amadeus::download_data()`, while NARR and HMS use the local map functions.

## Parallel execution with mirai

The NARR/HMS scripts source `R/amadeus.R`, start their local worker pools with `mirai::daemons(n)`, and collect results before saving the rule outputs. Each script calls `mirai::daemons(0)` after its download or calculation returns successfully. The helpers detect active daemons and have sequential fallback paths, but the current scripts always start the pools listed here.

| Rule | Local entry point | Unit dispatched to mirai | Daemons |
| --- | --- | --- | --- |
| `download_narr` | `download_narr_map()` | One URL/destination pair for a required NetCDF file. | 50 |
| `download_hms` | `download_hms_map()` | One URL/destination pair for a required daily smoke file. | 100 |
| `calculate_narr` | `calculate_narr_mirai()` | One raster layer within the current NARR variable. | 100 |
| `calculate_hms` | `calculate_hms_map()` | One date's smoke polygons, evaluated at all supplied locations. | 100 |
| `prediction_narr` | `calculate_narr_mirai()` | One raster layer within the current NARR variable, evaluated over the H3 polygons. | 100 |
| `prediction_hms` | `calculate_hms_map()` | One date's smoke polygons, evaluated against the H3 polygons. | 100 |

Mapped jobs are collected with `mirai::collect_mirai(..., options = ".stop")`, so worker errors stop collection. AQS download/processing, initialization, grid generation, and both merge scripts do not start mirai pools.

The daemon counts are independent of `--cores`, `SLURM_CPUS_PER_TASK`, and `snakemake@threads`. The rules currently declare no `threads:` or worker resources, so Snakemake does not account for these pools when scheduling jobs. Either the AQS-site or grid NARR/HMS pair can start 200 daemons in total, exceeding the 105 CPUs requested by `run.sh`; even `--cores 1` still permits a running script to start its fixed pool. Set the daemon counts in the six R scripts to fit the available allocation and any concurrently running rules.

## Containers

Run the workflow from the `beethoven-sm` directory with Snakemake and Apptainer available on the host. Every active R rule uses `container/sif/container_covariates.sif`.

The covariates build definition uses `rocker/geospatial:latest`, installs `pak`, `qs2`, `mirai`, `mori`, and `h3jsr`, and installs `amadeus` from `NIEHS/amadeus` without a branch or commit pin. It disables user R profiles and environment files inside the container. `R/amadeus.R` is sourced from the checkout by the workflow scripts. Rebuild an older image if it lacks the required packages, including `h3jsr` for grid generation. The models definition and build script provide a separate GPU modelling environment, but no current rule uses that image.

If the covariates image needs to be built, run the following from `beethoven-sm`. The build script uses paths relative to `container/sh` and requires Apptainer fakeroot support and network access:

```bash
mkdir -p container/sif
(cd container/sh && bash build_container_covariates.sh)
```

## Run

Run the `beethoven` pipeline from R or from the command line.

```R
source("R/helpers.R")
batch()
```

or

```bash
mkdir -p slurm
sbatch run.sh
```

`run.sh` requests the `geo` partition, one task, 105 CPUs, and 10 GB of memory. It writes `slurm/cov_<jobid>.out` and `.err` and includes email notifications for completion or failure. Review the allocation and notification directives for the intended environment. Snakemake and the local mirai pools run within this single allocation; no Snakemake cluster executor or remote mirai deployment is configured.

The Snakemake core limit is selected from the first script argument, then `SLURM_CPUS_PER_TASK`, then a fallback of `1`. `run.sh` also exports `CURL_CA_BUNDLE` and `SSL_CERT_FILE` as `/etc/ssl/certs/ca-certificates.crt` for download certificate verification.
