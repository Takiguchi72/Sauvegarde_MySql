#! /bin/bash
########################################################
# Script de sauvegarde de la base de données gsb_frais #
########################################################

# ******************* #
#  F O N C T I O N S  #
# ******************* #

#Fonction permettant d'écrire une ligne dans le fichier de logs
#@param Le message à afficher et insérer dans le fichier de logs [String]
ecrireLog()
{
	#Si la fonction a été appelée sans paramètres, on affiche un message d'erreur
	if [ $# -eq 0 ]
	then
		echo "La fonction a été appelée sans paramètres !"
		echo "Aucun log n'a été écrit !"
	#Si il y a au moins un paramètre,
	else
		#S'il y avait plus qu'un seul paramètre, on affiche un message d'erreur
		if [ $# -ge 2 ]
		then	
			echo "La fonction a été appelé avec plus d'un paramètre !"
			echo "Aucun log n'a été écrit !"
		#Sinon, c'est qu'on a appelé la fonction avec un seul paramètre,
		#donc on va écrire dans le fichier de logs
		else
			#Écriture dans le fichier de logs
			echo "$dateLog $1" >> $fichierLog
			#Affichage à l'échan 
			echo $1
		fi
	fi
}

# *************************************** #
#  P R O G R A M M E   P R I N C I P A L  #
# *************************************** #

#Liste des variables
pathSave='/var/sauvdb'
pathLog='/var/log/mysql'
fichierLog="/var/log/mysql/gsb_frais_save.log"
dateLog=$(date +%d-%m-%Y:%H-%M-%S)

echo " " >> $fichierLog
echo $(date) >> $fichierLog

#On vérifie que le service MySql tourne
# => La commande retourne soit "start" (MySql allumé) soit "stop" (MySql éteint)
etatMySql=$(service mysql status | cut -f2 -d " " | cut -f1 -d "/")

#Si $etatMySql vaut "stop", c'est que le serveur MySql est éteint, donc on arrête le script
if [ $etatMySql = "stop" ]
then
	#On affiche que MySql est éteint
	ecrireLog "Le service MySql est arrêté !"
	ecrireLog "Impossible de réaliser la sauvegarde."
	exit 1
fi

#Test de connexion à la base mysql
bases=$(mysql -h localhost -u root -pp@ssword -e "show databases;" -B -s 2>> $fichierLog)
#Si bases est vide, c'est qu'on a pas réussi à lister les bdd, donc qu'on a pas réussi à se connecter.
#On affiche une erreur puis on arrête le script
if [ -z bases ]
then
	ecrireLog "Impossible de se connecter à MySql !"
	ecrireLog "Impossible de réaliser la sauvegarde."
	exit 1
fi

#Création du dossier /var/log/mysql
#Si le dossier n'existe pas, je le créer
if [ ! -d $pathLog ]
then
	#Création du dossier et redirection du canal d'erreur vers le fichier de log
	ecrireLog "Le dossier $pathLog n'existe pas. Création du dossier $pathLog..."
	mkdir $pathLog 2>> $fichierLog

	#Gestion du code retour de la création du dossier
	#Si mkdir ne retourne pas '0', c'est qu'on a pas réussi à créer le dossier
	if [ $? -ne 0 ]
	then
		ecrireLog "Echec de la création du dossier $pathLog !"
		#On quitte le programme avec le code d'erreur '1'
		exit 1
	#Sinon c'est qu'on l'a bien créé,
	else
		#donc on l'affiche
		ecrireLog "Le dossier $pathLog vient d'être créé !"
	fi
#Sinon, c'est qu'il existe
else
	ecrireLog "Le dossier $pathLog existe déjà ! Rien n'est donc créé."
fi

#Création du dossier /var/sauvbd
#Si le dossier n'existe pas, je le créer
if [ ! -d $pathSave ]
then
	#Création du dossier et redirection du canal d'erreur vers le fichier de log
	ecrireLog "Le dossier $pathSave n'existe pas..."
	mkdir $pathSave 2>> $fichierLog

	#Gestion du code retour de la création du dossier
	#Si mkdir ne retourne pas '0', c'est qu'on a pas réussi à créer le dossier
	if [ $? -ne 0 ]
	then
		#On affiche un message d'erreur
		ecrireLog "Echec de la création du dossier $pathSave !"

		#Puis on retourne 1 car il y a eu un probleme
		exit 1
	else
		#On affiche qu'on a réussi à créer le dossier
		ecrireLog "Le dossier $pathSave vient d'être créé !"
	fi
#Le dossier existe déjà donc on l'affiche
else
	ecrireLog "Le dossier $pathSave existe déjà ! Rien n'est donc créé !"
fi

#Sauvegarde de la base de données gsb_frais
ecrireLog "Création de la sauvegarde de la base de données gsb_frais..."

#On défini le chemin et le nom du fichier pour pouvoir le retrouver dans la suite du script pour le comprésser
fichierSauvegarde="/var/sauvdb/gsb_frais$(date +%d%m%Y-%H%M%S).sql"

#mysqldump -u usauv -pusauv -h localhost --opt gsb_frais > /var/sauvdb/gsb_frais$(date +%d%m%Y-%H%M%S).sql 2>> $fichierLog
mysqldump -u usauv -pusauv -h localhost --opt gsb_frais > $fichierSauvegarde 2>> $fichierLog

#Gestion du code retour de la sauvegarde
#Si la sauvegarde s'est bien effectuée
if [ $? -eq 0 ]
then
	#Si la sauvegarde a été effectuée correctement,
	#on affiche un message
	ecrireLog "Sauvegarde effectuée avec succès !"

	#puis on compresse la sauvegarde avec gzip
	ecrireLog "Compression de la sauvegarde..."
	gzip $fichierSauvegarde

	#Si gzip retourne '0'
	if [ $? -eq 0 ]
	then
		#On affiche que tout s'est bien passé
		ecrireLog "La sauvegarde a correctement été compréssée !"

		#On retourne 0 car tout s'est bien passé
		exit 0
	else
		#Sinon, on indique qu'il y a eu une erreur
		ecrireLog "Echec de la compression de la sauvegarde !"

		#On retourne 1 car il y a eu une erreur
		exit 1
	fi
#Si la sauvegarde a échouée
else
	#On affiche un message d'erreur
	ecrireLog "La sauvegarde de la base a échouée !"

	#On retourne 1 car il y a eu une erreur
	exit 1
fi
