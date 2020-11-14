# my_module_dir variable define in puppet script

# Linux required -i'', not "-i ''" for inplace
os=$( uname -s )
case "${os}" in
	Linux)
		# Linux require -i'', not -i ' '
		sed_delimer=
		;;
	FreeBSD)
		sed_delimer=" "
	;;
esac

generate_manifest()
{

cat <<EOF
  class { 'profiles::mq::rabbitmq': }
  package { 'curl':
    ensure => present,
  }
EOF

}

generate_hieradata()
{
	local my_common_yaml="${my_module_dir}/common.yaml"
	local vhost_part_header="${my_module_dir}/vhost_part_header.yaml"
	local vhost_part_body="${my_module_dir}/vhost_part_body.yaml"
	local vhost_policy_part_header="${my_module_dir}/vhost_policy_part_header.yaml"
	local vhost_policy_part_body="${my_module_dir}/vhost_policy_part_body.yaml"
	local user_part_header="${my_module_dir}/user_part_header.yaml"
	local user_part_body="${my_module_dir}/user_part_body.yaml"
	local permission_user_vhost_part_header="${my_module_dir}/permision_user_vhost_part_header.yaml"
	local permission_user_vhost_part_body="${my_module_dir}/permission_user_vhost_part_body.yaml"
	local plugin_part_header="${my_module_dir}/plugin_part_header.yaml"
	local plugin_part_body="${my_module_dir}/plugin_part_body.yaml"
	local _val _tpl

	if [ ! -r ${vhost_part_header} ]; then
		echo "no such ${vhost_part_header}" 1>&2
		exit 1
	fi
	if [ ! -r ${vhost_part_body} ]; then
		echo "no such ${vhost_part_body}" 1>&2
		exit 1
	fi
	if [ ! -r ${vhost_policy_part_header} ]; then
		echo "no such ${vhost_policy_part_header}" 1>&2
		exit 1
	fi
	if [ ! -r ${vhost_policy_part_body} ]; then
		echo "no such ${vhost_policy_part_body}" 1>&2
		exit 1
	fi
	if [ ! -r ${user_part_header} ]; then
		echo "no such ${user_part_header}" 1>&2
		exit 1
	fi
	if [ ! -r ${user_part_body} ]; then
		echo "no such ${user_part_body}" 1>&2
		exit 1
	fi
	if [ ! -r ${permission_user_vhost_part_header} ]; then
		echo "no such ${permission_user_vhost_part_header}" 1>&2
		exit 1
	fi
	if [ ! -r ${permission_user_vhost_part_body} ]; then
		echo "no such ${permission_user_vhost_part_body}" 1>&2
		exit 1
	fi
	if [ ! -r ${plugin_part_header} ]; then
		echo "no such ${plugin_part_header}" 1>&2
		exit 1
	fi
	if [ ! -r ${plugin_part_body} ]; then
		echo "no such ${plugin_part_body}" 1>&2
		exit 1
	fi

	local form_add_vhost_name=0
	local form_add_user_name=0
	local form_add_permission_user_vhost=0
	local form_add_plugin_name=0

	if [ -f "${my_common_yaml}" ]; then
		local tmp_common_yaml=$( mktemp )
		/bin/cp ${my_common_yaml} ${tmp_common_yaml}
		for i in ${param}; do
			case "${i}" in
				vhost_name[1-9]*)
					form_add_vhost_name=$(( form_add_vhost_name + 1 ))
					continue;
					;;
				user_name[1-9]*)
					form_add_user_name=$(( form_add_user_name + 1 ))
					continue;
					;;
				permission_user_vhost[1-9]*)
					form_add_permission_user_vhost=$(( form_add_permission_user_vhost + 1 ))
					continue;
					;;
				plugin_name[1-9]*)
					form_add_plugin_name=$(( form_add_plugin_name + 1 ))
					continue;
					;;
				-*)
					# delimier params
					continue
					;;
				Expand)
					# delimier params
					continue
					;;
			esac

			eval _val=\${${i}}
			_tpl="#${i}#"
			sed -i${sed_delimer}'' -Ees:"${_tpl}":"${_val}":g ${tmp_common_yaml}
		done
	else
		for i in ${param}; do
			eval _val=\${${i}}
		cat <<EOF
 $i: "${_val}"
