#!/bin/sh

TABLE=$(curl -s nodejs.org/dist/index.tab)

FIRST=

LTSPOS=
VERSIONPOS=

ORGIFS=$IFS
IFS="
"
for i in $TABLE
do

	IFS="	"

	# echo -n "$IFS" | hexdump -C

	CTR=0

	ISLTS=
	CURVER=

	for j in $i
	do

		if [ -z "$FIRST" ]
		then

			case "$j" in 
			
			"version")
				VERSIONPOS=$CTR
				;;
			"lts")
				LTSPOS=$CTR
				;;
			*)
				;;
			
			esac

		else
			case "$CTR" in 
			
			"$VERSIONPOS")
				CURVER=$j
				;;
			"$LTSPOS")
				ISLTS=$j
				;;
			*)
				;;
			
			esac
		fi

		# echo -n $j

		CTR=$(($CTR+1))
		# echo $CTR $VERSIONPOS $LTSPOS "'$j'"
	done

	if [ "$ISLTS" != "-" ] && [ "$ISLTS" != "" ]; then
		echo newest lts: $CURVER
		break;
	fi

	if [ -z "$FIRST" ]
	then

		FIRST="FALSE"

	fi

	IFS="
"

done

OS=
ARCH=

case "$(uname)" in 

"Linux")
	OS="linux"
	;;
"Darwin")
	OS="darwin"
	;;
*)
	echo platform not configured.
	exit 1
	;;

esac

case "$(uname -m)" in 

"x86_64")
	ARCH="x64"
	;;
"x86")
	ARCH="x86"
	;;
"arm64")
	ARCH="arm64"
	;;
"aarch64")
	ARCH="arm64"
	;;
*)
	echo arch not configured.
	exit 1
	;;

esac

echo downloading Node $CURVER \($OS $ARCH\)...
(curl -s https://nodejs.org/dist/$CURVER/node-$CURVER-$OS-$ARCH.tar.gz | tar -C . --strip-components=2 --wildcards -zxf - \*bin/node)
