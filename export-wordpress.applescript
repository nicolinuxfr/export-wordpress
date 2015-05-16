
-- On cr�e une liste avec toutes les taxonomies demand�es
on listeMeta(type)
	set listeTemp to "\""
	repeat with x from 1 to count of type
		set listeTemp to listeTemp & |name| of item x of type & "\", "
	end repeat
	
	
	return ("[ " & (characters 1 thru -3 of listeTemp) as text) & " ]"
end listeMeta


-- On cr�e une liste avec toutes les taxonomies demand�es
on rechercheImages(texte)
	set AppleScript's text item delimiters to "src=\""
	set listeTemp to []
	
	repeat with x from 2 to count of text items in texte
		set temp to text item x of texte
		set urlTemp to text 1 thru ((offset of "\"" in temp) - 1) of temp
		if urlTemp ends with "jpg" then set listeTemp to listeTemp & urlTemp
	end repeat
	
	return listeTemp
end rechercheImages


on chercherRemplacer(texte, rechercher, remplacer)
	set AppleScript's text item delimiters to the rechercher
	set the item_list to every text item of texte
	set AppleScript's text item delimiters to the remplacer
	set texte to the item_list as string
	set AppleScript's text item delimiters to ""
	return texte
end chercherRemplacer



-- *********************** D�BUT DU PROGRAMME ***********************


tell application "JSON Helper"
	set infoArticle to fetch JSON from "http://voiretmanger.fr/wp-json/posts/13634" with cleaning feed
	
end tell

-- R�cup�ration des trois donn�es importantes : slug, l'article en lui-m�me et les m�tadonn�es
set slugArticle to slug of infoArticle
set article to content of infoArticle
set lesMeta to terms of infoArticle


try
	tell application "Finder" to make new folder at (path to desktop folder from user domain) with properties {name:slugArticle}
end try

-- *********************** CR�ATION LISTE TAXONOMIES ***********************
set lesCategories to false
set lesTags to false
set lesActeurs to false
set lesCreateurs to false
set lesSagas to false
set lesAnnees to false

try
	set lesCategories to my listeMeta(category of lesMeta)
end try

try
	set lesTags to my listeMeta(post_tag of lesMeta)
end try

try
	set lesActeurs to my listeMeta(acteur of lesMeta)
end try

try
	set lesCreateurs to my listeMeta(createur of lesMeta)
end try

try
	set lesAnnees to my listeMeta(annee of lesMeta)
end try

try
	set lesSagas to my listeMeta(saga of lesMeta)
end try


-- *********************** T�L�CHARGEMENT DES IMAGES ***********************

-- Image de couverture
set imageCouv to source of featured_image of infoArticle

-- Recherche des autres images dans l'article
set listeImages to (imageCouv as list) & my rechercheImages(article)

-- T�l�chargement dans le dossier cr�� au d�part
try
	repeat with x from 1 to count of listeImages
		do shell script "cd " & quoted form of (POSIX path of (path to desktop folder from user domain) & slugArticle) & "  ; curl --max-time 5 -O " & quoted form of item x of listeImages
	end repeat
on error -- en cas de probl�me la premi�re fois, on recommence
	repeat with x from 1 to count of listeImages
		do shell script "cd " & quoted form of (POSIX path of (path to desktop folder from user domain) & slugArticle) & "  ; curl --max-time 5 -O " & quoted form of item x of listeImages
	end repeat
end try

-- *********************** CR�ATION FICHIER FINAL ***********************

set fichierTemp to "---
title: \"" & title of infoArticle & "\"
slug: \"" & slugArticle & "\"
couverture: \"" & imageCouv & "\""

if lesCategories is not false then set fichierTemp to fichierTemp & "
categories: " & lesCategories

if lesTags is not false then set fichierTemp to fichierTemp & "
tags: " & lesTags

if lesCreateurs is not false then set fichierTemp to fichierTemp & "
createurs: " & lesCreateurs

if lesActeurs is not false then set fichierTemp to fichierTemp & "
acteurs: " & lesActeurs

if lesAnnees is not false then set fichierTemp to fichierTemp & "
annees: " & lesAnnees

if lesSagas is not false then set fichierTemp to fichierTemp & "
sagas: " & lesSagas

set fichierTemp to fichierTemp & "

---

" & article

do shell script "cd " & quoted form of (POSIX path of (path to desktop folder from user domain) & slugArticle) & " ; echo " & quoted form of fichierTemp & " > " & slugArticle & ".md"