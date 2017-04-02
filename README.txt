## Steps to setting up environment
Make sure you're using Quartus Prime tools 16.1
Some weird errors appear when using prime tools 16.0

1. Clone to directory
2. Start up quartus prime
3. open Qsys and open nes_nios.qsys
4. generate hdl files.
5. Compile and verify (there should be no errors)

Set up NIOS

Open up build tools for nios ii

1. click new application from bsp and template
2. Browse to project folder and click .sopcinfo
3. name the project nes_nios
4. Choose hello World template
5. *Important* go to git and revert changes to hello_world.c
6. Generate BSp
7. Test hello_world
