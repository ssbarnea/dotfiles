#!/bin/sh

#################################################################
#
#	Kaspersky Anti-Virus for Mac uninstallation script
#	Requires admin password to execute
#
#################################################################
: ${VERBOSE:=0}
if [ $VERBOSE != 0 ]; then
    RMVERBARG=-v
else
    RMVERBARG=
fi

KAVBIN_DIR="/Library/Application Support/Kaspersky Lab/KAV/Binaries"

LAUNCHDAEMON_DIR="/Library/LaunchDaemons"
LAUNCHDAEMON_KAV_ID="com.kaspersky.kav"
LAUNCHDAEMON_KAV_PLIST="$LAUNCHDAEMON_DIR/$LAUNCHDAEMON_KAV_ID.plist"

LAUNCHAGENT_DIR="/Library/LaunchAgents"
LAUNCHAGENT_KAV_GUI_ID="com.kaspersky.kav.gui"
LAUNCHAGENT_KAV_GUI_PLIST="$LAUNCHAGENT_DIR/$LAUNCHAGENT_KAV_GUI_ID.plist"

KEXT_DIR="/System/Library/Extensions"

KLIF_BUNDLE_ID="com.kaspersky.kext.klif"
KLIF_KEXT_PATH="$KEXT_DIR"/klif.kext
DELOLD_KLIF_BUNDLE_DIR="/Library/Application Support/Kaspersky Lab/klif/klif.kext"
DELOLD_KLIF_PLIST="/Library/LaunchDaemons/com.kaspersky.klif_loader.plist"

KLNKE_BUNDLE_ID="com.kaspersky.nke"
KLNKE_KEXT_PATH="$KEXT_DIR"/klnke.kext

KLNKEINTERCEPTORS_BUNDLE_ID="com.kaspersky.nke.interceptors"
KLNKEINTERCEPTORS_KEXT_PATH="$KEXT_DIR"/klnkeinterceptors.kext

APP_BUNDLE="/Applications/Kaspersky Anti-Virus For Mac.app"
APP_BUNDLE_OLD="/Applications/Kaspersky Anti-Virus.app"
APP_SUPPORT_FOLDER="/Library/Application Support/Kaspersky Lab"
CACHES_FOLDER="/Library/Caches/com.kaspersky.kav"

LOG_DIR="Library/Logs/Kaspersky Lab"

USERS_DIR="/Users"

LIB_RECEIPTS="/Library/Receipts"
LIB_RECEIPTS_OAS="$LIB_RECEIPTS"/oas.pkg
LIB_RECEIPTS_WEBAV="$LIB_RECEIPTS"/WebAV.pkg
LIB_RECEIPTS_PARCTL="$LIB_RECEIPTS"/ParCtl.pkg
LIB_RECEIPTS_CORE="$LIB_RECEIPTS"/Core.pkg
LIB_RECEIPTS_FINDERPLUGIN="$LIB_RECEIPTS"/FinderCMPlugin.pkg
LIB_RECEIPTS_WKS_OLD="$LIB_RECEIPTS"/wks.pkg
LIB_RECEIPTS_WKS="$LIB_RECEIPTS"/"Kaspersky Network Agent.pkg"
LIB_RECEIPTS_WKSCONNECTOR="$LIB_RECEIPTS"/"WKSConnector.pkg"
LIB_RECEIPTS_WEBTOOLBAR="$LIB_RECEIPTS"/"WebToolBar.pkg"
LIB_RECEIPTS_VKBD="$LIB_RECEIPTS"/"Vkbd.pkg"

KAV_SERVICE="/System/Library/Services/KAVService.service"

KAVSYMLINK_DIR="/usr/bin"

MANPAGES_DIR="/usr/share/man/man1"

FINDER_PLUGIN="/Library/Contextual Menu Items/KavFinderCMPlugIn.plugin"

# uninstall extensions

firefox_uninstall()
{
    echo "Uninstalling Kaspersky $FIREFOX_EXT_NAME extension..."

    rm $RMVERBARG -f "$FIREFOX_EXT_PATH"
    if [ $? != 0 ]; then
        echo "Cannot remove extension from Library"
        return 1
    fi
}

