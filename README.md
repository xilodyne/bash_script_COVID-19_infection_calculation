# bash_script_COVID-19_infection_calculation

Bash script which does the following (based on current date):
 * downloads COVID-19 country mortality (death) data from opendata.ecdc.europa.eu
 * extracts country names
 * for each country name, calculates total deaths 
 * calculates infection rate of country based upon number of deaths (deaths / mortality rate = infections)
 * exports data to HTML table

## Setup:<br>
From your work directory, create directories:<br />
./dump<br />
./tables<br />
./tmp<br />

## Run:<br />
./get_covid_data.sh

<br />
<br />
Error messages are non-existent.  
To find problems with curl data download (particularly if the data for the current day has not been posted), check the HTML generated in ./tmp/today.DATE(yyyy-mm-dd)

Runs fine on ubuntu 18.04 LTS
