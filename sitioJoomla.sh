#!/bin/bash
#Descripcion:  Utileria para manejar sitios Joomla desde el CLI.
#Author     :  fitorec
#                           _           _
# _ __ ___  _   _ _ __   __| | ___  ___(_) ___ __ _   ___ ___  _ __ ___
#| '_ ` _ \| | | | '_ \ / _` |/ _ \/ __| |/ __/ _` | / __/ _ \| '_ ` _ \
#| | | | | | |_| | | | | (_| | (_) \__ \ | (_| (_| || (_| (_) | | | | | |
#|_| |_| |_|\__,_|_| |_|\__,_|\___/|___/_|\___\__,_(_)___\___/|_| |_| |_|
##########################################################################################


##########################################################################################
# Manejo de colores, por favor consulte el siguiente link para mayor información:
# link: http://www.bashguru.com/2010/01/shell-colors-colorizing-shell-scripts.html
##########################################################################################
cyan='\e[0;36m'
darkCyan='\e[1;36;40m'
light='\e[1;36m'
red="\e[0;31m"
yellow="\e[0;33m"
darkYellow="\e[1;33;40m"
white="\e[0;37m"
darkGreen="\e[1;32;40m"
end='\e[0m'
 
if [ "$(git config --global alias.sitio-joomla)" = "" ]
then
	echo -en "${light}Congigurando el Alias${end} ";
	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	git config  --global alias.sitio-joomla  "!bash $DIR/sitioJoomla.sh"
	if [ $? -eq 0 ]
	then
		echo -e "<- ${white}Se creo satisfactoriamente${end}";
	else
		echo "<- ${red}No se pudo crear${end}";
	fi
	exit 0;
fi

export REPO_PATH=$(pwd);
export MYSQL_CLIENT=$(git config joomla.mysql-client);
if [ "${MYSQL_CLIENT}" == '' ]
then
	MYSQL_CLIENT=$(which mysql);
fi
echo -e "\t->${yellow}joomla.mysql-client: ${light}${MYSQL_CLIENT}${end}"

export	JOOMLA_DST=`git config joomla.dir-dst`;
if [ "${JOOMLA_DST}" = "" ]
then
	echo -e "${red}Error: Debe de configurar su directorio destino Donde se moveran los archivos"
	echo -e "${end}Por favor ejecute ${light}git sitio-joomla -ayuda${end} para obtener mas información"
	exit 0;
fi
##########################################################################################
# Descricipcion: Extrae la información de la base de datos del JOOMLA                    #
# Recibe como argumento el nombre del parametro al que le va extraer la información      #
##########################################################################################
function extractParamBD()
{
	cat "${REPO_PATH}/configuration.php" | grep -Eo "^\s+public\s*.$1\s+=\s+'.*'" \
	| sed -re "s/.*=\s*//g;s/'//g" | head -1;
}

