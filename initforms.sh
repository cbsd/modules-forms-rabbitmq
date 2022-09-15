#!/bin/sh
pgm="${0##*/}"          # Program basename
progdir="${0%/*}"       # Program directory
: ${REALPATH_CMD=$( which realpath )}
: ${SQLITE3_CMD=$( which sqlite3 )}
: ${RM_CMD=$( which rm )}
: ${MKDIR_CMD=$( which mkdir )}
: ${FORM_PATH="/opt/forms"}
: ${distdir="/usr/local/cbsd"}

MY_PATH="$( ${REALPATH_CMD} ${progdir} )"
HELPER="rabbitmq"

# MAIN
if [ -z "${workdir}" ]; then
	[ -z "${cbsd_workdir}" ] && . /etc/rc.conf
	[ -z "${cbsd_workdir}" ] && exit 0
	workdir="${cbsd_workdir}"
fi

set -e
. ${distdir}/cbsd.conf
. ${subrdir}/tools.subr
. ${subr}
set +e

FORM_PATH="${workdir}/formfile"

[ ! -d "${FORM_PATH}" ] && err 1 "No such ${FORM_PATH}"
[ -f "${FORM_PATH}/${HELPER}.sqlite" ] && ${RM_CMD} -f "${FORM_PATH}/${HELPER}.sqlite"

/usr/local/bin/cbsd ${miscdir}/updatesql ${FORM_PATH}/${HELPER}.sqlite ${distsharedir}/forms.schema forms
/usr/local/bin/cbsd ${miscdir}/updatesql ${FORM_PATH}/${HELPER}.sqlite ${distsharedir}/forms.schema additional_cfg
/usr/local/bin/cbsd ${miscdir}/updatesql ${FORM_PATH}/${HELPER}.sqlite ${distsharedir}/forms_system.schema system

${SQLITE3_CMD} ${FORM_PATH}/${HELPER}.sqlite <<EOF
BEGIN TRANSACTION;
INSERT INTO forms VALUES(1,'forms',1,1,'-Globals','Globals','Globals','PP','',1,'maxlen=60',NULL,'delimer','','');
INSERT INTO forms VALUES(2,'forms',1,3,'cluster_name','cluster_name','myclu1','myclu1','',1,'maxlen=5',NULL,'inputbox','','');
INSERT INTO forms VALUES(3,'forms',1,4,'port','port','5672','5672','',1,'maxlen=5',NULL,'inputbox','','');
INSERT INTO forms VALUES(4,'forms',1,4,'management_port','management_port','15672','15672','',1,'maxlen=5',NULL,'inputbox','','');
INSERT INTO forms VALUES(5,'forms',1,5,'delete_guest_user','delete_guest_user','true','true','',1,'maxlen=5',NULL,'inputbox','','');
INSERT INTO forms VALUES(6,'forms',1,7,'cluster_node_type','cluster_node_type','2','ram','',1,'maxlen=5',NULL,'inputbox','','');
INSERT INTO forms VALUES(7,'forms',1,8,'admin_enable','admin_enable','2','true','',1,'maxlen=5',NULL,'inputbox','','');
INSERT INTO forms VALUES(8,'forms',1,9,'tcp_recbuf','tcp_recbuf','2','196608','',1,'maxlen=5',NULL,'inputbox','','');
INSERT INTO forms VALUES(9,'forms',1,10,'tcp_sndbuf','tcp_sndbuf','2','196608','',1,'maxlen=5',NULL,'inputbox','','');
INSERT INTO forms VALUES(10,'forms',1,200,'-Vhosts','Vhosts','Vhosts','-','',1,'maxlen=60',NULL,'delimer','','vhostgroup');
INSERT INTO forms VALUES(11,'forms',1,201,'vhost','add vhosts','201','201','',0,'maxlen=60',NULL,'group_add','','vhostgroup');
INSERT INTO forms VALUES(12,'forms',1,300,'-Users','Users','Users','-','',1,'maxlen=60',NULL,'delimer','','usersgroup');
INSERT INTO forms VALUES(13,'forms',1,301,'user','add users','301','301','',0,'maxlen=60',NULL,'group_add','','usersgroup');
INSERT INTO forms VALUES(14,'forms',1,400,'-Permissions','Permissions','Permissions','-','',1,'maxlen=60',NULL,'delimer','','permissionsgroup');
INSERT INTO forms VALUES(15,'forms',1,401,'permission','add permissions','401','401','',0,'maxlen=60',NULL,'group_add','','permissionsgroup');
INSERT INTO forms VALUES(16,'forms',1,500,'-Plugins','Permissions','Plugins','-','',1,'maxlen=60',NULL,'delimer','','pluginsgroup');
INSERT INTO forms VALUES(17,'forms',1,501,'plugin','add plugins','501','501','',0,'maxlen=60',NULL,'group_add','','pluginsgroup');
INSERT INTO forms VALUES(18,'forms',2,301,'user_name2','user part 2','','admin','',1,'maxlen=60','dynamic','inputbox','','usersgroup');
INSERT INTO forms VALUES(19,'forms',2,301,'user_password2','password part 2','simplepassword','admin','',1,'maxlen=60','dynamic','inputbox','','usersgroup');
INSERT INTO forms VALUES(20,'forms',2,301,'user_admin2','admin part 2','false','true','',1,'maxlen=60','dynamic','inputbox','','usersgroup');
COMMIT;
EOF

${SQLITE3_CMD} ${FORM_PATH}/${HELPER}.sqlite << EOF
BEGIN TRANSACTION;
INSERT INTO system ( helpername, version, packages, have_restart ) VALUES ( "rabbitmq", "201607", "net/rabbitmq", "rabbitmq" );
COMMIT;
EOF

# CREATE VIEW
${SQLITE3_CMD} ${FORM_PATH}/${HELPER}.sqlite << EOF
BEGIN TRANSACTION;
CREATE VIEW FORM_VIEW AS SELECT * FROM forms UNION SELECT * FROM additional_cfg;
COMMIT;
EOF

# long description
${SQLITE3_CMD} ${FORM_PATH}/${HELPER}.sqlite << EOF
BEGIN TRANSACTION;
UPDATE system SET longdesc='\\
Erlang implementation of AMQP \\
';
COMMIT;
EOF
