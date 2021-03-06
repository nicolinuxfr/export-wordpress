
-- On cr�e une liste avec toutes les taxonomies demand�es
on listeMeta(type)
	set AppleScript's text item delimiters to ""
	set listeTemp to ""
	repeat with x from 1 to count of type
		set listeTemp to listeTemp & "\"" & |name| of item x of type & "\", "
	end repeat
	return ("[ " & (characters 1 thru -3 of listeTemp) as text) & " ]"
end listeMeta


-- On cr�e une liste avec toutes les taxonomies demand�es
on rechercheImages(texte)
	set AppleScript's text item delimiters to "src=\""
	set listeTemp to []
	
	repeat with x from 2 to count of text items in texte
		try
			set temp to text item x of texte
			set urlTemp to text 1 thru ((offset of "\"" in temp) - 1) of temp
			if urlTemp begins with "//" then set urlTemp to "http:" & urlTemp
			if urlTemp ends with "jpg" or urlTemp ends with "jpeg" then set listeTemp to listeTemp & urlTemp
		on error
			log "Erreur : urlTemp"
		end try
	end repeat
	
	set AppleScript's text item delimiters to "href=\""
	repeat with x from 2 to count of text items in texte
		try
			set temp to text item x of texte
			set urlTemp to text 1 thru ((offset of "\"" in temp) - 1) of temp
			if urlTemp begins with "//" then set urlTemp to "http:" & urlTemp
			if urlTemp ends with "jpg" or urlTemp ends with "jpeg" then set listeTemp to listeTemp & urlTemp
		on error
			log "Erreur : urlTemp"
		end try
	end repeat
	
	
	
	return listeTemp
	
end rechercheImages