function	installBD()
{
	echo -e "${light}Creando Jaula SQL${end}";
	#Extraemos la configuración del sistema del usuario/password
	user=`extractParamBD 'user'`
	password=`extractParamBD 'password'`
	database=`extractParamBD 'db'`
	#la información global del admin/password de mysql.
	mysql_admin=`git config joomla.mysql-admin`
	mysql_admin_pass=`git config joomla.mysql-password`
	#Extraemos la información global de nuestro
	######### Creando el usuario
	echo -ne "Usuario ${light}$user${end}";
	${MYSQL_CLIENT} --user=$mysql_admin --password="$mysql_admin_pass" -e \
	"CREATE USER '$user'@'localhost' IDENTIFIED BY '$password';"
	echo -e " [Creado]";
	#mostrando los usuarios
	#${MYSQL_CLIENT} --user=$mysql_admin --password=$mysql_admin_pass mysql "SELECT DISTINCT( user.User ) from user";
	######### Creando la BD
	echo -ne "Creando Bse de datos ${light}$database${end}";
	${MYSQL_CLIENT} --user=$mysql_admin --password="$mysql_admin_pass" -e \
	"CREATE DATABASE IF NOT EXISTS $database;"
	echo -e " [Bien]";
	
	######### Otorgando privilegios
	echo -ne "Otorgando privilegios de ${light}${database}${end} a ${light}${user}${end}";
	${MYSQL_CLIENT} --user=$mysql_admin --password="$mysql_admin_pass" -e "GRANT ALL PRIVILEGES ON $database.* TO '$user'@'localhost';"
	echo -e " [Bien]";
	######### Actualizando privilegios
	echo -ne "Actualizando permisos";
	${MYSQL_CLIENT} --user=$mysql_admin --password="$mysql_admin_pass" -e "FLUSH PRIVILEGES;"
	echo -e " [Bien]";
}
################################################################################
# Nos ayuda a configurar un host virtual apache
# Categoria: Tools
################################################################################
function	vhost()
{
	echo -e "${light}Bienvenido a la configuración apache${end}"
	echo -ne "${darkGreen}Inserte el nombre host Virual [ENTER]:${end} "
	read nombre
	echo -ne "${darkGreen}Inserte la ruta  documentRoot [ENTER]:${end} "
	read documentRoot
	email=$(git config user.email)
	clear
	echo -e "${darkYellow}1.-${darkCyan}Inserte la siguiente configuración en su archivo de hosts virtuales de Apache${end}"
	echo -e "  (Tipicamente se localiza en: /etc/apache2/sites-enabled/000-default)"
	echo -e "${yellow}<VirtualHost *:80>
	RewriteEngine ${darkYellow}On${yellow}
	RewriteOptions ${darkYellow}Inherit${yellow}
	ServerAdmin ${darkYellow}${email}${yellow}
	ServerName ${darkYellow}${nombre}${yellow}
	DocumentRoot ${darkYellow}${documentRoot}${yellow}
</VirtualHost>${end}"
	echo -e "${darkYellow}2.-${darkCyan}Agregue la siguiente configuración en su archivos hots${end}"
	echo -e "  (Se localiza en: /etc/hosts)"
	echo -e "${yellow}127.0.0.1\t${darkYellow}botanaselangel${end}"
	echo -ne "Presione enter para continuar..."
	read trash
	clear
	echo -e "${darkYellow}3.-${darkCyan}Reinicie su servidor web${end}"
	echo -e "  Por ejemplo: sudo /etc/init.d/apache2 restart"
	echo -e "  ó Quizas   : sudo /opt/lammp/lammp apache-restart"
	echo -e "${darkYellow}4.-${darkCyan}Revise que el servidor web funcione${end}"
	echo -e "  Abra su navegador web con la dirección ${darkYellow}http://${nombre}/${end}"
}
################################################################################
# Revisa que todos los directorios en el repositorio no tienen el archivo
# Index.html de no existir crea el archivo.
# Categoria: Security
################################################################################
function existeIndexHTML()
{
	echo -e "${light}Creando archivos index${end}"
	export count="0";
	echo -ne "${yellow}${count}${end}\r";
	find "${REPO_PATH}" -type d | grep -vE '\.git' | \
	grep -vE 'sitio_joomla' | while read dir; do
		if [ ! -f "${dir}/index.html" ]
		then
			export count=`expr  1 + $count`;
			echo -ne "${yellow}${count}${end}\r";
			touch "${dir}/index.html"
		fi
	done
	echo -e "\t ${light}←${end} Archivos Creados";
}
##########################################################################################
# Descricipcion: Borra todas las tablas de una BD MySQL                                  #
# link: http://bash.cyberciti.biz/mysql/drop-all-tables-shell-script/                    #
##########################################################################################
function borrarTodasLasTablas()
{
	login=`extractParamBD 'user'`
	password=`extractParamBD 'password'`
	database=`extractParamBD 'db'`
	for t in `${MYSQL_CLIENT} -u ${login} -p${password} ${database} -BNe 'show tables'`
	do
		echo -ne "${red}Borrando${end} -> ${yellow}${database}${end}.${light}${t}${end}"
		echo -ne "                                                      \r"
		${MYSQL_CLIENT} --user="${login}" --password="${password}" ${database} -e "drop table ${t}"
	done
}
#########################################################################################
function actualizaArchivo(){
	local localName=$(echo $1)
	#Extraemos el la ubicación del con directorio relativo al repositorio.
	local fileDst=$(echo "${JOOMLA_DST}${localName}");
	#Si el archivo no existe entonces significa que fue borrado
	if [ ! -e "${REPO_PATH}/${localName}" ]
	then
		if [ -e "${fileDst}" ]
		then
			echo -ne "  → ${red}☹ Archivo Eliminado  :${end} ${localName}";
			echo -e "\t←--${red}[Borrando]${end}";
			rm ${fileDst};
		fi
	else
		echo -ne "  → ${yellow}😁 Archivo Modificado :${end} ${localName}";
		#Si la carpeta destino no existe la creamos.
		local dirDst=$(dirname "${fileDst}")
		if [ ! -d "${dirDst}" ]
		then
			echo -ne "${yellow}←--[Creando directorio]${end}"
			echo "Directorio ${dirDst}";
			mkdir -p "${dirDst}"
		fi
		cp "${REPO_PATH}/${localName}" "${fileDst}";
		echo ''
	fi
}
function actualizar_path()
{
	num_commit="1"
	if [ $# -eq 1 ]
	then
		num_commit=${1}
	fi
	echo -e "${light}Backtraking sobre ${num_commit} confirmaciones${end}"
	git log -1 --name-only --pretty=format:'' HEAD~${num_commit} | grep -E "^[^\s]" |\
	grep -vE 'sitio_joomla' | while read localName; do
		actualizaArchivo ${localName};
	done
	git status -s | sed  -r 's/^[^\s]+\s+//' | grep -vE 'sitio_joomla' |\
	while read localName; do
		actualizaArchivo ${localName};
	done
}
##########################################################################################
#      Actualiza la base de datos                                                        #
##########################################################################################
function actualizaBD()
{
	echo -e "${light}Actualizando Base de datos${end}"
	bdFile=$(echo "${REPO_PATH}/sitio_joomla/bd.sql")
	borrarTodasLasTablas
	echo -e "  → ${red}Todas las tablas han sido borradas${end}                "
	#Extraemos los parametros de la BD en cuestion
	login=`extractParamBD 'user'`
	password=`extractParamBD 'password'`
	database=`extractParamBD 'db'`
	for f in `find ${REPO_PATH}/sitio_joomla/ -iregex ".*sql$" | sort`
	do
		echo -ne "${light}Cargando datos...${end}\r";
		${MYSQL_CLIENT} --user="${login}" --password="${password}" ${database} < "${f}";
	done;
	echo -e "  → ${cyan}Los datos han sido actualizados correctamente${end}"
}
##########################################################################################
#  Asigna permisos a los archivos                                                        #
##########################################################################################
function permisos()
{
	chmod 755 -R "${JOOMLA_DST}"
}
function mensajeDeAyuda()
{
echo -e "\t\t\t${light}Actualizador de proyectos Joomla${end}

 ${light}Descripción${end}

	Debe de configurar un par de parametros, para esto configura el directorio destino:
		${cyan}git config joomla.dir-dst /opt/lampp/httpdocs/sportmall/${end}
	En este caso hemos configurado el directorio destino en /opt/lampp/httpdocs/sportmall/
	para ver si la configuracion es correcta puede usar el mismo comando pero sin arugmento de setado:
		${cyan}git config joomla.dir-dst${end}
	Debera aparecer el directorio que inserto el usuario:
		 ${cyan}/opt/lampp/httpdocs/sportmall/${end}

	De igual forma usted puede configurar la ruta de su propio cliente mysql, por ejemplo
		${cyan}git config joomla.mysql-client /opt/lampp/etc/bin/mysql${end}
	En caso de no configurar buscara el mysql-client que tenga instalado en su S.O.

	Para instalar/borrar la bases de datos y usuarios automaticamente, es necesario agregar
	usuario/password administrador de nuestro mysql p.e:${cyan}
	
		 git config --global joomla.mysql-admin 'root'
		 git config --global joomla.mysql-password 'libertad'

 ${light}Ejemplos de uso${end}
	Creando la Base de datos, su usaurio, la ruta de archivos, etc...:
	${cyan}git sitio-joomla -instalar${end}

	Actualizando Simple(archivos sin seguimiento y modificados en el ultimo commit):
	${cyan}git sitio-joomla${end}

	Actualizando base de datos:
	${cyan}git sitio-joomla -db${end}

	Actualizando los archivos sin seguimiento y modificados hace 2 commits:
	${cyan}git sitio-joomla -c2${end}

	Actualizando base de datos, archivos sin seguimiento y modificados hace 5 commits:
	${cyan}git sitio-joomla -bd -c5${end}

	Esta página de ayuda:
	${cyan}git sitio-joomla -ayuda${end}

	Nos ayuda a configurar hosts virtuales de apache:
	${cyan}git sitio-joomla -vhost${end}

 ${light}Autor${end}
	Fitorec
";
}
if [ $# -gt 0 ]
then
	for arg in "$@"
	do
		case "${arg}" in
		"-bd")
				actualizaBD
				;;
		"-ayuda")
				mensajeDeAyuda
				;;
		"-instalar")
				installBD
				actualizaBD
				actualizar_path
				permisos;
				;;
		"-vhost")
				echo 'vhost';
				vhost
				;;
		*)
			if [ $? -eq 0 ]
			then
				num_commit=$(echo "${arg}" | grep -oE '[0-9]+$');
				actualizar_path ${num_commit}
				permisos;
			fi
			;;
		esac
	done
else
	#existeIndexHTML
	actualizar_path 0
fi
