GRANT SELECT ON upload,navigation,navigation_request,update_request,location,match,notmatch,tag,report,report2,report3 TO PUBLIC;
GRANT SELECT ON report,report2,report3 TO "reportlatency";
GRANT SELECT,INSERT ON upload,navigation,navigation_request,update_request TO "reportlatency";
GRANT SELECT,INSERT,UPDATE,DELETE ON location,match,notmatch,tag TO "reportlatency";
