\copy upload (id,collected_on,timestamp,location,user_agent,tz,version,options) TO 'upload.csv' DELIMITER ',';
\copy navigation (upload,name,service,count,total,high,low,tabclosed,response200,response300,response400,response500) TO 'navigation.csv' DELIMITER ',' NULL AS '';
\copy navigation_request (upload,name,service,count,total,high,low,tabclosed,response200,response300,response400,response500) TO 'navigation_request.csv' DELIMITER ',' NULL AS '';
\copy update_request (upload,name,service,count,total,high,low,tabclosed,response200,response300,response400,response500) TO 'update_request.csv' DELIMITER ',' NULL AS '';