chrome_uninstall()
{
    echo "Uninstalling $CHROME_EXT_NAME extension..."

    # TODO
    OLDIFS=$IFS
    IFS=$'\n'
    # foreach installed Google Chrome, edit external_extensions.json
    CHROME_BROWSERS=$(mdfind "kMDItemCFBundleIdentifier == 'com.google.Chrome'")
    for c in $CHROME_BROWSERS
    do
        PREF_PATH=$c"/Contents/Extensions"
        PREF_FILE=$PREF_PATH"/external_extensions.json"
        SWAPFILE="$(mktemp /tmp/XXXXXX)"

        if [ -e "$PREF_FILE" ];
        then
            COUNTER=0
            SKIP=false
            SKIPCOUNTER=0

            INSERTPOINT=$(grep -n "$CHROME_MAGIC" "$PREF_FILE" | cut -f1 -d:)

            cat "$PREF_FILE" | while read LINE; do
                let "COUNTER"++;
                if [ "$COUNTER" == "$INSERTPOINT" ]; then
                    SKIP="true"
                fi

                if [ "$SKIP" == "true" ]; then
                    let "SKIPCOUNTER"++;
                    if [ "$SKIPCOUNTER" == 4 ]; then
                        SKIP="false"
                    fi
                else
                    echo "$LINE" >> "$SWAPFILE";
                fi
            done
            mv "$SWAPFILE" "$PREF_FILE"
            chmod 777 "$PREF_FILE"
        fi
        done
    IFS=$OLDIFS

    return 0
}

safari_uninstall()
{
    echo "Unstalling $SAFARI_EXT_NAME Extension"

    # Delete KasperskyURLAdvisor.safariextz
    rm "$SAFARI_DEST_PATH"

    # Edit Extensions.plist
    PYTHON_COMMAND_UNINSTALL="uninstallExtension('$SAFARI_EXT_NAME')"
    python -c "$PYTHON_ENVIRONMENT$PYTHON_COMMAND_UNINSTALL"
    if [ $? != 0 ]; then
        echo "Cannot remove extension $SAFARI_EXT_NAME"
        return 1
    fi

    return 0
}

# uninstall URL Advisor extensions
FIREFOX_DEST_PATH="/Library/Application Support/Mozilla/Extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
FIREFOX_EXT_PATH="$FIREFOX_DEST_PATH/urladvisor@kaspersky.com"
FIREFOX_EXT_NAME="URLAdvisor"
FIREFOX_BROWSERS=""
SAFARI_EXT_PATH="$HOME/Library/Safari/Extensions"
SAFARI_EXT_NAME="KasperskyURLAdvisor.safariextz"
SAFARI_DEST_PATH="$SAFARI_EXT_PATH/$SAFARI_EXT_NAME"
EXTZPLIST_PATH="$SAFARI_EXT_PATH/Extensions.plist"
PYTHON_ENVIRONMENT="""
import os.path
import plistlib
import sys
import xml.parsers.expat as expat
import commands

def readExtensionsPlistObject(path):
    os.system('/usr/bin/plutil -convert xml1 %s' % path )
    try:
        extensionPlist = plistlib.readPlist(path)
        if not(extensionPlist.has_key('Installed Extensions')):
        	extensionPlist['Installed Extensions'] = []
    except:
        extensionPlist = { 'Installed Extensions' : [],
                           'Version'              : 1 }
    return extensionPlist

def uninstallExtensionBody(extensionPlist, extensionArchiveName):
    flag = True
    while flag:
        flag = False
        for anEntry in extensionPlist['Installed Extensions']:
            if anEntry['Archive File Name'] == extensionArchiveName:
                flag = True
                extensionPlist['Installed Extensions'].remove(anEntry)
    return extensionPlist

def uninstallExtension(extensionArchiveName):
    path = '$EXTZPLIST_PATH'
    extensionPlist = readExtensionsPlistObject(path)
    ###
    extensionPlist = uninstallExtensionBody(extensionPlist, extensionArchiveName)
    ###
    plistlib.writePlist(extensionPlist, path)

def installExtension(extensionArchiveName, extensionBundleName):
    path = '$EXTZPLIST_PATH'
    extensionPlist = readExtensionsPlistObject(path)
    ###
    extensionPlist = uninstallExtensionBody(extensionPlist, extensionArchiveName)
    theEntry = {}
    theEntry['Archive File Name'] = extensionArchiveName
    theEntry['Bundle Directory Name'] = extensionBundleName
    theEntry['Enabled'] = True
    extensionPlist['Installed Extensions'].append(theEntry)
    ###
    plistlib.writePlist(extensionPlist, path)
"""
SAFARI_BROWSERS=""
CHROME_EXT_PATH=""
CHROME_EXT_NAME="KasperskyUrlAdvisor"
CHROME_DEST_PATH=""
PREF_PATH=""
CHROME_BROWSERS=""
CHROME_MAGIC="ddoleachckhhdmhpbkddgechjfhnphpe"

