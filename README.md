# Android Studio SEC Fonts

As described in [this issue](https://github.com/OneUIProject/OneUI-Design-Library/issues/58), using
one of our One UI libraries (both [sesl](https://github.com/OneUIProject/oneui-core) and the
old [Design lib](https://github.com/OneUIProject/OneUI-Design-Library)) will cause issues with
the [Android Studio Layout Editor](https://developer.android.com/studio/write/layout-editor). This
happens because Samsung's text styles use a custom fontFamily which is not available on AOSP. This
repository contains a Samsung fonts pack that needs to be added to the AOSP ones included in Android
Studio.

## Usage

Download
the [repo](https://github.com/tribalfs/android-studio-sec-fonts/archive/refs/heads/main.zip)
archive and extract it.

Navigate to the "plugins/design-tools/resources/layoutlib/data/fonts" directory inside your Android
Studio
folder, then:

_Before proceeding, make a backup of this "fonts" folder first as you need to (temporarily) restore
this everytime you need update Android Studio_

- Add the all "*.tff" files from the "secfonts" folder of the downloaded archive.
- Open the "fonts.xml" file and append to inside the `<familyset>` tag the contents from
  inside `<familyset>` tag of the "fonts.xml" found inside "secfonts" folder.

For Windows, you can run `SecFontsFix.ps1` in Windows PowerShell to automatically perform the above
including backing and and restoring the original "fonts" directory.
