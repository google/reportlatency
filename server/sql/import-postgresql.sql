\copy upload (id,collected_on,timestamp,location,user_agent,tz,version,options) FROM 'upload.csv' DELIMITER ',';
\copy navigation (upload,name,service,count,total,high,low,tabclosed,response200,response300,response400,response500) FROM 'navigation.csv' DELIMITER ',' NULL AS '';
\copy navigation_request (upload,name,service,count,total,high,low,tabclosed,response200,response300,response400,response500) FROM 'navigation_request.csv' DELIMITER ',' NULL AS '';
\copy update_request (upload,name,service,count,total,high,low,tabclosed,response200,response300,response400,response500) FROM 'update_request.csv' DELIMITER ',' NULL AS '';