safari_uninstall;
chrome_uninstall;
firefox_uninstall;

# uninstall Virtual Keyboard extensions
FIREFOX_DEST_PATH="/Library/Application Support/Mozilla/Extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
FIREFOX_EXT_PATH="$FIREFOX_DEST_PATH/wvkbd@kaspersky.com"
FIREFOX_EXT_NAME="VirtualKeyboard"
FIREFOX_BROWSERS=""
SAFARI_EXT_PATH="$HOME/Library/Safari/Extensions"
SAFARI_EXT_NAME="KasperskyVirtualKeyboard.safariextz"
SAFARI_DEST_PATH="$SAFARI_EXT_PATH/$SAFARI_EXT_NAME"
EXTZPLIST_PATH="$SAFARI_EXT_PATH/Extensions.plist"
SAFARI_BROWSERS=""
CHROME_EXT_PATH=""
CHROME_EXT_NAME="KasperskyVirtualKeyboard"
CHROME_DEST_PATH=""
PREF_PATH=""
CHROME_BROWSERS=""
CHROME_MAGIC="mcobjbefejmnadahpjbfibgkgchhmjke"

safari_uninstall;
chrome_uninstall;
firefox_uninstall;

#reload connectors

echo ""
echo "Removing the connection with klnagent..."
KL_NAGENT_FOLDER="$APP_SUPPORT_FOLDER/klnagent/"
KL_NAGENT_EXEC="$KL_NAGENT_FOLDER/Binaries/klnagent"
KL_NAGENT_CONF="$APP_SUPPORT_FOLDER/klnagent_conf/connectors.d/wks8.conf"

if [ -e "$KL_NAGENT_CONF" ]
	then
		rm $RMVERBARG -rf "$KL_NAGENT_CONF";
		rmdir "$APP_SUPPORT_FOLDER/klnagent_conf/connectors.d"
		rmdir "$APP_SUPPORT_FOLDER/klnagent_conf/"
		if [ -e "$KL_NAGENT_EXEC" ]
		then
			"$KL_NAGENT_EXEC" -reload-connectors;
		fi
fi


#Stop KAVService if running
echo ""
echo "Stopping service..."
KAVPID=$(ps -axwo pid,command | grep -v grep | grep "$KAV_SERVICE" | awk '{print $1}')
if [ "$KAVPID" != "" ]
then
	kill -s KILL $KAVPID
fi

#Stop the UI application if running
echo ""
echo "Stopping application..."
KAVPID=$(ps -axwo pid,command | grep -v grep | grep "Contents/MacOS/kav_app" | awk '{print $1}')
if [ "$KAVPID" != "" ]
then
	kill -s KILL $KAVPID
fi

#Stop the old UI application if running
echo ""
echo "Stopping application..."
KAVPID=$(ps -axwo pid,command | grep -v grep | grep "Contents/MacOS/kav" | awk '{print $1}')
if [ "$KAVPID" != "" ]
then
	kill -s KILL $KAVPID
fi

#Stop the UI agent if running
echo ""
echo "Stopping agent..."
KAVPID=$(ps -axwo pid,command | grep -v grep | grep "Contents/MacOS/kav_agent" | awk '{print $1}')
if [ "$KAVPID" != "" ]
then
	kill -s KILL $KAVPID
fi

#Stop kav daemon
echo ""
echo "Stopping daemon..."
KAVPID=$(ps -axwo pid,command | grep -v grep | grep "KAV/Binaries/kav" | awk '{print $1}')
if [ "$KAVPID" != "" ]
then
	kill -s TERM $KAVPID
	for ((t = 0; t < 10; t++))
	do
		PID=$(ps -axwo pid,command $KAVPID | grep -v grep | grep "KAV/Binaries/kav" | awk '{print $1}')
		if [ "$PID" == "$KAVPID" ]
		then
			sleep 0.5
		else
			break
		fi
	done
