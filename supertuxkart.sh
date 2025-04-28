#!/bin/sh

APP=supertuxkart

ARCH="x86_64"

# DEPENDENCIES

dependencies="tar"
for d in $dependencies; do
	if ! command -v "$d" 1>/dev/null; then
		echo "ERROR: missing command \"d\", install the above and retry" && exit 1
	fi
done

_appimagetool() {
	if ! command -v appimagetool 1>/dev/null; then
		[ ! -f ./appimagetool ] && curl -#Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-"$ARCH".AppImage && chmod a+x ./appimagetool
		./appimagetool "$@"
	else
		appimagetool "$@"
	fi
}

DOWNLOAD_PAGE=$(curl -Ls https://api.github.com/repos/supertuxkart/stk-code/releases/latest)
DOWNLOAD_URL=$(echo "$DOWNLOAD_PAGE" | sed 's/[()",{} ]/\n/g' | grep -i "http.*linux" | grep -i "tar.xz$\|tar.gz$" | grep -i "x64\|amd64\|x86_64" | head -1)
VERSION=$(echo "$DOWNLOAD_URL" | tr '/-' '\n' | grep "^[0-9]" | tail -1)
if ! test -f ./*tar*; then wget "$DOWNLOAD_URL"; fi
mkdir -p "$APP".AppDir || exit 1

# Extract the package
tar fx ./*tar* -C ./"$APP".AppDir/ || exit 1

# Fix directory
if test -d ./"$APP".AppDir/S*; then
	mv ./"$APP".AppDir/S*/* ./"$APP".AppDir/ && rmdir ./"$APP".AppDir/S* || exit 1
fi

_appimage_basics() {
	# Launcher
	cat <<-HEREDOC >> ./"$APP".AppDir/"$APP".desktop
	[Desktop Entry]
	Name=SuperTuxKart
	Icon=supertuxkart
	GenericName=A kart racing game
	GenericName[da]=Et kart racerspil
	GenericName[de]=Ein Kart-Rennspiel
	GenericName[fr]=Un jeu de karting
	GenericName[gl]=Xogo de carreiras con karts
	GenericName[pl]=Wyścigi gokartów
	GenericName[ro]=Un joc de curse cu carturi
	Exec=supertuxkart
	Terminal=false
	StartupNotify=false
	Type=Application
	Categories=Game;ArcadeGame;
	Keywords=tux;game;race;
	HEREDOC

	# Icon
	cp ./$APP.AppDir/data/supertuxkart_512.png ./$APP.AppDir
	mv ./$APP.AppDir/supertuxkart_512.png ./$APP.AppDir/$APP.png

	# AppRun
	mv ./$APP.AppDir/run_game.sh ./$APP.AppDir/AppRun && chmod a+x ./"$APP".AppDir/AppRun
}

_appimage_basics

# CONVERT THE APPDIR TO AN APPIMAGE
APPNAME=$(cat ./"$APP".AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
REPO="SuperTuxKart-appimage"
TAG="latest"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*x86_64.AppImage.zsync"

ARCH=x86_64 _appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
	-u "$UPINFO" \
	./"$APP".AppDir "$APPNAME"_"$VERSION"-x86_64.AppImage

if ! test -f ./*.AppImage; then
	echo "No AppImage available."; exit 1
fi