-- Nettoyage du titre (http://www.macosxautomation.com/applescript/sbrt/sbrt-04.html)
on remove_markup(this_text)
	set copy_flag to true
	set the clean_text to ""
	repeat with this_char in this_text
		set this_char to the contents of this_char
		if this_char is "<" then
			set the copy_flag to false
		else if this_char is ">" then
			set the copy_flag to true
		else if the copy_flag is true then
			set the clean_text to the clean_text & this_char as string
		end if
	end repeat
	
	
	if clean_text contains "&rsquo;" then
		-- Remplacement des ' en entit�s HTML
		set AppleScript's text item delimiters to "&rsquo;"
		set textTemp to ""
		repeat with x from 1 to count of text item in clean_text
			set textTemp to textTemp & text item x of clean_text & "'"
		end repeat
		return text 1 thru -2 of textTemp
	else
		return clean_text
	end if
end remove_markup


on traitementArticle(infoArticle)
	-- R�cup�ration des trois donn�es importantes : slug, l'article en lui-m�me et les m�tadonn�es
	set slugArticle to slug of infoArticle
	set article to content of infoArticle
	set dateArticle to |date| of infoArticle
	set dateEdit to |modified| of infoArticle
	set lesMeta to terms of infoArticle
	
	try
		tell application "Finder" to make new folder at (path to temporary items from user domain) with properties {name:slugArticle}
	end try
	
	-- *********************** CR�ATION LISTE TAXONOMIES ***********************
	set lesCategories to false
	set lesTags to false
	set lesActeurs to false
	set lesCreateurs to false
	set lesPays to false
	set lesSagas to false
	set lesAnnees to false
	set titreOriginal to false
	set lesMetteursEnScene to false
	set lesLieux to false
	set lesChef to false
	set lesFestival to false
	
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
		set lesPays to my listeMeta(pays of lesMeta)
	end try
	
	
	try
		set lesSagas to my listeMeta(saga of lesMeta)
	end try
	
	try
		set titreOriginal to my listeMeta(original of lesMeta)
	end try
	
	try
		set lesMetteursEnScene to my listeMeta(metteurenscene of lesMeta)
	end try
	
	try
		set lesLieux to my listeMeta(lieu of lesMeta)
	end try
	
	try
		set lesChef to my listeMeta(chef of lesMeta)
	end try
	
	try
		set lesFestival to my listeMeta(festival of lesMeta)
	end try
	
	try
		set imageCouv to source of featured_image of infoArticle
	end try
	
	
	-- *********************** T�L�CHARGEMENT DES IMAGES ***********************
	(*
	-- Image de couverture
	try
		set imageCouv to source of featured_image of infoArticle
		set listeImages to (imageCouv as list) & my rechercheImages(article)
	on error
		-- Recherche des autres images dans l'article
		set imageCouv to ""
		set listeImages to my rechercheImages(article)
	end try
	
	
	-- T�l�chargement dans le dossier cr�� au d�part
	try
		repeat with x from 1 to count of listeImages
			try
				do shell script "cd " & quoted form of (POSIX path of (path to temporary items from user domain) & slugArticle) & "  ; curl --max-time 5 -O " & quoted form of item x of listeImages
			on error
				log "Erreur : " & item x of listeImages
			end try
		end repeat
	on error -- en cas de probl�me la premi�re fois, on recommence
		repeat with x from 1 to count of listeImages
			try
				do shell script "cd " & quoted form of (POSIX path of (path to temporary items from user domain) & slugArticle) & "  ; curl --max-time 5 -O " & quoted form of item x of listeImages
			on error
				log "Erreur : " & item x of listeImages
			end try
		end repeat
	end try

	
	set AppleScript's text item delimiters to "/"
	set imageCouv to last text item of imageCouv
	
*)
	
	-- *********************** CR�ATION FICHIER FINAL ***********************
	
	set fichierTemp to "+++
titre = \"" & title of infoArticle & "\"
title = \"" & my remove_markup(title of infoArticle) & "\"
url = \"/" & slugArticle & "\"
date = \"" & dateArticle & "\"
Lastmod = \"" & dateEdit & "\""
	
	if imageCouv is not false then set fichierTemp to fichierTemp & "
cover = " & imageCouv
	
	if lesCategories is not false then set fichierTemp to fichierTemp & "
categorie = " & lesCategories
	
	if lesTags is not false then set fichierTemp to fichierTemp & "
tag = " & lesTags
	
	if lesCreateurs is not false then set fichierTemp to fichierTemp & "
createur = " & lesCreateurs
	
	if lesActeurs is not false then set fichierTemp to fichierTemp & "
acteur = " & lesActeurs
	
	set AppleScript's text item delimiters to "\""
	if lesAnnees is not false then set fichierTemp to fichierTemp & "
annee = " & lesAnnees & "
weight = " & text item 2 of lesAnnees
	
	if lesSagas is not false then set fichierTemp to fichierTemp & "
saga = " & lesSagas
	
	if lesPays is not false then set fichierTemp to fichierTemp & "
pays = " & lesPays
	
	if lesMetteursEnScene is not false then set fichierTemp to fichierTemp & "
metteur = " & lesMetteursEnScene
	
	if lesLieux is not false then set fichierTemp to fichierTemp & "
lieu = " & lesLieux
	
	if lesChef is not false then set fichierTemp to fichierTemp & "
chef = " & lesChef
	
	if lesFestival is not false then set fichierTemp to fichierTemp & "
festival = " & lesFestival
	
	if titreOriginal is not false then set fichierTemp to fichierTemp & "
original = \"" & text item 2 of titreOriginal & "\""
	
	set fichierTemp to fichierTemp & "

+++

" & article
	
	do shell script "cd " & quoted form of (POSIX path of (path to temporary items from user domain) & slugArticle) & " ; echo " & quoted form of fichierTemp & " > index.md"
	
end traitementArticle


-- *********************** LANCEMENT ***********************

tell application "JSON Helper"
	repeat with x from 1 to 200
		log "Page n�" & x & " sur 200"
		try
			set listeArticles to fetch JSON from "https://voiretmanger.fr/wp-json/posts/?page=" & x with cleaning feed
		on error
			try
				set listeArticles to fetch JSON from "https://voiretmanger.fr/wp-json/posts/?page=" & x with cleaning feed
			on error
				log "Page n�" & x & " - impossible � charger"
			end try
		end try
		repeat with x from 1 to count of listeArticles
			my traitementArticle(item x of listeArticles)
		end repeat
		
	end repeat
	
end tell