fi

#Unload kav daemon from launchd
echo ""
echo "Unloading daemon from launchd..."
if [ "$(launchctl list | grep $LAUNCHDAEMON_KAV_ID)" != "" ]
then
	launchctl unload "$LAUNCHDAEMON_KAV_PLIST"
fi

#Unload klif kext if registered
echo ""
echo "Unloading klif kernel extensions (if any)..."
if [ "$(kextstat | grep ${KLIF_BUNDLE_ID})" != "" ]
then
	kextunload -b "$KLIF_BUNDLE_ID"
fi

#remove klif kext
if [ -d "$KLIF_KEXT_PATH" ]
then
	rm $RMVERBARG -rf "$KLIF_KEXT_PATH"
fi

#remove klif kext
if [ -d "$DELOLD_KLIF_BUNDLE_DIR" ]
then
	rm $RMVERBARG -rf "$DELOLD_KLIF_BUNDLE_DIR"
fi


#remove klif kext
if [ -e "$DELOLD_KLIF_PLIST" ]
then
	rm $RMVERBARG -rf "$DELOLD_KLIF_PLIST"
fi

#Unload klnke kext if registered
echo ""
echo "Unloading klnke kernel extensions (if any)..."
if [ "$(kextstat | grep ${KLNKE_BUNDLE_ID})" != "" ]
then
	kextunload -b "$KLNKE_BUNDLE_ID"
fi

#remove klnke kext
if [ -d "$KLNKE_KEXT_PATH" ]
then
	rm $RMVERBARG -rf "$KLNKE_KEXT_PATH"
fi

#Unload klnkeinterceptors kext if registered
echo ""
echo "Unloading klnkeinterceptors kernel extensions (if any)..."
if [ "$(kextstat | grep ${KLNKEINTERCEPTORS_BUNDLE_ID})" != "" ]
then
	kextunload -b "$KLNKEINTERCEPTORS_BUNDLE_ID"
fi

#remove klnkeinterceptors kext
if [ -d "$KLNKEINTERCEPTORS_KEXT_PATH" ]
then
	rm $RMVERBARG -rf "$KLNKEINTERCEPTORS_KEXT_PATH"
fi

#remove kimuls
echo ""
echo "Unloading kimul kernel extensions (if any)..."
KIMULS=$(kextstat -l | grep "com.kaspersky.kext.kimul" | awk '{print $6}')
if [ "$KIMULS" != "" ]
then
    for KIMUL in $KIMULS
    do
		kextunload -b "$KIMUL"
    done
fi

#remove daemon plist
if [ -f "$LAUNCHDAEMON_KAV_PLIST" ]
then
	rm $RMVERBARG "$LAUNCHDAEMON_KAV_PLIST"
fi

#remove agent plist
if [ -f "$LAUNCHAGENT_KAV_GUI_PLIST" ]
then
	sudo -u "$USER" launchctl unload "$LAUNCHAGENT_KAV_GUI_PLIST"
	rm $RMVERBARG "$LAUNCHAGENT_KAV_GUI_PLIST"
fi

#remove GUI app
echo ""
echo "Processing \"$APP_BUNDLE\" bundle..."
if [ -d "$APP_BUNDLE" ]
then
	rm $RMVERBARG -rf "$APP_BUNDLE"
fi

#remove old GUI app
echo ""
echo "Processing \"$APP_BUNDLE_OLD\" bundle..."
if [ -d "$APP_BUNDLE_OLD" ]
then
	rm $RMVERBARG -rf "$APP_BUNDLE_OLD"
fi


#remove App Support folder
echo ""
echo "Processing \"/$APP_SUPPORT_FOLDER\" folder..."
if [ -d "/$APP_SUPPORT_FOLDER" ]
then
	rm $RMVERBARG -rf "/$APP_SUPPORT_FOLDER/KAV"
	rm $RMVERBARG -rf "/$APP_SUPPORT_FOLDER/klconnector"
fi

#remove users App Support folders
for USERHOME in $(ls "$USERS_DIR")
do
	if [ -d "$USERS_DIR/$USERHOME/$APP_SUPPORT_FOLDER" ]
	then
		echo ""
		echo "Processing \"$USERS_DIR/$USERHOME/$APP_SUPPORT_FOLDER\" folder..."
		rm $RMVERBARG -rf "$USERS_DIR/$USERHOME/$APP_SUPPORT_FOLDER"
	fi
