================================================================================

                           PascalSDK Headers Condenser

================================================================================

Description
------------------------------
This program is developed as a console utility for project PascalSDK - you can
find PascalSDK project in the following repository:

  https://github.com/TheLazyTomcat/PascalSDK

Its function is to take translated header files and, using few other supporting
files, combine or condense them into a single unit for easier use.

Note that the program was written for a single purpose and requires that the
files which are being condensed to be specially formatted. Therefore it is not
suitable for general use.



Command-line parameters
----------------------------------------
Mandatory parameters:

  -s source_files

    Comma-separated list of source files (translated headers) that are to be
    condensed. The file names can be listed with absolute or relative paths if
    they do not reside in the current directory.

  -t template_file

    Name of a file that contains a valid template into which the condensed code
    will be inserted. Can be relative or absolute path.

  -o output_file

    Name of a file to which the resulting condesed code will be saved. The file
    does not need to exist (if it does, it will be completely rewritten), but
    potential directory where it will saved must exist. Can be relative or
    absolute path.

Optional parameters (none of them is required, but if any is present, it must
be valid):

  -d define_files

    Comma-separated list of files from which defines (eg. conditional
    compilation symbols) will be loaded. The defines from all files are merged
    into one block and then inserted to marked spot in the output template.
    File names can be given with relative or absolute path.

  -c source_file

    File from which a unit description will be loaded. Can be relative or
    absolute path.

  -h
  --help

    When present, disables any processing and shows short help for the program.

  --split

    Enables insertion of visual splitters (code decoration in form of
    horizontal lines) into the condensed code at original headers boundaries.

  --debug

    Disables saving of the output, the processing is not changed in any other
    way.



Repositories
----------------------------------------
You can get actual copy of this project on the following git repository:

  https://github.com/TheLazyTomcat/PascalSDK_Headers_Condenser



Licensing
----------------------------------------
Everything (source codes, binaries, ...) is licensed under Mozilla Public
License Version 2.0. You can find full text of this license in file license.txt
or on web page https://www.mozilla.org/MPL/2.0/.



Authors, contacts, links
----------------------------------------
František Milt, frantisek.milt@gmail.com

If you find this project useful, please consider making a small donation using
the following link:

  https://www.paypal.me/FMilt



Copyright
----------------------------------------
©2023 František Milt, all rights reserved