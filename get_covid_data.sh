#!/bin/bash
#
# Bash script to generate html table showing
# country COVID infection rates
# based upon mortality rate and death count 
# downloaded from opendata.ecdc.europa.eu
# (check ./tmp/today.$DATE_YMD to see any curl errors)
#
# author:  aholiday@xilodyne.com
# date:  2020-07-22
#

#0.2% = 0.002
#deaths / mortality rate = infections
MORTALITY_RATE=0.002

DUMP=./dump
TMP=./tmp
TABLE=./tables

#DATE_YMD=`date -d "1 days ago" +%F`
#DATE_DMY=`date -d "1 days ago" +"%d/%m/%Y"`
DATE_DMY_20200701="01/07/2020"
DATE_YMD_20200701="2020-07-01"
DATE_YMD=`date +%F`
DATE_DMY=`date +"%d/%m/%Y"`
TIMESTAMP="$DATE_YMD `date +%T`"


COVID_FILE=covid_dump-$DATE_YMD
COVID_FILE_NOTCLEANED=covid_dump_dirty-$DATE_YMD
COUNTRY_LIST=$TMP/countries.$DATE_YMD_20200701.$DATE_YMD
SUMMED_DATA=$TMP/today_summed.$DATE_YMD
FILETABLE=table.$DATE_YMD
TABLE_NAME=$TABLE/$FILETABLE
ZERO=0

#https://www.ecdc.europa.eu/en/publications-data/download-todays-data-geographic-distribution-covid-19-cases-worldwide
#https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-2020-07-19.csv
#https://opendata.ecdc.europa.eu/covid19/casedistribution/csv/

#SITE=https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-
SITE=https://opendata.ecdc.europa.eu/covid19/casedistribution/csv/

#URL=$SITE$DATE_YMD.csv
#URL=$SITE-2020-07-19.csv
URL=$SITE

echo
echo "**********************************************************"
echo
echo "Running data for $TIMESTAMP "
echo
echo "**********************************************************"
echo

echo "Date: yyyy-mm-dd: " $DATE_YMD
echo "Date: dd/mm/yyyy: " $DATE_DMY
echo "Dump Dirty File: $DUMP/$COVID_FILE_NOTCLEANED"
echo "Dump File: $DUMP/$COVID_FILE"
echo "URL: $URL"
echo "Country list: " $COUNTRY_LIST
echo "Table File: $TABLE_NAME"
echo
echo

###################################
# Get data from website
###################################
function get_data {
	echo "Getting data from website..."
	curl -o $DUMP/$COVID_FILE_NOTCLEANED $URL
}

###################################
# Extract unique country list
###################################
function extract_unique {
	echo "Extract $DATE_DMY data to $DUMP/$DATE_YMD"
	cat $DUMP/$COVID_FILE_NOTCLEANED | sed "s/Bonaire,/Bonair;/g" | sed "s/\"//g" | sed "s/ /_/g" > $DUMP/$COVID_FILE
	cat $DUMP/$COVID_FILE | grep $DATE_DMY_20200701 > $COUNTRY_LIST
	echo "Line count of "`wc -l $COUNTRY_LIST`
}

###################################
# Sum country totals
###################################
function sum_ctry_totals {
UNIQUE_DATA=`cat $COUNTRY_LIST`

rm $TMP/*

for LINE in $UNIQUE_DATA;
do
 DEATH_COUNT=0
 CTRY=`echo $LINE | awk -F, '{print $9}'`
 echo -ne "Searching for country: $CTRY , Deaths: "
 cat $DUMP/$COVID_FILE | grep $CTRY > $TMP/$DATE_YMD.$CTRY
 
 CRTY_COVID=`cat $TMP/$DATE_YMD.$CTRY`
 for CTRY_DEATHS in $CRTY_COVID
 do
  #echo -ne "Current total: $DEATH_COUNT," 
  COUNTRY=`echo $CTRY_DEATHS | awk -F, '{print $7}'`
  DTH=`echo $CTRY_DEATHS | awk -F, '{print $6}'`
  #ignore negative values
  DEATHS=$(awk -v d1=$DTH -v z1=$ZERO 'BEGIN{print (d1<z1)?0:d1}')
  DEATH_COUNT=`echo $DEATHS $DEATH_COUNT | awk '{print $1+$2}'`
  #echo "adding: $DEATHS, New Total: $DEATH_COUNT"
 done
 echo "$COUNTRY,$DEATH_COUNT,TBD" >> $SUMMED_DATA
 echo $DEATH_COUNT
done

}


###################################
# Create table
###################################
function table_head {
 echo "<table cellpadding='2' cellspacing='2' border='1' style='text-align: left; width: 400px;'> " > $TABLE_NAME
 echo "<caption>Time Stamp: $TIMESTAMP</caption>" >> $TABLE_NAME
 echo "<tr><th>Country</th><th>Deaths</th><th>Persons Infected (Estimated)</th></tr>" >> $TABLE_NAME
}

###################################
# Load Table Data
###################################
function table_data {
FILEDATA=`cat $SUMMED_DATA`

for LINE in $FILEDATA;
do
  	COUNTRY=`echo $LINE | awk -F, '{print $1}' | sed "s/_/ /g"`
	DEATHS=`echo $LINE | awk -F, '{print $2}'`
	INFECTIONS=`echo $DEATHS $MORTALITY_RATE | awk {'print $1/$2'}` 
	FORMAT_DEATH=`printf "%'d\n" $DEATHS`
	FORMAT_INFECT=`printf "%'d\n" $INFECTIONS`
#	echo $FORMAT_DEATH
	echo "<tr><td>$COUNTRY</td><td>$FORMAT_DEATH</td><td>$FORMAT_INFECT</td></tr>" >> $TABLE_NAME
done
}

###################################
# Table footer
###################################
function table_footer {
 echo "</table>" >> $TABLE_NAME

}


get_data
extract_unique
sum_ctry_totals
table_head
table_data
table_footer
