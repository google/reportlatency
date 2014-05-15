.mode csv
.headers on
.output upload.csv
select id,collected_on,timestamp,location,user_agent,tz,version,options from upload;
.output navigation.csv
select upload,name,service,count,total,high,low,tabclosed,response200,response300,response400,response500 from navigation;
.output navigation_request.csv
select upload,name,service,count,total,high,low,tabclosed,response200,response300,response400,response500 from navigation_request;
.output update_request.csv
select upload,name,service,count,total,high,low,tabclosed,response200,response300,response400,response500 from update_request;
