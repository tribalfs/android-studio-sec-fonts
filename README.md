# Android Studio SEC Fonts

Both the [SESL modules](https://github.com/tribalfs/sesl-androidx) 
and the [OneUI Design Library](https://github.com/tribalfs/oneui-design)
libraries use a custom fontFamily which is not included in the stock fonts included in Android Studio. 
This causes [Android Studio Layout Preview|Editor](https://developer.android.com/studio/write/layout-editor) 
to not work properly when using any of these libraries. 

This repository contains a Samsung fonts pack that needs to be added to the AOSP ones included in Android
Studio in order to fix this issue.

## Usage

Download
the [repo](https://github.com/tribalfs/android-studio-sec-fonts/archive/refs/heads/main.zip)
archive and extract it.

Navigate to the "plugins/design-tools/resources/layoutlib/data/fonts" directory inside your Android
Studio
folder, then:

_Before proceeding, make a backup of this "fonts" folder first as you need to (temporarily) restore
this everytime you need update Android Studio.

- Add the all "*.tff" files from the "secfonts" folder of the downloaded archive.
- Open the "fonts.xml" file and append to inside the `<familyset>` tag the contents from
  inside `<familyset>` tag of the "fonts.xml" found inside "secfonts" folder.
- If present, open the "font_fallback.xml" file and append to inside the `<familyset>` tag the contents from
  inside `<familyset>` tag of the "fonts.xml" found inside "secfonts" folder.

For Windows, you can run the included `SecFontsFix.ps1` in Windows PowerShell to automatically
perform the above steps including the backing up and restoring the original "fonts" directory.