done

#clear cache folders
echo ""
echo "Removing caches..."
if [ -d "$CACHES_FOLDER" ]
then
	rm $RMVERBARG -rf "$CACHES_FOLDER"
fi

#remove KAVService

echo ""
echo "Removing service..."
if [ -d "$KAV_SERVICE" ]
then
	rm $RMVERBARG -rf "$KAV_SERVICE"

	OSMINOR=$(system_profiler SPSoftwareDataType | awk '/System Version/ {print $6}' | awk -F"." '{printf "%d\n", $2}')

	if [ $OSMINOR -gt 4 ]
	then
		sudo -u "$USER" /System/Library/CoreServices/pbs -existing_languages
	fi
fi

#remove kav symlink

echo
echo "Removing symbolic link..."
if [ -e "$KAVSYMLINK_DIR"/kav ]
then
	rm $RMVERBARG -f "$KAVSYMLINK_DIR"/kav
fi

for USERHOME in $(ls "$USERS_DIR")
do
	for SCOPE in kav kav2012 kav_agent
	do
		if [ -f "$USERS_DIR/$USERHOME/Library/Preferences/com.kaspersky.$SCOPE.plist" ]
		then
			rm $RMVERBARG -f "$USERS_DIR/$USERHOME/Library/Preferences/com.kaspersky.$SCOPE.plist"
			rm $RMVERBARG -f "$USERS_DIR/$USERHOME/Library/Preferences/com.kaspersky.$SCOPE.plist.lockfile"
		fi
	done
done

#remove authorization rights
echo
echo "Removing authorization rights..."
/usr/libexec/PlistBuddy -c "Delete :rights:com.kaspersky.licensing"   /etc/authorization
/usr/libexec/PlistBuddy -c "Delete :rights:com.kaspersky.preferences" /etc/authorization
/usr/libexec/PlistBuddy -c "Delete :rights:com.kaspersky.parental"    /etc/authorization

#remove man pages
echo
echo "Removing man pages..."
rm $RMVERBARG -f "$MANPAGES_DIR"/kav.1

#remove Finder Plugin
echo ""
echo "Removing Finder Contextual Menu..."
if [ -d "$FINDER_PLUGIN" ]
then
	rm $RMVERBARG -rf "$FINDER_PLUGIN"
	osascript -e 'tell application "Finder"' -e 'quit' -e 'delay 2' -e 'select window of desktop' -e 'end tell'
	osascript -e 'tell application "Kaspersky Anti-Virus Uninstaller"' -e 'activate' -e 'end tell'
fi

#remove daemon traces
echo ""
echo "Removing daemon traces from \"/$LOG_DIR\"..."
if [ -d "/$LOG_DIR" ]
then
	rm $RMVERBARG -rf "/$LOG_DIR"
fi

echo ""
echo "Removing daemon traces from \"/var/log\"..."
rm $RMVERBARG -f /var/log/kav_daemon*.log

#remove gui traces
for USERHOME in $(ls "$USERS_DIR")
do
	echo ""
	echo "Removing gui traces from \"$USERS_DIR/$USERHOME/$LOG_DIR\"..."
	rm $RMVERBARG -rf "$USERS_DIR/$USERHOME/$LOG_DIR"
done