EOF
		done
	fi

	# custom vhost
	if [ ${form_add_vhost_name} -ne 0 ]; then
		cat ${vhost_part_header} >> ${tmp_common_yaml}

		# populate vhost_policy part in parallel for each vhost
		tmpfile=$( mktemp )
		cp -a ${vhost_policy_part_header} ${tmpfile}

		for i in ${param}; do
			case "${i}" in
				vhost_name[1-9]*)
					;;
				*)
					continue
					;;
			esac

			eval _val=\${${i}}
			[ -z "${_val}" ] && continue

			_tpl="#vhost_name#"
			sed -Ees/"${_tpl}"/"${_val}"/g ${vhost_part_body} >> ${tmp_common_yaml}
			sed -Ees/"${_tpl}"/"${_val}"/g ${vhost_policy_part_body} >> ${tmpfile}
		done

		cat ${tmpfile} >> ${tmp_common_yaml}
		rm -f ${tmpfile}
	fi

	# custom user rules
	if [ ${form_add_user_name} -ne 0 ]; then
		cat ${user_part_header} >> ${tmp_common_yaml}
		tmpfile=$( mktemp )
		cp -a ${user_part_body} ${tmpfile}
		for i in ${param}; do
			case "${i}" in
				user_name[1-9]*)
					_tpl="#user_name#"
					;;
				user_password[1-9]*)
					_tpl="#user_password#"
					;;
				user_admin[1-9]*)
					_tpl="#user_admin#"
					;;
				*)
					continue
					;;
			esac

			eval _val=\${${i}}
			[ -z "${_val}" ] && continue

			rule_name="XXX"		# concat from all field
			sed -i${sed_delimer}'' -Ees/"${_tpl}"/"${_val}"/g ${tmpfile}
		done
		cat ${tmpfile} >> ${tmp_common_yaml}
		cp -a ${tmpfile} /tmp/x.yaml
		rm -f ${tmpfile}
	fi

	# custom permission rules
	if [ ${form_add_permission_user_vhost} -ne 0 ]; then
		cat ${permission_user_vhost_part_header} >> ${tmp_common_yaml}
		tmpfile=$( mktemp )
		cp -a ${permission_user_vhost_part_body} ${tmpfile}
		for i in ${param}; do
			case "${i}" in
				permission_user_vhost[1-9]*)
					_tpl="#permission_user_vhost#"
					;;
				permission_configure_permission[1-9]*)
					_tpl="#permission_configure_permission#"
					;;
				permission_read_permission[1-9]*)
					_tpl="#permission_read_permission#"
					;;
				permission_write_permission[1-9]*)
					_tpl="#permission_write_permission#"
					;;
				*)
					continue
					;;
			esac

			eval _val=\${${i}}
			[ -z "${_val}" ] && continue

			rule_name="XXX"		# concat from all field
			sed -i${sed_delimer}'' -Ees/"${_tpl}"/"${_val}"/g ${tmpfile}
		done
		cat ${tmpfile} >> ${tmp_common_yaml}
		cp -a ${tmpfile} /tmp/x.yaml
		rm -f ${tmpfile}
	fi

	# custom plugin rules
	if [ ${form_add_plugin_name} -ne 0 ]; then
		cat ${plugin_part_header} >> ${tmp_common_yaml}
		tmpfile=$( mktemp )
		cp -a ${plugin_part_body} ${tmpfile}
		for i in ${param}; do
			case "${i}" in
				plugin_name[1-9]*)
					_tpl="#plugin_name#"
					;;
				*)
					continue
					;;
			esac

			eval _val=\${${i}}
			[ -z "${_val}" ] && continue

			rule_name="XXX"		# concat from all field
			sed -i${sed_delimer}'' -Ees/"${_tpl}"/"${_val}"/g ${tmpfile}
		done
		cat ${tmpfile} >> ${tmp_common_yaml}
		cp -a ${tmpfile} /tmp/x.yaml
		rm -f ${tmpfile}
	fi

	cat ${tmp_common_yaml}
}
