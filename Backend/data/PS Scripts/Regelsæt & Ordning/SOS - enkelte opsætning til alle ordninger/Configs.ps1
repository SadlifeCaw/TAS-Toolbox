#Author : Nevethan Alagaratnam

###############################################
#########      CONFIGS         ################
###############################################

#ConnectionString information
# You can get 'server' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)
$server = "BSMSOSSQL01T.prod.sitad.dk\TASTest" # Data server 
$db = "TASTestDB" # Database name'

#ConnectionString

#With user ID and password
#$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=false;User Id = adm1; Password=mgetmk"

#Windows authentication
$connectionstring = "Data server=$server;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 999999999 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 
######################################################################################################

$ordning_forsystem_ids = @(1519882
,1519881
,1519880
,1519879
,1519878
,1519877
,1519876
,1519875
,1522931
,1522930
,1522929
,1522928
,1522923
,1522922
,1522921) -join ',' #specific ordning_forsystem ids will want to retrieve/transfer

#$list_regelsaet = @("'Ansøgningsrunder - ANS9'","'Ansøgningsrunder og Løse ansøgninger T5'","'Ansøgningsrunder - Tom kontering - ANS9T'","'Ansøgningsrunde ANS9 B Forudbetaling'") -join ','

$RegelsætName = '' # The name of the regelsæt you want to transfer

$ordning = '' #Ordningen du vil arbejde med.

######################################################################################################


