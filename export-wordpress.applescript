
-- On crŽe une liste avec toutes les taxonomies demandŽes
on listeMeta(type)
	set AppleScript's text item delimiters to ""
	set listeTemp to ""
	repeat with x from 1 to count of type
		set listeTemp to listeTemp & "\"" & |name| of item x of type & "\", "
	end repeat
	return ("[ " & (characters 1 thru -3 of listeTemp) as text) & " ]"
end listeMeta


-- On crŽe une liste avec toutes les taxonomies demandŽes
on rechercheImages(texte)
	set AppleScript's text item delimiters to "src=\""
	set listeTemp to []
	
	repeat with x from 2 to count of text items in texte
		set temp to text item x of texte
		set urlTemp to text 1 thru ((offset of "\"" in temp) - 1) of temp
		if urlTemp begins with "//" then set urlTemp to "http:" & urlTemp
		if urlTemp ends with "jpg" then set listeTemp to listeTemp & urlTemp
	end repeat
	return listeTemp
	
	
end rechercheImages


on traitementArticle(infoArticle)
	-- RŽcupŽration des trois donnŽes importantes : slug, l'article en lui-mme et les mŽtadonnŽes
	set slugArticle to slug of infoArticle
	set article to content of infoArticle
	set dateArticle to |date| of infoArticle
	set dateEdit to |modified| of infoArticle
	set lesMeta to terms of infoArticle
	
	try
		tell application "Finder" to make new folder at (path to temporary items from user domain) with properties {name:slugArticle}
	end try
	
	-- *********************** CRƒATION LISTE TAXONOMIES ***********************
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
	
	
	-- *********************** TƒLƒCHARGEMENT DES IMAGES ***********************
	
	-- Image de couverture
	try
		set imageCouv to source of featured_image of infoArticle
		set listeImages to (imageCouv as list) & my rechercheImages(article)
	on error
		-- Recherche des autres images dans l'article
		set imageCouv to ""
		set listeImages to my rechercheImages(article)
	end try
	
	
	-- TŽlŽchargement dans le dossier crŽŽ au dŽpart
	try
		repeat with x from 1 to count of listeImages
			try
				do shell script "cd " & quoted form of (POSIX path of (path to temporary items from user domain) & slugArticle) & "  ; curl --max-time 5 -O " & quoted form of item x of listeImages
			on error
				log "Erreur : " & item x of listeImages
			end try
		end repeat
	on error -- en cas de problme la premire fois, on recommence
		repeat with x from 1 to count of listeImages
			try
				do shell script "cd " & quoted form of (POSIX path of (path to temporary items from user domain) & slugArticle) & "  ; curl --max-time 5 -O " & quoted form of item x of listeImages
			on error
				log "Erreur : " & item x of listeImages
			end try
		end repeat
	end try
	
	set AppleScript's text item delimiters to "/"
	set imageCouv to "/" & slugArticle & "/" & last text item of imageCouv
	
	-- *********************** CRƒATION FICHIER FINAL ***********************
	
	set fichierTemp to "+++
title = \"" & title of infoArticle & "\"
url = \"/" & slugArticle & "\"
date = \"" & dateArticle & "\"
dateEdit = \"" & dateEdit & "\"
cover = \"" & imageCouv & "\""
	
	if lesCategories is not false then set fichierTemp to fichierTemp & "
categories = " & lesCategories
	
	if lesTags is not false then set fichierTemp to fichierTemp & "
tags = " & lesTags
	
	if lesCreateurs is not false then set fichierTemp to fichierTemp & "
createurs = " & lesCreateurs
	
	if lesActeurs is not false then set fichierTemp to fichierTemp & "
acteurs = " & lesActeurs
	
	set AppleScript's text item delimiters to "\""
	if lesAnnees is not false then set fichierTemp to fichierTemp & "
annees = " & lesAnnees & "
weight = " & text item 2 of lesAnnees
	
	if lesSagas is not false then set fichierTemp to fichierTemp & "
sagas = " & lesSagas
	
	set fichierTemp to fichierTemp & "

+++

" & article
	
	do shell script "cd " & quoted form of (POSIX path of (path to temporary items from user domain) & slugArticle) & " ; echo " & quoted form of fichierTemp & " > index.md"
	
end traitementArticle


-- *********************** LANCEMENT ***********************

tell application "JSON Helper"
	repeat with x from 1 to 120
		log "Page n¡" & x & " sur 120"
		try
			set listeArticles to fetch JSON from "http://voiretmanger.fr/wp-json/posts/?page=" & x with cleaning feed
		on error
			try
				set listeArticles to fetch JSON from "http://voiretmanger.fr/wp-json/posts/?page=" & x with cleaning feed
			on error
				log "Page n¡" & x & " - impossible ˆ charger"
			end try
		end try
		repeat with x from 1 to count of listeArticles
			my traitementArticle(item x of listeArticles)
		end repeat
		
	end repeat
	
end tell