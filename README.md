sitiosJoomla
=============

> Un _simple alias para el git_, que nos ayuda a actualizar sitios Joomla!

**sitiosJoomla!** es un script que nos facilita la tarea de trabajar con sitios desarrollados con __Joomla!__ en repositorios administrados con **git**.


## Instalación

### Obteniendo el proyecto

Lo primero que tienes que hacer es descargar el proyecto y ubicado en una parte donde lo puedas acceder fácilmente, p.e:

	/home/<user>/proyectos_web/sitios-joomla/

Donde **`<user>`** es nuestro usuario, en mi caso @fitorec quedaria de la suguiente forma:

	/home/fitorec/proyectos_web/sitios-joomla/


### Configurando alias.

Vamos agregar un alias "**sitio-joomla**" esto es similar a agregar otro "**sub-comando** al git", es decir podremos ejecutar:


	git sitio-joomla -<opción>

Lo hace el script cuando se ejecuta por primera vez:

	bash /home/fitorec/proyectos_web/sitios-joomla/sitioJoomla.sh

¿Como lo hace?, agrega un alias hacia donde apunta nuestro script, esto tambien lo puedes hacer tu mismo con la instrucción, el script solo te facilita la configuración:

	git config  --global alias.sitio-joomla  '!bash /home/fitorec/proyectos_web/sitios-joomla/sitioJoomla.sh'

### Configuracion general SQL

#### Ruta de nuestro cliente mySQL

Tal vez estes usando un entorno de desarrollo ageno al la configuración de tu S.O. por ejemplo tal ves puedas estar usando [lampp](http://www.apachefriends.org/en/xampp-linux.html), entonces la configuracion de tu cliente mysql puede estar en otra parte, por ejemplo:

	/opt/lammp/etc/bin/mysql

De ser asi tenemos que indicarle al script la ruta de nuestro cliente Mysql a usar, esto lo podemos hacer con la siguiente instrucción:
	
	git config  --global joomla.mysql-client

**Nota:** Si tu cliente mysql es el mismo que el que nos devuelve el comando `which mysql` no es necesario configurar nada.

#### Acceso al administrador MSQL


Para instalar/borrar la bases de datos y usuarios automaticamente, es necesario agregar usuario/password administrador de nuestro mysql p.e:
	
		 git config --global joomla.mysql-admin 'root'
		 git config --global joomla.mysql-password 'libertad'

## Uso

Supongamos que ya tenemos configurado el alias y que tenemos un proyecto joomla! administrado con **git** p.e. `/home/proyectos/site-x`, por otra parte los archivos los tengo ubicados en `/var/www/site-x`.

Lo primero que tenemos que hacer es indicarle nuestro script que el directorio destino sera `/var/www/site-x`, para esto configuramos **localmente** el directorio destino de la siguiente manera:

```sh
	#Indicamos que /var/www/site-x es el directorio destino
	git config joomla.dir-dst /var/www/site-x
```

Bien ahora ya tienes todo configurado!, lo siguiente sera instalar la aplicación en tu servidor local, esto significa que los archivos que tienes en tu repositorio local `/home/proyectos/site-x` se pasaran a `/var/www/site-x`.

Por otra parte localmente te extrae la configuración del archivo `/var/www/site-x/` te crea el usuario/base de datos y te la carga, con un simple:

	git sitio-joomla -instalar


## Algunos Ejemplos de uso

Creando la Base de datos, su usuario, la ruta de archivos, etc...:

	git sitio-joomla -instalar

Actualizando Simple(archivos sin seguimiento y modificados en el ultimo commit):

	git sitio-joomla

Actualizando base de datos:

	git sitio-joomla -db

Actualizando los archivos sin seguimiento y modificados hace 2 commits:

	git sitio-joomla -c2

Actualizando base de datos, archivos sin seguimiento y modificados hace 5 commits:

	git sitio-joomla -bd -c5

Esta página de ayuda:

	git sitio-joomla -ayuda
