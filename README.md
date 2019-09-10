## Seattle Pet Licenses Data Ingest and Analysis Demo

There are three components to this exercise:

1. Initial data ingest was performed in Python using the provided SODA API to pull Seattle's pet license data into a Microsoft SQL Server relational database
     * seattle_pet_licenses_data_load.py
2. Data analysis was performed in SQL to answer questions about dog breeds by zip code and the number of licenses per year per species.  Data was also prepared in SQL for visualization output to Excel.
     * golden_retriever_count.sql
3. Data visualization was done in Excel.
     * licenses_by_species_visualization.xlsx


### Results

To briefly answer the questions:

1. Zip code 98115 has the most Golden Retrievers.
2. See Excel for visualization.
3. See SQL file for an outline of next steps to continuously capture pet data.

I've embedded the details of my results as comments within the Python, SQL, and Excel files to better demonstrate the thought process and development steps that occur as I work with the data.



------------------------------------------------------
Copyright 2019 Derek Daniel. All rights reserved.
