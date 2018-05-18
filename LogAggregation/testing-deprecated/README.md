Testing ELK Stack configured for log4j Input and ES Output plugins
==================================================================

* Copy TstLg4jELK.class, log4j-1.2.17.jar, log4j.properties and test_log4j_elk.sh to the server where logstash is
running or from where that could be reached on the port configured in the log4j.properties ,
* put proper host in the log4j.properties ,
* run *bash test_log4j_elk.sh* on the server where all the files were copied ,
* access kibana in a web browser (chrome of firefox) through <kibana server e.g tst-01-elk0[12].test.reltio.com>:5601
and you should see messages like ELK 1 2 3 ..., ELK 4 5 6 ... on Discover -> select logstash-* ,
* you could also see the logstash indices created at ES level through *curl <ES client host>:9200/_cat/indices?v* .
