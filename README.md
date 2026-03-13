# World Education Dashboard

## Motivation

Education systems vary dramatically across the world, and understanding which factors contribute to better educational outcomes is crucial for policymakers, researchers, and educators. This dashboard addresses the challenge of making sense of complex global education data by providing an interactive visualization tool that enables users to:

- Explore education indicators across 202 countries
- Compare regional performance and identify disparities
- Analyze gender gaps in education access and completion
- Make data-driven decisions to improve education systems globally

The dashboard leverages data from UNESCO Institute for Statistics, UNICEF, and UN Statistics Division to provide comprehensive insights into global education patterns.

## Features

The dashboard is organized into two main tabs:

**Main Dashboard** (with sub-tabs):

- **Overview**: Interactive world map (choropleth) for any selected education metric; KPI cards that update to match the chosen map metric (average, vs world, coverage)
- **Completion & Literacy**: Education level by region bar chart; completion rate gap by region; male vs female literacy scatter by region
- **Data Table**: Country-level data with configurable columns, filtered by selected regions

Additional capabilities:

- **Regional Filtering**: Focus on specific continents; filters apply to map, KPIs, charts, and table
- **Map Metric Selection**: Choose from grouped metrics (Access, Completion, Learning, Context) for the choropleth
- **KPI Cards**: Reflect the currently selected map metric for quick context

## Live Dashboard

Access the deployed dashboard here:

- [World Education Dashboard](https://sapolraadnui-worldeducation-r.share.connect.posit.cloud)

## For Contributors

### Installation

```bash
# Clone the repository
git clone https://github.com/sapolraadnui/WorldEducation_R.git
cd WorldEducation_R

# Create the environment
conda env create -f environment.yml

# Activate the environment
conda activate worldeducation-r
```

### Running the App Locally

```bash
# Make sure you're in the project root directory
# Start R
R
# Then, run 
shiny::runApp()
```

The dashboard will be available at `http://127.0.0.1:4885/` (or the port shown in your terminal).


### Project Structure

```
.
├── LICENSE
├── README.md
├── app.R
├── data
│   ├── processed
│   │   └── processed_global_education.csv
│   └── raw
│       └── Global_Education.csv
├── environment.yml
├── manifest.json
└── requirement.txt

```
## Data Source

The dataset is sourced from [Kaggle - World Educational Data](https://www.kaggle.com/datasets/nelgiriyewithana/world-educational-data/data), compiled from UNESCO Institute for Statistics, UNICEF, and UN Statistics Division.

## License

See [LICENSE](LICENSE) for details.