#remove Receipts
echo ""
echo "Processing \"$LIB_RECEIPTS_CORE\" installer receipt..."
if [ -d "$LIB_RECEIPTS_CORE" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_CORE"
fi

echo "Processing \"$LIB_RECEIPTS_OAS\" installer receipt..."
if [ -d "$LIB_RECEIPTS_OAS" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_OAS"
fi

echo "Processing \"$LIB_RECEIPTS_WEBAV\" installer receipt..."
if [ -d "$LIB_RECEIPTS_WEBAV" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_WEBAV"
fi

echo "Processing \"$LIB_RECEIPTS_PARCTL\" installer receipt..."
if [ -d "$LIB_RECEIPTS_PARCTL" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_PARCTL"
fi

echo "Processing \"$LIB_RECEIPTS_FINDERPLUGIN\" installer receipt..."
if [ -d "$LIB_RECEIPTS_FINDERPLUGIN" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_FINDERPLUGIN"
fi

echo "Processing \"$LIB_RECEIPTS_WKS\" installer receipt..."
if [ -d "$LIB_RECEIPTS_WKS" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_WKS"
fi

echo "Processing \"$LIB_RECEIPTS_WKSCONNECTOR\" installer receipt..."
if [ -d "$LIB_RECEIPTS_WKS" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_WKSCONNECTOR"
fi

echo "Processing \"$LIB_RECEIPTS_WKS_OLD\" installer receipt..."
if [ -d "$LIB_RECEIPTS_WKS_OLD" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_WKS_OLD"
fi

echo "Processing \"$LIB_RECEIPTS_WEBTOOLBAR\" installer receipt..."
if [ -d "$LIB_RECEIPTS_WEBTOOLBAR" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_WEBTOOLBAR"
fi

echo "Processing \"$LIB_RECEIPTS_VKBD\" installer receipt..."
if [ -d "$LIB_RECEIPTS_VKBD" ]
then
	rm $RMVERBARG -rf "$LIB_RECEIPTS_VKBD"
fi



#remove Kaspersky Lab Folder if empty
rmdir "/Library/Application Support/Kaspersky Lab"

#forget the packages

if [ -e "/usr/sbin/pkgutil" ]
then
	echo "Forgetting installation packages..."
#	KAV_PKG_ID="com.kaspersky.kav";
	CORE_PKG_ID="com.kaspersky.kav.core";
	OAS_PKG_ID="com.kaspersky.kav.oas";
	WEBAV_PKG_ID="com.kaspersky.kav.webav";
	PARCTL_PKG_ID="com.kaspersky.kav.parctl";
	WKSCONN_PKG_ID="com.kaspersky.kav.wksconnector";
	WEBTOOLBAR_PKG_ID="com.kaspersky.kav.webtoolbar";
	VKBD_PKG_ID="com.kaspersky.kav.vkbd";
	FINDER_PLUGIN_PKG_ID="com.kaspersky.kav.finder_plugin";

#	if [ "$(pkgutil --pkgs | grep $KAV_PKG_ID)" != "" ]
#	then
#		echo "Forgetting Kaspersky Anti-Virus..."
#		pkgutil --forget $KAV_PKG_ID
#	fi

	if [ "$(pkgutil --pkgs | grep $CORE_PKG_ID)" != "" ]
	then
		echo "Forgetting Virus Scan..."
		pkgutil --forget $CORE_PKG_ID
	fi

	if [ "$(pkgutil --pkgs | grep $OAS_PKG_ID)" != "" ]
	then
		echo "Forgetting File Anti-Virus..."
		pkgutil --forget $OAS_PKG_ID
	fi

	if [ "$(pkgutil --pkgs | grep $WEBAV_PKG_ID)" != "" ]
	then
		echo "Forgetting Web Anti-Virus..."
		pkgutil --forget $WEBAV_PKG_ID
	fi

	if [ "$(pkgutil --pkgs | grep $PARCTL_PKG_ID)" != "" ]
	then
		echo "Forgettings Parental Control..."
		pkgutil --forget $PARCTL_PKG_ID
	fi

	if [ "$(pkgutil --pkgs | grep $WKSCONN_PKG_ID)" != "" ]
	then
		echo "Forgetting Network Agent Connector..."
		pkgutil --forget $WKSCONN_PKG_ID
	fi

	if [ "$(pkgutil --pkgs | grep $FINDER_PLUGIN_PKG_ID)" != "" ]
	then
		echo "Forgetting Finder Plugin..."
		pkgutil --forget $FINDER_PLUGIN_PKG_ID
	fi

	if [ "$(pkgutil --pkgs | grep $WEBTOOLBAR_PKG_ID)" != "" ]
	then
		echo "Forgetting URL Advisor..."
		pkgutil --forget $WEBTOOLBAR_PKG_ID
	fi

	if [ "$(pkgutil --pkgs | grep $VKBD_PKG_ID)" != "" ]
	then
		echo "Forgetting Virtual Keybord..."
		pkgutil --forget $VKBD_PKG_ID
	fi

fi

echo ""
echo "Kaspersky Anti-Virus for Mac is successfully uninstalled from your computer."
