#!/bin/sh
## File: NOLF Dedicated Server Docker Script - nolf_startup.sh
## Author: Kevin Moore <admin@sbotnas.io>
## Date: 2023/11/13
## License: MIT License 

GAMEDIR=/container/.wine/drive_c/nolf

cd /container/.wine/drive_c/nolf

# Clear our startup.txt file starting from MODENIZER.rez down
sed -i '11,$d' "$GAMEDIR/startup.txt"

if [[ ! -z "$CUSTOM_REZ" ]]; then
	if [[ "$DISABLE_WIZARD" == "[Tt]rue" ]]; then
	
		# Rez number for MODERNIZER.rez in startup.txt	
		i=8

		for f in $CUSTOM_REZ; do
			if [[ "$(grep $(echo $f | tr '[a-z]' '[A-Z]') "$GAMEDIR/startup.txt")" ]]; then
               			echo "Duplicate rez found, skipping $f."
                 		continue
         		else
        	        	echo "Rez$(( i=$i+1 )) = \"custom/$f.rez\"" >> "$GAMEDIR/startup.txt"
				echo "Adding $f.rez"
			fi
        	done
	else
		# Disable custom rez add for people who only want to use the wizard to manage their server
		echo "Server Wizard active, skipping custom rez add"
	fi
fi

# Logic for handling adding/removing maps to NetHost.txt via docker-compose with included map persistence
# Mostly works with some bugs, use at your own risk
# Disabled for RC1 as it is too cumbersome syncing changes between Server GUI Wizard & Docker compose/run commands, may revisit in future
: <<'END_MAP_LOGIC'
case $GAMETYPE in
        1) # H.A.R.M vs. UNITY
        map_path="Worlds\Multi\AssaultMap"
        levels="$ASSAULT_MAPS"
        hoststring="NetCALevel"
	netnum="NetCANumLevels"
        ;;

        2|*) # DeathMatch
        map_path="Worlds\Multi\DeathMatch"
        levels=$DEATHMATCH_MAPS
        hoststring="NetLevel"
	netnum="NetNumLevels"
        ;;
esac

if [[ "$PERSIST_MAPLIST" == "[Tt]rue" ]]; then
        lvlcnt=$( cat "$GAMEDIR/NetHost.txt" | grep $hoststring | wc -l)
        reqlvlcnt=$(echo $levels | wc -w)

        if [[ $(( $lvlcnt + $reqlvlcnt )) -gt 32 ]]; then
                echo "Caution, there are more than 32 maps in rotation, server may become unstable or crash."
        fi
else
        sed -i "/$hoststring/d" "$GAMEDIR/NetHost.txt"
        lvlcnt=0
fi

for i in $levels; do
        if [[ "$(grep $(echo $i | tr '[a-z]' '[A-Z]') "$GAMEDIR/NetHost.txt")" ]]; then
                echo "Duplicate found, skipping $i."
                continue
        else
                echo "$hoststring$lvlcnt = \"$map_path\\$(echo $i | tr '[a-z]' '[A-Z]')\"" >> "$GAMEDIR/NetHost.txt"
                lvlcnt=$(( $lvlcnt + 1 ))
        fi
done

sed -i "s/$netnum.*/$netnum = $(( $lvlcnt )).000000f/g" "$GAMEDIR/NetHost.txt"
END_MAP_LOGIC

if [[ ! -z "$SERVER_PASSWORD" ]]; then
        PASSWORD_ENABLED="1.0"
	sed -i -e "s/NetPassword.*/NetPassword = \"$SERVER_PASSWORD\"/g; 
		s/NetUsePassword.*/NetUsePassword = 1.000000f/g" "$GAMEDIR/NetHost.txt"
else
        PASSWORD_ENABLED="0.0"
	sed -i -e "s/NetPassword.*/NetPassword = \"\"/g; 
		s/NetUsePassword.*/NetUsePassword = 0.000000f/g" "$GAMEDIR/NetHost.txt"
fi

if [[ "$DISABLE_WIZARD" = "[Tt]rue" ]]; then
        DISABLE_WIZARD="-nowiz"
else
        DISABLE_WIZARD=""
fi

exec wine NolfServ.exe ${DISABLE_WIZARD:-} -NetSessionName "${SERVER_NAME:-"A Docker NOLF Server"}" -NetGameType ${GAMETYPE:=2} ${PASSWORD_ENABLED:+"-NetUsePassword $PASSWORD_ENABLED"} ${SERVER_PASSWORD:+"-NetPassword $SERVER_PASSWORD"} -NetMaxPlayers ${MAX_PLAYERS:-8} -NetPort ${SERVER_PORT:-27888} ${ADDITIONAL_ARGS:-}
