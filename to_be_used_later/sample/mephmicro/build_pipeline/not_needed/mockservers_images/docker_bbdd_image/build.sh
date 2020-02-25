
 #!/usr/bin/env bash
cat base_init.sql > data/init.sql
cat ../../../mngpatilleditor-model/db_model/oracle/*.sql >> data/init.sql
docker build --tag  mngpatilleditor_bbddtest .
rm data/init.sql
