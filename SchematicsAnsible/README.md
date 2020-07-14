# Aprovisionamiento y configuracion de joomla con Terraform y Ansible

Plantilla para el aprovisionamiento de recursos necesarios para el despliegue de joomla en una arquitectura VPC IBM CLoud con VSI.

## Requerimentos

Como caracteristicas especificas de este despliegue se requiere:

*	Contar con una cuenta en IBM Cloud 💻

## Indice

* Arquitectura de implementación
* Ejecución de la plantilla de terraform y ansible en IBM Cloud Schematics

---

### 1. Arquitectura de implementación

Con el fin de ilustrar los recursos necesarios para el despliegue de la plataforma Joomla, a continuación de muestra un diagrama.

<p align="center">
<img width="800" alt="img8" src="https://user-images.githubusercontent.com/40369712/87473604-57d64980-c5e7-11ea-8ef6-ff8a454c1923.png">
</p>

---

### 2. Ejecución de la plantilla de terraform en IBM Cloud Schematics

Ingrese a IBM Cloud para crear un espacio de trabajo en [Schematics](https://cloud.ibm.com/schematics/workspaces) y seleccione crear espacio de trabajo.

<p align="center">
<img width="900" alt="img8" src="https://user-images.githubusercontent.com/40369712/87476947-e13c4a80-c5ec-11ea-872f-d1f10db02c47.png">
</p>

Allí debera proporcional un nombre, las etiquetas que desee, seleccionar el grupo de recursos, la hubicación, proporcionar una descripción y finalmente seleccionar crear.


<p align="center">
<img width="900" alt="img8" src="https://user-images.githubusercontent.com/40369712/87478029-b81cb980-c5ee-11ea-984a-9c16b313b736.png">
</p>

Dentro de **Valores** Ingrese la [URL del git](https://github.com/emeloibmco/Schematics-VPC-Schematics-3-Tier-App-Joomla/tree/master/SchematicsAnsible) donde se encuentra la plantilla de despliegue de Schematics, seleccione la version 0.12 de terraform y presione Guardar informacion de la plantilla.

<p align="center">
<img width="900" alt="img8" src="https://user-images.githubusercontent.com/40369712/87478899-257d1a00-c5f0-11ea-9923-658736cf5866.png">
</p>

Una vez hecho el paso anterior Schematics cargara las variables de personalización de la plantilla, donde podra modificar lo siguiente:

## Inputs

| name | description | type | required | default | sensitive |
| ---------- | -------- | -------------- | ---------- | ----------- | ----------- |
| ibm_region | Region of deployed VPC | string | |"us-south" |   |
|  vpc_name  | Unique VPC name     | string | | "ssh-bastion-host"   |   |
|  resource_group_name | Name of IBM Cloud Resource Group used for all VPC resources | string | | "Default" |  |
|  ssh_source_cidr_override |  User specified list of CIDR ranges requiring SSH access. When used with Schematics the default is to allow access only from Schematics, otherwise set to "0.0.0.0/0" | list(string) | | {{Schematics}}  |   |
|  bastion_cidr | CIDR range for bastion subnets  |  string  | | "172.22.192.0/20"  |   |
|  frontend_cidr |  List of CIDRs the bastion is to route SSH traffic to |  list(string) | | "172.16.0.0/20"  |   |
|  backend_cidr" |  List of CIDRs the bastion is to route SSH traffic to   | list(string) | | "172.17.0.0/20"  |   |
|  vsi_profile | Profile for VSIs deployed in frontend and backend  | string  | | "cx2-2x4" |  |
|  image_name |  OS image for VSI deployments. Only tested with Centos | string | | "ibm-centos-7-6-minimal-amd64-1" |  |
|  ssh_key_name | Name given to public SSH key uploaded to IBM Cloud for VSI access |  string |  ✓   |    |    |     
|  ssh_accesscheck | Set to "true' if access to VSIs via SSH is to be validated |  string | | "false" |  |
|  ssh_private_key | Optional private key from key pair. Only required if it desired to validate remote SSH access to the bastion host and VSIs. | string  | | |  ✓   |               


<p align="center">
<img width="900" alt="img8" src="https://user-images.githubusercontent.com/40369712/87479485-324e3d80-c5f1-11ea-8bb0-e1d3daad9544.png">
</p>

Una vez modificadas las variables de entrada, seleccione guardar cambios.

Una vez guardados los cambios, nos dirigimos a **Actividad** y para ejecutar el despliegue del ambiente deberemos seleccionar generar plan y posteriormente aplicar plan.

<p align="center">
<img width="900" alt="img8" src="https://user-images.githubusercontent.com/40369712/87479985-139c7680-c5f2-11ea-9dd7-eb5c7615a3b6.png">
</p>


---

# Referencias 📖

* [Pagina de joomla](https://www.joomla.org/about-joomla.html).
* [Guia para la instalación de mysql](https://linuxize.com/post/how-to-install-mysql-on-ubuntu-18-04/).
* [Instalación de ansible en SO Ubuntu](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-ubuntu).
* [Modulos de ansible](https://docs.ansible.com/ansible/latest/modules/).# Example VPC with SSH access and Bastion Host for Redhat Ansible
