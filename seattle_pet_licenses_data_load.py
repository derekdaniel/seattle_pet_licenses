
import datetime
import requests
import pyodbc


# Initialize------------------------------------------------------------------------------------------------------------

# Timer to see how long the code takes to run
startTime = datetime.datetime.now()

# Format a current timestamp for use in table names.  YYYYMMDD_HHmm   e.g. 20190907_1306
todaystamp = str(datetime.datetime.now()).split('.')[0].replace(':','').replace(' ','_').replace('-','')[:13]

# Database connection
server = 'tcp:localhost'
database = 'seattle_pet_licenses'
cnxn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=' + server + ';DATABASE=' + database + ';Trusted_Connection=yes', autocommit=True)  # Windows Auth




# Functions-------------------------------------------------------------------------------------------------------------

def write_csv_and_bulk_insert(data_to_write, rows_processed) -> int:
    """
    Write data to a csv file and then bulk insert that csv file into SQL.  Currently, this is hardcoded
    to only be used on the seattle pet licenses data set.  As it turns out, the results from the Seattle Pet Licenses
    data set is already in a nicely-formatted CSV string format, so we can simply dump the API results into a CSV file,
    no need to use a dataframe.

    :param data_to_write:  Currently expects a string, although we could later create a Pandas dataframe version.
    :param rows_processed:  The number of rows we're expecting.  We can use this to manage batch size later if we need to.
    :return:  0 = success.
    """
    print('Writing CSV file...')
    f = open('C:\\PycharmProjects\\seatle_pet_licenses\\raw_data\\pet_license_raw_data_' + str(rows_processed) + '.csv', 'w+')
    f.write(data_to_write)
    f.close()

    # TODO:  Pandas version, optionally, if we want to make a dataframe out of it instead.
    # data_to_write.to_csv('C:\\PycharmProjects\\seatle_pet_licenses\\raw_data\\pet_license_raw_data_' + str(rows_processed) + '.csv', index=False)

    print('CSV file done, inserting into SQL')
    cursor = cnxn.cursor()
    cursor.execute('''
        DROP TABLE IF EXISTS [dbo].[Ingest_pet_license_raw_data_''' + str(rows_processed) + '''_''' + todaystamp + ''']
        CREATE TABLE [dbo].[Ingest_pet_license_raw_data_''' + str(rows_processed) + '''_''' + todaystamp + '''](
            [license_issue_date] [smalldatetime] NOT NULL,
            [license_number] [varchar](max) NOT NULL,
            [animal_name] [varchar](max) NULL,
            [species] [varchar](max) NULL,
            [primary_breed] [varchar](max) NULL,
            [secondary_breed] [varchar](max) NULL,
            [zip_code] [varchar](max) NULL
        ) with (data_compression = page)
    '''
    )

    cursor = cnxn.cursor()
    cursor.execute('''
        BULK INSERT [dbo].[Ingest_pet_license_raw_data_''' + str(rows_processed) + '''_''' + todaystamp + ''']
        FROM \'C:\\PycharmProjects\\seatle_pet_licenses\\raw_data\\pet_license_raw_data_''' + str(rows_processed) + '''.csv\'
        WITH 
          (
             FORMAT = \'CSV\'
             ,FIRSTROW = 2            --First row is header
          )
    '''
    )

    return 0   # Placeholder for future more-robust error handling, etc.




# Data load-------------------------------------------------------------------------------------------------------------


# API documentation here:   https://dev.socrata.com/docs/paging.html
# I've made this extensible so we can later add the capability to retrieve results in batches, if necessary.
# For this data set of only 51.8k records, we can retrieve all at once by setting a high limit.
batch_size = str(999999)
offset = str(0)
# TODO:  Heads up, according to the API documentation, if we need to page through in batches,
#        we will need to order the results with something like this:  '&$order=license_issue_date'

response = requests.get('https://data.seattle.gov/resource/jguv-t9rb.csv?$limit=' + batch_size + '&$offset=' + offset)
if response.status_code == requests.codes.ok:
    # print(response.text)  # Debug
    write_csv_and_bulk_insert(response.text, batch_size)
else:
    print('Problem with API request.')
    print(response.text)


# ----------------------------------------------------------------------------------------------------------------------


# Display running time for the code  (Most of my code runs longer than this exercise, so I always like to include this.)
print('\n\nTotal running time:  ' + str(datetime.datetime.now() - startTime))


